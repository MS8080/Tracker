# Medication Tracking Feature

## Overview

The Behavior Tracker app now includes comprehensive medication tracking functionality that allows users to log their daily medications and analyze how they affect behavioral patterns, mood, and energy levels.

## Features

### 1. Medication Management

- **Add Medications**: Create medication entries with name, dosage, frequency, and notes
- **Frequency Options**:
  - Daily
  - Twice Daily
  - Three Times Daily
  - Every Other Day
  - Weekly
  - As Needed
- **Active/Inactive Status**: Mark medications as active or inactive without deleting history

### 2. Daily Medication Logging

For each medication taken, you can log:
- **Taken Status**: Whether you took the medication or skipped it
- **Skip Reason**: If skipped, optionally note why
- **Effectiveness Rating**: 1-5 scale of how effective the medication was
- **Mood Rating**: 1-5 scale of your mood after taking medication
- **Energy Level**: 1-5 scale of your energy level
- **Side Effects**: Optional text field for noting any side effects
- **Additional Notes**: Any other observations

### 3. Medication Dashboard

The main Medications tab shows:
- **Today's Medications**: Quick view of all medications with checkboxes
  - Visual indicator showing if medication was taken today
  - Quick stats (effectiveness, mood, energy) if logged
  - One-tap logging interface

- **All Medications List**: Overview of all active medications
  - 7-day adherence rate percentage
  - Color-coded adherence indicators:
    - Green: ≥80% adherence
    - Orange: 60-79% adherence
    - Red: <60% adherence

### 4. Medication Detail View

Each medication has a detailed view showing:
- **Medication Information**: Name, dosage, frequency, prescribed date, notes
- **Statistics** (configurable for 7, 30, or 90 days):
  - Adherence rate percentage
  - Average effectiveness rating
  - Average mood rating
- **Trend Charts**:
  - Effectiveness over time (line chart)
  - Mood over time (line chart)
- **Recent Logs**: List of recent medication logs with all details

### 5. Dashboard Integration

The main Dashboard now includes:
- **Today's Medications Summary**: Shows up to 3 medications with checkmark status
- Quick navigation to full Medications view
- Visual indicators for completed/pending medications

### 6. Analytics & Reports

#### Weekly Reports Include:
- Medication adherence rates for the week
- Average effectiveness, mood, and energy ratings
- Side effects frequency
- Behavioral correlations:
  - Positive patterns on high-effectiveness days
  - Fewer challenging behaviors with good medication compliance

#### Monthly Reports Include:
- Long-term medication effectiveness trends
- Adherence patterns over 30 days
- Correlations between medication effectiveness and:
  - Reduced sensory overload incidents
  - Increased hyperfocus/special interest engagement
  - Improved mood regulation
  - Better energy management

### 7. Medication-Behavior Correlations

The app automatically analyzes relationships between:
- Medication effectiveness and positive behavioral patterns
- Medication compliance and reduced challenging behaviors
- Mood ratings and emotional regulation patterns
- Energy levels and overall daily function

## Data Model

### Medication Entity
- `id`: Unique identifier
- `name`: Medication name
- `dosage`: Optional dosage information (e.g., "10mg")
- `frequency`: How often taken (daily, twice daily, etc.)
- `prescribedDate`: Date medication was started
- `isActive`: Whether medication is currently being taken
- `notes`: Optional notes about the medication

### MedicationLog Entity
- `id`: Unique identifier
- `timestamp`: When the log was created
- `taken`: Boolean indicating if medication was taken
- `skippedReason`: Optional reason for skipping
- `sideEffects`: Optional side effects notes
- `effectiveness`: 1-5 rating (0 if not rated)
- `mood`: 1-5 rating (0 if not rated)
- `energyLevel`: 1-5 rating (0 if not rated)
- `notes`: Optional additional notes
- Relationship to `Medication` entity

## User Interface

### New Tab
- Pills icon in the tab bar
- Positioned between "Log" and "Reports" tabs

### Views
1. **MedicationView**: Main medications interface
2. **AddMedicationView**: Form for adding new medications
3. **LogMedicationView**: Form for logging daily medication intake
4. **MedicationDetailView**: Detailed view with charts and history

### Design Consistency
- Follows existing app design with liquid glass effects
- SF Symbols for icons
- Color-coded visual indicators
- SwiftUI animations and haptic feedback

## Privacy & Security

- All medication data stored locally using Core Data
- No cloud sync by default (privacy-first approach)
- Data can be exported with other app data
- No third-party medication databases or APIs
- Completely offline functionality

## Use Cases

1. **Daily Medication Management**: Track if you took your medications each day
2. **Effectiveness Monitoring**: See if medications are helping
3. **Side Effect Tracking**: Document and monitor side effects
4. **Adherence Improvement**: Visual reminders and statistics encourage compliance
5. **Clinical Discussions**: Export data to share with healthcare providers
6. **Pattern Recognition**: Understand how medications affect behavior and mood
7. **Medication Adjustments**: Data to support decisions about dosage or timing changes

## Technical Implementation

### Files Added
- `Models/Medication+CoreDataClass.swift`
- `Models/MedicationLog+CoreDataClass.swift`
- `Models/MedicationFrequency.swift`
- `ViewModels/MedicationViewModel.swift`
- `Views/Medications/MedicationView.swift`
- `Views/Medications/AddMedicationView.swift`
- `Views/Medications/LogMedicationView.swift`
- `Views/Medications/MedicationDetailView.swift`

### Files Modified
- `Services/DataController.swift` - Added medication CRUD operations
- `Services/ReportGenerator.swift` - Added medication insights and correlations
- `Views/Dashboard/DashboardView.swift` - Added medication summary card
- `ContentView.swift` - Added Medications tab

### Core Data Schema Updates
The app uses automatic lightweight migration, so existing data is preserved when adding:
- `Medication` entity
- `MedicationLog` entity
- Relationships between entities

## Future Enhancements

Potential additions for future versions:
- Medication reminders/notifications at specific times
- Medication interaction warnings
- Prescription refill tracking
- Photo attachments of medication packaging
- Export medication logs as PDF for doctor visits
- Apple Health integration for medication data
- Medication history timeline visualization
- Multi-medication correlation analysis
- Dose timing optimization suggestions

## Getting Started

1. **Add Your First Medication**:
   - Open the Medications tab
   - Tap the "+" button
   - Enter medication details
   - Save

2. **Log Daily Intake**:
   - View Today's Medications section
   - Tap the circle next to a medication
   - Complete the logging form
   - Save

3. **Review Insights**:
   - Check individual medication detail views for trends
   - View weekly/monthly reports for correlations
   - Monitor adherence rates

4. **Correlate with Behaviors**:
   - Continue logging behavioral patterns as usual
   - The app automatically analyzes relationships
   - Review correlations in weekly and monthly reports

## Notes for Healthcare Providers

This tracking tool:
- Provides objective data on medication adherence
- Documents side effects as they occur
- Shows effectiveness ratings over time
- Correlates medication use with behavioral patterns
- Can be exported for clinical review
- Supports shared decision-making about treatment

**Important**: This app is a tracking tool, not a medical device. Always consult healthcare providers for medical decisions.
