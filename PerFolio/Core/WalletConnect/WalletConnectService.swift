import Combine
import Foundation
import WalletConnectSign
import WalletConnectPairing
import WalletConnectNetworking
import WalletConnectRelay
import WalletConnectUtils

@MainActor
final class WalletConnectService: ObservableObject {
    enum ConnectionState {
        case idle
        case pairing(WalletConnectURI)
        case connected([Session])
        case failed(String)
    }

    static let shared = WalletConnectService()

    @Published private(set) var connectionState: ConnectionState = .idle
    @Published private(set) var sessions: [Session] = []
    @Published private(set) var latestProposal: Session.Proposal?

    var activePairingURI: WalletConnectURI? {
        connectionURI
    }

    var walletDeepLink: URL? {
        guard let uri = connectionURI else { return nil }
        return configuration.deepLinkURL(for: uri)
    }

    private let configuration: WalletConnectConfiguration
    private let cryptoProvider: CryptoProvider
    private let socketFactory: WebSocketFactory
    private var signClient: SignClient?
    private var connectionURI: WalletConnectURI?
    private var cancellables: Set<AnyCancellable> = []
    private var isConfigured = false

    init(
        configuration: WalletConnectConfiguration = .fromBundle(),
        cryptoProvider: CryptoProvider = WalletConnectCryptoProvider(),
        socketFactory: WebSocketFactory = WalletConnectURLSessionFactory()
    ) {
        self.configuration = configuration
        self.cryptoProvider = cryptoProvider
        self.socketFactory = socketFactory
    }

    func configureIfNeeded() {
        guard !isConfigured else { return }

        guard !configuration.projectId.isEmpty else {
            AppLogger.log("⚠️ WalletConnect project id missing. Update WALLETCONNECT_PROJECT_ID.", category: "walletconnect")
            return
        }

        Networking.configure(
            relayHost: configuration.relayHost,
            groupIdentifier: configuration.groupIdentifier,
            projectId: configuration.projectId,
            socketFactory: socketFactory,
            socketConnectionType: .automatic
        )
        Pair.configure(metadata: configuration.metadata)
        Sign.configure(crypto: cryptoProvider)

        let client = Sign.instance
        bind(to: client)
        signClient = client
        isConfigured = true

        AppLogger.log("✅ WalletConnect ready (relay: \(configuration.relayHost))", category: "walletconnect")
    }

    @discardableResult
    func connect(
        requiredNamespaces: [String: ProposalNamespace]? = nil,
        sessionProperties: [String: String]? = nil
    ) async throws -> WalletConnectURI {
        guard !configuration.projectId.isEmpty else {
            throw WalletConnectServiceError.missingProjectID
        }

        configureIfNeeded()
        guard let client = signClient else {
            throw WalletConnectServiceError.notInitialized
        }

        let namespaces = requiredNamespaces ?? configuration.defaultRequiredNamespaces
        let uri = try await client.connect(
            requiredNamespaces: namespaces,
            sessionProperties: sessionProperties
        )

        connectionURI = uri
        connectionState = .pairing(uri)
        AppLogger.log("🔗 WalletConnect pairing URI created", category: "walletconnect")
        return uri
    }

    func disconnect(topic: String) async {
        guard let client = signClient else { return }
        do {
            try await client.disconnect(topic: topic)
        } catch {
            AppLogger.log("❌ Failed to disconnect WalletConnect topic \(topic): \(error.localizedDescription)", category: "walletconnect")
        }
    }

    func resetPairing() {
        connectionURI = nil
        latestProposal = nil
        if sessions.isEmpty {
            connectionState = .idle
        }
    }

    private func bind(to client: SignClient) {
        client.sessionsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sessions in
                guard let self else { return }
                self.sessions = sessions
                self.connectionState = sessions.isEmpty ? .idle : .connected(sessions)
            }
            .store(in: &cancellables)

