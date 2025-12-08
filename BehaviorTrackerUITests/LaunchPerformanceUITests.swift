import XCTest

/// Performance tests for app launch and critical interactions.
final class LaunchPerformanceUITests: BehaviorTrackerUITests {

    // MARK: - Launch Performance

    func testLaunchPerformance() throws {
        // Measure how long it takes to launch
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    func testLaunchToInteractivePerformance() throws {
        // Measure time from launch until UI is interactive
        let app = XCUIApplication()

        measure(metrics: [XCTApplicationLaunchMetric(waitUntilResponsive: true)]) {
            app.launch()
            // Wait for first interactive element
            _ = app.tabBars.firstMatch.waitForExistence(timeout: 10)
        }
    }

    // MARK: - Navigation Performance

    func testTabSwitchingPerformance() throws {
        let tabs = ["Home", "Journal", "Calendar", "Reports"]

        measure {
            for tab in tabs {
                tapTabBarItem(tab)
            }
        }
    }

    // MARK: - Scroll Performance

    func testJournalScrollPerformance() throws {
        tapTabBarItem("Journal")

        // Wait for content to load
        Thread.sleep(forTimeInterval: 1)

        measure {
            // Perform scroll operations
            app.swipeUp()
            app.swipeUp()
            app.swipeDown()
            app.swipeDown()
        }
    }

    func testCalendarScrollPerformance() throws {
        tapTabBarItem("Calendar")

        // Wait for calendar to load
        Thread.sleep(forTimeInterval: 1)

        measure {
            // Swipe through months
            app.swipeLeft()
            app.swipeLeft()
            app.swipeRight()
            app.swipeRight()
        }
    }
}
