# Visual Architecture Diagrams

## App Structure Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    BehaviorTrackerApp                        │
│                  (App Entry Point)                           │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                    ContentView                               │
│           (Tab Navigation Container)                         │
└──────────────────────────┬──────────────────────────────────┘
        │        │        │       │        │
    ┌───▼─┐  ┌───▼─┐  ┌──▼──┐ ┌─▼──┐ ┌──▼──┐
    │  0  │  │  1  │  │  2  │ │ 3  │ │  4  │
    └────┬┘  └────┬┘  └──┬──┘ └┬───┘ └──┬──┘
    Dashboard Log Meds Reports Settings
```

## Tab Organization

```
┌──────────────────────────────────────────────────────────────────┐
│                        CONTENT VIEW                              │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────────┐│
│  │DASHBOARD │  │ LOGGING  │  │MEDICATION│  │    REPORTS       ││
│  │   (0)    │  │   (1)    │  │   (2)    │  │      (3)         ││
│  │          │  │          │  │          │  │                  ││
│  │ Streak   │  │Categories│  │ Today's  │  │Weekly Report     ││
│  │ Today's  │  │ Favorites│  │Meds List │  │ Pattern freq     ││
│  │ Summary  │  │ History  │  │ Add Med  │  │ Category dist    ││
│  │ Recent   │  │ Form     │  │ Log      │  │ Energy trends    ││
│  │          │  │          │  │ Detail   │  │Monthly Report    ││
│  │          │  │          │  │          │  │ Top patterns     ││
│  └──────────┘  └──────────┘  └──────────┘  │ Correlations     ││
│                                             └──────────────────┘│
│  ┌──────────────────────────────────────────────────────────┐   │
│  │               SETTINGS (4)                               │   │
│  │ Notifications │ Favorites │ Export │ Privacy │ About    │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

## Data Flow Architecture (MVVM)

```
┌─────────────────────────────────────────────────────────────┐
│                     USER INTERACTION                         │
│                   (Tap, Swipe, Type)                         │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                   VIEW LAYER (SwiftUI)                       │
│  • DashboardView    • LoggingView    • ReportsView          │
│  • MedicationView   • SettingsView   • HistoryView         │
└────────────────────────┬────────────────────────────────────┘
                         │ Calls methods on
                         ▼
┌─────────────────────────────────────────────────────────────┐
│               VIEWMODEL LAYER (@Observable)                  │
│  • LoggingViewModel    • DashboardViewModel                 │
│  • ReportsViewModel    • MedicationViewModel                │
│  • SettingsViewModel   • HistoryViewModel                   │
│                                                             │
│  Publishes state changes via @Published properties          │
└────────────────────────┬────────────────────────────────────┘
                         │ Calls methods on
                         ▼
┌─────────────────────────────────────────────────────────────┐
│               SERVICE LAYER (Business Logic)                │
│  • DataController   (Core Data management)                  │
│  • ReportGenerator  (Analytics calculations)                │
└────────────────────────┬────────────────────────────────────┘
                         │ Reads/writes to
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                  DATA LAYER (Core Data)                      │
│  • PatternEntry  • Medication   • MedicationLog             │
│  • UserPreferences • Tag                                     │
│                                                             │
│  Persisted to SQLite database on device                     │
└─────────────────────────────────────────────────────────────┘

↑                                                            ↓
└─────────────── Reverse Flow: Data Updates ────────────────┘
  (Published properties automatically update Views)
```

## Core Data Entity Relationships

```
┌─────────────────────┐         ┌────────────────┐
│  PatternEntry       │◄────────│     Tag        │
├─────────────────────┤ many-to-│────────────────┤
│ • id (UUID)         │  many   │ • id (UUID)    │
│ • timestamp         │         │ • name (String)│
│ • category          │         │                │
│ • patternType       │         └────────────────┘
│ • intensity         │
│ • duration          │
│ • contextNotes      │
│ • specificDetails   │
│ • customPatternName │
│ • isFavorite        │
│ • tags (-> NSSet)    │
└─────────────────────┘

┌──────────────┐       one-to-many    ┌─────────────────┐
│ Medication   │◄──────────────────────│  MedicationLog  │
├──────────────┤                       ├─────────────────┤
│ • id         │                       │ • id (UUID)     │
│ • name       │                       │ • timestamp     │
│ • dosage     │                       │ • medication_id │
│ • frequency  │                       │ • taken (Bool)  │
│ • isActive   │                       │ • effectiveness │
│ • notes      │                       │ • mood          │
│ • logs       │──────────────────────►│ • energyLevel   │
│              │                       │ • sideEffects   │
└──────────────┘                       │ • skippedReason │
                                       │ • notes         │
                                       └─────────────────┘

┌────────────────────────┐
│  UserPreferences       │
├────────────────────────┤
│ • id (UUID)            │
│ • notificationEnabled  │
│ • notificationTime     │
│ • streakCount          │
│ • favoritePatternsStr  │
└────────────────────────┘
```

