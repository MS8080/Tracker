# Behavior Tracker App - Current State & Architecture Overview

## Executive Summary

The Behavior Tracker is a complete, production-ready native iOS application (iOS 17.0+) designed to track autism spectrum behavioral patterns with comprehensive analytics. It follows clean MVVM architecture with no external dependencies, using only Apple frameworks (SwiftUI, Core Data, Charts).

**Key Statistics:**
- 41 Swift files (~4,500+ lines of code)
- 3 test files with unit test coverage
- 6 documentation files
- 0 external dependencies
- Privacy-first, local-only data storage

---

## 1. APP STRUCTURE & ARCHITECTURE

### Directory Organization

```
BehaviorTracker/
├── BehaviorTrackerApp.swift     (Main app entry point)
├── ContentView.swift            (Tab-based navigation container)
├── Models/                      (5 data models)
│   ├── PatternEntry+CoreDataClass.swift
│   ├── PatternCategory.swift
│   ├── PatternType.swift
│   ├── UserPreferences+CoreDataClass.swift
│   ├── Tag+CoreDataClass.swift
│   ├── Medication+CoreDataClass.swift
│   ├── MedicationLog+CoreDataClass.swift
│   └── MedicationFrequency.swift
├── Views/                       (Organized by feature)
│   ├── Logging/
│   │   ├── LoggingView.swift
│   │   ├── CategoryLoggingView.swift
│   │   └── PatternEntryFormView.swift
│   ├── Dashboard/
│   │   ├── DashboardView.swift
│   │   └── HistoryView.swift
│   ├── Reports/
│   │   └── ReportsView.swift
│   ├── Medications/
│   │   ├── MedicationView.swift
│   │   ├── AddMedicationView.swift
│   │   ├── LogMedicationView.swift
│   │   └── MedicationDetailView.swift
│   └── Settings/
│       ├── SettingsView.swift
│       └── ExportDataView.swift
├── ViewModels/                  (5 business logic managers)
│   ├── LoggingViewModel.swift
│   ├── DashboardViewModel.swift
│   ├── ReportsViewModel.swift
│   ├── HistoryViewModel.swift
│   ├── SettingsViewModel.swift
│   └── MedicationViewModel.swift
├── Services/                    (Data & business logic)
│   ├── DataController.swift
│   └── ReportGenerator.swift
├── Utilities/                   (Cross-cutting concerns)
│   ├── AccessibilityLabels.swift
│   ├── Accessibility+Extensions.swift
│   ├── HapticFeedback.swift
│   └── Date+Extensions.swift
└── Models/
    └── BehaviorTrackerModel.xcdatamodeld/
        └── BehaviorTracker.xcdatamodel/
            └── contents (Core Data schema)
```

### Architectural Pattern: MVVM

```
User Interaction (View)
    ↓
View (SwiftUI)
    ↓
ViewModel (Logic & State)
    ↓
Service Layer (DataController, ReportGenerator)
    ↓
Core Data
    ↓
Persistent Storage
```

**Key Design Principles:**
- **Separation of Concerns:** Views only handle UI, ViewModels handle logic, Services handle data
- **Unidirectional Data Flow:** Changes flow from Views -> ViewModels -> Services -> Data
- **Reactive Updates:** @Published properties in ViewModels trigger automatic View updates
- **Singleton Pattern:** DataController shared instance for centralized data management

---

## 2. CURRENT FEATURES & FUNCTIONALITY

### 2.1 Core Pattern Tracking

**9 Pattern Categories** with 37 specific pattern types:

1. **Behavioral** (4 types)
   - Repetitive Behavior, Hyperfocus Episode, Task Switching Difficulty, Special Interest Deep Dive

2. **Sensory** (5 types)
   - Sensory Overload, Sensory Seeking, Environmental Trigger, Eyeglass Tint Usage, Physical Discomfort

3. **Social/Communication** (4 types)
   - Social Interaction, Masking Episode, Communication Preference, Social Recovery Time

4. **Executive Function** (4 types)
   - Decision Fatigue, Time Blindness, Planning Challenge, Transition Difficulty

