# Core Data Setup for Medication Feature

## Overview
This guide explains how to add the Medication and MedicationLog entities to your Core Data model in Xcode.

## Steps

### 1. Open Core Data Model
1. In Xcode, navigate to `BehaviorTracker/Models/`
2. Open `BehaviorTrackerModel.xcdatamodeld`
3. You'll see the visual Core Data editor

### 2. Add Medication Entity

**Create Entity:**
1. Click the "+" button at the bottom of the Entities list
2. Name it: `Medication`
3. Set Class to: `Medication`
4. Set Module to: `Current Product Module`

**Add Attributes:**
Click "+" in Attributes section and add:
- `id` - Type: UUID
- `name` - Type: String
- `dosage` - Type: String, Optional: [x]
- `frequency` - Type: String
- `prescribedDate` - Type: Date
- `isActive` - Type: Boolean
- `notes` - Type: String, Optional: [x]

**Configure Attribute Details:**
- Select `id` attribute:
  - Default Value: (leave empty, will be set in code)
- Select `name` attribute:
  - Default Value: (empty)
- Select `frequency` attribute:
  - Default Value: "Daily"
- Select `prescribedDate` attribute:
  - Default Value: (leave empty, will be set in code)
- Select `isActive` attribute:
  - Default Value: YES

### 3. Add MedicationLog Entity

**Create Entity:**
1. Click "+" button again
2. Name it: `MedicationLog`
3. Set Class to: `MedicationLog`
4. Set Module to: `Current Product Module`

**Add Attributes:**
Click "+" in Attributes section and add:
- `id` - Type: UUID
- `timestamp` - Type: Date
- `taken` - Type: Boolean
- `skippedReason` - Type: String, Optional: [x]
- `sideEffects` - Type: String, Optional: [x]
- `effectiveness` - Type: Integer 16
- `mood` - Type: Integer 16
- `energyLevel` - Type: Integer 16
- `notes` - Type: String, Optional: [x]

**Configure Attribute Details:**
- Select `taken` attribute:
  - Default Value: YES
- Select `effectiveness` attribute:
  - Default Value: 0
- Select `mood` attribute:
  - Default Value: 0
- Select `energyLevel` attribute:
  - Default Value: 0

### 4. Set Up Relationships

**From Medication to MedicationLog:**
1. Select `Medication` entity
2. In Relationships section, click "+"
3. Add relationship:
   - Name: `logs`
   - Destination: `MedicationLog`
   - Type: To Many
   - Inverse: `medication`
   - Delete Rule: Cascade
   - Optional: [x]

**From MedicationLog to Medication:**
1. Select `MedicationLog` entity
2. In Relationships section, click "+"
3. Add relationship:
   - Name: `medication`
   - Destination: `Medication`
   - Type: To One
   - Inverse: `logs`
   - Delete Rule: Nullify
   - Optional: [x]

### 5. Configure Codegen

For both entities:
1. Select entity
2. In Data Model Inspector (right panel):
   - Codegen: `Manual/None`
   - Class: (entity name)
   - Module: `Current Product Module`

We use Manual/None because we've created the classes manually.

### 6. Verify Existing Entities

Make sure these existing entities are present:
- `PatternEntry`
- `UserPreferences`
- `Tag`

### 7. Save the Model
- Press Cmd+S to save
- Build the project (Cmd+B) to verify no errors

## Visual Reference

Your Core Data model should now look like this:

```
Entities:
├── Medication
│   ├── Attributes
│   │   ├── id: UUID
│   │   ├── name: String
│   │   ├── dosage: String (Optional)
│   │   ├── frequency: String
│   │   ├── prescribedDate: Date
│   │   ├── isActive: Boolean
│   │   └── notes: String (Optional)
│   └── Relationships
│       └── logs -> MedicationLog (To Many, Cascade)
│
├── MedicationLog
│   ├── Attributes
│   │   ├── id: UUID
│   │   ├── timestamp: Date
│   │   ├── taken: Boolean
│   │   ├── skippedReason: String (Optional)
│   │   ├── sideEffects: String (Optional)
│   │   ├── effectiveness: Integer 16
│   │   ├── mood: Integer 16
│   │   ├── energyLevel: Integer 16
│   │   └── notes: String (Optional)
│   └── Relationships
│       └── medication -> Medication (To One, Nullify)
│
├── PatternEntry (existing)
├── UserPreferences (existing)
└── Tag (existing)
```

## Migration

The app is configured for automatic lightweight migration:
- Existing data will be preserved
- New entities will be added automatically
- No manual migration mapping needed

If users already have data:
- PatternEntry, UserPreferences, and Tag data remains intact
- Medication and MedicationLog tables are created empty
- Users start fresh with medication tracking

## Troubleshooting

### "Entity not found" error
- Verify entity names match exactly: `Medication` and `MedicationLog`
- Check that Class names are set correctly in inspector

### Build errors about duplicate symbols
- Ensure Codegen is set to "Manual/None" for all entities
- Clean build folder (Shift+Cmd+K) and rebuild

### Core Data errors at runtime
- Verify all attribute types match the Swift files
- Check that relationships are properly configured
- Ensure inverse relationships are set

### Migration errors
- Delete app from simulator/device
- Clean build folder
- Rebuild and reinstall

## Testing Core Data Setup

After setup, test with this code in your app:

```swift
// Test creating a medication
let testMed = DataController.shared.createMedication(
    name: "Test Medication",
    dosage: "10mg",
    frequency: "Daily",
    notes: "Test note"
)

// Test creating a log
let testLog = DataController.shared.createMedicationLog(
    medication: testMed,
    taken: true,
    effectiveness: 4,
    mood: 4,
    energyLevel: 3
)

// Test fetching
let medications = DataController.shared.fetchMedications()
print("Medications count: \(medications.count)")

let logs = DataController.shared.getTodaysMedicationLogs()
print("Today's logs: \(logs.count)")
```

## Next Steps

After Core Data setup:
1. Build the project (Cmd+B)
2. Run on simulator or device
3. Test adding a medication
4. Test logging medication intake
5. Verify data persists between app launches
6. Check that charts render with real data

## Important Notes

- **Backup**: Back up your existing Core Data model before making changes
- **Testing**: Test thoroughly with sample data before using with real user data
- **Migration**: The first launch after adding these entities will perform a migration
- **Performance**: Indexes are not required for initial implementation but can be added later if needed

## Files to Reference

If you need to verify the implementation:
- `Models/Medication+CoreDataClass.swift`
- `Models/MedicationLog+CoreDataClass.swift`
- `Services/DataController.swift` (medication methods)

The Core Data classes define the Swift interface, and the .xcdatamodeld file defines the database schema. Both must match.
