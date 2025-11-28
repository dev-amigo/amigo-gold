import Foundation
import TipKit

/// Tip to help first-time users understand the onboarding steps
struct OnboardingTip: Tip {
    var title: Text {
        Text("Complete Your Setup")
    }
    
    var message: Text? {
        Text("Tap 'Get Started' to see your onboarding checklist. Complete these simple steps to start using PerFolio:\n\n1. Deposit USDC with INR\n2. Swap USDC to PAXG (tokenized gold)\n3. Borrow USDC using your gold as collateral\n\nEach step takes just a few minutes!")
    }
    
    var image: Image? {
        Image(systemName: "star.circle.fill")
    }
    
    // Rules to control when tip should appear
    var rules: [Rule] {
        [
            // Only show if user hasn't completed onboarding
            #Rule(Self.$hasCompletedOnboarding) { $0 == false }
        ]
    }
    
    // State to track if onboarding is completed
    @Parameter
    static var hasCompletedOnboarding: Bool = false
}