5. **Energy/Capacity** (4 types)
   - Energy Level, Burnout Warning, Rest/Recovery Period, Sleep Quality

6. **Emotional Regulation** (5 types)
   - Meltdown Trigger, Shutdown Episode, Anxiety Spike, Emotional Recovery Time, Overwhelm Indicator

7. **Routine/Structure** (3 types)
   - Routine Adherence, Flexibility Tolerance, Disruption Impact

8. **Physical** (3 types)
   - Movement Needs, Posture/Positioning, Stimming Type

9. **Contextual** (4 types)
   - Academic/Work Performance, Environmental Change, Bureaucratic Stress, Regulatory Activity

### 2.2 Tab-Based Navigation

1. **Dashboard Tab** (0)
   - Streak tracking with flame icon
   - Medication summary card
   - Today's summary (entries logged)
   - Recent entries section
   - Quick insights

2. **Logging Tab** (1)
   - Favorites section (quick access)
   - All categories grid view
   - Sheet-based category selection
   - Detailed pattern entry form with:
     - Intensity scale (1-5) for applicable patterns
     - Duration picker (hours/minutes)
     - Context notes
     - Specific details
     - Custom pattern names
     - Tagging system

3. **Medications Tab** (2)
   - Today's medications section
   - All medications list
   - Add medication functionality
   - Medication adherence tracking
   - Side effects logging
   - Effectiveness ratings
   - Mood and energy level tracking

4. **Reports Tab** (3)
   - Weekly report generation
     - Total entries & daily average
     - Most active day identification
     - Pattern frequency analysis
     - Category distribution (pie chart)
     - Energy trend visualization (line chart)
     - Common triggers list
     - Medication insights
   
   - Monthly report generation
     - Top patterns identification
     - Category trends over time
     - Correlation analysis
     - Best vs challenging days
     - Behavioral change insights
     - Medication effectiveness correlation

5. **Settings Tab** (4)
   - User preferences
   - Notification management & scheduling
   - Favorite patterns management
   - Data export (JSON/CSV)
   - Privacy information
   - App version info

### 2.3 Data Management Features

- **Full CRUD Operations:** Create, Read, Update, Delete pattern entries
- **Favorites System:** Mark patterns for quick access
- **Tagging:** Add custom tags to entries for organization
- **Search & Filter:** By date range, category, pattern type
- **Swipe-to-Delete:** Gesture-based entry removal
- **Streak Tracking:** Automatic consecutive logging day counter
- **User Preferences:** Persisted settings and notification times

### 2.4 Analytics & Insights

- **Weekly Reports:** 7-day analysis with trends
- **Monthly Reports:** 30-day patterns and correlations
- **Visualizations:**
  - Bar charts (pattern frequency)
  - Pie charts (category distribution)
  - Line graphs (energy trends over time)
  - Statistical summaries
- **Medication Correlation:** Track medication impact on patterns
- **Trend Analysis:** Identify behavioral changes and patterns

---

## 3. DATA MODELS & CORE DATA SCHEMA

### 3.1 Core Data Entities

**PatternEntry** (Main behavioral logging entity)
```
- id: UUID (Primary key)
- timestamp: Date (Auto-captured)
- category: String (PatternCategory enum)
- patternType: String (PatternType enum)
- intensity: Int16 (0-5 scale, optional)
- duration: Int32 (minutes, optional)
- contextNotes: String? (User notes about context)
- specificDetails: String? (Additional details)
- customPatternName: String? (User-defined pattern name)
- isFavorite: Bool (For quick access)
- tags: NSSet [Tag] (Many-to-many relationship)
```

**Medication** (Medication tracking entity)
```
- id: UUID (Primary key)
- name: String
- dosage: String?
- frequency: String (daily, twice_daily, as_needed, etc.)
- prescribedDate: Date
- isActive: Bool
- notes: String?
- logs: NSSet [MedicationLog] (One-to-many relationship)
```

