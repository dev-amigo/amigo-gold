import Foundation
import Security

enum PrivyTokenVerifierError: LocalizedError {
    case invalidTokenFormat
    case unsupportedAlgorithm
    case missingKey
    case signatureInvalid
    case keyCreationFailed
    case jwksFetchFailed
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidTokenFormat:
            return "Access token is not a valid JWT."
        case .unsupportedAlgorithm:
            return "Unsupported signing algorithm."
        case .missingKey:
            return "Unable to find matching signing key."
        case .signatureInvalid:
            return "Access token signature is invalid."
        case .keyCreationFailed:
            return "Failed to build RSA key from JWKS."
        case .jwksFetchFailed:
            return "Unable to fetch JWKS from Privy."
        case .decodingFailed:
            return "Failed to decode token or JWKS data."
        }
    }
}

extension PrivyTokenVerifierError: Equatable {}

actor PrivyTokenVerifier {
    private struct JWKSResponse: Decodable {
        let keys: [JWK]
    }

    private struct JWK: Decodable {
        let kty: String
        let kid: String
        let alg: String?
        let use: String?
        let crv: String?  // For EC keys
        let x: String?    // For EC keys
        let y: String?    // For EC keys
        let n: String?    // For RSA keys
        let e: String?    // For RSA keys
    }

    private struct JWTHeader: Decodable {
        let alg: String
        let kid: String
    }

    private let configuration: EnvironmentConfiguration
    private let session: URLSession
    private var keyCache: [String: JWK] = [:]
    private var lastRefresh: Date?
    private let cacheTTL: TimeInterval = 60 * 10

    init(configuration: EnvironmentConfiguration, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
    }

    func verify(accessToken: String) async throws {
        let segments = accessToken.split(separator: ".")
        guard segments.count == 3 else {
            AppLogger.log("Token verification failed: Invalid format (segments: \(segments.count))", category: "auth")
            throw PrivyTokenVerifierError.invalidTokenFormat
        }

        guard
            let headerData = Data(base64URLEncoded: String(segments[0])),
            var signatureData = Data(base64URLEncoded: String(segments[2]))
        else {
            AppLogger.log("Token verification failed: Base64 decoding failed", category: "auth")
            throw PrivyTokenVerifierError.decodingFailed
        }

        let header = try JSONDecoder().decode(JWTHeader.self, from: headerData)
        AppLogger.log("Token header - alg: \(header.alg), kid: \(header.kid)", category: "auth")
        
        let algorithm = header.alg.uppercased()
        guard algorithm == "RS256" || algorithm == "ES256" else {
            AppLogger.log("Token verification failed: Unsupported algorithm '\(header.alg)'", category: "auth")
            throw PrivyTokenVerifierError.unsupportedAlgorithm
        }

        let jwk = try await key(for: header.kid)
        AppLogger.log("Found JWK for kid: \(header.kid), alg: \(jwk.alg ?? "none"), kty: \(jwk.kty)", category: "auth")
        
        let publicKey = try buildPublicKey(from: jwk, algorithm: algorithm)
        AppLogger.log("Public key created successfully", category: "auth")

        let signedInput = Data("\(segments[0]).\(segments[1])".utf8)
        
        // Choose the right verification algorithm based on token type
        let secAlgorithm: SecKeyAlgorithm
        if algorithm == "ES256" {
            secAlgorithm = .ecdsaSignatureMessageX962SHA256
            // JWT ES256 signatures are in raw format (r||s), but SecKey expects DER
            // Check if it's already DER (starts with 0x30 SEQUENCE tag)
            if signatureData.count > 0 && signatureData[0] == 0x30 {
                AppLogger.log("Signature already in DER format (\(signatureData.count) bytes)", category: "auth")
            } else {
                // Convert raw format to DER for SecKey
                AppLogger.log("Converting raw signature (\(signatureData.count) bytes) to DER format", category: "auth")
                signatureData = try rawToDerSignature(signatureData)
                AppLogger.log("Converted to DER signature (\(signatureData.count) bytes)", category: "auth")
            }
        } else {
            secAlgorithm = .rsaSignatureMessagePKCS1v15SHA256
        }
        
        let isSupported = SecKeyIsAlgorithmSupported(publicKey, .verify, secAlgorithm)
        AppLogger.log("\(algorithm) algorithm supported: \(isSupported)", category: "auth")
        
        guard isSupported else {
            AppLogger.log("Token verification failed: Algorithm not supported by SecKey", category: "auth")
            throw PrivyTokenVerifierError.unsupportedAlgorithm
        }

        var error: Unmanaged<CFError>?
        let verified = SecKeyVerifySignature(
            publicKey,
            secAlgorithm,
            signedInput as CFData,
            signatureData as CFData,
            &error
        )

        if !verified {
            if let err = error?.takeRetainedValue() {
                AppLogger.log("Token verification failed: \(err)", category: "auth")
                throw err
            } else {
                AppLogger.log("Token verification failed: Invalid signature", category: "auth")
                throw PrivyTokenVerifierError.signatureInvalid
            }
        }
        
        AppLogger.log("Token verification succeeded!", category: "auth")
    }

    private func key(for kid: String) async throws -> JWK {
        if let cached = keyCache[kid], let lastRefresh, Date().timeIntervalSince(lastRefresh) < cacheTTL {
            return cached
        }

        try await refreshKeys()

        if let cached = keyCache[kid] {
            return cached
        }

        throw PrivyTokenVerifierError.missingKey
    }

    private func refreshKeys() async throws {
        if let lastRefresh, Date().timeIntervalSince(lastRefresh) < cacheTTL, !keyCache.isEmpty {
            return
        }

        AppLogger.log("Fetching JWKS from: \(configuration.privyJWKSURL.absoluteString)", category: "auth")
        
        let (data, response) = try await session.data(from: configuration.privyJWKSURL)
        guard let httpResponse = response as? HTTPURLResponse, (200 ... 299).contains(httpResponse.statusCode) else {
            AppLogger.log("JWKS fetch failed: HTTP status \((response as? HTTPURLResponse)?.statusCode ?? -1)", category: "auth")
            throw PrivyTokenVerifierError.jwksFetchFailed
        }

        let jwks = try JSONDecoder().decode(JWKSResponse.self, from: data)
        AppLogger.log("JWKS fetched successfully: \(jwks.keys.count) keys", category: "auth")
        keyCache = Dictionary(uniqueKeysWithValues: jwks.keys.map { ($0.kid, $0) })
        lastRefresh = Date()
    }

    private func buildPublicKey(from jwk: JWK, algorithm: String) throws -> SecKey {
        let keyType = jwk.kty.uppercased()
        
        if keyType == "EC" {
            // Elliptic Curve key (ES256)
            AppLogger.log("Building EC public key for ES256", category: "auth")
            guard let crv = jwk.crv, crv == "P-256" else {
                AppLogger.log("buildPublicKey failed: EC curve '\(jwk.crv ?? "none")' not supported", category: "auth")
                throw PrivyTokenVerifierError.unsupportedAlgorithm
            }
            guard
                let xData = jwk.x.flatMap({ Data(base64URLEncoded: $0) }),
                let yData = jwk.y.flatMap({ Data(base64URLEncoded: $0) })
            else {
                AppLogger.log("buildPublicKey failed: Unable to decode EC x or y coordinates", category: "auth")
                throw PrivyTokenVerifierError.decodingFailed
            }
            
            // EC public key format: 0x04 + x-coordinate + y-coordinate
            var keyData = Data([0x04])
            keyData.append(xData)
            keyData.append(yData)
            
            let attributes: [String: Any] = [
                kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
                kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
                kSecAttrKeySizeInBits as String: 256
            ]
            
            guard let key = SecKeyCreateWithData(keyData as CFData, attributes as CFDictionary, nil) else {
                AppLogger.log("buildPublicKey failed: SecKeyCreateWithData returned nil for EC key", category: "auth")
                throw PrivyTokenVerifierError.keyCreationFailed
            }
            
            AppLogger.log("buildPublicKey succeeded: Created EC public key", category: "auth")
            return key
            
        } else if keyType == "RSA" {
            // RSA key (RS256)
            AppLogger.log("Building RSA public key for RS256", category: "auth")
            guard
                let modulus = jwk.n.flatMap({ Data(base64URLEncoded: $0) }),
                let exponent = jwk.e.flatMap({ Data(base64URLEncoded: $0) })
            else {
                AppLogger.log("buildPublicKey failed: Unable to decode RSA modulus or exponent", category: "auth")
                throw PrivyTokenVerifierError.decodingFailed
            }

            let keyData = rsaPublicKeyData(modulus: modulus, exponent: exponent)
            let attributes: [String: Any] = [
                kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
                kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
                kSecAttrKeySizeInBits as String: modulus.count * 8,
            ]

            guard let key = SecKeyCreateWithData(keyData as CFData, attributes as CFDictionary, nil) else {
                AppLogger.log("buildPublicKey failed: SecKeyCreateWithData returned nil for RSA key", category: "auth")
                throw PrivyTokenVerifierError.keyCreationFailed
            }

            AppLogger.log("buildPublicKey succeeded: Created RSA public key", category: "auth")
            return key
        } else {
            AppLogger.log("buildPublicKey failed: Key type '\(keyType)' not supported", category: "auth")
            throw PrivyTokenVerifierError.unsupportedAlgorithm
        }
    }

    private func rsaPublicKeyData(modulus: Data, exponent: Data) -> Data {
        let modulusInteger = derEncodeInteger(modulus)
        let exponentInteger = derEncodeInteger(exponent)
        let sequencePayload = modulusInteger + exponentInteger
        let sequence = derEncode(tag: 0x30, data: sequencePayload)

        let algorithmIdentifier: [UInt8] = [
            0x30, 0x0d, 0x06, 0x09,
            0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01, 0x01,
            0x05, 0x00,
        ]

        let bitString = derEncode(tag: 0x03, data: Data([0x00]) + sequence)

        return derEncode(tag: 0x30, data: Data(algorithmIdentifier) + bitString)
    }

    private func derEncode(tag: UInt8, data: Data) -> Data {
        var encoded = Data([tag])
        encoded.append(derLength(of: data.count))
        encoded.append(data)
        return encoded
    }

    private func derEncodeInteger(_ data: Data) -> Data {
        var bytes = data
        if bytes.first ?? 0 >= 0x80 {
            bytes.insert(0x00, at: 0)
        }
        return derEncode(tag: 0x02, data: bytes)
    }

    private func derLength(of length: Int) -> Data {
        if length < 0x80 {
            return Data([UInt8(length)])
        }

        var value = length
        var bytes: [UInt8] = []
        while value > 0 {
            bytes.insert(UInt8(value & 0xff), at: 0)
            value >>= 8
        }

        var data = Data([0x80 | UInt8(bytes.count)])
        data.append(contentsOf: bytes)
        return data
    }
    
    /// Converts raw ECDSA signature (r || s) to DER format
    /// ES256 uses P-256 curve, so r and s are each 32 bytes
    private func rawToDerSignature(_ rawSignature: Data) throws -> Data {
        guard rawSignature.count == 64 else {
            AppLogger.log("Raw signature: Expected 64 bytes, got \(rawSignature.count)", category: "auth")
            throw PrivyTokenVerifierError.decodingFailed
        }
        
        // Split into r and s (32 bytes each)
        let rData = rawSignature.prefix(32)
        let sData = rawSignature.suffix(32)
        
        // Encode as DER INTEGERs
        let rInteger = derEncodeInteger(Data(rData))
        let sInteger = derEncodeInteger(Data(sData))
        
        // Build SEQUENCE
        let sequenceContent = rInteger + sInteger
        let derSignature = derEncode(tag: 0x30, data: sequenceContent)
        
        AppLogger.log("Raw to DER: r=32 bytes, s=32 bytes -> DER=\(derSignature.count) bytes", category: "auth")
        
        return derSignature
    }
    
    /// Converts DER-encoded ECDSA signature to raw format (r || s)
    /// ES256 uses P-256 curve, so r and s are each 32 bytes
    private func derToRawSignature(_ derSignature: Data) throws -> Data {
        var index = 0
        
        // Check SEQUENCE tag
        guard derSignature[index] == 0x30 else {
            AppLogger.log("DER signature: Expected SEQUENCE tag", category: "auth")
            throw PrivyTokenVerifierError.decodingFailed
        }
        index += 1
        
        // Skip sequence length
        let sequenceLength = Int(derSignature[index])
        index += 1
        
        // Extract r
        guard derSignature[index] == 0x02 else {
            AppLogger.log("DER signature: Expected INTEGER tag for r", category: "auth")
            throw PrivyTokenVerifierError.decodingFailed
        }
        index += 1
        
        let rLength = Int(derSignature[index])
        index += 1
        
        var rData = derSignature.subdata(in: index..<index+rLength)
        index += rLength
        
        // Remove leading zero byte if present (added for sign bit)
        if rData.count == 33 && rData[0] == 0x00 {
            rData = rData.dropFirst()
        }
        
        // Pad to 32 bytes if needed
        while rData.count < 32 {
            rData.insert(0x00, at: 0)
        }
        
        // Extract s
        guard derSignature[index] == 0x02 else {
            AppLogger.log("DER signature: Expected INTEGER tag for s", category: "auth")
            throw PrivyTokenVerifierError.decodingFailed
        }
        index += 1
        
        let sLength = Int(derSignature[index])
        index += 1
        
        var sData = derSignature.subdata(in: index..<index+sLength)
        
        // Remove leading zero byte if present
        if sData.count == 33 && sData[0] == 0x00 {
            sData = sData.dropFirst()
        }
        
        // Pad to 32 bytes if needed
        while sData.count < 32 {
            sData.insert(0x00, at: 0)
        }
        
        // Concatenate r and s
        var rawSignature = Data()
        rawSignature.append(rData)
        rawSignature.append(sData)
        
        AppLogger.log("DER to raw: r=\(rData.count) bytes, s=\(sData.count) bytes, total=\(rawSignature.count) bytes", category: "auth")
        
        return rawSignature
    }
}
