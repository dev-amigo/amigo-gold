//
//  Amigo_GoldApp.swift
// PerFolio
//
//  Created by Tirupati Balan on 12/11/25.
//

import SwiftUI
import SwiftData
import TipKit

@available(iOS 17.0, *)
@main
struct Amigo_GoldApp: App {
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var privyCoordinator = PrivyAuthCoordinator.shared
    private let swiftDataStack = SwiftDataStack()

    init() {
        // Configure TipKit for onboarding tutorial
        try? Tips.configure([
            .displayFrequency(.immediate),
            .datastoreLocation(.applicationDefault)
        ])
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(themeManager)
                .environmentObject(privyCoordinator)
                .environment(\.colorScheme, themeManager.colorScheme)
                .environment(\.locale, LocalizationManager.shared.locale)
        }
        .modelContainer(swiftDataStack.container)
    }
}