**MedicationLog** (Medication adherence/effectiveness tracking)
```
- id: UUID (Primary key)
- timestamp: Date
- medication: Medication (Many-to-one relationship)
- taken: Bool (Was it taken?)
- effectiveness: Int16 (1-5 scale)
- mood: Int16 (1-5 scale)
- energyLevel: Int16 (1-5 scale)
- sideEffects: String?
- skippedReason: String?
- notes: String?
```

**UserPreferences** (User settings & state)
```
- id: UUID (Primary key)
- notificationEnabled: Bool
- notificationTime: Date?
- streakCount: Int32
- favoritePatternsString: String (CSV list of pattern types)
```

**Tag** (Custom tagging system)
```
- id: UUID (Primary key)
- name: String
- entries: NSSet [PatternEntry] (Many-to-many relationship)
```

### 3.2 Relationships

- **PatternEntry ↔ Tag:** Many-to-many (entries can have multiple tags)
- **Medication ↔ MedicationLog:** One-to-many (one medication has many logs)

---

## 4. VIEWS ORGANIZATION & NAVIGATION

### 4.1 View Hierarchy

```
BehaviorTrackerApp (Main App)
    ↓
ContentView (Tab Container)
    ├── DashboardView (Tab 0)
    │   └── HistoryView (Embedded)
    ├── LoggingView (Tab 1)
    │   └── CategoryLoggingView (Sheet Modal)
    │       └── PatternEntryFormView (Embedded)
    ├── MedicationView (Tab 2)
    │   ├── AddMedicationView (Sheet Modal)
    │   ├── LogMedicationView (Sheet Modal)
    │   └── MedicationDetailView (Navigation Link)
    ├── ReportsView (Tab 3)
    │   └── (Embedded chart views)
    └── SettingsView (Tab 4)
        └── ExportDataView (Navigation Link)
```

### 4.2 Navigation Patterns

1. **Tab Navigation:** Primary navigation via TabView in ContentView
2. **Sheet Modals:** For overlays (logging, adding medication)
3. **NavigationStack:** For hierarchical detail views
4. **NavigationLink:** For linking to settings and detail screens

### 4.3 Key View Components

**DashboardView**
- Displays streak information
- Shows today's medication summary
- Lists recent entries
- Provides quick insights
- Loads data on appearance

**LoggingView**
- Grid-based category selection
- Favorites section for frequently logged patterns
- LazyVGrid for responsive layout

**CategoryLoggingView**
- Shows patterns for selected category
- Handles pattern selection
- Passes control to form view

**PatternEntryFormView**
- Conditional intensity slider (for applicable patterns)
- Conditional duration picker (for applicable patterns)
- Context notes text input
- Specific details text input
- Custom pattern name input
- Submit/save functionality

**ReportsView**
- Toggle between weekly and monthly views
- Chart visualizations using Swift Charts framework
- Statistical data display
- Selectable timeframe picker

**MedicationView**
- Today's medications with adherence tracking
- List of all medications
- Add/edit/delete functionality
- Medication detail view with history

**SettingsView**
- Toggle notifications
- Manage favorite patterns
- View privacy information
- Export data (JSON/CSV)

---

## 5. ACCESSIBILITY FEATURES IMPLEMENTED

### 5.1 VoiceOver Support

**AccessibilityLabels.swift** provides semantic labels for:
- Tab items
- Buttons (category buttons, quick log buttons)
- Sliders (intensity level)
- Pickers (duration)
- Charts (pattern frequency)
- Controls (delete, favorite toggles)

**Accessibility Hints** for:
- Category buttons: "Double tap to see specific patterns in this category"
- Quick log: "Double tap to quickly log this pattern with default values"
- Favorite toggle: "Add to favorites for quick access on the logging screen"
- Delete entry: "Swipe left to delete this entry"

### 5.2 Dynamic Type Support

- `dynamicTypeSize()` extension for scalable text
- Flexible layouts that adapt to text size
- Text scaling from small to xxxLarge

### 5.3 Visual Accessibility

- Color-coded category icons (each category has unique color)
- High contrast SF Symbols
- Color not the only indicator (icons + colors)
- Reduced motion support through SwiftUI defaults
- Dark mode and light mode support

