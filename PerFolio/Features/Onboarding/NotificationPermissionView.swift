import SwiftUI

/// First page of onboarding - request notification permission
struct NotificationPermissionView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var viewModel: InitialOnboardingViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Bell Icon (animated)
            ZStack {
                Circle()
                    .fill(Color(hex: "D4AF37").opacity(0.15))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "bell.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "D4AF37"), Color(hex: "FFD700")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .rotationEffect(.degrees(viewModel.bellRotation))
            }
            
            VStack(spacing: 12) {
                // Title
                Text("Stay Updated")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(themeManager.perfolioTheme.textPrimary)
                
                // Subtitle
                Text("Get notified about important updates")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundStyle(themeManager.perfolioTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // Benefits list
            VStack(alignment: .leading, spacing: 16) {
                BenefitRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Price Alerts",
                    description: "Get notified when prices move"
                )
                
                BenefitRow(
                    icon: "exclamationmark.triangle.fill",
                    title: "Loan Health Warnings",
                    description: "Stay informed about your loan status"
                )
                
                BenefitRow(
                    icon: "checkmark.circle.fill",
                    title: "Transaction Confirmations",
                    description: "Know when your transactions complete"
                )
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Buttons
            VStack(spacing: 12) {
                // Primary: Enable Notifications
                Button {
                    HapticManager.shared.medium()
                    Task {
                        await viewModel.requestNotificationPermission()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "bell.badge.fill")
                        Text("Enable Notifications")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "D4AF37"), Color(hex: "FFD700")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundStyle(.black)
                    .cornerRadius(12)
                }
                
                // Secondary: Maybe Later
                Button {
                    HapticManager.shared.light()
                    viewModel.skipNotifications()
                } label: {
                    Text("Maybe Later")
                        .fontWeight(.medium)
                        .foregroundStyle(themeManager.perfolioTheme.textSecondary)
                        .padding(.vertical, 16)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager.perfolioTheme.primaryBackground)
        .onAppear {
            viewModel.startBellAnimation()
        }
    }
}

// MARK: - Benefit Row

struct BenefitRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(Color(hex: "D4AF37"))
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(themeManager.perfolioTheme.textPrimary)
                
                Text(description)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(themeManager.perfolioTheme.textSecondary)
                    .lineSpacing(2)
            }
        }
    }
}

// MARK: - Preview
// Preview temporarily disabled

