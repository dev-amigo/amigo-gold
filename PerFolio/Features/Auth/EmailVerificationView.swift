import SwiftUI

struct EmailVerificationView: View {
    let email: String
    let onCodeEntered: (String) -> Void
    let onCancel: () -> Void
    
    @State private var code: String = ""
    @FocusState private var isCodeFocused: Bool
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        ZStack {
            themeManager.perfolioTheme.primaryBackground
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Icon
                Image(systemName: "envelope.badge.fill")
                    .font(.system(size: 60))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(themeManager.perfolioTheme.tintColor)
                
                // Title and Instructions
                VStack(spacing: 12) {
                    Text("Check your email")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(themeManager.perfolioTheme.textPrimary)
                    
                    Text("We sent a verification code to")
                        .font(.system(size: 16, design: .rounded))
                        .foregroundStyle(themeManager.perfolioTheme.textSecondary)
                    
                    Text(email)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(themeManager.perfolioTheme.tintColor)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                
                // Code Input
                PerFolioCard(style: .secondary) {
                    VStack(spacing: 16) {
                        Text("Enter 6-digit code")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(themeManager.perfolioTheme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        TextField("", text: $code)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(themeManager.perfolioTheme.textPrimary)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .focused($isCodeFocused)
                            .onChange(of: code) { oldValue, newValue in
                                // Limit to 6 digits
                                if newValue.count > 6 {
                                    code = String(newValue.prefix(6))
                                }
                                // Auto-submit when 6 digits entered
                                if code.count == 6 {
                                    onCodeEntered(code)
                                }
                            }
                    }
                    .padding(20)
                }
                .padding(.horizontal, 24)
                
                // Actions
                VStack(spacing: 16) {
                    PerFolioButton(
                        "Verify Code",
                        isDisabled: code.count != 6
                    ) {
                        onCodeEntered(code)
                    }
                    
                    Button(action: onCancel) {
                        Text("Use different email")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(themeManager.perfolioTheme.textSecondary)
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
        }
        .onAppear {
            isCodeFocused = true
        }
    }
}

#Preview {
    EmailVerificationView(
        email: "user@example.com",
        onCodeEntered: { _ in },
        onCancel: {}
    )
    .environmentObject(ThemeManager())
}

