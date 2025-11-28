import Foundation

/// Service for handling Alchemy Account Abstraction (AA) wallet operations
/// 
/// **Features:**
/// - Gas-sponsored transactions via Alchemy Gas Manager
/// - Account Abstraction wallet management
/// - Transaction broadcasting with sponsorship policies
/// 
/// **Documentation:**
/// - https://docs.alchemy.com/docs/account-abstraction-overview
/// - https://docs.alchemy.com/docs/gas-manager-services
@MainActor
final class AlchemyAAService {
    
    // MARK: - Properties
    
    private let apiKey: String
    private let network: String
    private let rpcURL: String
    private let policyId: String?
    
    // MARK: - Initialization
    
    init(
        apiKey: String,
        network: String = "eth-mainnet",
        policyId: String? = nil
    ) {
        self.apiKey = apiKey
        self.network = network
        self.rpcURL = "https://\(network).g.alchemy.com/v2/\(apiKey)"
        self.policyId = policyId
        
        AppLogger.log("🌟 AlchemyAAService initialized", category: "alchemy")
        AppLogger.log("   Network: \(network)", category: "alchemy")
        AppLogger.log("   RPC: \(rpcURL)", category: "alchemy")
        if let policyId = policyId {
            AppLogger.log("   Policy ID: \(policyId)", category: "alchemy")
        }
    }
    
    // MARK: - Public Methods
    
    /// Send a gas-sponsored transaction using Alchemy
    /// 
    /// **Flow:**
    /// 1. Estimate gas for the transaction
    /// 2. Get gas price from network
    /// 3. Send transaction with sponsorship parameters
    /// 4. Return transaction hash
    /// 
    /// - Parameters:
    ///   - to: Destination address
    ///   - data: Transaction data (encoded function call)
    ///   - value: ETH value to send (hex string)
    ///   - from: Sender address
    /// - Returns: Transaction hash
    func sendSponsoredTransaction(
        to: String,
        data: String,
        value: String,
        from: String
    ) async throws -> String {
        AppLogger.log("🚀 Preparing sponsored transaction via Alchemy AA", category: "alchemy")
        AppLogger.log("   From: \(from)", category: "alchemy")
        AppLogger.log("   To: \(to)", category: "alchemy")
        AppLogger.log("   Data: \(data.prefix(66))...", category: "alchemy")
        AppLogger.log("   Value: \(value)", category: "alchemy")
        
        // STEP 1: Estimate gas
        let gasEstimate = try await estimateGas(
            from: from,
            to: to,
            data: data,
            value: value
        )
        AppLogger.log("⛽ Gas estimate: \(gasEstimate)", category: "alchemy")
        
        // STEP 2: Get current gas price
        let gasPrice = try await getGasPrice()
        AppLogger.log("💰 Gas price: \(gasPrice)", category: "alchemy")
        
        // STEP 3: Build transaction request
        var txParams: [String: Any] = [
            "from": from,
            "to": to,
            "data": data,
            "value": value,
            "gas": gasEstimate,
            "gasPrice": gasPrice
        ]
        
        // STEP 4: Add sponsorship parameters if policy ID is available
        if let policyId = policyId {
            txParams["paymasterAndData"] = buildPaymasterData(policyId: policyId)
            AppLogger.log("✨ Added paymaster data for sponsorship", category: "alchemy")
        }
        
        // STEP 5: Send transaction
        AppLogger.log("📤 Sending sponsored transaction...", category: "alchemy")
        let txHash = try await sendTransaction(params: txParams)
        
        AppLogger.log("✅ Transaction sent: \(txHash)", category: "alchemy")
        AppLogger.log("   View on Etherscan: https://etherscan.io/tx/\(txHash)", category: "alchemy")
        
        return txHash
    }
    
    /// Get transaction receipt
    func getTransactionReceipt(_ txHash: String) async throws -> TransactionReceipt {
        AppLogger.log("🔍 Fetching receipt for: \(txHash)", category: "alchemy")
        
        let params: [Any] = [txHash]
        let response = try await rpcCall(method: "eth_getTransactionReceipt", params: params)
        
        guard let receiptData = response as? [String: Any] else {
            throw AlchemyError.invalidResponse
        }
        
        return try TransactionReceipt(from: receiptData)
    }
    
