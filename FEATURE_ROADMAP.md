# Feature Enhancement Roadmap

## Current App State Summary

[x] **Production Ready**
- Pattern tracking (37 patterns across 9 categories)
- Medication tracking & adherence
- Weekly/monthly analytics reports
- Settings & preferences
- Data export (JSON/CSV)
- Full accessibility (VoiceOver labels, Dynamic Type)

---

## Planned Enhancements

### Phase 1: Journal & Notes System (Foundation)

**Purpose:** Enable users to write reflections and journal entries linked to their behavioral patterns

**Components to Add:**

1. **New Core Data Model**
   ```
   JournalEntry
   - id: UUID
   - timestamp: Date
   - title: String
   - content: String (Long text)
   - mood: Int16 (optional)
   - patternEntries: Relationship to [PatternEntry]
   ```

2. **New Views**
   - `JournalListView` - List of all journal entries
   - `JournalDetailView` - Read a specific journal entry
   - `JournalCreateView` - Create/edit journal entry
   - Add "Journal" tab to ContentView (Tab 5)

3. **New ViewModel**
   - `JournalViewModel`
   - Methods: createEntry, updateEntry, deleteEntry, searchEntries

4. **Integration Points**
   - Link journal entries to pattern entries
   - Show related patterns in journal detail view
   - Search journal content

**Files to Create:**
- `Models/JournalEntry+CoreDataClass.swift`
- `ViewModels/JournalViewModel.swift`
- `Views/Journal/JournalListView.swift`
- `Views/Journal/JournalDetailView.swift`
- `Views/Journal/JournalCreateView.swift`

**Files to Modify:**
- `BehaviorTrackerModel.xcdatamodeld` - Add JournalEntry entity
- `Services/DataController.swift` - Add journal CRUD methods
- `ContentView.swift` - Add Journal tab

---

### Phase 2: Text-to-Speech (Accessibility Enhancement)

**Purpose:** Allow users to hear their journal entries and notes read aloud for accessibility

**Components to Add:**

1. **Speech Synthesis Service**
   ```swift
   class SpeechSynthesisManager {
       func speak(_ text: String, rate: Float = 0.5)
       func pause()
       func resume()
       func stop()
   }
   ```

2. **UI Components**
   - "Read Aloud" button for journal entries
   - "Listen to Notes" button on pattern details
   - Speech rate slider in settings
   - Voice selection toggle (male/female)

3. **Settings Integration**
   - Add speech rate preference
   - Add voice choice preference
   - Add volume control preference
   - Add "read while locked" option

**Framework:** AVFoundation (AVSpeechSynthesizer)

**Files to Create:**
- `Services/SpeechSynthesisManager.swift`
- `Views/Components/ReadAloudButton.swift`
- `Views/Settings/SpeechSettingsView.swift`

**Files to Modify:**
- `Views/Journal/JournalDetailView.swift` - Add read aloud button
- `Views/Logging/PatternEntryFormView.swift` - Add read aloud for notes
- `Views/Settings/SettingsView.swift` - Add speech settings

**Accessibility Benefits:**
- Users with visual impairments can hear their entries
- Users with dyslexia can hear while reading
- Auditory learners benefit from audio review
- Users can listen while doing other activities

---

### Phase 3: Home Screen & Lock Screen Widgets

**Purpose:** Provide quick access to key information without opening the app

**Components to Add:**

1. **Dashboard Widget** (Home Screen)
   - Shows: Streak count, Today's entry count, Next medication due
   - Size: Small (2x2) and Medium (2x4)
   - Refresh: Every 15 minutes

2. **Medication Reminder Widget** (Lock Screen)
   - Shows: Due medications for today
   - Size: Lock Screen appropriate (narrow)
   - Refresh: Hourly

3. **Quick Log Widget** (Home Screen)
   - Shows: 5 favorite patterns as quick action buttons
   - Size: Medium (2x4)
   - Action: Tap to quick log

**Implementation:**

1. **Create Widget Extension Target**
   - New target: `BehaviorTrackerWidget`
   - Include in App Groups for data sharing

2. **Enable App Groups**
   - Add app group identifier to signing
   - Configure Core Data for App Groups
   - Share UserDefaults between app and widget

3. **Widget Views**
   - `DashboardWidgetView.swift`
   - `MedicationReminderWidget.swift`
   - `QuickLogWidget.swift`

