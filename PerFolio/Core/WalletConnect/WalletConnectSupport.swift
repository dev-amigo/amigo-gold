import Foundation
import WalletConnectSigner
import WalletConnectRelay
import secp256k1
import CryptoSwift

struct WalletConnectCryptoProvider: CryptoProvider {
    enum CryptoError: Error {
        case invalidContext
        case signatureParseFailed
        case recoveryFailed
    }

    func recoverPubKey(signature: EthereumSignature, message: Data) throws -> Data {
        let hash = message.sha3(.keccak256)

        guard let ctx = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN | SECP256K1_CONTEXT_VERIFY)) else {
            throw CryptoError.invalidContext
        }
        defer { secp256k1_context_destroy(ctx) }

        var recoveryID = normalizedRecoveryID(signature.v)
        var serializedSignature = Data(padded(signature.r) + padded(signature.s))

        let recoverableSignature = UnsafeMutablePointer<secp256k1_ecdsa_recoverable_signature>.allocate(capacity: 1)
        defer { recoverableSignature.deallocate() }

        let parseResult = serializedSignature.withUnsafeBytes {
            secp256k1_ecdsa_recoverable_signature_parse_compact(
                ctx,
                recoverableSignature,
                $0.bindMemory(to: UInt8.self).baseAddress!,
                recoveryID
            )
        }

        guard parseResult == 1 else {
            throw CryptoError.signatureParseFailed
        }

        let pubkey = UnsafeMutablePointer<secp256k1_pubkey>.allocate(capacity: 1)
        defer { pubkey.deallocate() }

        let recoverResult = hash.withUnsafeBytes {
            secp256k1_ecdsa_recover(
                ctx,
                pubkey,
                recoverableSignature,
                $0.bindMemory(to: UInt8.self).baseAddress!
            )
        }

        guard recoverResult == 1 else {
            throw CryptoError.recoveryFailed
        }

        var outputLength = 65
        var output = Data(count: outputLength)
        output.withUnsafeMutableBytes {
            secp256k1_ec_pubkey_serialize(
                ctx,
                $0.bindMemory(to: UInt8.self).baseAddress!,
                &outputLength,
                pubkey,
                UInt32(SECP256K1_EC_UNCOMPRESSED)
            )
        }

        return Data(output[1..<outputLength])
    }

    func keccak256(_ data: Data) -> Data {
        data.sha3(.keccak256)
    }

    private func padded(_ bytes: [UInt8]) -> [UInt8] {
        if bytes.count >= 32 {
            return Array(bytes.suffix(32))
        }
        return Array(repeating: 0, count: 32 - bytes.count) + bytes
    }

    private func normalizedRecoveryID(_ value: UInt8) -> Int32 {
        var id = Int32(value)
        if (27...30).contains(id) {
            id -= 27
        } else if (31...34).contains(id) {
            id -= 31
        } else if (35...38).contains(id) {
            id -= 35
        }
        return id
    }
}

final class WalletConnectURLSessionFactory: WebSocketFactory {
    func create(with url: URL) -> WebSocketConnecting {
        URLSessionWebSocketConnection(url: url)
    }
}

private final class URLSessionWebSocketConnection: NSObject, WebSocketConnecting, URLSessionWebSocketDelegate {
    var isConnected: Bool {
        task?.state == .running
    }

    var onConnect: (() -> Void)?
    var onDisconnect: ((Error?) -> Void)?
    var onText: ((String) -> Void)?

    var request: URLRequest {
        didSet {
            if task != nil {
                task?.cancel()
                task = nil
            }
        }
    }

    private let queue = DispatchQueue(label: "com.transak.walletconnect.websocket")
    private lazy var session: URLSession = {
        URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }()
    private var task: URLSessionWebSocketTask?

    init(url: URL) {
        self.request = URLRequest(url: url)
        super.init()
    }

    func connect() {
        guard task == nil else {
            task?.resume()
            return
        }

        task = session.webSocketTask(with: request)
        task?.resume()
        listen()
    }

    func disconnect() {
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
    }

    func write(string: String, completion: (() -> Void)?) {
        guard let task else { return }
        task.send(.string(string)) { error in
            if let error {
                self.onDisconnect?(error)
            }
            completion?()
        }
    }

    private func listen() {
        task?.receive { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let message):
                if case let .string(text) = message {
                    self.onText?(text)
                }
                self.listen()
            case .failure(let error):
                self.onDisconnect?(error)
            }
        }
    }

    // MARK: - URLSessionWebSocketDelegate

    func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didOpenWithProtocol protocol: String?
    ) {
        queue.async { [weak self] in
            self?.onConnect?()
        }
    }

    func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
        reason: Data?
    ) {
        queue.async { [weak self] in
            self?.onDisconnect?(nil)
        }
    }
}
