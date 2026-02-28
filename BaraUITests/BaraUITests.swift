import XCTest

final class BaraUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testOnboardingAppearsOnFreshLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.buttons["Get Started"].waitForExistence(timeout: 3) || app.staticTexts["Meet Bara"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testTabsRenderWhenSkippingOnboarding() throws {
        let app = XCUIApplication()
        app.launchArguments.append("UITEST_SKIP_ONBOARDING")
        app.launch()

        XCTAssertTrue(app.tabBars.buttons["Dashboard"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.tabBars.buttons["Stats"].exists)
        XCTAssertTrue(app.tabBars.buttons["Settings"].exists)

        app.tabBars.buttons["Stats"].tap()
        XCTAssertTrue(app.navigationBars["Stats"].waitForExistence(timeout: 3))
    }
}
