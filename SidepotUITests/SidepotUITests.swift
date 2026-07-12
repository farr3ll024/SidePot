import XCTest

/// Starting point for the UI test checklist in IMPLEMENTATION_SPEC.md §26 (complete onboarding,
/// create players, start a round, enter scores, finish and settle, relaunch and restore...).
/// Only the first step is implemented in this build; the rest are a Phase 6 follow-up once the
/// corresponding flows (§13's task list items 3-9) are built out.
@MainActor
final class SidepotUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testOnboardingShowsFirstLaunchContent() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-com.example.sidepot.UITesting", "1"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Track the game, not the GPS"].waitForExistence(timeout: 5))
    }
}
