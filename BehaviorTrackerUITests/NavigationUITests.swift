import XCTest

/// Tests for main navigation and tab bar functionality.
final class NavigationUITests: BehaviorTrackerUITests {

    // MARK: - Tab Bar Navigation

    func testTabBarExists() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(waitForElement(tabBar), "Tab bar should be visible")
    }

    func testNavigateToHomeTab() throws {
        tapTabBarItem("Home")

        // Verify we're on the home screen
        let homeTitle = app.navigationBars["Home"]
        XCTAssertTrue(waitForElement(homeTitle), "Home navigation title should be visible")
    }

    func testNavigateToJournalTab() throws {
        tapTabBarItem("Journal")

        // Verify we're on the journal screen
        // The journal might show "Journal" or a date-based title
        let journalExists = app.staticTexts["Journal"].waitForExistence(timeout: 3)
            || app.navigationBars.element.waitForExistence(timeout: 3)
        XCTAssertTrue(journalExists, "Journal screen should be visible")
    }

    func testNavigateToCalendarTab() throws {
        tapTabBarItem("Calendar")

        // Verify we're on the calendar screen
        let calendarView = app.otherElements["CalendarView"]
        let monthPicker = app.buttons.matching(identifier: "monthNavigationButton").firstMatch
        let calendarExists = calendarView.waitForExistence(timeout: 3)
            || monthPicker.waitForExistence(timeout: 3)
            || app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "2025")).firstMatch.waitForExistence(timeout: 3)
        XCTAssertTrue(calendarExists, "Calendar screen should be visible")
    }

    func testNavigateToReportsTab() throws {
        tapTabBarItem("Reports")

        // Verify we're on the reports screen
        let reportsTitle = app.navigationBars["Reports"]
        let reportsExists = reportsTitle.waitForExistence(timeout: 3)
            || app.staticTexts["Reports"].waitForExistence(timeout: 3)
        XCTAssertTrue(reportsExists, "Reports screen should be visible")
    }

    func testNavigateThroughAllTabs() throws {
        let tabs = ["Home", "Journal", "Calendar", "Reports"]

        for tab in tabs {
            tapTabBarItem(tab)
            // Small delay to allow transition
            Thread.sleep(forTimeInterval: 0.5)
            takeScreenshot(name: "\(tab)Tab")
        }
    }

    // MARK: - Back Navigation

    func testBackNavigationInJournal() throws {
        tapTabBarItem("Journal")

        // If there's a detail view, test back navigation
        let cells = app.cells
        if cells.count > 0 {
            cells.firstMatch.tap()

            // Wait for detail view
            Thread.sleep(forTimeInterval: 0.5)

            // Try to navigate back
            let backButton = app.navigationBars.buttons.element(boundBy: 0)
            if backButton.exists && backButton.isHittable {
                backButton.tap()
            }
        }
    }
}