### 5.4 Accessibility Traits

- Statistical cards marked as trait information
- Chart elements identified as charts
- Semantic view grouping

### 5.5 Accessibility Utilities

```swift
// Custom helper for adding labels and hints
extension View {
    func accessibilityElement(
        label: String,
        hint: String? = nil,
        traits: [String] = []
    ) -> some View
}

// Optional hint modifier (only applies if hint exists)
struct OptionalAccessibilityHint: ViewModifier
```

---

## 6. SERVICES LAYER

### 6.1 DataController (Singleton)

**Responsibilities:**
- Initialize Core Data stack
- Manage persistent container
- Provide CRUD operations
- Handle context saving
- Support in-memory testing

**Key Methods:**
```swift
- save()
- createPatternEntry(patternType, intensity, duration, notes, details)
- deletePatternEntry(_ entry)
- fetchPatternEntries(startDate, endDate)
- getUserPreferences()
- updateStreak()
- createMedication(...)
- logMedication(...)
```

**Design Pattern:**
- Singleton (DataController.shared)
- Lightweight migrations enabled
- Parent-child context merging
- Property object trump merge policy

### 6.2 ReportGenerator

**Responsibilities:**
- Generate weekly reports
- Generate monthly reports
- Analyze patterns and correlations
- Calculate statistics

**Report Structures:**
- `WeeklyReport` - 7-day analysis
- `MonthlyReport` - 30-day analysis
- `DataPoint` - Time-series data for charts
- `MedicationInsight` - Medication correlation data

**Calculations:**
- Pattern frequency
- Category distribution
- Energy trends
- Trigger analysis
- Medication adherence rates
- Correlation detection

---

## 7. VIEW MODELS

### 7.1 LoggingViewModel

**Published Properties:**
- `favoritePatterns: [String]`

**Methods:**
- `quickLog(patternType: PatternType)`
- Favorite pattern management

**Responsibilities:**
- Manage pattern logging
- Handle quick logging
- Manage favorite patterns

### 7.2 DashboardViewModel

**Published Properties:**
- `streakCount: Int32`
- `todayEntryCount: Int`
- `recentEntries: [PatternEntry]`
- `todayStats: DashboardStats`

**Methods:**
- `loadData()` - Fetch dashboard data
- Streak calculation
- Recent entries aggregation

### 7.3 HistoryViewModel

**Published Properties:**
- `filteredEntries: [PatternEntry]`
- `selectedCategory: PatternCategory?`

**Methods:**
- `loadEntries()`
- `deleteEntry(_ entry)`
- `filterByCategory(_ category)`
- `filterByDateRange(start, end)`

### 7.4 ReportsViewModel

**Published Properties:**
- `selectedTimeframe: ReportTimeframe`
- `weeklyReport: WeeklyReport?`
- `monthlyReport: MonthlyReport?`

**Methods:**
- `generateWeeklyReport()`
- `generateMonthlyReport()`
- Report data provisioning

### 7.5 SettingsViewModel

**Published Properties:**
- `notificationEnabled: Bool`
- `notificationTime: Date?`
- `favoritePatterns: [String]`

**Methods:**
- `savePreferences()`
- `exportToJSON()` -> Data
- `exportToCSV()` -> Data
- `toggleFavorite(_ pattern)`
- `updateNotificationTime(_ time)`

### 7.6 MedicationViewModel

**Published Properties:**
- `medications: [Medication]`
- `todaysLogs: [MedicationLog]`
- `selectedMedication: Medication?`

**Methods:**
- `addMedication(...)`
- `updateMedication(...)`
- `deleteMedication(...)`
- `logMedicationTaken(...)`
- `loadMedications()`
- `loadTodaysLogs()`

---

## 8. UTILITIES & EXTENSIONS

### 8.1 AccessibilityLabels.swift

Centralized repository of VoiceOver labels and hints for all UI elements.

### 8.2 Accessibility+Extensions.swift

