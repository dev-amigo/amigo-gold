import Foundation
import TipKit

/// Tip to help first-time users understand the onboarding steps
struct OnboardingTip: Tip {
    var title: Text {
        Text("Complete Setup to Start")
    }
    
    var message: Text? {
        Text("Tap above to see your checklist. Deposit, swap to gold, and borrow!")
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

