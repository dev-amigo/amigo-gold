import SwiftUI

struct PerFolioDashboardView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var collateralAmount: String = ""
    @State private var borrowAmount: String = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                goldenHeroCard
                yourGoldHoldingsCard
                getInstantLoanCard
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .background(themeManager.perfolioTheme.primaryBackground.ignoresSafeArea())
    }
    
    // MARK: - Golden Hero Card
    
    private var goldenHeroCard: some View {
        PerFolioCard(style: .gradient, padding: 24) {
            VStack(alignment: .leading, spacing: 16) {
                portfolioHeader
                chartPlaceholder
                PerFolioButton("BUY GOLD") {
                    // Will be implemented in Phase 4
                }
            }
        }
    }
    
    private var portfolioHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Gold Portfolio")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("$0.00")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text("+0.0%")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(themeManager.perfolioTheme.success)
            }
        }
    }
    
    private var chartPlaceholder: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let points: [CGFloat] = [0.6, 0.4, 0.5, 0.3, 0.4, 0.2, 0.3, 0.1]
                    
                    path.move(to: CGPoint(x: 0, y: height * points[0]))
                    for (index, point) in points.enumerated() {
                        let x = width * CGFloat(index) / CGFloat(points.count - 1)
                        let y = height * point
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                .stroke(Color.white.opacity(0.8), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            }
            .frame(height: 80)
            
            Text("24H Price Movement")
                .font(.caption)
                .foregroundStyle(Color.white.opacity(0.7))
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Your Gold Holdings Card
    
    private var yourGoldHoldingsCard: some View {
        PerFolioCard {
            VStack(alignment: .leading, spacing: 16) {
                PerFolioSectionHeader(
                    icon: "bitcoinsign.circle.fill",
                    title: "Your Gold Holdings"
                )
                
                Divider()
                    .background(themeManager.perfolioTheme.border)
                
                // Balance rows
                PerFolioBalanceRow(
                    tokenSymbol: "PAXG",
                    tokenAmount: "0.00",
                    usdValue: "$0.00"
                )
                
                PerFolioBalanceRow(
                    tokenSymbol: "USDT",
                    tokenAmount: "0.00",
                    usdValue: "$0.00"
                )
                
                Divider()
                    .background(themeManager.perfolioTheme.border)
                
                // Action buttons
                HStack(spacing: 12) {
                    PerFolioButton("Deposit", style: .primary) {
                        // Will be implemented in Phase 4
                    }
                    
                    PerFolioButton("Buy", style: .secondary) {
                        // Will be implemented in Phase 4
                    }
                }
            }
        }
    }
    
    // MARK: - Get Instant Loan Card
    
    private var getInstantLoanCard: some View {
        PerFolioCard {
            VStack(alignment: .leading, spacing: 16) {
                PerFolioSectionHeader(
                    icon: "banknote.fill",
                    title: "Get Instant Loan",
                    subtitle: "Borrow USDT against your PAXG collateral"
                )
                
                Divider()
                    .background(themeManager.perfolioTheme.border)
                
                // Input fields
                PerFolioInputField(
                    label: "PAXG Collateral",
                    text: $collateralAmount,
                    trailingText: "PAXG",
                    presetValues: ["25%", "50%", "75%", "100%"]
                )
                
                PerFolioInputField(
                    label: "USDT to Borrow",
                    text: $borrowAmount,
                    trailingText: "USDT"
                )
                
                // Loan metrics
                VStack(spacing: 8) {
                    PerFolioMetricRow(label: "LTV", value: "0%")
                    PerFolioMetricRow(label: "Health Factor", value: "∞")
                }
                .padding(12)
                .background(themeManager.perfolioTheme.primaryBackground.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                
                // Borrow button
                PerFolioButton("BORROW USDT", style: .disabled, isDisabled: true) {
                    // Will be implemented in Phase 3
                }
            }
        }
    }
}

#Preview {
    PerFolioDashboardView()
        .environmentObject(ThemeManager())
}
