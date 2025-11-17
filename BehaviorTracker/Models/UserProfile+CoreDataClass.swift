import Foundation
import CoreData
import UIKit

@objc(UserProfile)
public class UserProfile: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var email: String?
    @NSManaged public var dateOfBirth: Date?
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged private var profileImageData: Data?
    
    // MARK: - Profile Image Handling
    
    /// Get or set the profile image as a UIImage
    public var profileImage: UIImage? {
        get {
            guard let data = profileImageData else { return nil }
            return UIImage(data: data)
        }
        set {
            // Compress and resize image to save storage space
            if let image = newValue {
                profileImageData = image.jpegData(compressionQuality: 0.7)
            } else {
                profileImageData = nil
            }
            updatedAt = Date()
        }
    }
    
    /// Check if user has a profile image
    public var hasProfileImage: Bool {
        return profileImageData != nil
    }
    
    // MARK: - Computed Properties
    
    /// User's initials for placeholder display
    public var initials: String {
        let components = name.split(separator: " ")
        if components.count >= 2 {
            let first = components[0].prefix(1)
            let last = components[1].prefix(1)
            return "\(first)\(last)".uppercased()
        } else if let first = components.first {
            return String(first.prefix(2)).uppercased()
        }
        return "?"
    }
    
    /// Formatted date of birth string
    public var formattedDateOfBirth: String? {
        guard let dob = dateOfBirth else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: dob)
    }
    
    /// Calculate age from date of birth
    public var age: Int? {
        guard let dob = dateOfBirth else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: dob, to: Date())
        return components.year
    }
    
    // MARK: - Lifecycle
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        self.id = UUID()
        self.name = ""
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // MARK: - Update Methods
    
    /// Update profile information
    public func update(
        name: String? = nil,
        email: String? = nil,
        dateOfBirth: Date? = nil
    ) {
        if let name = name {
            self.name = name
        }
        if let email = email {
            self.email = email
        }
        if let dob = dateOfBirth {
            self.dateOfBirth = dob
        }
        self.updatedAt = Date()
    }
}

// MARK: - UIImage Extension for Resizing

extension UIImage {
    /// Resize image to a maximum dimension while maintaining aspect ratio
    func resized(toMaxDimension maxDimension: CGFloat) -> UIImage {
        let aspectRatio = size.width / size.height
        var newSize: CGSize
        
        if size.width > size.height {
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
