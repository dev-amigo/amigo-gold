import Foundation
import Combine

/// Service for fetching real-time PAXG price from CoinGecko API
/// Includes caching to avoid excessive API calls
@MainActor
final class PriceOracleService: ObservableObject {
    
    // MARK: - Published State
    
    @Published var isLoading = false
    @Published var cachedPrice: Decimal?
    @Published var lastUpdated: Date?
    
    // MARK: - Configuration
    
    private let cacheExpiration: TimeInterval = 300  // 5 minutes
    private let coingeckoAPIKey: String?
    
    // MARK: - Cache
    
    private struct PriceCache {
        let price: Decimal
        let timestamp: Date
        
        var isValid: Bool {
            return Date().timeIntervalSince(timestamp) < 300  // 5 min expiration
        }
    }
    
    private var cache: PriceCache?
    
    // MARK: - Initialization
    
    init(apiKey: String? = nil) {
        self.coingeckoAPIKey = apiKey
        AppLogger.log("💰 PriceOracleService initialized", category: "oracle")
    }
    
    // MARK: - Fetch PAXG Price
    
    /// Fetch current PAXG/USD price from CoinGecko
    /// Returns cached value if still valid
    /// - Returns: PAXG price in USD
    func fetchPAXGPrice() async throws -> Decimal {
        // Return cached price if valid
        if let cache = cache, cache.isValid {
            AppLogger.log("📊 Using cached PAXG price: $\(cache.price)", category: "oracle")
            return cache.price
        }
        
        isLoading = true
        defer { isLoading = false }
        
        AppLogger.log("🔄 Fetching fresh PAXG price from CoinGecko...", category: "oracle")
        
        do {
            // CoinGecko API endpoint for PAX Gold (pax-gold)
            let urlString = "https://api.coingecko.com/api/v3/simple/price?ids=pax-gold&vs_currencies=usd"
            
            guard let url = URL(string: urlString) else {
                throw PriceOracleError.invalidURL
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.timeoutInterval = 10
            
            // Add API key if provided (for higher rate limits)
            if let apiKey = coingeckoAPIKey {
                request.setValue(apiKey, forHTTPHeaderField: "x-cg-pro-api-key")
            }
            
            // Fetch data
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Validate response
            guard let httpResponse = response as? HTTPURLResponse else {
                throw PriceOracleError.invalidResponse
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw PriceOracleError.httpError(statusCode: httpResponse.statusCode)
            }
            
            // Parse JSON
            // Expected format: { "pax-gold": { "usd": 4183.00 } }
            struct CoinGeckoResponse: Codable {
                let paxGold: PriceData
                
                enum CodingKeys: String, CodingKey {
                    case paxGold = "pax-gold"
                }
                
                struct PriceData: Codable {
                    let usd: Double
                }
            }
            
            let decoder = JSONDecoder()
            let result = try decoder.decode(CoinGeckoResponse.self, from: data)
            let price = Decimal(result.paxGold.usd)
            
            // Update cache
            cache = PriceCache(price: price, timestamp: Date())
            cachedPrice = price
            lastUpdated = Date()
            
            AppLogger.log("✅ PAXG price fetched: $\(price)", category: "oracle")
            
            return price
            
        } catch {
            AppLogger.log("❌ Failed to fetch PAXG price: \(error.localizedDescription)", category: "oracle")
            
            // If fetch fails but we have expired cache, return it anyway
            if let cache = cache {
                AppLogger.log("⚠️ Using stale cached price: $\(cache.price)", category: "oracle")
                return cache.price
            }
            
            throw error
        }
    }
    
    /// Clear cached price (force refresh on next fetch)
    func clearCache() {
        cache = nil
        cachedPrice = nil
        lastUpdated = nil
        AppLogger.log("🗑️ Price cache cleared", category: "oracle")
    }
}

// MARK: - Errors

enum PriceOracleError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case parsingError
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid CoinGecko API URL"
        case .invalidResponse:
            return "Invalid response from CoinGecko"
        case .httpError(let statusCode):
            return "HTTP error \(statusCode) from CoinGecko"
        case .parsingError:
            return "Failed to parse price data"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Mock/Fallback

extension PriceOracleService {
    
    /// Return mock price for development/testing
    static func mockPrice() -> Decimal {
        return 4183.0  // $4,183/oz (approximate current PAXG price)
    }
}