## View Hierarchy

```
BehaviorTrackerApp
│
└── ContentView (TabView with 5 tabs)
    │
    ├── Tab 0: DashboardView
    │   │
    │   ├── streakCard
    │   ├── medicationSummaryCard
    │   ├── todaySummaryCard
    │   ├── recentEntriesSection
    │   │   └── ScrollView
    │   │       └── LazyVStack
    │   │           └── HistoryView (embedded)
    │   │               └── ForEach entries
    │   │                   └── EntryRow
    │   └── quickInsightsSection
    │
    ├── Tab 1: LoggingView
    │   ├── favoritesSection
    │   │   └── LazyVGrid
    │   │       └── ForEach favoritePatterns
    │   │           └── QuickLogButton
    │   │
    │   ├── allCategoriesView
    │   │   └── LazyVGrid
    │   │       └── ForEach categories
    │   │           └── CategoryButton
    │   │
    │   └── .sheet: CategoryLoggingView
    │       └── LazyVGrid patterns
    │           └── PatternButton
    │               └── NavigationLink: PatternEntryFormView
    │                   └── Form with:
    │                       ├── Slider (intensity)
    │                       ├── Picker (duration)
    │                       ├── TextField (notes)
    │                       ├── TextField (details)
    │                       └── Button (save)
    │
    ├── Tab 2: MedicationView
    │   ├── todaysMedicationsSection
    │   │   └── LazyVStack
    │   │       └── ForEach medications
    │   │
    │   ├── allMedicationsSection
    │   │   └── LazyVStack
    │   │       └── NavigationLink: MedicationDetailView
    │   │
    │   └── .sheet: AddMedicationView
    │       └── Form
    │
    ├── Tab 3: ReportsView
    │   ├── Picker (timeframe)
    │   ├── ScrollView
    │   │   └── VStack
    │   │       ├── Chart (BarChart for frequency)
    │   │       ├── Chart (PieChart for categories)
    │   │       ├── Chart (LineChart for energy)
    │   │       └── Text (statistics)
    │   │
    │   └── [Switches between weekly/monthly]
    │
    └── Tab 4: SettingsView
        ├── Section: Notifications
        │   ├── Toggle (enable)
        │   └── DatePicker (time)
        │
        ├── Section: Favorites
        │   └── List of patterns with toggles
        │
        ├── Section: Data
        │   └── NavigationLink: ExportDataView
        │       └── Buttons (JSON, CSV export)
        │
        ├── Section: Privacy
        │   └── Text (privacy policy)
        │
        └── Section: About
            └── Text (version, app info)
```

## ViewModel Dependency Graph

```
┌─────────────────────────────────────────────┐
│            LoggingViewModel                  │
│  • favoritePatterns: [String]                │
│  • quickLog(patternType)                     │
│  • addFavorite(pattern)                      │
│  • removeFavorite(pattern)                   │
└──────────────────┬──────────────────────────┘
                   │
           Uses DataController
                   │
                   ▼
        ┌──────────────────────┐
        │  DataController      │
        │  (Singleton)         │
        │                      │
        │  • save()            │
        │  • createEntry()     │
        │  • deleteEntry()     │
        │  • fetchEntries()    │
        │  • getUserPrefs()    │
        │  • createMed()       │
        │  • logMedication()   │
        └──────────┬───────────┘
                   │
                   ▼
        ┌──────────────────────┐
        │  Core Data Context   │
        │  (SQLite on Disk)    │
        └──────────────────────┘

Other ViewModels:
├── DashboardViewModel ──┐
├── HistoryViewModel    ─┼──-> DataController
├── ReportsViewModel    ─┤
├── SettingsViewModel   ─┤
└── MedicationViewModel ┘
```

## Pattern Tracking Categories (9 Total)

```
PATTERN CATEGORIES
═══════════════════════════════════════════════════════════

1. Behavioral (4 types)
   • Repetitive Behavior
   • Hyperfocus Episode
   • Task Switching Difficulty
   • Special Interest Deep Dive

2. Sensory (5 types)
   • Sensory Overload
   • Sensory Seeking
   • Environmental Trigger
   • Eyeglass Tint Usage
   • Physical Discomfort

3. Social/Communication (4 types)
   • Social Interaction
   • Masking Episode
   • Communication Preference
   • Social Recovery Time

4. Executive Function (4 types)
   • Decision Fatigue
   • Time Blindness
   • Planning Challenge
   • Transition Difficulty

5. Energy/Capacity (4 types)
   • Energy Level
   • Burnout Warning
   • Rest/Recovery Period
   • Sleep Quality

6. Emotional Regulation (5 types)
   • Meltdown Trigger
   • Shutdown Episode
   • Anxiety Spike
   • Emotional Recovery Time
   • Overwhelm Indicator

7. Routine/Structure (3 types)
   • Routine Adherence
   • Flexibility Tolerance
   • Disruption Impact

8. Physical (3 types)
   • Movement Needs
   • Posture/Positioning
   • Stimming Type

9. Contextual (4 types)
   • Academic/Work Performance
   • Environmental Change
   • Bureaucratic Stress
   • Regulatory Activity
```

