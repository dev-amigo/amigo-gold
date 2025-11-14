import SwiftUI

struct PerFolioShellView: View {
    @SceneStorage("perfolio.selectedTab") private var selectedTabRawValue: Int = PerFolioTab.dashboard.rawValue
    @EnvironmentObject private var themeManager: ThemeManager
    
    @State private var selectedTab: PerFolioTab = .dashboard {
        didSet {
            selectedTabRawValue = selectedTab.rawValue
        }
    }
    
    enum PerFolioTab: Int, CaseIterable {
        case dashboard = 0
        case depositBuy = 1
        case withdraw = 2
        
        var title: String {
            switch self {
            case .dashboard:
                return "Dashboard"
            case .depositBuy:
                return "Deposit & Buy"
            case .withdraw:
                return "Withdraw"
            }
        }
        
        var systemImage: String {
            switch self {
            case .dashboard:
                return "chart.pie.fill"
            case .depositBuy:
                return "arrow.left.arrow.right"
            case .withdraw:
                return "arrow.up.circle.fill"
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            themeManager.perfolioTheme.primaryBackground
                .ignoresSafeArea()
            
            // Tab view
            if #available(iOS 18.0, *) {
                modernTabView
            } else {
                legacyTabView
            }
        }
        .onAppear {
            // Restore tab from SceneStorage
            if let tab = PerFolioTab(rawValue: selectedTabRawValue) {
                selectedTab = tab
            }
        }
    }
    
    // MARK: - Modern Tab View (iOS 18+)
    
    @available(iOS 18.0, *)
    private var modernTabView: some View {
        TabView(selection: $selectedTab) {
            Tab(PerFolioTab.dashboard.title, systemImage: PerFolioTab.dashboard.systemImage, value: .dashboard) {
                PerFolioDashboardView()
            }
            
            Tab(PerFolioTab.depositBuy.title, systemImage: PerFolioTab.depositBuy.systemImage, value: .depositBuy) {
                DepositBuyView()
            }
            
            Tab(PerFolioTab.withdraw.title, systemImage: PerFolioTab.withdraw.systemImage, value: .withdraw) {
                WithdrawView()
            }
        }
        .tint(themeManager.perfolioTheme.tintColor)
        .tabViewStyle(.sidebarAdaptable)
    }
    
    // MARK: - Legacy Tab View (iOS 17)
    
    private var legacyTabView: some View {
        TabView(selection: $selectedTab) {
            PerFolioDashboardView()
                .tag(PerFolioTab.dashboard)
                .tabItem {
                    Label(PerFolioTab.dashboard.title, systemImage: PerFolioTab.dashboard.systemImage)
                }
            
            DepositBuyView()
                .tag(PerFolioTab.depositBuy)
                .tabItem {
                    Label(PerFolioTab.depositBuy.title, systemImage: PerFolioTab.depositBuy.systemImage)
                }
            
            WithdrawView()
                .tag(PerFolioTab.withdraw)
                .tabItem {
                    Label(PerFolioTab.withdraw.title, systemImage: PerFolioTab.withdraw.systemImage)
                }
        }
        .tint(themeManager.perfolioTheme.tintColor)
    }
}

#Preview {
    PerFolioShellView()
        .environmentObject(ThemeManager())
}

