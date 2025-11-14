import SwiftUI

struct EmailVerificationView: View {
    let email: String
    let onCodeEntered: (String) -> Void
    let onCancel: () -> Void
    let onResendCode: () -> Void
    
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
                    VStack(spacing: 20) {
                        Text("Enter 6-digit code")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(themeManager.perfolioTheme.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        // Code input with styled background
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(themeManager.perfolioTheme.primaryBackground)
                                .frame(height: 70)
                            
                            if code.isEmpty {
                                Text("000000")
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundStyle(themeManager.perfolioTheme.textSecondary.opacity(0.3))
                                    .kerning(8)
                            }
                            
                            TextField("", text: $code)
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundStyle(themeManager.perfolioTheme.tintColor)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                                .focused($isCodeFocused)
                                .kerning(8)
                                .onChange(of: code) { oldValue, newValue in
                                    // Only allow digits
                                    let filtered = newValue.filter { $0.isNumber }
                                    if filtered != newValue {
                                        code = filtered
                                    }
                                    // Limit to 6 digits
                                    if code.count > 6 {
                                        code = String(code.prefix(6))
                                    }
                                    // Auto-submit when 6 digits entered
                                    if code.count == 6 {
                                        onCodeEntered(code)
                                    }
                                }
                        }
                        .frame(height: 70)
                        
                        // Code counter
                        Text("\(code.count)/6")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(themeManager.perfolioTheme.textTertiary)
                    }
                    .padding(24)
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
                    
                    HStack(spacing: 24) {
                        Button(action: onResendCode) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Resend code")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                            }
                            .foregroundStyle(themeManager.perfolioTheme.tintColor)
                            .padding(.vertical, 12)
                        }
                        
                        Button(action: onCancel) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.left")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Back")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                            }
                            .foregroundStyle(themeManager.perfolioTheme.textSecondary)
                            .padding(.vertical, 12)
                        }
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
        onCancel: {},
        onResendCode: {}
    )
    .environmentObject(ThemeManager())
}