        client.sessionProposalPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.latestProposal = event.proposal
            }
            .store(in: &cancellables)

        client.sessionSettlePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session in
                guard let self else { return }
                AppLogger.log("🤝 WalletConnect session settled: \(session.topic)", category: "walletconnect")
                self.sessions = client.getSessions()
                self.connectionState = .connected(self.sessions)
                self.connectionURI = nil
                self.latestProposal = nil
            }
            .store(in: &cancellables)

        client.sessionDeletePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] topic, reason in
                guard let self else { return }
                AppLogger.log("🔌 WalletConnect session removed (\(topic)): \(reason.message)", category: "walletconnect")
                self.sessions = client.getSessions()
                self.connectionState = self.sessions.isEmpty ? .idle : .connected(self.sessions)
            }
            .store(in: &cancellables)

        client.sessionRejectionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _, reason in
                self?.connectionURI = nil
                self?.latestProposal = nil
                self?.connectionState = .failed(reason.message)
                AppLogger.log("⚠️ WalletConnect session rejected: \(reason.message)", category: "walletconnect")
            }
            .store(in: &cancellables)

        client.socketConnectionStatusPublisher
            .receive(on: DispatchQueue.main)
            .sink { status in
                AppLogger.log("📡 WalletConnect socket status: \(status)", category: "walletconnect")
            }
            .store(in: &cancellables)
    }
}

enum WalletConnectServiceError: LocalizedError {
    case missingProjectID
    case notInitialized

    var errorDescription: String? {
        switch self {
        case .missingProjectID:
            return "WalletConnect project id is missing. Set WALLETCONNECT_PROJECT_ID in your configuration."
        case .notInitialized:
            return "WalletConnect has not been configured yet."
        }
    }
}

struct WalletConnectConfiguration {
    let projectId: String
    let relayHost: String
    let appScheme: String
    let groupIdentifier: String
    let metadata: AppMetadata
    let defaultRequiredNamespaces: [String: ProposalNamespace]

    static func fromBundle(_ bundle: Bundle = .main) -> WalletConnectConfiguration {
        let projectId = bundle.infoDictionary?["AGWalletConnectProjectID"] as? String ?? ""
        let relayHost = (bundle.infoDictionary?["AGWalletConnectRelayHost"] as? String ?? "relay.walletconnect.com")
        let appScheme = (bundle.infoDictionary?["AGWalletConnectAppScheme"] as? String ??
                         bundle.bundleIdentifier ?? "perfolio").replacingOccurrences(of: " ", with: "")
        let groupIdentifier = bundle.object(forInfoDictionaryKey: "AppGroupIdentifier") as? String ??
            bundle.bundleIdentifier ?? "com.transak.perfolio"

        let displayName = bundle.displayName
        let description = "Manage your gold-backed loans wherever you are."
        let fallbackIcon = URL(string: "https://perfolio.ai/icon.png")!
        let redirect: AppMetadata.Redirect = {
            if let value = try? AppMetadata.Redirect(native: "\(appScheme)://wc", universal: nil) {
                return value
            }
            if let fallback = try? AppMetadata.Redirect(native: "perfolio://wc", universal: nil) {
                return fallback
            }
            return try! AppMetadata.Redirect(native: "perfolio://wc", universal: nil)
        }()

        let metadata = AppMetadata(
            name: displayName,
            description: description,
            url: "https://perfolio.ai",
            icons: [fallbackIcon.absoluteString],
            redirect: redirect
        )

        let chains: [Blockchain] = ["eip155:1", "eip155:137"].compactMap { Blockchain($0) }
        let methods: Set<String> = [
            "eth_sendTransaction",
            "eth_signTransaction",
            "personal_sign",
            "eth_signTypedData",
            "eth_signTypedData_v4"
        ]
        let events: Set<String> = ["accountsChanged", "chainChanged"]
        let namespace = ProposalNamespace(chains: chains, methods: methods, events: events)

        return WalletConnectConfiguration(
            projectId: projectId,
            relayHost: relayHost,
            appScheme: appScheme,
            groupIdentifier: groupIdentifier,
            metadata: metadata,
            defaultRequiredNamespaces: ["eip155": namespace]
        )
    }

    func deepLinkURL(for uri: WalletConnectURI) -> URL? {
        var components = URLComponents()
        components.scheme = appScheme
        components.host = "wc"
        components.queryItems = [
            URLQueryItem(name: "uri", value: uri.absoluteString)
        ]
        return components.url
    }
}

private extension Bundle {
    var displayName: String {
        if let displayName = object(forInfoDictionaryKey: "CFBundleDisplayName") as? String {
            return displayName
        }
        if let name = object(forInfoDictionaryKey: "CFBundleName") as? String {
            return name
        }
        return "PerFolio"
    }
}
