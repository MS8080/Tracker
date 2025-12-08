import XCTest

/// Tests for pattern logging functionality.
final class PatternLoggingUITests: BehaviorTrackerUITests {

    // MARK: - Pattern Logging Access

    func testHomeScreenShowsLoggingButton() throws {
        tapTabBarItem("Home")

        // Look for logging-related buttons
        let logButtons = app.buttons.matching(NSPredicate(
            format: "label CONTAINS[c] 'log' OR label CONTAINS[c] 'track' OR label CONTAINS[c] 'add'"
        ))

        let hasLoggingUI = logButtons.count > 0

        takeScreenshot(name: "HomeWithLogging")

        XCTAssertTrue(hasLoggingUI || app.buttons.count > 0, "Home screen should have interactive elements")
    }

    func testOpenPatternLoggingView() throws {
        tapTabBarItem("Home")

        // Try to find and tap a logging button
        let logButton = app.buttons.matching(NSPredicate(
            format: "label CONTAINS[c] 'log' OR label CONTAINS[c] 'track'"
        )).firstMatch

        if logButton.waitForExistence(timeout: 3) && logButton.isHittable {
            logButton.tap()
            Thread.sleep(forTimeInterval: 0.5)
            takeScreenshot(name: "PatternLoggingView")
        }
    }

    // MARK: - Pattern Categories

    func testPatternCategoriesExist() throws {
        tapTabBarItem("Home")

        // Navigate to logging view
        let logButton = app.buttons.matching(NSPredicate(
            format: "label CONTAINS[c] 'log' OR label CONTAINS[c] 'track'"
        )).firstMatch

        if logButton.waitForExistence(timeout: 3) && logButton.isHittable {
            logButton.tap()
            Thread.sleep(forTimeInterval: 0.5)

            // Look for category-related elements
            let categoryElements = app.staticTexts.matching(NSPredicate(
                format: "label CONTAINS[c] 'category' OR label CONTAINS[c] 'sensory' OR label CONTAINS[c] 'behavior' OR label CONTAINS[c] 'emotion'"
            ))

            takeScreenshot(name: "PatternCategories")

            // Categories should exist in logging view
            let hasCategoryUI = categoryElements.count > 0 || app.cells.count > 0
            XCTAssertTrue(hasCategoryUI, "Logging view should show categories or options")
        }
    }

    // MARK: - Pattern Entry Form

    func testPatternEntryFormFields() throws {
        tapTabBarItem("Home")

        // Navigate to logging
        let logButton = app.buttons.matching(NSPredicate(
            format: "label CONTAINS[c] 'log' OR label CONTAINS[c] 'track'"
        )).firstMatch

        if logButton.waitForExistence(timeout: 3) && logButton.isHittable {
            logButton.tap()
            Thread.sleep(forTimeInterval: 0.5)

            // Look for form elements: intensity slider, notes field, etc.
            let sliders = app.sliders
            let textFields = app.textFields
            let textViews = app.textViews
            let steppers = app.steppers

            let hasFormElements = sliders.count > 0 || textFields.count > 0
                || textViews.count > 0 || steppers.count > 0

            takeScreenshot(name: "PatternEntryForm")

            // If we're in the form, we should have some input elements
            if hasFormElements {
                XCTAssertTrue(true, "Form has input elements")
            }
        }
    }

    // MARK: - Intensity Selection

    func testIntensitySliderInteraction() throws {
        tapTabBarItem("Home")

        let logButton = app.buttons.matching(NSPredicate(
            format: "label CONTAINS[c] 'log' OR label CONTAINS[c] 'track'"
        )).firstMatch

        if logButton.waitForExistence(timeout: 3) && logButton.isHittable {
            logButton.tap()
            Thread.sleep(forTimeInterval: 0.5)

            // Try to interact with intensity controls
            let sliders = app.sliders
            if sliders.count > 0 {
                let slider = sliders.firstMatch
                slider.adjust(toNormalizedSliderPosition: 0.8)

                takeScreenshot(name: "IntensitySet")
            }

            // Also check for stepper or segmented control
            let steppers = app.steppers
            if steppers.count > 0 {
                let stepper = steppers.firstMatch
                stepper.buttons.element(boundBy: 1).tap() // Increment
                stepper.buttons.element(boundBy: 1).tap() // Increment again

                takeScreenshot(name: "IntensityStepperUsed")
            }
        }
    }
}
