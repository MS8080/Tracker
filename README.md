# Behavior Tracker

A comprehensive iOS application for tracking autism spectrum behavioral patterns throughout the day and generating weekly and monthly analytical reports.

## App Icon

The app features a custom "patterns" icon with a neural network design representing behavioral connections and insights. All required iOS icon sizes (13 files) have been generated and are ready to use.

**Icon Location**: `Resources/patterns-1024.png` (and other sizes)
**Installation**: See `ICON_INSTALLATION.md` for quick setup

## Overview

Behavior Tracker is a native iOS app built with Swift and SwiftUI that helps users track various behavioral patterns including sensory experiences, social interactions, executive function challenges, energy levels, emotional regulation, routines, physical patterns, and contextual factors.

## Features

### Quick Daily Logging
- Simple, elegant interface for logging events
- Maximum 3-5 taps per entry
- Automatic timestamp capture
- Optional quick notes field
- Favorite patterns for even faster logging

### Pattern Categories
- **Behavioral**: Repetitive behaviors, hyperfocus, task switching, special interests
- **Sensory**: Overload, seeking behaviors, environmental triggers, physical discomfort
- **Social/Communication**: Interactions, masking, communication preferences, recovery time
- **Executive Function**: Decision fatigue, time blindness, planning challenges, transitions
- **Energy/Capacity**: Energy levels, burnout warnings, rest periods, sleep quality
- **Emotional Regulation**: Meltdowns, shutdowns, anxiety, recovery time, overwhelm
- **Routine/Structure**: Adherence, flexibility tolerance, disruption impact
- **Physical**: Movement needs, posture preferences, stimming
- **Contextual**: Academic/work performance, environmental changes, bureaucratic stress

### Analytics & Reports

#### Weekly Reports
- Pattern frequency charts
- Most common triggers
- Energy level trends
- Social interaction patterns
- Sensory overload frequency
- Best vs challenging days comparison

#### Monthly Reports
- Long-term pattern identification
- Correlations between factors
- Behavior change trends over time
- Executive function patterns
- Most effective coping strategies
- Environmental factors impact analysis

### Data Management
- All data stored locally on device (privacy first)
- Core Data for persistence
- Export capability (JSON/CSV formats)
- Optional iCloud sync (user configurable)
- Search and filter historical entries

### Design
- Modern iOS interface using SwiftUI
- Liquid glass frosted effects
- SF Symbols throughout
- Smooth animations
- Haptic feedback
- Dark mode and light mode support
- Dynamic Type support
- VoiceOver accessibility

## Technical Stack

- **Language**: Swift 5.9+
- **Framework**: SwiftUI
- **Minimum iOS**: 17.0
- **Data Persistence**: Core Data
- **Charts**: Swift Charts framework
- **Notifications**: UserNotifications framework

## Architecture

The app follows the MVVM (Model-View-ViewModel) architecture:

```
BehaviorTracker/
├── Models/              # Data models and Core Data entities
├── Views/               # SwiftUI views organized by feature
│   ├── Logging/         # Pattern logging interface
│   ├── Dashboard/       # Home screen and history
│   ├── Reports/         # Analytics and visualizations
│   └── Settings/        # App configuration
├── ViewModels/          # Business logic and state management
├── Services/            # Data persistence and report generation
├── Utilities/           # Helper functions and extensions
└── Resources/           # Assets and configurations
```

## Core Components

### Data Layer
- **DataController**: Manages Core Data stack and operations
- **PatternEntry**: Core Data entity for logged patterns
- **UserPreferences**: Stores user settings and favorites
- **Tag**: Optional tagging system for entries

### Services
- **ReportGenerator**: Generates weekly and monthly analytics
- **NotificationManager**: Handles daily reminder scheduling

### Models
- **PatternCategory**: Main category enumeration
- **PatternType**: Specific pattern types within categories
- **WeeklyReport**: Weekly analytics data structure
- **MonthlyReport**: Monthly analytics data structure

## Key Features Implementation

### Quick Logging
1. User selects category
2. Chooses specific pattern type
3. Optionally adjusts intensity (1-5 scale)
4. Optionally sets duration
5. Can add notes or details
6. Save creates entry and updates streak

### Favorites System
- Users can mark patterns as favorites
- Favorite patterns appear on main logging screen
- One-tap quick logging for favorites
- Manage favorites in settings

### Streak Tracking
- Automatically tracks consecutive days of logging
- Encourages daily engagement
- Displayed prominently on dashboard

### Data Export
- Export all data as JSON or CSV
- Shareable via iOS share sheet
- Includes all entry details and timestamps
- Formatted for easy import to spreadsheets

## Privacy & Security

- **Local-First**: All data stored on device only
- **No Analytics**: No usage tracking or data collection
- **No Internet Required**: App works completely offline
- **User Control**: Full data export and deletion capabilities
- **Optional Cloud Sync**: iCloud sync disabled by default

## Setup & Installation

### Requirements
- Xcode 15.0 or later
- iOS 17.0 or later
- macOS Sonoma or later (for development)

### Building the Project

1. Clone or download the repository
2. Open `BehaviorTracker.xcodeproj` in Xcode
3. Select your target device or simulator
4. Build and run (Cmd+R)

### Configuration

No additional configuration is required. The app will:
- Initialize Core Data on first launch
- Create default user preferences
- Set up the data model automatically

## Testing

The project includes unit tests for:
- Core Data operations
- Pattern type categorization
- Report generation
- Data export functionality

Run tests in Xcode:
```
Cmd+U
```

## Code Structure

### Models
```swift
PatternCategory        # Main behavioral categories
PatternType           # Specific patterns within categories
PatternEntry          # Core Data entity for entries
UserPreferences       # User settings and configuration
```

### ViewModels
```swift
LoggingViewModel      # Handles pattern logging
DashboardViewModel    # Dashboard data and stats
ReportsViewModel      # Report generation coordination
HistoryViewModel      # Entry history management
SettingsViewModel     # App settings and preferences
```

### Services
```swift
DataController        # Core Data management
ReportGenerator       # Analytics generation
```

## Future Enhancements

Potential features for future versions:
- Custom pattern creation
- Medication tracking integration
- Photo attachments for context
- Location-based pattern triggers
- PDF report export
- Widget support
- Apple Watch companion app
- Siri shortcuts integration
- Advanced correlation analysis
- Pattern prediction using ML

## Accessibility

The app includes comprehensive accessibility support:
- VoiceOver labels and hints
- Dynamic Type for text scaling
- High contrast mode support
- Reduced motion support
- Keyboard navigation
- Semantic HTML-like structure

## Contributing

This is a personal project template. If you'd like to use or modify it:
1. Fork the repository
2. Make your changes
3. Ensure tests pass
4. Document your modifications

## License

This project is provided as-is for personal use and modification.

## Support

For issues or questions about the codebase:
- Review the inline code documentation
- Check the unit tests for usage examples
- Examine the ViewModels for business logic patterns

## Acknowledgments

Built with Swift, SwiftUI, and Core Data.
Uses Apple's SF Symbols for iconography.
Charts powered by Swift Charts framework.
