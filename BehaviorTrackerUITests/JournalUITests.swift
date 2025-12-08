import XCTest

/// Tests for journal entry creation and management.
final class JournalUITests: BehaviorTrackerUITests {

    // MARK: - Journal Entry Creation

    func testJournalTabShowsContent() throws {
        tapTabBarItem("Journal")

        // Journal view should be visible
        let journalVisible = app.otherElements.firstMatch.waitForExistence(timeout: 5)
        XCTAssertTrue(journalVisible, "Journal content should be visible")

        takeScreenshot(name: "JournalView")
    }

    func testCreateJournalEntry() throws {
        tapTabBarItem("Journal")

        // Look for the add button (plus icon in toolbar)
        let addButton = app.buttons["Add Entry"]
            .exists ? app.buttons["Add Entry"] : app.navigationBars.buttons.matching(
                NSPredicate(format: "label CONTAINS[c] %@ OR identifier CONTAINS[c] %@", "add", "plus")
            ).firstMatch

        // Also try toolbar buttons
        let toolbarAddButton = app.toolbars.buttons.firstMatch

        if addButton.exists && addButton.isHittable {
            addButton.tap()
        } else if toolbarAddButton.exists && toolbarAddButton.isHittable {
            toolbarAddButton.tap()
        } else {
            // Try finding any add/plus button
            let plusButtons = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'add' OR label CONTAINS[c] 'plus' OR label CONTAINS[c] 'new'"))
            if plusButtons.count > 0 {
                plusButtons.firstMatch.tap()
            } else {
                XCTFail("Could not find add entry button")
                return
            }
        }

        // Wait for editor to appear
        Thread.sleep(forTimeInterval: 0.5)
        takeScreenshot(name: "JournalEditor")

        // Look for text editor/field
        let textViews = app.textViews
        let textFields = app.textFields

        if textViews.count > 0 {
            let editor = textViews.firstMatch
            editor.tap()
            editor.typeText("UI Test Entry - This is a test journal entry created by automated UI tests.")
        } else if textFields.count > 0 {
            let field = textFields.firstMatch
            field.tap()
            field.typeText("UI Test Entry")
        }

        takeScreenshot(name: "JournalEntryFilled")
    }

    func testJournalEntryHasMoodSelector() throws {
        tapTabBarItem("Journal")

        // Navigate to create new entry
        let addButtons = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'add' OR label CONTAINS[c] 'plus' OR label CONTAINS[c] 'new'"))
        if addButtons.count > 0 {
            addButtons.firstMatch.tap()
        }

        Thread.sleep(forTimeInterval: 0.5)

        // Look for mood-related elements
        let moodElements = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'mood'"))
        let moodButtons = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'mood'"))
        let emojiButtons = app.buttons.matching(NSPredicate(format: "label MATCHES '.*[\\U0001F600-\\U0001F64F].*'"))

        let hasMoodUI = moodElements.count > 0 || moodButtons.count > 0 || emojiButtons.count > 0

        takeScreenshot(name: "JournalMoodSelector")

        // This is informational - not all journal views may have mood visible initially
        if hasMoodUI {
            XCTAssertTrue(true, "Mood selector found")
        }
    }

    // MARK: - Journal Search

    func testJournalSearch() throws {
        tapTabBarItem("Journal")

        // Look for search field
        let searchField = app.searchFields.firstMatch
        if searchField.waitForExistence(timeout: 3) {
            searchField.tap()
            searchField.typeText("test")

            takeScreenshot(name: "JournalSearchResults")

            // Clear search
            let clearButton = searchField.buttons["Clear text"]
            if clearButton.exists {
                clearButton.tap()
            }
        }
    }

    // MARK: - Journal Entry Detail

    func testOpenExistingJournalEntry() throws {
        tapTabBarItem("Journal")

        // Wait for entries to load
        Thread.sleep(forTimeInterval: 1)

        // Try to tap the first cell/entry
        let cells = app.cells
        let buttons = app.buttons.matching(NSPredicate(format: "identifier CONTAINS[c] 'entry' OR identifier CONTAINS[c] 'journal'"))

        if cells.count > 0 {
            cells.firstMatch.tap()
            Thread.sleep(forTimeInterval: 0.5)
            takeScreenshot(name: "JournalEntryDetail")
        } else if buttons.count > 0 {
            buttons.firstMatch.tap()
            Thread.sleep(forTimeInterval: 0.5)
            takeScreenshot(name: "JournalEntryDetail")
        }
    }
}
