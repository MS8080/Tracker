import CoreData
import Foundation

/// Repository for UserProfile and UserPreferences CRUD operations
final class UserProfileRepository {
    static let shared = UserProfileRepository()

    private var viewContext: NSManagedObjectContext {
        DataController.shared.container.viewContext
    }

    private init() {}

    // MARK: - UserProfile Create

    func createProfile(
        name: String,
        email: String? = nil,
        dateOfBirth: Date? = nil
    ) -> UserProfile {
        let profile = UserProfile(context: viewContext)
        profile.name = name
        profile.email = email
        profile.dateOfBirth = dateOfBirth

        DataController.shared.save()
        return profile
    }

    // MARK: - UserProfile Read

    func fetchProfiles() -> [UserProfile] {
        do {
            return try fetchProfilesOrThrow()
        } catch {
            print("Failed to fetch user profiles: \(error.localizedDescription)")
            return []
        }
    }

    func fetchProfilesOrThrow() throws -> [UserProfile] {
        let request = NSFetchRequest<UserProfile>(entityName: "UserProfile")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \UserProfile.name, ascending: true)]

        do {
            return try viewContext.fetch(request)
        } catch {
            throw DataController.DataError.fetchFailed(error)
        }
    }

    func getCurrentProfile() -> UserProfile? {
        do {
            return try getCurrentProfileOrThrow()
        } catch {
            print("Failed to fetch current user profile: \(error.localizedDescription)")
            return nil
        }
    }

    func getCurrentProfileOrThrow() throws -> UserProfile? {
        let request = NSFetchRequest<UserProfile>(entityName: "UserProfile")
        request.fetchLimit = 1
        request.sortDescriptors = [NSSortDescriptor(keyPath: \UserProfile.createdAt, ascending: true)]

        do {
            return try viewContext.fetch(request).first
        } catch {
            throw DataController.DataError.fetchFailed(error)
        }
    }

    func getOrCreateProfile() -> UserProfile {
        if let existing = getCurrentProfile() {
            return existing
        }
        return createProfile(name: "User")
    }

    // MARK: - UserProfile Update/Delete

    func updateProfile(_ profile: UserProfile) {
        profile.updatedAt = Date()
        DataController.shared.save()
    }

    func deleteProfile(_ profile: UserProfile) {
        viewContext.delete(profile)
        DataController.shared.save()
    }

    // MARK: - UserPreferences

    func getPreferences() -> UserPreferences {
        let request = NSFetchRequest<UserPreferences>(entityName: "UserPreferences")
        request.fetchLimit = 1

        do {
            let results = try viewContext.fetch(request)
            if let preferences = results.first {
                return preferences
            } else {
                let newPreferences = UserPreferences(context: viewContext)
                DataController.shared.save()
                return newPreferences
            }
        } catch {
            print("Failed to fetch preferences: \(error.localizedDescription)")
            let newPreferences = UserPreferences(context: viewContext)
            DataController.shared.save()
            return newPreferences
        }
    }

    func updateStreak() {
        let preferences = getPreferences()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let request = NSFetchRequest<PatternEntry>(entityName: "PatternEntry")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PatternEntry.timestamp, ascending: false)]
        request.fetchLimit = 1

        do {
            let results = try viewContext.fetch(request)
            if let lastEntry = results.first {
                let lastEntryDate = calendar.startOfDay(for: lastEntry.timestamp)
                let daysDifference = calendar.dateComponents([.day], from: lastEntryDate, to: today).day ?? 0

                if daysDifference == 0 {
                    return
                } else if daysDifference == 1 {
                    preferences.streakCount += 1
                } else {
                    preferences.streakCount = 1
                }
            } else {
                preferences.streakCount = 1
            }
            DataController.shared.save()
        } catch {
            print("Failed to update streak: \(error.localizedDescription)")
        }
    }
}
