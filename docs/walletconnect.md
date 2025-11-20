## WalletConnect + web3.swift Integration

The iOS target now relies on the same primitives as the web stack for RPC calls and wallet sessions.

### Dependencies

- `web3.swift` (Argent Labs) for typed RPC access and BigInt helpers.
- `WalletConnectSign` (+ Networking/Pairing/Relay) for WalletConnect v2 flows.
- `secp256k1.swift` to recover public keys when verifying signatures from WalletConnect callbacks.

All packages are managed through Swift Package Manager and pinned from `PerFolio.xcodeproj`.

### Configuration

`Dev.xcconfig` and `Prod.xcconfig` expose the following WalletConnect keys:

| Key | Description |
| --- | --- |
| `WALLETCONNECT_PROJECT_ID` | Reown/WalletConnect Cloud project id. |
| `WALLETCONNECT_RELAY_HOST` | Relay host, defaults to `relay.walletconnect.com`. |
| `WALLETCONNECT_APP_SCHEME` | Native scheme used for deep-linking wallets back into the app. |

`Gold-Info.plist` mirrors the values under `AGWalletConnect*` so they are accessible at runtime.

### Runtime services

`Web3SwiftProvider` wraps `EthereumHttpClient` with automatic failover between the configured Alchemy RPC and the public fallback. It exposes helpers for `eth_call`, balances, gas price, and block height.

`WalletConnectService` is an `ObservableObject` that:

- Configures Networking/Pair/Sign clients with a custom URLSession-backed `WebSocketFactory`.
- Publishes connection state (`idle`, `pairing`, `connected`, `failed`) and active `Session` instances.
- Generates pairing URIs (with optional default namespaces targeting `eip155` chains) and deep links for wallets.
- Tracks proposals, session settlements, rejections, and socket connectivity for diagnostics.

The companion `WalletConnectCryptoProvider` reuses `secp256k1` to recover public keys from signature payloads before verification, matching the behaviour expected by WalletConnect’s `MessageVerifier`.

### Usage

1. Supply valid values for the WalletConnect keys in your `.xcconfig`.
2. Call `WalletConnectService.shared.configureIfNeeded()` during app start (once Privy auth is ready).
3. Trigger `connect()` to generate a QR/deep link when the user taps “Connect Wallet”.
4. Subscribe to `connectionState`/`sessions` in SwiftUI to update UI flows.
5. Use `Web3SwiftProvider` in networking layers that previously relied on the custom `Web3Client` once migration is complete.
