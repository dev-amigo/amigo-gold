import SwiftUI

struct EmailInputView: View {
    @Binding var email: String
    let onContinue: () -> Void
    let isLoading: Bool
    
    @FocusState private var isEmailFocused: Bool
    @EnvironmentObject private var themeManager: ThemeManager
    
    private var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    var body: some View {
        ZStack {
            themeManager.perfolioTheme.primaryBackground
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Icon
                Image(systemName: "circle.grid.cross.fill")
                    .font(.system(size: 80))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(themeManager.perfolioTheme.tintColor)
                
                // Title and Subtitle
                VStack(spacing: 12) {
                    Text("Welcome to PerFolio")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(themeManager.perfolioTheme.textPrimary)
                    
                    Text("Hold modern gold, backed by crypto,\nwith privacy-preserving custody.")
                        .font(.system(size: 16, design: .rounded))
                        .foregroundStyle(themeManager.perfolioTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                
                // Email Input Card
                PerFolioCard(style: .secondary) {
                    VStack(spacing: 16) {
                        Text("Enter your email")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(themeManager.perfolioTheme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        TextField("your@email.com", text: $email)
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundStyle(themeManager.perfolioTheme.textPrimary)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .focused($isEmailFocused)
                            .submitLabel(.continue)
                            .onSubmit {
                                if isValidEmail && !isLoading {
                                    onContinue()
                                }
                            }
                    }
                    .padding(20)
                }
                .padding(.horizontal, 24)
                
                // Continue Button
                PerFolioButton(
                    isLoading ? "Sending code..." : "Continue",
                    isLoading: isLoading,
                    isDisabled: !isValidEmail
                ) {
                    onContinue()
                }
                .padding(.horizontal, 24)
                
                Spacer()
                Spacer()
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isEmailFocused = true
            }
        }
    }
}

#Preview {
    EmailInputView(
        email: .constant(""),
        onContinue: {},
        isLoading: false
    )
    .environmentObject(ThemeManager())
}

