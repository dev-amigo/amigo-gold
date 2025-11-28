import SwiftUI

/// FAQ View with expandable/collapsible questions
struct FAQView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @State private var expandedItems: Set<String> = []
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    headerSection
                    
                    // Search Bar
                    searchBar
                    
                    // FAQ Items
                    VStack(spacing: 12) {
                        ForEach(filteredFAQItems) { item in
                            faqItemCard(item)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
            .background(themeManager.perfolioTheme.primaryBackground)
            .navigationTitle("FAQ")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        HapticManager.shared.light()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(themeManager.perfolioTheme.textSecondary)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(themeManager.perfolioTheme.tintColor)
                .symbolRenderingMode(.hierarchical)
            
            Text("Frequently Asked Questions")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(themeManager.perfolioTheme.textPrimary)
            
            Text("A safe and simple way to understand Web3 loans, gold-backed savings, and how PerFolio works")
                .font(.system(size: 15))
                .foregroundStyle(themeManager.perfolioTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.vertical, 32)
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(themeManager.perfolioTheme.textTertiary)
            
            TextField("Search FAQs...", text: $searchText)
                .font(.system(size: 16, design: .rounded))
                .foregroundStyle(themeManager.perfolioTheme.textPrimary)
            
            if !searchText.isEmpty {
                Button {
                    HapticManager.shared.light()
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(themeManager.perfolioTheme.textTertiary)
                }
            }
        }
        .padding(12)
        .background(themeManager.perfolioTheme.secondaryBackground)
        .cornerRadius(12)
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
    }
    
    // MARK: - FAQ Item Card
    
    private func faqItemCard(_ item: FAQItem) -> some View {
        let isExpanded = expandedItems.contains(item.id)
        
        return VStack(spacing: 0) {
            // Question Header
            Button {
                HapticManager.shared.light()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    if isExpanded {
                        expandedItems.remove(item.id)
                    } else {
                        expandedItems.insert(item.id)
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    // Icon
                    Text(item.emoji)
                        .font(.system(size: 24))
                    
                    // Question
                    Text(item.question)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(themeManager.perfolioTheme.textPrimary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Chevron
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(themeManager.perfolioTheme.tintColor)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(16)
            }
            
            // Answer (Expandable)
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                        .background(themeManager.perfolioTheme.border)
                    
                    Text(item.answer)
                        .font(.system(size: 15, design: .rounded))
                        .foregroundStyle(themeManager.perfolioTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // Bullet Points (if any)
                    if !item.bulletPoints.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(item.bulletPoints, id: \.self) { point in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("•")
                                        .foregroundStyle(themeManager.perfolioTheme.tintColor)
                                    Text(point)
                                        .font(.system(size: 14, design: .rounded))
                                        .foregroundStyle(themeManager.perfolioTheme.textSecondary)
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(themeManager.perfolioTheme.secondaryBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isExpanded ? themeManager.perfolioTheme.tintColor.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
    
    // MARK: - Filtered Items
    
    private var filteredFAQItems: [FAQItem] {
        if searchText.isEmpty {
            return FAQItem.allItems
        }
        return FAQItem.allItems.filter {
            $0.question.localizedCaseInsensitiveContains(searchText) ||
            $0.answer.localizedCaseInsensitiveContains(searchText) ||
            $0.bulletPoints.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })
        }
    }
}

// MARK: - FAQ Item Model

struct FAQItem: Identifiable {
    let id: String
    let emoji: String
    let question: String
    let answer: String
    let bulletPoints: [String]
    
    init(id: String, emoji: String, question: String, answer: String, bulletPoints: [String] = []) {
        self.id = id
        self.emoji = emoji
        self.question = question
        self.answer = answer
        self.bulletPoints = bulletPoints
    }
    
    // MARK: - All FAQ Items
    
    static let allItems: [FAQItem] = [
        FAQItem(
            id: "what-is-perfolio",
            emoji: "🟡",
            question: "What is PerFolio?",
            answer: "PerFolio is a digital finance app that lets you save in gold (PAXG), borrow USDC instantly using your gold as security, and keep your gold while getting cash.\n\nNo banks, no paperwork, no credit checks. Everything works through safe, transparent smart contracts on blockchain.",
            bulletPoints: [
                "Save in gold (PAXG)",
                "Borrow USDC instantly using your gold as security",
                "Keep your gold while getting cash"
            ]
        ),
        
        FAQItem(
            id: "what-is-web3",
            emoji: "🟣",
            question: "What is Web3? (Simple Version)",
            answer: "Web3 is like using the internet, but with your own control over your money. Think of it like a digital locker where only you hold the keys.",
            bulletPoints: [
                "No bank needed",
                "No middleman",
                "Everything is handled by secure computer code",
                "You own your assets fully"
            ]
        ),
        
        FAQItem(
            id: "what-is-paxg",
            emoji: "🟢",
            question: "What is PAXG (Gold Token)?",
            answer: "PAXG = Digital gold. 1 PAXG = 1 ounce of real physical gold stored in London vaults, fully backed. You can buy/sell small amounts anytime.\n\nPerFolio uses PAXG so you can save in gold and borrow USDC without selling your gold.",
            bulletPoints: [
                "1 PAXG = 1 ounce of real physical gold",
                "Stored in London vaults",
                "Fully backed",
                "You can buy/sell small amounts anytime"
            ]
        ),
        
        FAQItem(
            id: "what-is-smart-contract",
            emoji: "🔵",
            question: "What is a Smart Contract?",
            answer: "A smart contract is a computer program that automatically follows financial rules. Like a robot banker that never makes mistakes.",
            bulletPoints: [
                "Holds your deposits safely",
                "Gives loans instantly",
                "Calculates interest",
                "Protects your collateral",
                "Cannot be changed or cheated"
            ]
        ),
        
        FAQItem(
            id: "borrow-against-gold",
            emoji: "🟠",
            question: "What does 'Borrow Against Gold' mean?",
            answer: "You can lock your PAXG (digital gold) in PerFolio and instantly get a USDC loan. You still own your gold, but it is locked as security.",
            bulletPoints: [
                "Your gold is locked as security",
                "When you repay the loan, your gold unlocks",
                "If you don't repay or gold value drops too much → some gold may be sold automatically (liquidation)"
            ]
        ),
        
        FAQItem(
            id: "why-borrow-against-gold",
            emoji: "🟤",
            question: "Why would someone borrow against gold?",
            answer: "People borrow against PAXG because they want quick cash without selling gold, believe gold will go up in value, want to keep savings intact, avoid traditional bank paperwork, and get liquidity instantly.",
            bulletPoints: [
                "Want quick cash without selling gold",
                "Believe gold will go up in value",
                "Want to keep savings intact",
                "Want to avoid traditional bank paperwork",
                "Want liquidity (money to use) instantly"
            ]
        ),
        
        FAQItem(
            id: "what-is-loan-ratio",
            emoji: "🟩",
            question: "What is Loan Ratio?",
            answer: "Loan Ratio = How much you borrowed compared to the value of your gold.\n\nLow ratio = safe\nHigh ratio = risky\n\nExample: Your gold is worth $100, you borrow $20. Loan ratio = 20% → very safe."
        ),
        
        FAQItem(
            id: "what-is-liquidation",
            emoji: "🟥",
            question: "What is Liquidation? Will I lose all my gold?",
            answer: "No, you will not lose all your gold.\n\nLiquidation means: If your gold price falls too much, a small portion of your gold is automatically sold to cover the loan. This protects you and the system.",
            bulletPoints: [
                "You can avoid liquidation by adding more gold",
                "Or by paying some loan back"
            ]
        ),
        
        FAQItem(
            id: "what-is-interest",
            emoji: "🟧",
            question: "What is Interest?",
            answer: "Interest = The extra amount you pay when you borrow USDC.\n\nPerFolio does not charge hidden fees. Borrowing interest is shown clearly. Interest is small on a daily basis and gets added to your loan."
        ),
        
        FAQItem(
            id: "what-is-apy",
            emoji: "🟪",
            question: "What is APY?",
            answer: "APY = Annual Percentage Yield\n\nIt means: How much interest you pay (or earn) in one year.\n\nIf APY is 7%, borrowing $100 means you pay about $7 in one year."
        ),
        
        FAQItem(
            id: "is-perfolio-safe",
            emoji: "🟫",
            question: "Is PerFolio safe?",
            answer: "Yes! PerFolio does not keep your money. Smart contracts do.",
            bulletPoints: [
                "Your gold is held via secure blockchain contracts",
                "No one can take or freeze your assets",
                "You control everything with your wallet",
                "Transparent on blockchain",
                "No hidden charges"
            ]
        ),
        
        FAQItem(
            id: "why-not-bank-loan",
            emoji: "⚪",
            question: "Why use PerFolio instead of a bank loan?",
            answer: "You borrow against your own asset, not your credit score.",
            bulletPoints: [
                "✔ Instant loan",
                "✔ No documents",
                "✔ No credit history",
                "✔ No salary proof",
                "✔ No waiting",
                "✔ Low interest",
                "✔ You keep your gold"
            ]
        ),
        
        FAQItem(
            id: "when-not-to-borrow",
            emoji: "🟤",
            question: "When should I NOT borrow?",
            answer: "Avoid borrowing if you need long-term loans with EMI, you are unsure about gold price, or you can't monitor your loan ratio.\n\nUse PerFolio loans for:",
            bulletPoints: [
                "Short-term cash needs",
                "Emergencies",
                "Opportunities",
                "Quick liquidity"
            ]
        ),
        
        FAQItem(
            id: "does-perfolio-take-gold",
            emoji: "🔘",
            question: "Does PerFolio take my gold?",
            answer: "No. You only lock your PAXG as collateral. You can unlock it anytime by repaying your loan."
        ),
        
        FAQItem(
            id: "how-perfolio-earns",
            emoji: "⚫",
            question: "How does PerFolio earn money?",
            answer: "You always see what you pay.",
            bulletPoints: [
                "Small fee from borrow interest",
                "Small fee from swaps",
                "Commission from on-ramp providers"
            ]
        ),
        
        FAQItem(
            id: "one-line-summary",
            emoji: "🌟",
            question: "One-Line Summary",
            answer: "PerFolio is your digital gold locker + instant loan system — safe, transparent, and built for everyone."
        )
    ]
}

// MARK: - Preview

#Preview {
    FAQView()
        .environmentObject(ThemeManager())
}

