import SwiftUI

/// Sheet for selecting transaction method before executing borrow transaction
/// Allows developer to choose between Privy SDK and Privy REST API
struct WalletProviderSelectionSheet: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    @Binding var selectedProvider: WalletProvider
    let onProceed: () -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Method Options
                    VStack(spacing: 12) {
                        ForEach(WalletProvider.allCases.filter { $0.isAvailable }) { provider in
                            methodCard(provider)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Info Banner
                    infoBanner
                    
                    // Proceed Button
                    proceedButton
                }
                .padding(.vertical, 24)
            }
            .background(themeManager.perfolioTheme.primaryBackground)
            .navigationTitle("Select Transaction Method")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        HapticManager.shared.light()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
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
            Image(systemName: "arrow.triangle.branch")
                .font(.system(size: 48))
                .foregroundStyle(themeManager.perfolioTheme.tintColor)
                .symbolRenderingMode(.hierarchical)
            
            Text("Choose Transaction Method")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(themeManager.perfolioTheme.textPrimary)
            
            Text("Select how to send your transaction to the blockchain")
                .font(.system(size: 15))
                .foregroundStyle(themeManager.perfolioTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
    }
    
    // MARK: - Method Card
    
    private func methodCard(_ provider: WalletProvider) -> some View {
        Button {
            HapticManager.shared.medium()
            selectedProvider = provider
        } label: {
            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    // Icon
                    Image(systemName: provider.icon)
                        .font(.system(size: 28))
                        .foregroundStyle(themeManager.perfolioTheme.tintColor)
                        .symbolRenderingMode(.hierarchical)
                        .frame(width: 44, height: 44)
                    
                    // Info
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(provider.displayName)
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundStyle(themeManager.perfolioTheme.textPrimary)
                            
                            if let badge = provider.badge {
                                Text(badge)
                                    .font(.system(size: 11, weight: .medium))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(
                                        provider == .privyRestAPI 
                                            ? themeManager.perfolioTheme.success.opacity(0.2)
                                            : Color.orange.opacity(0.2)
                                    )
                                    .foregroundStyle(
                                        provider == .privyRestAPI
                                            ? themeManager.perfolioTheme.success
                                            : Color.orange
                                    )
                                    .cornerRadius(4)
                            }
                        }
                        
                        Text(provider.description)
                            .font(.system(size: 14))
                            .foregroundStyle(themeManager.perfolioTheme.textSecondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    // Selection Indicator
                    Image(systemName: selectedProvider == provider ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundStyle(selectedProvider == provider ? themeManager.perfolioTheme.tintColor : themeManager.perfolioTheme.textTertiary)
                        .symbolRenderingMode(.hierarchical)
                }
                .padding(16)
                
                // Technical details
                Divider()
                    .background(themeManager.perfolioTheme.border)
                
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                        .font(.system(size: 14))
                        .foregroundStyle(themeManager.perfolioTheme.textSecondary)
                    
                    Text(provider.technicalDetails)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(themeManager.perfolioTheme.textSecondary)
                    
                    Spacer()
                    
                    if provider == .privyRestAPI {
                        Text("✓ Web Parity")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(themeManager.perfolioTheme.success)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(themeManager.perfolioTheme.secondaryBackground.opacity(0.5))
            }
            .background(themeManager.perfolioTheme.secondaryBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(selectedProvider == provider ? themeManager.perfolioTheme.tintColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Info Banner
    
    private var infoBanner: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(themeManager.perfolioTheme.tintColor)
                
                Text("Developer Testing")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(themeManager.perfolioTheme.textPrimary)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 6, height: 6)
                    Text("Privy SDK: Requires policies in Privy Dashboard")
                        .font(.system(size: 12))
                        .foregroundStyle(themeManager.perfolioTheme.textSecondary)
                }
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(themeManager.perfolioTheme.success)
                        .frame(width: 6, height: 6)
                    Text("Privy REST API: Uses sponsor: true (same as web)")
                        .font(.system(size: 12))
                        .foregroundStyle(themeManager.perfolioTheme.textSecondary)
                }
            }
        }
        .padding(16)
        .background(themeManager.perfolioTheme.tintColor.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // MARK: - Proceed Button
    
    private var proceedButton: some View {
        Button {
            HapticManager.shared.success()
            selectedProvider.select()  // Save to preferences
            dismiss()
            onProceed()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 18))
                
                Text("Proceed with \(selectedProvider.displayName)")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(themeManager.perfolioTheme.buttonBackground)
            .cornerRadius(16)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    WalletProviderSelectionSheet(
        selectedProvider: .constant(.privyRestAPI),
        onProceed: {}
    )
    .environmentObject(ThemeManager())
}
#endif

