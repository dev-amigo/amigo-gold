import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SettingsViewModel()
    var onLogout: (() -> Void)?
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.perfolioTheme.primaryBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // User Profile Card
                        userProfileCard
                        
                        // App Settings
                        appSettingsSection
                        
                        // Support & Legal
                        supportSection
                        
                        // Libraries & Dependencies
                        librariesSection
                        
                        // Logout Button
                        logoutButton
                        
                        // Version Info
                        versionInfo
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
            }
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
        }
    }
    
    // MARK: - User Profile Card
    
    private var userProfileCard: some View {
        PerFolioCard {
            VStack(spacing: 16) {
                // Profile Icon
                Circle()
                    .fill(themeManager.perfolioTheme.tintColor.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(themeManager.perfolioTheme.tintColor)
                    )
                
                // User Info
                VStack(spacing: 8) {
                    Text(viewModel.userEmail)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(themeManager.perfolioTheme.textPrimary)
                    
                    if let walletAddress = viewModel.walletAddress {
                        HStack(spacing: 8) {
                            Text(viewModel.truncatedAddress(walletAddress))
                                .font(.system(size: 14, weight: .regular, design: .monospaced))
                                .foregroundStyle(themeManager.perfolioTheme.textSecondary)
                            
                            Button {
                                HapticManager.shared.light()
                                viewModel.copyAddress(walletAddress)
                            } label: {
                                Image(systemName: viewModel.addressCopied ? "checkmark.circle.fill" : "doc.on.doc")
                                    .font(.system(size: 14))
                                    .foregroundStyle(viewModel.addressCopied ? .green : themeManager.perfolioTheme.tintColor)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - App Settings Section
    
    private var appSettingsSection: some View {
        VStack(spacing: 16) {
            sectionHeader("App Settings")
            
            PerFolioCard {
                VStack(spacing: 0) {
                    // Theme Toggle
                    SettingsRow(
                        icon: "moon.fill",
                        title: "Dark Mode",
                        subtitle: "Always enabled"
                    ) {
                        Toggle("", isOn: .constant(true))
                            .labelsHidden()
                            .disabled(true)
                            .tint(themeManager.perfolioTheme.tintColor)
                    }
                    
                    Divider()
                        .background(themeManager.perfolioTheme.textSecondary.opacity(0.2))
                    
                    // Haptic Feedback
                    SettingsRow(
                        icon: "hand.tap.fill",
                        title: "Haptic Feedback",
                        subtitle: "Vibration on interactions"
                    ) {
                        Toggle("", isOn: $viewModel.isHapticEnabled)
                            .labelsHidden()
                            .tint(themeManager.perfolioTheme.tintColor)
                            .onChange(of: viewModel.isHapticEnabled) { _, newValue in
                                if newValue {
                                    HapticManager.shared.medium()
                                }
                            }
                    }
                    
                    Divider()
                        .background(themeManager.perfolioTheme.textSecondary.opacity(0.2))
                    
                    // Sound Effects
                    SettingsRow(
                        icon: "speaker.wave.2.fill",
                        title: "Sound Effects",
                        subtitle: "Audio feedback on haptics"
                    ) {
                        Toggle("", isOn: $viewModel.isSoundEnabled)
                            .labelsHidden()
                            .tint(themeManager.perfolioTheme.tintColor)
                            .disabled(!viewModel.isHapticEnabled)
                            .onChange(of: viewModel.isSoundEnabled) { _, newValue in
                                if newValue {
                                    HapticManager.shared.medium()
                                }
                            }
                    }
                }
            }
        }
    }
    
    // MARK: - Support Section
    
    private var supportSection: some View {
        VStack(spacing: 16) {
            sectionHeader("Support & Legal")
            
            PerFolioCard {
                VStack(spacing: 0) {
                    SettingsRow(
                        icon: "envelope.fill",
                        title: "Email Support",
                        subtitle: "support@perfolio.com"
                    ) {
                        Button {
                            HapticManager.shared.light()
                            viewModel.openEmail()
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(themeManager.perfolioTheme.textSecondary)
                        }
                    }
                    
                    Divider()
                        .background(themeManager.perfolioTheme.textSecondary.opacity(0.2))
                    
                    SettingsRow(
                        icon: "doc.text.fill",
                        title: "Terms of Service",
                        subtitle: "Read our terms"
                    ) {
                        Button {
                            HapticManager.shared.light()
                            viewModel.openTermsOfService()
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(themeManager.perfolioTheme.textSecondary)
                        }
                    }
                    
                    Divider()
                        .background(themeManager.perfolioTheme.textSecondary.opacity(0.2))
                    
                    SettingsRow(
                        icon: "hand.raised.fill",
                        title: "Privacy Policy",
                        subtitle: "Your data privacy"
                    ) {
                        Button {
                            HapticManager.shared.light()
                            viewModel.openPrivacyPolicy()
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(themeManager.perfolioTheme.textSecondary)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Libraries Section
    
    private var librariesSection: some View {
        VStack(spacing: 16) {
            sectionHeader("Libraries & Dependencies")
            
            PerFolioCard {
                VStack(spacing: 0) {
                    ForEach(viewModel.libraries.indices, id: \.self) { index in
                        if index > 0 {
                            Divider()
                                .background(themeManager.perfolioTheme.textSecondary.opacity(0.2))
                        }
                        
                        let library = viewModel.libraries[index]
                        SettingsRow(
                            icon: "shippingbox.fill",
                            title: library.name,
                            subtitle: library.version
                        ) {
                            if let _ = library.licenseURL {
                                Button {
                                    HapticManager.shared.light()
                                    viewModel.openLibraryLicense(library)
                                } label: {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(themeManager.perfolioTheme.textSecondary)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Logout Button
    
    private var logoutButton: some View {
        Button {
            HapticManager.shared.medium()
            viewModel.showLogoutConfirmation()
        } label: {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 16, weight: .semibold))
                
                Text("Logout")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(.red)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
    
    // MARK: - Version Info
    
    private var versionInfo: some View {
        VStack(spacing: 8) {
            Text("PerFolio")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(themeManager.perfolioTheme.textSecondary)
            
            Text("Version \(viewModel.appVersion) (\(viewModel.buildNumber))")
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(themeManager.perfolioTheme.textSecondary.opacity(0.7))
            
            Text("Made with ❤️ in India")
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(themeManager.perfolioTheme.textSecondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
    
    // MARK: - Helper Views
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 20, weight: .semibold, design: .rounded))
            .foregroundStyle(themeManager.perfolioTheme.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Settings Row Component

struct SettingsRow<Trailing: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    @ViewBuilder let trailing: () -> Trailing
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(themeManager.perfolioTheme.tintColor)
                .frame(width: 32, height: 32)
            
            // Title & Subtitle
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(themeManager.perfolioTheme.textPrimary)
                
                Text(subtitle)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(themeManager.perfolioTheme.textSecondary)
            }
            
            Spacer()
            
            // Trailing content
            trailing()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#Preview {
    SettingsView()
        .environmentObject(ThemeManager())
}

