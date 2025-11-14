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
                let user = try await authCoordinator.verifyEmailCode(code: code)
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
                    title: "Verification Failed",
                    message: "Invalid code. Please try again."
                )
                AppLogger.log("Email code verification failed: \(error.localizedDescription)", category: "auth")
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
