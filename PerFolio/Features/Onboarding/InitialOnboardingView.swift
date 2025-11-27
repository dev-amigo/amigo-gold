import SwiftUI

/// Main container for initial onboarding flow (2 pages)
struct InitialOnboardingView: View {
    @StateObject private var viewModel = InitialOnboardingViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    
    var onComplete: () -> Void
    
    init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Page Content
            TabView(selection: $viewModel.currentPage) {
                // Page 1: Notification Permission
                NotificationPermissionView(viewModel: viewModel)
                    .tag(0)
                    .environmentObject(themeManager)
                
                // Page 2: Currency Selection
                CurrencySelectionView(viewModel: viewModel)
                    .tag(1)
                    .environmentObject(themeManager)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
            
            // Top Bar
            HStack {
                // Back button (only on page 2)
                if viewModel.currentPage > 0 {
                    Button {
                        HapticManager.shared.light()
                        viewModel.previousPage()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(themeManager.perfolioTheme.textPrimary)
                    }
                } else {
                    Spacer()
                        .frame(width: 80)
                }
                
                Spacer()
                
                // Progress indicator
                HStack(spacing: 8) {
                    ForEach(0..<2, id: \.self) { index in
                        Circle()
                            .fill(
                                index == viewModel.currentPage ?
                                    Color(hex: "D4AF37") :
                                    themeManager.perfolioTheme.textTertiary.opacity(0.3)
                            )
                            .frame(width: 8, height: 8)
                    }
                }
                
                Spacer()
                
                // Skip button
                Button {
                    HapticManager.shared.light()
                    viewModel.skipToEnd()
                } label: {
                    Text("Skip")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(themeManager.perfolioTheme.textSecondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 60)
            .background(
                LinearGradient(
                    colors: [
                        themeManager.perfolioTheme.primaryBackground,
                        themeManager.perfolioTheme.primaryBackground.opacity(0.95),
                        themeManager.perfolioTheme.primaryBackground.opacity(0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 120)
                .ignoresSafeArea(edges: .top)
            )
        }
        .onAppear {
            viewModel.onComplete = onComplete
            viewModel.onSkip = onComplete
        }
    }
}

// MARK: - Preview
// Preview temporarily disabled