Helper extensions for applying accessibility labels and hints:
```swift
extension View {
    func accessibilityLabel(_ label: String, hint: String?) -> some View
}

extension Text {
    func dynamicTypeSize() -> some View  // Supports accessibility scaling
}
```

### 8.3 HapticFeedback.swift

Haptic feedback system:
```swift
enum HapticFeedback {
    case light, medium, heavy
    case success, warning, error
    case selection
    
    func trigger()
}

struct HapticButton<Label: View>: View {
    // Pre-built button with haptic feedback
}
```

### 8.4 Date+Extensions.swift

Date formatting and calculation helpers for reports and displays.

---

## 9. TESTING INFRASTRUCTURE

### Test Files (3)

1. **DataControllerTests.swift**
   - CRUD operation testing
   - In-memory store testing
   - Save/load functionality

2. **PatternTypeTests.swift**
   - Pattern type validation
   - Category mapping
   - Intensity/duration flags

3. **ReportGeneratorTests.swift**
   - Weekly report generation
   - Monthly report generation
   - Calculation accuracy

### Testing Strategy

- **In-memory Core Data store** for isolated tests
- **Mocked data** for predictable test scenarios
- **No external dependencies** to test
- **Core business logic coverage**

---

## 10. EXISTING ACCESSIBILITY IMPLEMENTATION SUMMARY

### What's Already Implemented

[x] **VoiceOver Labels**
- All buttons have semantic labels
- Tab items are labeled
- Chart elements described
- Controls have hints

[x] **Dynamic Type Support**
- Text can scale
- Flexible layouts
- Responsive to accessibility settings

[x] **Visual Accessibility**
- Color-coded categories with icons
- High contrast SF Symbols
- Dark/light mode support

[x] **Semantic Structure**
- Proper view hierarchy
- Related elements grouped
- Hints provided for gestures

### What's NOT Yet Implemented

[Not Implemented] **Text-to-Speech for Notes**
- No current audio readback of journal/note entries
- Great opportunity for accessibility enhancement

[Not Implemented] **Widgets**
- No home screen or lock screen widgets
- Dashboard summary widget would be useful
- Medication reminder widget possible

[Not Implemented] **Notes/Journal Functionality**
- Pattern entries have limited text (context notes, specific details)
- No dedicated journal or daily notes feature
- No rich text editing

---

## 11. CURRENT STATE & READINESS

### What's Complete & Production-Ready

[x] Full pattern tracking system (37 patterns)
[x] Medication tracking and logging
[x] Analytics and reporting
[x] Data export (JSON/CSV)
[x] Settings and preferences
[x] Accessibility labels and hints
[x] Haptic feedback
[x] Core Data persistence
[x] MVVM architecture
[x] Unit tests
[x] Comprehensive documentation

### What Needs Implementation for Enhanced Features

