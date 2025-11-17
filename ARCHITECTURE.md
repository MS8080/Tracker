# Architecture Overview

## Design Patterns

### MVVM (Model-View-ViewModel)

The app uses MVVM architecture to separate concerns and maintain testability:

**Models**
- Define data structures
- Represent Core Data entities
- Contain business logic for data validation
- Examples: PatternEntry, UserPreferences, PatternType

**Views**
- SwiftUI views for UI presentation
- Minimal logic, primarily layout and styling
- Observe ViewModels for state changes
- Examples: DashboardView, LoggingView, ReportsView

**ViewModels**
- Manage view state and business logic
- Handle user interactions
- Coordinate with services and data layer
- Publish changes to views via @Published properties
- Examples: LoggingViewModel, DashboardViewModel

### Data Flow

```
User Interaction
    ↓
View (SwiftUI)
    ↓
ViewModel
    ↓
Service Layer (DataController, ReportGenerator)
    ↓
Core Data
    ↓
Persistent Storage
```

### Reverse Data Flow

```
Core Data Change
    ↓
Service Layer
    ↓
ViewModel (@Published updates)
    ↓
View (Auto-updates via @ObservedObject/@StateObject)
```

## Core Components

### 1. Data Layer

#### DataController
Singleton class managing Core Data stack:
- Initializes persistent container
- Provides CRUD operations
- Handles context saving
- Manages fetch requests
- Supports in-memory store for testing

```swift
class DataController: ObservableObject {
    static let shared = DataController()
    let container: NSPersistentContainer

    func save()
    func createPatternEntry(...)
    func deletePatternEntry(...)
    func fetchPatternEntries(...)
    func getUserPreferences()
    func updateStreak()
}
```

#### Core Data Entities

**PatternEntry**
- id: UUID
- timestamp: Date
- category: String
- patternType: String
- intensity: Int16
- duration: Int32
- contextNotes: String?
- specificDetails: String?
- customPatternName: String?
- isFavorite: Bool
- tags: Relationship to Tag

**UserPreferences**
- id: UUID
- notificationEnabled: Bool
- notificationTime: Date?
- streakCount: Int32
- favoritePatterns: [String]

**Tag**
- id: UUID
- name: String
- entries: Relationship to PatternEntry

### 2. Service Layer

#### ReportGenerator
Generates analytics and insights:
- Weekly report compilation
- Monthly report generation
- Correlation analysis
- Trend identification
- Day performance scoring

```swift
class ReportGenerator {
    func generateWeeklyReport() -> WeeklyReport
    func generateMonthlyReport() -> MonthlyReport
    private func findCorrelations(...) -> [String]
    private func analyzeDays(...) -> ([String], [String])
}
```

### 3. ViewModel Layer

Each major feature has a dedicated ViewModel:

**LoggingViewModel**
- Manages pattern logging
- Handles favorite patterns
- Quick log functionality
- Coordinates with DataController

**DashboardViewModel**
- Loads dashboard statistics
- Calculates streak information
- Aggregates today's data
- Provides recent entries

**ReportsViewModel**
- Coordinates report generation
- Manages timeframe selection
- Publishes report data to views

**HistoryViewModel**
- Manages entry history
- Handles filtering and search
- Groups entries by date
- Manages entry deletion

**SettingsViewModel**
- Manages user preferences
- Handles notification scheduling
- Manages favorite patterns
- Exports data (JSON/CSV)

### 4. View Layer

Views are organized by feature:

**Logging/**
- LoggingView: Main pattern logging interface
- CategoryLoggingView: Category-specific patterns
- PatternEntryFormView: Detailed entry form

**Dashboard/**
- DashboardView: Main dashboard
- HistoryView: Entry history list

**Reports/**
- ReportsView: Analytics and visualizations

**Settings/**
- SettingsView: App settings
- ExportDataView: Data export interface

## State Management

### @StateObject vs @ObservedObject

**@StateObject**: Used when view owns the ViewModel
```swift
struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
}
```

**@ObservedObject**: Used when ViewModel is passed from parent
```swift
struct CategoryLoggingView: View {
    @ObservedObject var viewModel: LoggingViewModel
}
```

### @State for Local UI State

```swift
@State private var selectedCategory: PatternCategory?
@State private var showingExportSheet = false
```

### @Environment for Shared Dependencies

```swift
@Environment(\.managedObjectContext) private var viewContext
@Environment(\.dismiss) private var dismiss
```

## Navigation

Uses NavigationStack for hierarchical navigation:
- Tab-based main navigation
- Sheet presentations for modals
- NavigationLink for detail views

## Data Persistence Strategy

### Core Data Configuration
- Automatic merging of changes from parent context
- Property object trump merge policy
- Background context for heavy operations
- Main context for UI updates

### Transaction Flow
1. User initiates action (e.g., logs pattern)
2. ViewModel calls DataController method
3. DataController creates/modifies Core Data objects
4. Context saved immediately
5. Published properties updated
6. SwiftUI views auto-refresh

## Performance Optimizations

### Fetch Requests
- Predicates for filtering at database level
- Sort descriptors for ordering
- Fetch limits where appropriate
- Batch operations for multiple items

### View Updates
- Lazy loading with LazyVStack/LazyVGrid
- Conditional view rendering
- Minimizing @Published updates
- Strategic use of .id() for view identity

### Memory Management
- Weak references where appropriate
- Proper cleanup in deinit
- In-memory testing stores
- Context merging policies

## Testing Strategy

### Unit Tests
- DataController CRUD operations
- Pattern type categorization
- Report generation logic
- Export functionality

### Test Data
- In-memory Core Data store
- Isolated test instances
- Predictable test data

### Test Coverage
- Core business logic
- Data operations
- Report calculations
- Model validations

## Error Handling

### Core Data Errors
- Graceful save failures
- Fetch error recovery
- User-friendly error messages
- Logging for debugging

### UI Error States
- Empty states for no data
- Loading indicators
- Error recovery options
- Fallback content

## Accessibility Implementation

### VoiceOver Support
- Semantic labels
- Hints for complex controls
- Trait assignments
- Grouping related elements

### Dynamic Type
- Scalable text
- Flexible layouts
- Size category limits
- Layout adaptations

### Visual Accessibility
- High contrast support
- Reduced motion support
- Color-independent information
- Sufficient touch targets

## Security & Privacy

### Data Protection
- Local-only storage by default
- No network requests
- Keychain for sensitive data (if needed)
- User-controlled exports

### Privacy Design
- No analytics collection
- No third-party SDKs
- Optional iCloud sync
- Transparent data handling

## Future Scalability

### Extensibility Points
- Custom pattern types
- Plugin architecture potential
- Additional export formats
- Third-party integrations

### Performance Scaling
- Pagination for large datasets
- Background processing
- Index optimization
- Archive old data

## Dependencies

### Apple Frameworks
- SwiftUI: UI framework
- CoreData: Data persistence
- Charts: Data visualization
- UserNotifications: Reminders

### No External Dependencies
- Self-contained codebase
- Standard library only
- Reduces maintenance burden
- Improves security posture