## File Organization

```
BehaviorTracker/
│
├── BehaviorTrackerApp.swift         ← Entry point
├── ContentView.swift                ← Tab navigation
│
├── Models/                          ← Data entities
│   ├── PatternEntry+CoreDataClass.swift
│   ├── Medication+CoreDataClass.swift
│   ├── MedicationLog+CoreDataClass.swift
│   ├── UserPreferences+CoreDataClass.swift
│   ├── Tag+CoreDataClass.swift
│   ├── PatternCategory.swift
│   ├── PatternType.swift
│   ├── MedicationFrequency.swift
│   └── BehaviorTrackerModel.xcdatamodeld/
│       └── BehaviorTracker.xcdatamodel
│
├── Views/                           ← UI Components
│   ├── Dashboard/
│   │   ├── DashboardView.swift
│   │   └── HistoryView.swift
│   ├── Logging/
│   │   ├── LoggingView.swift
│   │   ├── CategoryLoggingView.swift
│   │   └── PatternEntryFormView.swift
│   ├── Medications/
│   │   ├── MedicationView.swift
│   │   ├── AddMedicationView.swift
│   │   ├── LogMedicationView.swift
│   │   └── MedicationDetailView.swift
│   ├── Reports/
│   │   └── ReportsView.swift
│   └── Settings/
│       ├── SettingsView.swift
│       └── ExportDataView.swift
│
├── ViewModels/                      ← Business Logic
│   ├── LoggingViewModel.swift
│   ├── DashboardViewModel.swift
│   ├── HistoryViewModel.swift
│   ├── ReportsViewModel.swift
│   ├── SettingsViewModel.swift
│   └── MedicationViewModel.swift
│
├── Services/                        ← Data Layer
│   ├── DataController.swift
│   └── ReportGenerator.swift
│
└── Utilities/                       ← Helpers
    ├── AccessibilityLabels.swift
    ├── Accessibility+Extensions.swift
    ├── HapticFeedback.swift
    └── Date+Extensions.swift
```

## Feature Enhancement Roadmap Visualization

```
CURRENT STATE ─────────► PHASE 1 ─────────► PHASE 2 ─────────► PHASE 3
(Production Ready)      (Journals)        (Text-to-Speech)   (Widgets)


Current:
├─ Pattern Tracking [x]
├─ Medications [x]
├─ Reports [x]
├─ Settings [x]
└─ Basic Accessibility [x]

                   Phase 1 (8-10 hrs):
                   ├─ JournalEntry Model
                   ├─ JournalListView
                   ├─ JournalDetailView
                   ├─ JournalCreateView
                   ├─ JournalViewModel
                   └─ Integration with patterns

                                    Phase 2 (6-8 hrs):
                                    ├─ SpeechSynthesisManager
                                    ├─ ReadAloudButton
                                    ├─ SpeechSettingsView
                                    ├─ Integration with journals
                                    └─ Accessibility enhancements

                                                     Phase 3 (10-12 hrs):
                                                     ├─ WidgetKit target
                                                     ├─ DashboardWidget
                                                     ├─ MedicationWidget
                                                     ├─ QuickLogWidget
                                                     └─ App Groups setup


Total: 28-36 hours development
```

## Accessibility Feature Map

```
ACCESSIBILITY FEATURES
══════════════════════════════════════════════════════════════

IMPLEMENTED [x]
├── VoiceOver Support
│   ├── Semantic labels on all controls
│   ├── Hints for gestures (swipe, double-tap)
│   ├── Traits for special elements
│   └── Centralized in AccessibilityLabels.swift
│
├── Dynamic Type
│   ├── Scalable text from small to xxxLarge
│   ├── Responsive layouts
│   └── dynamicTypeSize() extension
│
├── Visual Design
│   ├── Color-coded categories (9 colors)
│   ├── High-contrast SF Symbols
│   ├── Dark/light mode support
│   └── No color-only indicators
│
└── Semantic Structure
    ├── Proper view hierarchy
    ├── Related elements grouped
    └── Meaningful nesting


TO IMPLEMENT [Not Implemented]
├── Text-to-Speech
│   ├── Read journal entries aloud
│   ├── Read pattern notes
│   ├── Adjustable speech rate
│   └── Voice selection
│
├── Journal Functionality
│   ├── Write reflections
│   ├── Linked to pattern entries
│   └── Searchable content
│
├── Widgets
│   ├── Dashboard widget
│   ├── Medication reminder
│   └── Quick log buttons
│
└── Enhanced Features
    ├── Voice control compatibility
    ├── Screen reader optimizations
    └── Braille display support
```

---

This visual guide provides a quick reference for understanding the app's structure, relationships, and component organization.
