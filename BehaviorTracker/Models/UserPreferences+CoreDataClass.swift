import Foundation
import CoreData

/// Core Data entity that stores user preferences and settings.
/// This is a singleton-like entity - only one instance should exist per user.
@objc(UserPreferences)
public class UserPreferences: NSManagedObject, Identifiable {
    
    // MARK: - Core Data Managed Properties
    
    /// Unique identifier for the preferences record
    ///
    @NSManaged public var id: UUID
    
    /// Whether daily reminder notifications are enabled
    @NSManaged public var notificationEnabled: Bool
    
    /// The time of day to send reminder notifications (if enabled)
    @NSManaged public var notificationTime: Date?
    
    /// Number of consecutive days the user has logged patterns
    @NSManaged public var streakCount: Int32
    
    /// Internal storage for favorite patterns as a comma-separated string.
    /// Use the `favoritePatterns` computed property instead of accessing this directly.
    @NSManaged private var favoritePatternsString: String?

    // MARK: - Computed Properties
    
    /// Array of favorite pattern type raw values for quick logging.
    /// Stored internally as a comma-separated string for Core Data compatibility.
    public var favoritePatterns: [String] {
        get {
            // Return empty array if no favorites are stored
            guard let string = favoritePatternsString, !string.isEmpty else {
                return []
            }
            // Split the comma-separated string into an array
            return string.components(separatedBy: ",")
        }
        set {
            // Join the array into a comma-separated string for storage
            favoritePatternsString = newValue.joined(separator: ",")
        }
    }

    // MARK: - Lifecycle
    
    /// Called when a new UserPreferences object is inserted into the managed object context.
    /// Sets up default values for all properties.
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        self.id = UUID()
        self.notificationEnabled = false
        self.streakCount = 0
        self.favoritePatternsString = ""
    }
}
