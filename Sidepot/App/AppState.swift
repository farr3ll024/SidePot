import Foundation
import Observation

enum RootTab: String, CaseIterable {
    case home
    case history
    case standings
    case settings
}

/// UI-level app state — navigation and onboarding progress. Domain state (players, rounds,
/// games) lives in SwiftData; this only tracks things the interface itself needs to remember.
@Observable
final class AppState {
    var hasCompletedOnboarding: Bool
    var selectedTab: RootTab = .home

    init(hasCompletedOnboarding: Bool = UserDefaults.standard.bool(forKey: Keys.hasCompletedOnboarding)) {
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: Keys.hasCompletedOnboarding)
    }

    private enum Keys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
    }
}
