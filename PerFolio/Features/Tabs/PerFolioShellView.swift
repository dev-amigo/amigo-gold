import SwiftUI

struct PerFolioShellView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    var onLogout: (() -> Void)?
    
    var body: some View {
        ZStack {
            // Background
            themeManager.perfolioTheme.primaryBackground
                .ignoresSafeArea()
            
            // Phase 2: Dashboard only (tabs hidden)
            PerFolioDashboardView(onLogout: onLogout)
        }
    }
}

#Preview {
    PerFolioShellView()
        .environmentObject(ThemeManager())
}



