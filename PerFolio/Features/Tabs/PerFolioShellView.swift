import SwiftUI

struct PerFolioShellView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    var onLogout: (() -> Void)?
    @State private var selectedTab: AppTab = .dashboard
    
    enum AppTab: Int {
        case dashboard = 0
        case wallet = 1
        case borrow = 2
        case loans = 3
        case activity = 4
    }
    
    var body: some View {
        ZStack {
            // Background
            themeManager.perfolioTheme.primaryBackground
                .ignoresSafeArea()
            
            if #available(iOS 18.0, *) {
                // Modern Tab API (iOS 18+) with native .searchable() support
                modernTabView
            } else {
                // Legacy TabView for iOS 17 and below
                legacyTabView
            }
        }
    }
    
    // MARK: - Modern Tab View (iOS 18+)
    
    @available(iOS 18.0, *)
    private var modernTabView: some View {
        TabView(selection: $selectedTab) {
            Tab("Dashboard", systemImage: "chart.line.uptrend.xyaxis", value: AppTab.dashboard) {
                PerFolioDashboardView(
                    onLogout: onLogout,
                    onNavigateToTab: { destination in
                        navigateToTab(destination)
                    }
                )
            }
            
            Tab("Wallet", systemImage: "wallet.bifold", value: AppTab.wallet) {
                DepositBuyView()
            }
            
            Tab("Borrow", systemImage: "banknote.fill", value: AppTab.borrow) {
                BorrowView()
            }
            
            Tab("Loans", systemImage: "list.bullet.rectangle", value: AppTab.loans) {
                ActiveLoansView()
            }
            
            Tab("Activity", systemImage: "clock.arrow.circlepath", value: AppTab.activity, role: .search) {
                ActivityView()
            }
        }
        .tint(themeManager.perfolioTheme.tintColor)
    }
    
    // MARK: - Legacy Tab View (iOS 17 and below)
    
    private var legacyTabView: some View {
        TabView(selection: $selectedTab) {
            PerFolioDashboardView(
                onLogout: onLogout,
                onNavigateToTab: { destination in
                    navigateToTab(destination)
                }
            )
            .tabItem {
                Label("Dashboard", systemImage: "chart.line.uptrend.xyaxis")
            }
            .tag(AppTab.dashboard)
            
            DepositBuyView()
                .tabItem {
                    Label("Wallet", systemImage: "wallet.bifold")
                }
                .tag(AppTab.wallet)
            
            BorrowView()
                .tabItem {
                    Label("Borrow", systemImage: "banknote.fill")
                }
                .tag(AppTab.borrow)
            
            ActiveLoansView()
                .tabItem {
                    Label("Loans", systemImage: "list.bullet.rectangle")
                }
                .tag(AppTab.loans)
            
            ActivityView()
                .tabItem {
                    Label("Activity", systemImage: "clock.arrow.circlepath")
                }
                .tag(AppTab.activity)
        }
        .tint(themeManager.perfolioTheme.tintColor)
    }
    
    // MARK: - Navigation Helper
    
    private func navigateToTab(_ destination: String) {
        withAnimation {
            switch destination.lowercased() {
            case "wallet":
                selectedTab = .wallet
            case "borrow":
                selectedTab = .borrow
            case "loans":
                selectedTab = .loans
            case "dashboard":
                selectedTab = .dashboard
            default:
                AppLogger.log("⚠️ Unknown navigation destination: \(destination)", category: "shell")
            }
        }
        HapticManager.shared.light()
    }
}

#Preview {
    PerFolioShellView()
        .environmentObject(ThemeManager())
}