1. **Widgets**
   - Dashboard widget (shows streak, today's count)
   - Medication reminder widget
   - Quick log widget

2. **Notes/Journal**
   - Dedicated journal model in Core Data
   - Journal entry creation UI
   - Journal list view
   - Rich text editing (optional)
   - Journal search and filtering

3. **Text-to-Speech**
   - AVFoundation AVSpeechSynthesizer integration
   - Read aloud buttons for notes
   - Adjustable speech rate
   - Voice selection (male/female)

4. **Enhanced Accessibility**
   - Additional accessibility announcements
   - Screen reader optimizations for charts
   - Voice control compatibility
   - Braille support information

---

## 12. INTEGRATION POINTS FOR NEW FEATURES

### For Adding Widgets

1. **WidgetKit Framework**
   - Create widget extension target
   - Share Core Data between app and widget
   - Use App Groups for data access

2. **Required Changes:**
   - Add app group identifier to signing
   - Configure Core Data for App Groups
   - Create widget views

3. **Possible Widgets:**
   - Dashboard glance (3 statistics)
   - Medication reminder (due medications)
   - Quick log buttons (top 5 patterns)
   - Streak display

### For Adding Notes/Journal

1. **New Core Data Entity:**
   ```swift
   @objc(JournalEntry)
   public class JournalEntry: NSManagedObject {
       @NSManaged public var id: UUID
       @NSManaged public var timestamp: Date
       @NSManaged public var title: String
       @NSManaged public var content: String
       @NSManaged public var patternEntries: NSSet? // Relationship
       @NSManaged public var tags: NSSet?
   }
   ```

2. **New Views:**
   - JournalListView (in Dashboard)
   - JournalEntryDetailView
   - JournalCreateEditView
   - JournalSearchView

3. **New ViewModel:**
   - JournalViewModel (CRUD operations)

4. **Integration Points:**
   - Link journal entries to pattern entries
   - Add journal tab or section
   - Include journal insights in reports

### For Adding Text-to-Speech

1. **Framework:** AVFoundation (already available)
2. **Components:**
   - SpeechSynthesisManager (service)
   - "Read Aloud" button (view component)
   - Speech settings (rate, pitch, voice)
3. **Integration:**
   - Add to journal entries
   - Add to pattern entry notes
   - Add to report summaries

---

## 13. KEY FILES FOR EXTENSION

### Must Modify

**Core Data Model:**
- `/Users/ms/Tracker/BehaviorTrackerApp/BehaviorTracker/Models/BehaviorTrackerModel.xcdatamodeld/`
  - Add new entities for journal, widget data

**DataController:**
- `/Users/ms/Tracker/BehaviorTrackerApp/BehaviorTracker/Services/DataController.swift`
  - Add CRUD methods for new entities
  - Add App Group support for widgets

**ContentView:**
- `/Users/ms/Tracker/BehaviorTrackerApp/BehaviorTracker/ContentView.swift`
  - May add new tab or reorganize navigation

### Create New Files

**For Widgets:**
- `JournalWidget.swift` (new target)
- `WidgetKitSupport.swift` (shared utilities)

**For Journal:**
- `JournalEntry+CoreDataClass.swift` (model)
- `JournalViewModel.swift` (business logic)
- `JournalListView.swift` (UI)
- `JournalDetailView.swift` (UI)
- `JournalCreateView.swift` (UI)

**For Text-to-Speech:**
- `SpeechSynthesisManager.swift` (service)
- `SpeechControlButton.swift` (UI component)
- `SpeechSettingsView.swift` (settings)

---

## 14. DEVELOPMENT RECOMMENDATIONS

### Priority Order for Feature Addition

1. **Notes/Journal (Foundation)** - Required for text-to-speech
2. **Text-to-Speech (Enhancement)** - Improves accessibility
3. **Widgets (Polish)** - Improves user engagement

### Implementation Strategy

1. Start with Journal model and basic CRUD
2. Create simple journal views
3. Add text-to-speech to journal reading
4. Create widgets using shared data
5. Add widget-specific UI optimizations

### Testing Approach

1. Extend existing test files
2. Add journal CRUD tests
3. Test speech synthesis configuration
4. Test widget data sharing
5. Test accessibility of new features

---

## 15. SUMMARY TABLE

| Aspect | Status | Details |
|--------|--------|---------|
| **Architecture** | Complete | MVVM with clean separation |
| **Core Features** | Complete | 37 patterns, medications, analytics |
| **UI/UX** | Complete | Tab-based, modern design |
| **Data Persistence** | Complete | Core Data with full CRUD |
| **Accessibility** | Partial | VoiceOver, Dynamic Type, no TTS |
| **Analytics** | Complete | Weekly/monthly reports |
| **Testing** | Partial | Core logic covered |
| **Documentation** | Excellent | 6 docs + inline comments |
| **Widgets** | Not Started | WidgetKit ready to add |
| **Journal** | Not Started | Easy to add as new entity |
| **Text-to-Speech** | Not Started | AVFoundation available |

---

## READY FOR ENHANCEMENT

The app is **architecturally sound** and **ready for feature expansion**. The MVVM pattern makes it easy to add:
- New data models (Journal entries)
- New view controllers (Journal UI, Widget UI)
- New services (Speech synthesis)
- New viewmodels (JournalViewModel)

All without disrupting existing functionality.