**Files to Create:**
- `Widgets/BehaviorTrackerWidgetBundle.swift`
- `Widgets/DashboardWidget.swift`
- `Widgets/MedicationReminderWidget.swift`
- `Widgets/QuickLogWidget.swift`
- `Utilities/AppGroupDataManager.swift`

**Files to Modify:**
- `Services/DataController.swift` - App Group support
- Project signing settings - Add app group identifier

---

## Implementation Priority

### Tier 1: Critical (Do First)
1. **Journal System** - Foundation for text-to-speech, required for enhanced note-taking

### Tier 2: Important (Do Next)
2. **Text-to-Speech** - Significant accessibility improvement
3. **Dashboard Widget** - High-value user convenience feature

### Tier 3: Nice-to-Have (Later)
4. **Medication Widget** - Useful but less critical
5. **Quick Log Widget** - Convenience feature

---

## Development Checklist

### Phase 1: Journal System
- [ ] Add JournalEntry to Core Data model
- [ ] Create JournalEntry+CoreDataClass
- [ ] Add CRUD methods to DataController
- [ ] Create JournalViewModel
- [ ] Create JournalListView
- [ ] Create JournalDetailView
- [ ] Create JournalCreateView
- [ ] Add Journal tab to ContentView
- [ ] Test CRUD operations
- [ ] Add VoiceOver labels for journal views
- [ ] Update documentation

### Phase 2: Text-to-Speech
- [ ] Create SpeechSynthesisManager service
- [ ] Create ReadAloudButton component
- [ ] Add read aloud to JournalDetailView
- [ ] Add read aloud to pattern notes (optional)
- [ ] Create SpeechSettingsView
- [ ] Add speech settings to SettingsView
- [ ] Test speech synthesis with various content lengths
- [ ] Test with VoiceOver enabled
- [ ] Handle interruptions (phone calls, etc.)
- [ ] Update documentation

### Phase 3: Widgets
- [ ] Create widget extension target
- [ ] Add app group identifier to project
- [ ] Configure Core Data for app groups
- [ ] Create DashboardWidget
- [ ] Create MedicationReminderWidget (optional)
- [ ] Create QuickLogWidget (optional)
- [ ] Test widget data refresh
- [ ] Test widget interactions
- [ ] Test on lock screen (iOS 16+)
- [ ] Update documentation

---

## Testing Strategy

### Unit Tests to Add

```swift
// JournalViewModelTests
- testCreateJournal()
- testUpdateJournal()
- testDeleteJournal()
- testSearchJournal()

// SpeechSynthesisManagerTests
- testSpeechInitialization()
- testPlayPauseResume()
- testRateAdjustment()
- testVoiceSelection()

// WidgetTests
- testDashboardWidgetData()
- testWidgetRefresh()
- testAppGroupDataSharing()
```

### Integration Tests

- Journal entries persist correctly
- Speech synthesis starts/stops properly
- Widgets update when app data changes
- No data leakage between app and widget

### Accessibility Tests

- Journal views work with VoiceOver
- Speech output accessible to all
- Widget layout readable with accessibility sizes

---

## Architecture Changes Summary

### New Service Classes
- `SpeechSynthesisManager` - Handles text-to-speech
- `AppGroupDataManager` - Manages app group data sharing

### New ViewModels
- `JournalViewModel` - Manages journal CRUD
- `WidgetDataProvider` - Provides data to widgets

### New Views
- Journal views (list, detail, create)
- Speech settings view
- Widget views

### Core Data Changes
- Add JournalEntry entity
- Add relationships between JournalEntry and PatternEntry
- Configure Core Data for app groups

### No Breaking Changes
- Existing functionality remains unchanged
- All new features are additive
- Backward compatible Core Data migration

---

## Success Metrics

After implementing all phases:

[x] Users can journal their thoughts and experiences
[x] Users can listen to their journals with text-to-speech
[x] Users can see key information at a glance via widgets
[x] Users have improved accessibility options
[x] App provides more comprehensive tracking
[x] User engagement increases through convenience features

---

## Estimated Timeline

- Phase 1 (Journal): 8-10 hours development
- Phase 2 (Text-to-Speech): 6-8 hours development
- Phase 3 (Widgets): 10-12 hours development
- Testing & Polish: 4-6 hours

**Total: 28-36 hours of development**

---

## Notes

- All changes maintain existing privacy-first design
- No external dependencies added
- Uses only Apple frameworks
- Full accessibility support maintained
- Clean MVVM architecture preserved
