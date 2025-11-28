import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SettingsViewModel()
    var onLogout: (() -> Void)?
    
    var body: some View {
        NavigationStack {
            List {
                // User Profile Section
                userProfileSection
                
                // Theme Section
                themeSection
                
                // Preferences Section (NEW)
                preferencesSection
                
                // App Settings Section
                appSettingsSection
                
                #if DEBUG
                // Developer Section (DEBUG only)
                developerSection
                #endif
                
                // Support & Legal Section
                supportLegalSection
                
                // Libraries Section
                librariesSection
                
                // Logout Section
                logoutSection
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(themeManager.perfolioTheme.primaryBackground)
            .navigationTitle("Settings")
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
            .sheet(isPresented: $viewModel.showingSafari) {
                if let url = viewModel.safariURL {
                    SafariView(url: url) {}
                }
            }
            .alert("Logout", isPresented: $viewModel.showingLogoutConfirmation) {
                Button("Cancel", role: .cancel) {
                    HapticManager.shared.light()
                }
                Button("Logout", role: .destructive) {
                    HapticManager.shared.heavy()
                    viewModel.logout()
                    dismiss()
                    onLogout?()
                }
            } message: {
                Text("Are you sure you want to logout?")
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                versionFooter
            }
        }
    }
    
    // MARK: - User Profile Section
    
    private var userProfileSection: some View {
        Section {
            HStack(spacing: 16) {
                // Profile Icon
                Circle()
                    .fill(themeManager.perfolioTheme.tintColor.opacity(0.15))
                    .frame(width: 64, height: 64)
                    .overlay(
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(themeManager.perfolioTheme.tintColor)
                            .symbolRenderingMode(.hierarchical)
                    )
                
                // User Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.userEmail)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(themeManager.perfolioTheme.textPrimary)
                        .lineLimit(1)
                    
                    if let walletAddress = viewModel.walletAddress {
                        HStack(spacing: 6) {
                            Text(viewModel.truncatedAddress(walletAddress))
                                .font(.system(size: 13, weight: .regular, design: .monospaced))
                                .foregroundStyle(themeManager.perfolioTheme.textSecondary)
                            
                            Button {
                                HapticManager.shared.light()
                                viewModel.copyAddress(walletAddress)
                            } label: {
                                Image(systemName: viewModel.addressCopied ? "checkmark.circle.fill" : "doc.on.doc")
                                    .font(.system(size: 12))
                                    .foregroundStyle(viewModel.addressCopied ? .green : themeManager.perfolioTheme.tintColor)
                                    .symbolRenderingMode(.hierarchical)
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
            .listRowBackground(themeManager.perfolioTheme.secondaryBackground)
        }
    }
    
    // MARK: - Theme Section
    
    private var themeSection: some View {
        Section {
            ForEach(ThemeVariant.allCases) { variant in
                Button {
                    HapticManager.shared.medium()
                    themeManager.setThemeVariant(variant)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: variant.icon)
                            .font(.system(size: 18))
                            .foregroundStyle(themeManager.perfolioTheme.tintColor)
                            .symbolRenderingMode(.hierarchical)
                            .frame(width: 28, alignment: .center)
                        
                        Text(variant.rawValue)
                            .font(.system(size: 17, design: .rounded))
                            .foregroundStyle(themeManager.perfolioTheme.textPrimary)
                        
                        Spacer()
                        
                        if themeManager.currentThemeVariant == variant {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(themeManager.perfolioTheme.tintColor)
                                .symbolRenderingMode(.hierarchical)
                        }
                    }
                }
                .listRowBackground(themeManager.perfolioTheme.secondaryBackground)
            }
        } header: {
            Text("Theme")
                .foregroundStyle(themeManager.perfolioTheme.textPrimary)
        } footer: {
            Text("Changes apply instantly.")
                .foregroundStyle(themeManager.perfolioTheme.textSecondary)
                .font(.system(size: 13))
        }
    }
    
    // MARK: - Preferences Section
    
    private var preferencesSection: some View {
        Section {
            // Notifications Toggle
            HStack(spacing: 12) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(themeManager.perfolioTheme.tintColor)
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 28, alignment: .center)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Notifications")
                        .font(.system(size: 17, design: .rounded))
                        .foregroundStyle(themeManager.perfolioTheme.textPrimary)
                    Text("Price alerts & updates")
                        .font(.system(size: 13))
                        .foregroundStyle(themeManager.perfolioTheme.textSecondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $viewModel.notificationsEnabled)
                    .labelsHidden()
                    .tint(themeManager.perfolioTheme.tintColor)
                    .onChange(of: viewModel.notificationsEnabled) { _, newValue in
                        HapticManager.shared.light()
                        viewModel.updateNotificationPreference(newValue)
                    }
            }
            .listRowBackground(themeManager.perfolioTheme.secondaryBackground)
            
            // Currency Selection
            NavigationLink {
                CurrencySettingsView()
                    .environmentObject(themeManager)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(themeManager.perfolioTheme.tintColor)
                        .symbolRenderingMode(.hierarchical)
                        .frame(width: 28, alignment: .center)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Default Currency")
                            .font(.system(size: 17, design: .rounded))
                            .foregroundStyle(themeManager.perfolioTheme.textPrimary)
                        Text("Display amounts in \(viewModel.currentCurrency)")
                            .font(.system(size: 13))
                            .foregroundStyle(themeManager.perfolioTheme.textSecondary)
                    }
                    
                    Spacer()
                    
                    Text(viewModel.currencySymbol)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(themeManager.perfolioTheme.textTertiary)
                }
            }
            .listRowBackground(themeManager.perfolioTheme.secondaryBackground)
        } header: {
            Text("Preferences")
                .foregroundStyle(themeManager.perfolioTheme.textPrimary)
        }
    }
    
    // MARK: - App Settings Section
    
    private var appSettingsSection: some View {
        Section {
            // Haptic Feedback
            HStack(spacing: 12) {
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(themeManager.perfolioTheme.tintColor)
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 28, alignment: .center)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Haptic Feedback")
                        .font(.system(size: 17, design: .rounded))
                        .foregroundStyle(themeManager.perfolioTheme.textPrimary)
                    Text("Vibration on interactions")
                        .font(.system(size: 13))
                        .foregroundStyle(themeManager.perfolioTheme.textSecondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $viewModel.isHapticEnabled)
                    .labelsHidden()
                    .tint(themeManager.perfolioTheme.tintColor)
                    .onChange(of: viewModel.isHapticEnabled) { _, newValue in
                        if newValue {
                            HapticManager.shared.medium()
                        }
                    }
            }
            .listRowBackground(themeManager.perfolioTheme.secondaryBackground)
            
            // Sound Effects
            HStack(spacing: 12) {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(viewModel.isHapticEnabled ? themeManager.perfolioTheme.tintColor : themeManager.perfolioTheme.textTertiary)
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 28, alignment: .center)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sound Effects")
                        .font(.system(size: 17, design: .rounded))
                        .foregroundStyle(viewModel.isHapticEnabled ? themeManager.perfolioTheme.textPrimary : themeManager.perfolioTheme.textTertiary)
                    Text("Audio feedback on haptics")
                        .font(.system(size: 13))
                        .foregroundStyle(themeManager.perfolioTheme.textSecondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $viewModel.isSoundEnabled)
                    .labelsHidden()
                    .disabled(!viewModel.isHapticEnabled)
                    .tint(themeManager.perfolioTheme.tintColor)
                    .onChange(of: viewModel.isSoundEnabled) { _, newValue in
                        if newValue {
                            HapticManager.shared.medium()
                        }
                    }
            }
            .listRowBackground(themeManager.perfolioTheme.secondaryBackground)
        } header: {
            Text("App Settings")
                .foregroundStyle(themeManager.perfolioTheme.textPrimary)
        }
    }
    
    // MARK: - Developer Section
    
    #if DEBUG
    private var developerSection: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.orange)
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 28, alignment: .center)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Developer Mode")
                        .font(.system(size: 17, design: .rounded))
                        .foregroundStyle(themeManager.perfolioTheme.textPrimary)
                    Text("Experimental features for testing")
                        .font(.system(size: 13))
                        .foregroundStyle(themeManager.perfolioTheme.textSecondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $viewModel.isDevModeEnabled)
                    .labelsHidden()
                    .tint(.orange)
                    .onChange(of: viewModel.isDevModeEnabled) { _, newValue in
                        HapticManager.shared.medium()
                    }
            }
            .listRowBackground(themeManager.perfolioTheme.secondaryBackground)
        } header: {
            Text("Developer")
                .foregroundStyle(themeManager.perfolioTheme.textPrimary)
        } footer: {
            VStack(alignment: .leading, spacing: 8) {
                Text("Enables experimental features:")
                    .font(.system(size: 13))
                    .foregroundStyle(themeManager.perfolioTheme.textSecondary)
                
                Text("• Alchemy AA wallet for gas-sponsored transactions")
                    .font(.system(size: 12))
                    .foregroundStyle(themeManager.perfolioTheme.textTertiary)
                
                Text("• Alternative transaction signing methods")
                    .font(.system(size: 12))
                    .foregroundStyle(themeManager.perfolioTheme.textTertiary)
                
                Text("⚠️ For testing purposes only. Not available in production builds.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.orange)
                    .padding(.top, 4)
            }
        }
    }
    #endif
    
    // MARK: - Support & Legal Section
    
    private var supportLegalSection: some View {
        Section {
            // Email Support
            Button {
                HapticManager.shared.light()
                viewModel.openEmail()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(themeManager.perfolioTheme.tintColor)
                        .symbolRenderingMode(.hierarchical)
                        .frame(width: 28, alignment: .center)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Email Support")
                            .font(.system(size: 17, design: .rounded))
                            .foregroundStyle(themeManager.perfolioTheme.textPrimary)
                        Text("support@perfolio.ai")
                            .font(.system(size: 13))
                            .foregroundStyle(themeManager.perfolioTheme.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(themeManager.perfolioTheme.textTertiary)
                }
            }
            .listRowBackground(themeManager.perfolioTheme.secondaryBackground)
            
            // Terms of Service
            Button {
                HapticManager.shared.light()
                viewModel.openTermsOfService()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(themeManager.perfolioTheme.tintColor)
                        .symbolRenderingMode(.hierarchical)
                        .frame(width: 28, alignment: .center)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Terms of Service")
                            .font(.system(size: 17, design: .rounded))
                            .foregroundStyle(themeManager.perfolioTheme.textPrimary)
                        Text("Read our terms")
                            .font(.system(size: 13))
                            .foregroundStyle(themeManager.perfolioTheme.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(themeManager.perfolioTheme.textTertiary)
                }
            }
            .listRowBackground(themeManager.perfolioTheme.secondaryBackground)
            
            // Privacy Policy
            Button {
                HapticManager.shared.light()
                viewModel.openPrivacyPolicy()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(themeManager.perfolioTheme.tintColor)
                        .symbolRenderingMode(.hierarchical)
                        .frame(width: 28, alignment: .center)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Privacy Policy")
                            .font(.system(size: 17, design: .rounded))
                            .foregroundStyle(themeManager.perfolioTheme.textPrimary)
                        Text("Your data privacy")
                            .font(.system(size: 13))
                            .foregroundStyle(themeManager.perfolioTheme.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(themeManager.perfolioTheme.textTertiary)
                }
            }
            .listRowBackground(themeManager.perfolioTheme.secondaryBackground)
        } header: {
            Text("Support & Legal")
                .foregroundStyle(themeManager.perfolioTheme.textPrimary)
        }
    }
    
    // MARK: - Libraries Section
    
    private var librariesSection: some View {
        Section {
            ForEach(viewModel.libraries) { library in
                Button {
                    if library.licenseURL != nil {
                        HapticManager.shared.light()
                        viewModel.openLibraryLicense(library)
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "shippingbox.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(themeManager.perfolioTheme.tintColor)
                            .symbolRenderingMode(.hierarchical)
                            .frame(width: 28, alignment: .center)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(library.name)
                                .font(.system(size: 17, design: .rounded))
                                .foregroundStyle(themeManager.perfolioTheme.textPrimary)
                            Text(library.version)
                                .font(.system(size: 13))
                                .foregroundStyle(themeManager.perfolioTheme.textSecondary)
                        }
                        
                        Spacer()
                        
                        if library.licenseURL != nil {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(themeManager.perfolioTheme.textTertiary)
                        }
                    }
                }
                .disabled(library.licenseURL == nil)
                .listRowBackground(themeManager.perfolioTheme.secondaryBackground)
            }
        } header: {
            Text("Libraries & Dependencies")
                .foregroundStyle(themeManager.perfolioTheme.textPrimary)
        }
    }
    
    // MARK: - Logout Section
    
    private var logoutSection: some View {
        Section {
            Button {
                HapticManager.shared.medium()
                viewModel.showLogoutConfirmation()
            } label: {
                HStack {
                    Spacer()
                    
                    Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Spacer()
                }
                .padding(.vertical, 4)
            }
            .listRowBackground(Color.red)
        }
    }
    
    // MARK: - Version Footer
    
    private var versionFooter: some View {
        VStack(spacing: 4) {
            Text("Version \(viewModel.appVersion) (\(viewModel.buildNumber))")
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(themeManager.perfolioTheme.textTertiary)
            
            Text("Made with ❤️ in India")
                .font(.system(size: 11, weight: .regular, design: .rounded))
                .foregroundStyle(themeManager.perfolioTheme.textTertiary.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(themeManager.perfolioTheme.primaryBackground.opacity(0.95))
    }
}

#Preview {
    SettingsView()
        .environmentObject(ThemeManager())
}
