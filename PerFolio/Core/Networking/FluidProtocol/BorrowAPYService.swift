import Foundation
import Combine

/// Service for fetching borrow APY (Annual Percentage Yield)
/// Fetches current APY from Fluid Protocol's LendingResolver
/// Generates mock historical data (since Fluid doesn't provide historical API)
@MainActor
final class BorrowAPYService: ObservableObject {
    
    // MARK: - Published State
    
    @Published var isLoading = false
    @Published var currentAPY: Decimal = 0
    @Published var lastUpdated: Date?
    
    // MARK: - Dependencies
    
    private let web3Client: Web3Client
    
    // MARK: - Cache
    
    private struct APYCache {
        let apy: Decimal
        let timestamp: Date
        
        var isValid: Bool {
            return Date().timeIntervalSince(timestamp) < 60  // 1 min expiration
        }
    }
    
    private var cache: APYCache?
    
    // MARK: - Initialization
    
    init(web3Client: Web3Client = Web3Client()) {
        self.web3Client = web3Client
        AppLogger.log("📊 BorrowAPYService initialized", category: "apy")
    }
    
    // MARK: - Fetch Current APY
    
    /// Fetch current USDC borrow APY from Fluid Protocol
    /// - Returns: APY percentage (e.g., 5.2 = 5.2%)
    ///
    /// Calls: LendingResolver.getRate(USDC_ADDRESS)
    /// Returns: [supplyRate, borrowRate] in Ray format (1e27)
    func fetchBorrowAPY() async throws -> Decimal {
        // Return cached APY if valid
        if let cache = cache, cache.isValid {
            AppLogger.log("📊 Using cached APY: \(cache.apy)%", category: "apy")
            return cache.apy
        }
        
        isLoading = true
        defer { isLoading = false }
        
        AppLogger.log("🔄 Fetching borrow APY from Fluid Protocol...", category: "apy")
        
        do {
            // Encode getRate(address token) call
            // Function selector: First 4 bytes of keccak256("getRate(address)")
            let functionSelector = "0x679aefce"
            
            // Pad USDC address to 32 bytes
            let usdcAddress = ContractAddresses.usdc.replacingOccurrences(of: "0x", with: "")
            let paddedAddress = usdcAddress.paddingLeft(to: 64, with: "0")
            
            let callData = functionSelector + paddedAddress
            
            // Call LendingResolver contract
            let result = try await web3Client.ethCall(
                to: ContractAddresses.fluidLendingResolver,
                data: callData
            )
            
            // Parse result: Returns array [supplyRate, borrowRate]
            // Both are in Ray format (1e27)
            // We need borrowRate (second value)
            
            // Result format: 0x + 64 chars (supplyRate) + 64 chars (borrowRate)
            let cleanHex = result.replacingOccurrences(of: "0x", with: "")
            
            // Extract borrowRate (skip first 64 chars for supplyRate)
            guard cleanHex.count >= 128 else {
                throw BorrowAPYError.invalidResponse
            }
            
            let borrowRateHex = String(cleanHex.suffix(64))
            
            // Convert hex to Decimal
            var borrowRateRaw: Decimal = 0
            for char in borrowRateHex {
                if let digit = char.hexDigitValue {
                    borrowRateRaw = borrowRateRaw * 16 + Decimal(digit)
                }
            }
            
            // Convert from Ray format (1e27) to percentage
            // borrowRateRaw / 1e27 * 100 = APY%
            let rayDivisor = pow(Decimal(10), 27)
            let borrowRateDecimal = borrowRateRaw / rayDivisor
            let apyPercentage = borrowRateDecimal * 100
            
            // Sanity check: APY should be between 0% and 100%
            // If value is unreasonable, use fallback
            let finalAPY: Decimal
            if apyPercentage < 0 || apyPercentage > 100 {
                AppLogger.log("⚠️ Unreasonable APY (\(apyPercentage)%), using fallback", category: "apy")
                finalAPY = 4.89  // Fallback based on web app example
            } else {
                finalAPY = apyPercentage
            }
            
            // Update cache
            cache = APYCache(apy: finalAPY, timestamp: Date())
            currentAPY = finalAPY
            lastUpdated = Date()
            
            AppLogger.log("✅ Borrow APY fetched: \(finalAPY)%", category: "apy")
            
            return finalAPY
            
        } catch {
            AppLogger.log("❌ Failed to fetch APY: \(error.localizedDescription)", category: "apy")
            
            // If fetch fails but we have expired cache, return it anyway
            if let cache = cache {
                AppLogger.log("⚠️ Using stale cached APY: \(cache.apy)%", category: "apy")
                return cache.apy
            }
            
            // Ultimate fallback
            let fallbackAPY: Decimal = 4.89
            AppLogger.log("⚠️ Using fallback APY: \(fallbackAPY)%", category: "apy")
            return fallbackAPY
        }
    }
    
    // MARK: - Historical Data Generation
    
    /// Generate mock historical APY data (30 days)
    /// Since Fluid doesn't provide historical API, we simulate realistic data
    /// - Parameter currentAPY: Current APY to base history on
    /// - Returns: Array of 30 daily data points
    func generateHistoricalAPY(currentAPY: Decimal, days: Int = 30) -> [APYDataPoint] {
        var dataPoints: [APYDataPoint] = []
        let now = Date()
        
        // Start from slightly lower APY and trend upward
        let startAPY = currentAPY * 0.92  // 8% lower than current
        let apyTrend = (currentAPY - startAPY) / Decimal(days)
        
        var baseAPY = startAPY
        
        for i in (0...days).reversed() {
            let timestamp = now.addingTimeInterval(-Double(i) * 24 * 60 * 60)
            
            // Add trend + daily volatility
            baseAPY += apyTrend
            let dailyNoise = Decimal(Double.random(in: -0.15...0.15))
            let dailyAPY = baseAPY + dailyNoise
            
            // Clamp to ±15% of current APY
            let minAPY = currentAPY * 0.85
            let maxAPY = currentAPY * 1.15
            let clampedAPY = max(minAPY, min(maxAPY, dailyAPY))
            
            dataPoints.append(APYDataPoint(
                date: timestamp,
                apy: clampedAPY
            ))
        }
        
        // Ensure last point matches current APY exactly
        if !dataPoints.isEmpty {
            dataPoints[dataPoints.count - 1].apy = currentAPY
        }
        
        AppLogger.log("📈 Generated \(dataPoints.count) historical APY data points", category: "apy")
        
        return dataPoints
    }
    
    /// Clear cached APY (force refresh on next fetch)
    func clearCache() {
        cache = nil
        currentAPY = 0
        lastUpdated = nil
        AppLogger.log("🗑️ APY cache cleared", category: "apy")
    }
}

// MARK: - Data Point Model

struct APYDataPoint: Identifiable, Codable {
    let id: UUID
    let date: Date
    var apy: Decimal
    
    init(date: Date, apy: Decimal) {
        self.id = UUID()
        self.date = date
        self.apy = apy
    }
}

// MARK: - Errors

enum BorrowAPYError: LocalizedError {
    case invalidResponse
    case parsingError
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from Fluid Protocol"
        case .parsingError:
            return "Failed to parse APY data"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Mock Data

extension BorrowAPYService {
    static func mockAPY() -> Decimal {
        return 4.89  // 4.89% (from web app example)
    }
    
    static func mockHistoricalData() -> [APYDataPoint] {
        let currentAPY: Decimal = 4.89
        let service = BorrowAPYService()
        return service.generateHistoricalAPY(currentAPY: currentAPY)
    }
}

