import XCTest

/// Base class for UI tests with common setup and helper methods.
class BehaviorTrackerUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Helper Methods

    /// Wait for an element to exist with a timeout
    func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        return element.waitForExistence(timeout: timeout)
    }

    /// Tap a tab bar item by name
    func tapTabBarItem(_ name: String) {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5), "Tab bar should exist")
        let item = tabBar.buttons[name]
        XCTAssertTrue(item.exists, "Tab bar item '\(name)' should exist")
        item.tap()
    }

    /// Dismiss any presented sheet by tapping "Done" or pulling down
    func dismissSheet() {
        let doneButton = app.buttons["Done"]
        if doneButton.exists {
            doneButton.tap()
        } else {
            // Try swiping down to dismiss
            app.swipeDown()
        }
    }

    /// Take a screenshot for debugging
    func takeScreenshot(name: String) {
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
