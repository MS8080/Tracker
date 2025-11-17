# Quick Reference Guide - App Structure

## File Locations Quick Guide

### Core App Entry
- **App Launch**: `/BehaviorTracker/BehaviorTrackerApp.swift`
- **Main Navigation**: `/BehaviorTracker/ContentView.swift` (5 tabs)

### Models (Core Data Entities)
| File | Purpose |
|------|---------|
| `PatternEntry+CoreDataClass.swift` | Behavioral pattern log entries |
| `Medication+CoreDataClass.swift` | Medication information |
| `MedicationLog+CoreDataClass.swift` | Medication adherence tracking |
| `UserPreferences+CoreDataClass.swift` | User settings |
| `Tag+CoreDataClass.swift` | Custom entry tags |
| `PatternCategory.swift` | 9 behavioral categories |
| `PatternType.swift` | 37 specific pattern types |

### Views by Tab
| Tab | Files | Purpose |
|-----|-------|---------|
| 0: Dashboard | `DashboardView.swift`, `HistoryView.swift` | Streak, stats, recent entries |
| 1: Logging | `LoggingView.swift`, `CategoryLoggingView.swift`, `PatternEntryFormView.swift` | Log patterns |
| 2: Medications | `MedicationView.swift`, `AddMedicationView.swift`, `LogMedicationView.swift`, `MedicationDetailView.swift` | Medication tracking |
| 3: Reports | `ReportsView.swift` | Weekly/monthly analytics |
| 4: Settings | `SettingsView.swift`, `ExportDataView.swift` | Preferences & export |

### ViewModels (Business Logic)
| File | Manages |
|------|---------|
| `LoggingViewModel.swift` | Pattern logging & favorites |
| `DashboardViewModel.swift` | Dashboard stats & streak |
| `HistoryViewModel.swift` | Entry history & filtering |
| `ReportsViewModel.swift` | Report generation |
| `SettingsViewModel.swift` | Settings & export |
| `MedicationViewModel.swift` | Medication CRUD |

### Services (Data & Logic)
| File | Purpose |
|------|---------|
| `DataController.swift` | Core Data management (singleton) |
| `ReportGenerator.swift` | Analytics calculations |

### Utilities
| File | Purpose |
|------|---------|
| `AccessibilityLabels.swift` | VoiceOver label repository |
| `Accessibility+Extensions.swift` | Accessibility helpers |
| `HapticFeedback.swift` | Haptic feedback system |
| `Date+Extensions.swift` | Date utilities |

---

## Core Data Schema

```
PatternEntry
├── id: UUID
├── timestamp: Date
├── category: String (PatternCategory)
├── patternType: String (PatternType)
├── intensity: Int16 (0-5)
├── duration: Int32 (minutes)
├── contextNotes: String?
├── specificDetails: String?
├── customPatternName: String?
├── isFavorite: Bool
└── tags: NSSet [Tag] ←-> many-to-many

Medication
├── id: UUID
├── name: String
├── dosage: String?
├── frequency: String
├── prescribedDate: Date
├── isActive: Bool
├── notes: String?
└── logs: NSSet [MedicationLog] ←-> one-to-many

MedicationLog
├── id: UUID
├── timestamp: Date
├── medication: Medication ←-> many-to-one
├── taken: Bool
├── effectiveness: Int16
├── mood: Int16
├── energyLevel: Int16
├── sideEffects: String?
├── skippedReason: String?
└── notes: String?

UserPreferences
├── id: UUID
├── notificationEnabled: Bool
├── notificationTime: Date?
├── streakCount: Int32
└── favoritePatternsString: String

Tag
├── id: UUID
├── name: String
└── entries: NSSet [PatternEntry] ←-> many-to-many
```

---

## Data Flow Architecture

### Logging Pattern Flow
```
1. User selects category in LoggingView
2. CategoryLoggingView presents patterns
3. User selects pattern -> PatternEntryFormView opens
4. User fills form (intensity, duration, notes)
5. Form submits -> LoggingViewModel.createEntry()
6. ViewModel calls DataController.createPatternEntry()
7. DataController creates PatternEntry in Core Data
8. Context saves -> Published properties update
9. Views refresh automatically
```

### Report Generation Flow
```
1. User opens ReportsView
2. ViewModel calls ReportGenerator.generateWeeklyReport()
3. ReportGenerator queries DataController for entries
4. Calculations performed (frequency, trends, etc.)
5. WeeklyReport struct populated
6. @Published report property updated
7. Charts render with data
```

