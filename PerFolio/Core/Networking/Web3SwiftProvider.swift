import Foundation
import web3
import BigInt

struct Web3RPCConfiguration: Equatable {
    let primaryURL: URL
    let fallbackURL: URL

    static func resolved(bundle: Bundle = .main) -> Web3RPCConfiguration {
        let fallbackString = bundle.infoDictionary?["AGEthereumRPCFallback"] as? String
        let fallbackURL = URL(string: (fallbackString ?? Defaults.fallback).normalizedURLString) ?? URL(string: Defaults.fallbackNormalized)!

        if let alchemyKey = bundle.infoDictionary?["AGAlchemyAPIKey"] as? String,
           let derivedURL = Self.deriveAlchemyURL(from: alchemyKey) {
            return Web3RPCConfiguration(primaryURL: derivedURL, fallbackURL: fallbackURL)
        }

        return Web3RPCConfiguration(primaryURL: fallbackURL, fallbackURL: fallbackURL)
    }

    private static func deriveAlchemyURL(from value: String) -> URL? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if trimmed.hasPrefix("http") {
            return URL(string: trimmed.normalizedURLString)
        }

        let endpoint = "https://eth-mainnet.g.alchemy.com/v2/\(trimmed)"
        return URL(string: endpoint.normalizedURLString)
    }

    private enum Defaults {
        static let fallback = "https://ethereum.publicnode.com"
        static let fallbackNormalized = "https://ethereum.publicnode.com"
    }
}

enum Web3SwiftProviderError: LocalizedError {
    case invalidAddress(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidAddress(let address):
            return "Invalid Ethereum address: \(address)"
        case .invalidResponse:
            return "Unexpected response from RPC"
        }
    }
}

actor Web3SwiftProvider {
    private let configuration: Web3RPCConfiguration
    private let primaryClient: EthereumHttpClient
    private let fallbackClient: EthereumHttpClient

    init(configuration: Web3RPCConfiguration = .resolved(), network: EthereumNetwork = .mainnet) {
        self.configuration = configuration
        self.primaryClient = EthereumHttpClient(url: configuration.primaryURL, network: network)
        self.fallbackClient = EthereumHttpClient(url: configuration.fallbackURL, network: network)

        AppLogger.log("🔌 Web3SwiftProvider configured", category: "web3")
        AppLogger.log("   Primary RPC: \(configuration.primaryURL.absoluteString)", category: "web3")
        if configuration.fallbackURL != configuration.primaryURL {
            AppLogger.log("   Fallback RPC: \(configuration.fallbackURL.absoluteString)", category: "web3")
        }
    }

    func call(
        contract: EthereumAddress,
        data: Data,
        from: EthereumAddress? = nil,
        block: EthereumBlock = .Latest
    ) async throws -> Data {
        let tx = EthereumTransaction(
            from: from,
            to: contract,
            value: nil,
            data: data,
            nonce: nil,
            gasPrice: nil,
            gasLimit: nil,
            chainId: nil
        )
        let response = try await performWithFailover {
            try await $0.eth_call(tx, block: block)
        }

        guard let data = Data(hex: response) else {
            throw Web3SwiftProviderError.invalidResponse
        }
        return data
    }

    func call(
        contract: String,
        data: Data,
        from: String? = nil,
        block: EthereumBlock = .Latest
    ) async throws -> Data {
        guard let toAddress = EthereumAddress(contract) as EthereumAddress? else {
            throw Web3SwiftProviderError.invalidAddress(contract)
        }

        let fromAddress: EthereumAddress? = from.flatMap { EthereumAddress($0) }
        return try await call(contract: toAddress, data: data, from: fromAddress, block: block)
    }

    func gasPrice() async throws -> BigUInt {
        try await performWithFailover { try await $0.eth_gasPrice() }
    }

    func latestBlockNumber() async throws -> Int {
        try await performWithFailover { try await $0.eth_blockNumber() }
    }

    func balance(of address: EthereumAddress, block: EthereumBlock = .Latest) async throws -> BigUInt {
        try await performWithFailover { try await $0.eth_getBalance(address: address, block: block) }
    }

    func balance(of address: String, block: EthereumBlock = .Latest) async throws -> BigUInt {
        guard let addr = EthereumAddress(address) as EthereumAddress? else {
            throw Web3SwiftProviderError.invalidAddress(address)
        }
        return try await balance(of: addr, block: block)
    }

    func estimateGas(transaction: EthereumTransaction) async throws -> BigUInt {
        try await performWithFailover { try await $0.eth_estimateGas(transaction) }
    }

    private func performWithFailover<T>(
        _ block: @escaping (EthereumClientProtocol) async throws -> T
    ) async throws -> T {
        do {
            return try await block(primaryClient)
        } catch {
            AppLogger.log("⚠️ Primary RPC failed: \(error.localizedDescription)", category: "web3")
            if configuration.fallbackURL == configuration.primaryURL {
                throw error
            }
            return try await block(fallbackClient)
        }
    }
}

private extension String {
    var normalizedURLString: String {
        replacingOccurrences(of: ":/$()/", with: "://")
    }
}
