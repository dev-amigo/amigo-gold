import SwiftUI

struct SplashView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let didFinish: () -> Void
    @State private var isVisible = false

    var body: some View {
        ZStack {
            themeManager.perfolioTheme.primaryBackground
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Gold icon
                Image(systemName: "circle.grid.cross.fill")
                    .symbolRenderingMode(.hierarchical)
                    .font(.system(size: 72, weight: .regular, design: .rounded))
                    .foregroundStyle(themeManager.perfolioTheme.tintColor)
                    .opacity(isVisible ? 1 : 0)
                    .scaleEffect(isVisible ? 1 : 0.8)
                
                // App name
                Text("PerFolio")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(themeManager.perfolioTheme.textPrimary)
                    .tracking(2)
                    .opacity(isVisible ? 1 : 0)
                    .scaleEffect(isVisible ? 1 : 0.9)
            }
            .animation(.easeInOut(duration: AppConstants.splashFadeDuration), value: isVisible)
        }
        .task {
            guard !isVisible else { return }
            isVisible = true
            try? await Task.sleep(for: .seconds(AppConstants.splashDisplayTime))
            await MainActor.run {
                didFinish()
            }
        }
    }
}

#Preview {
    SplashView { }
        .environmentObject(ThemeManager())
}