---

## Accessibility Features

### Already Implemented
- VoiceOver labels via AccessibilityLabels.swift
- Accessibility hints on interactive elements
- Dynamic Type support with scalable text
- Color-coded categories (blue, purple, green, etc.)
- High-contrast SF Symbols
- Dark/light mode support
- Semantic view structure

### To Add
- Text-to-speech for notes/journal
- Journal/notes functionality
- Widgets (home screen, lock screen)

---

## Testing Files

| File | Tests |
|------|-------|
| `DataControllerTests.swift` | CRUD operations |
| `PatternTypeTests.swift` | Pattern validation |
| `ReportGeneratorTests.swift` | Report calculations |

**Testing Approach**: In-memory Core Data store, no external dependencies

---

## Key Code Patterns

### Creating a Pattern Entry
```swift
let entry = dataController.createPatternEntry(
    patternType: .hyperfocusEpisode,
    intensity: 4,
    duration: 120,
    contextNotes: "Worked on coding project",
    specificDetails: nil
)
```

### Fetching Entries
```swift
let entries = dataController.fetchPatternEntries(
    startDate: weekAgo,
    endDate: Date()
)
```

### Accessing ViewModel Data
```swift
@StateObject private var viewModel = DashboardViewModel()

// In body:
Text("\(viewModel.streakCount) Day Streak")
```

### Adding Accessibility
```swift
Button("Log Pattern") {
    // action
}
.accessibilityLabel("Log \(pattern.rawValue)")
.accessibilityHint("Double tap to log this pattern with default values")
```

---

## Important Constants

| Category | Count |
|----------|-------|
| Pattern Categories | 9 |
| Pattern Types | 37 |
| App Tabs | 5 (Dashboard, Log, Medications, Reports, Settings) |
| Core Data Entities | 5 |

---

## Common Tasks

### Add a New Tab
1. Create new View file in `Views/` subfolder
2. Create new ViewModel if needed
3. Add NavigationStack wrapper
4. Add to ContentView TabView
5. Add accessibility label

### Add a New Pattern Type
1. Add case to `PatternType` enum in `PatternType.swift`
2. Add to appropriate category in `category` computed property
3. Set `hasIntensityScale` and `hasDuration` flags if needed
4. Pattern automatically appears in UI (no UI changes needed!)

### Add Medication Functionality
1. Use `MedicationViewModel` (already exists)
2. Call methods like `addMedication()`, `logMedicationTaken()`
3. Views automatically update via @Published properties

### Implement Feature with Accessibility
1. Define label in `AccessibilityLabels.swift`
2. Apply using `.accessibilityLabel()` and `.accessibilityHint()`
3. Test with VoiceOver enabled
4. Verify with Dynamic Type settings

---

## Performance Tips

1. **Fetch Requests**: Use predicates for filtering at DB level
2. **View Updates**: Minimize @Published updates
3. **Lazy Loading**: Use LazyVStack/LazyVGrid for large lists
4. **Memory**: No external dependencies = minimal memory footprint

---

## Privacy & Security

- [x] Local-only storage (no cloud sync)
- [x] No analytics collection
- [x] No network requests
- [x] No third-party SDKs
- [x] User-controlled data export
- [x] Optional iCloud sync not implemented

---

## Debugging Commands

View all entries:
```swift
let request = NSFetchRequest<PatternEntry>(entityName: "PatternEntry")
let entries = try? dataController.container.viewContext.fetch(request)
```

Delete all data (for testing):
```swift
let request = NSFetchRequest<NSFetchRequestExpression>(entityName: "PatternEntry")
let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
try? dataController.container.viewContext.execute(deleteRequest)
```

---

## Key Framework Usage

| Framework | Purpose | Usage |
|-----------|---------|-------|
| SwiftUI | UI | All views |
| Core Data | Persistence | DataController, all models |
| Charts | Visualization | ReportsView |
| UserNotifications | Reminders | Settings (future) |
| AVFoundation | Speech (future) | Will be used for TTS |

---

## File Statistics

- **Total Swift Files**: 41
- **Total Lines of Code**: ~4,500+
- **Models**: 8 files
- **Views**: 15+ files (organized by feature)
- **ViewModels**: 6 files
- **Services**: 2 files
- **Utilities**: 4 files
- **Tests**: 3 files
- **Documentation**: 6+ files