    /// Wait for transaction confirmation
    func waitForConfirmation(_ txHash: String, maxAttempts: Int = 60) async throws {
        AppLogger.log("⏳ Waiting for confirmation: \(txHash)", category: "alchemy")
        
        for attempt in 1...maxAttempts {
            do {
                let receipt = try await getTransactionReceipt(txHash)
                if receipt.status == "0x1" {
                    AppLogger.log("✅ Transaction confirmed (attempt \(attempt)/\(maxAttempts))", category: "alchemy")
                    return
                } else if receipt.status == "0x0" {
                    throw AlchemyError.transactionFailed
                }
            } catch {
                // Receipt not available yet, wait and retry
                if attempt == maxAttempts {
                    throw AlchemyError.confirmationTimeout
                }
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            }
        }
        
        throw AlchemyError.confirmationTimeout
    }
    
    // MARK: - Private RPC Methods
    
    /// Estimate gas for transaction
    private func estimateGas(
        from: String,
        to: String,
        data: String,
        value: String
    ) async throws -> String {
        let params: [Any] = [
            [
                "from": from,
                "to": to,
                "data": data,
                "value": value
            ]
        ]
        
        let result = try await rpcCall(method: "eth_estimateGas", params: params)
        guard let gasHex = result as? String else {
            throw AlchemyError.invalidResponse
        }
        
        // Add 20% buffer for safety
        if let gasInt = Int(gasHex.replacingOccurrences(of: "0x", with: ""), radix: 16) {
            let bufferedGas = Int(Double(gasInt) * 1.2)
            return "0x" + String(bufferedGas, radix: 16)
        }
        
        return gasHex
    }
    
    /// Get current gas price
    private func getGasPrice() async throws -> String {
        let result = try await rpcCall(method: "eth_gasPrice", params: [])
        guard let gasPriceHex = result as? String else {
            throw AlchemyError.invalidResponse
        }
        return gasPriceHex
    }
    
    /// Send transaction to network
    private func sendTransaction(params: [String: Any]) async throws -> String {
        let rpcParams: [Any] = [params]
        let result = try await rpcCall(method: "eth_sendTransaction", params: rpcParams)
        
        guard let txHash = result as? String else {
            throw AlchemyError.invalidResponse
        }
        
        return txHash
    }
    
    /// Make RPC call to Alchemy
    private func rpcCall(method: String, params: [Any]) async throws -> Any {
        guard let url = URL(string: rpcURL) else {
            throw AlchemyError.invalidURL
        }
        
        let requestBody: [String: Any] = [
            "jsonrpc": "2.0",
            "id": 1,
            "method": method,
            "params": params
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AlchemyError.networkError
        }
        
        guard httpResponse.statusCode == 200 else {
            AppLogger.log("❌ Alchemy RPC error: \(httpResponse.statusCode)", category: "alchemy")
            throw AlchemyError.rpcError(httpResponse.statusCode)
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        if let error = json?["error"] as? [String: Any],
           let message = error["message"] as? String {
            AppLogger.log("❌ Alchemy error: \(message)", category: "alchemy")
            throw AlchemyError.rpcErrorMessage(message)
        }
        
        guard let result = json?["result"] else {
            throw AlchemyError.invalidResponse
        }
        
        return result
    }
    
    /// Build paymaster data for gas sponsorship
    private func buildPaymasterData(policyId: String) -> String {
        // Alchemy paymaster data format
        // This is a placeholder - actual implementation depends on Alchemy's Gas Manager setup
        return "0x" + policyId.padding(toLength: 64, withPad: "0", startingAt: 0)
    }
}

// MARK: - Transaction Receipt

struct TransactionReceipt {
    let transactionHash: String
    let blockNumber: String
    let status: String  // "0x1" = success, "0x0" = failed
    let gasUsed: String
    
    init(from dict: [String: Any]) throws {
        guard let txHash = dict["transactionHash"] as? String,
              let blockNum = dict["blockNumber"] as? String,
              let status = dict["status"] as? String,
              let gasUsed = dict["gasUsed"] as? String else {
            throw AlchemyError.invalidResponse
        }
        
        self.transactionHash = txHash
        self.blockNumber = blockNum
        self.status = status
        self.gasUsed = gasUsed
    }
}

// MARK: - Errors

enum AlchemyError: LocalizedError {
    case invalidURL
    case networkError
    case invalidResponse
    case rpcError(Int)
    case rpcErrorMessage(String)
    case transactionFailed
    case confirmationTimeout
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid Alchemy RPC URL"
        case .networkError:
            return "Network request failed"
        case .invalidResponse:
            return "Invalid response from Alchemy"
        case .rpcError(let code):
            return "RPC error (code: \(code))"
        case .rpcErrorMessage(let message):
            return "Alchemy error: \(message)"
        case .transactionFailed:
            return "Transaction failed on-chain"
        case .confirmationTimeout:
            return "Transaction confirmation timeout"
        }
    }
}

