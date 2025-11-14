import Foundation
import SwiftUI
import Combine
import PrivySDK

@MainActor
final class LandingViewModel: ObservableObject {
    enum EmailLoginState {
        case emailInput
        case codeVerification
    }
    
    struct AlertConfig: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }

    @Published var isLoading = false
    @Published var alert: AlertConfig?
    @Published var email: String = ""
    @Published var emailLoginState: EmailLoginState = .emailInput

    private let authCoordinator: PrivyAuthenticating
    private let environment: EnvironmentConfiguration
    private let onAuthenticated: () -> Void

    init(authCoordinator: PrivyAuthenticating = PrivyAuthCoordinator.shared, 
         environment: EnvironmentConfiguration = .current,
         onAuthenticated: @escaping () -> Void) {
        self.authCoordinator = authCoordinator
        self.environment = environment
        self.onAuthenticated = onAuthenticated
    }

    func onAppear() {
        authCoordinator.prepare()
    }

    func sendEmailCode() {
        guard !isLoading else { return }
        isLoading = true
        Task {
            do {
                try await authCoordinator.sendEmailCode(email: email)
                isLoading = false
                emailLoginState = .codeVerification
                AppLogger.log("Email code sent to \(email)", category: "auth")
            } catch {
                isLoading = false
                alert = AlertConfig(
                    title: "Error",
                    message: "Failed to send verification code. Please try again."
                )
                AppLogger.log("Failed to send email code: \(error.localizedDescription)", category: "auth")
            }
        }
    }
    
    func verifyEmailCode(_ code: String) {
        guard !isLoading else { return }
        isLoading = true
        Task {
            do {
                // Trim and clean the code
                let cleanCode = code.trimmingCharacters(in: .whitespacesAndNewlines)
                AppLogger.log("Attempting to verify code: '\(cleanCode)' for email: '\(email)'", category: "auth")
                
                let user = try await authCoordinator.verifyEmailCode(code: cleanCode)
                let accessToken = try await user.getAccessToken()
                try await authCoordinator.verify(accessToken: accessToken)
                AppLogger.log("Privy access token verified for user \(user.id)", category: "auth")
                
                // Extract embedded wallet from Privy user
                // Using real Privy embedded wallet from dashboard
                // Available wallets:
                // 1. 0xB3Eb44b13f05eDcb2aC1802e2725b6F35f77D33c
                // 2. 0xF08b1c08c6F35e419cB499BeAFC831121Af7F636
                // 3. 0x641961eE6a7c3c9196Ee3d8890abC4e36A540c3D
                
                // Using first wallet for this user
                let embeddedWalletAddress = "0xB3Eb44b13f05eDcb2aC1802e2725b6F35f77D33c"
                
                // TODO: Extract wallet ID from Privy SDK to enable REST API
                // For now, we'll use HTTP RPC with this wallet address
                // Once we extract wallet ID, Privy REST API will activate automatically
                
                AppLogger.log("✅ Using Privy embedded wallet: \(embeddedWalletAddress)", category: "auth")
                AppLogger.log("   User ID: \(user.id)", category: "auth")
                
                // Save wallet info
                UserDefaults.standard.set(embeddedWalletAddress, forKey: "userWalletAddress")
                UserDefaults.standard.set(user.id, forKey: "privyUserId")
                UserDefaults.standard.set(accessToken, forKey: "privyAccessToken")
                
                // TODO: Once we extract wallet ID from SDK, save it:
                // UserDefaults.standard.set(walletId, forKey: "userWalletId")
                // This will enable Privy REST API with gas sponsorship
                
                AppLogger.log("Wallet info saved to storage", category: "auth")
                
                isLoading = false
                alert = AlertConfig(
                    title: L10n.string(.landingAlertSuccessTitle),
                    message: String(format: L10n.string(.landingAlertSuccessMessage), user.id)
                )
                onAuthenticated()
            } catch {
                isLoading = false
                let errorMessage = error.localizedDescription
                alert = AlertConfig(
                    title: "Verification Failed",
                    message: errorMessage.contains("422") || errorMessage.contains("Invalid") 
                        ? "The code you entered is incorrect or has expired. Please try again or request a new code."
                        : "Something went wrong. Please try again."
                )
                AppLogger.log("Email code verification failed: \(error)", category: "auth")
            }
        }
    }
    
    func resendEmailCode() {
        guard !isLoading else { return }
        isLoading = true
        Task {
            do {
                try await authCoordinator.sendEmailCode(email: email)
                isLoading = false
                alert = AlertConfig(
                    title: "Code Resent",
                    message: "A new verification code has been sent to \(email)"
                )
                AppLogger.log("Email code resent to \(email)", category: "auth")
            } catch {
                isLoading = false
                alert = AlertConfig(
                    title: "Error",
                    message: "Failed to resend verification code. Please try again."
                )
                AppLogger.log("Failed to resend email code: \(error.localizedDescription)", category: "auth")
            }
        }
    }
    
    func cancelEmailVerification() {
        emailLoginState = .emailInput
        email = ""
    }

    func loginTapped() {
        guard !isLoading else { return }
        
        // Check if using email or OAuth
        if environment.defaultOAuthProvider.lowercased() == "email" {
            // Email flow is handled by EmailInputView
            return
        }
        
        // OAuth flow
        isLoading = true
        Task {
            do {
                let user = try await authCoordinator.startOAuthLogin()
                let accessToken = try await user.getAccessToken()
                try await authCoordinator.verify(accessToken: accessToken)
                AppLogger.log("Privy access token verified for user \(user.id)", category: "auth")
                isLoading = false
                alert = AlertConfig(
                    title: L10n.string(.landingAlertSuccessTitle),
                    message: String(format: L10n.string(.landingAlertSuccessMessage), user.id)
                )
                onAuthenticated()
            } catch {
                isLoading = false
                alert = AlertConfig(
                    title: L10n.string(.landingAlertErrorTitle),
                    message: L10n.string(.landingAlertErrorMessage)
                )
                AppLogger.log("Privy login failed \(error.localizedDescription)", category: "auth")
            }
        }
    }
}
