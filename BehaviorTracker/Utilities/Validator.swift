import Foundation

// MARK: - Validator Framework

/// A fluent, chainable validation framework for ensuring data integrity.
///
/// Provides type-safe validation with clear error messages for form validation
/// and data sanitization. Supports strings, optionals, and numeric types.
///
/// ## Usage
/// ```swift
/// // Validate a required string
/// try Validator(username, fieldName: "Username")
///     .notEmpty()
///     .minLength(3)
///     .maxLength(50)
///     .noSpecialCharacters()
///
/// // Validate an optional string
/// try Validator(bio, fieldName: "Bio")
///     .ifPresent { validator in
///         try validator.maxLength(500)
///     }
///
/// // Validate a numeric value
/// try Validator(rating, fieldName: "Rating")
///     .inRange(1...5)
/// ```
struct Validator<T> {
    /// The value being validated
    let value: T
    /// Human-readable name for error messages
    let fieldName: String

    /// Creates a new validator for the given value.
    /// - Parameters:
    ///   - value: The value to validate
    ///   - fieldName: Human-readable name used in error messages
    init(_ value: T, fieldName: String = "Value") {
        self.value = value
        self.fieldName = fieldName
    }
}

// MARK: - String Validation

extension Validator where T == String {
    /// Ensures the string is not empty after trimming whitespace
    @discardableResult
    func notEmpty(message: String? = nil) throws -> Validator {
        guard !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.invalid(message ?? "\(fieldName) cannot be empty")
        }
        return self
    }

    /// Ensures the string does not exceed maximum length
    @discardableResult
    func maxLength(_ max: Int, message: String? = nil) throws -> Validator {
        guard value.count <= max else {
            throw ValidationError.invalid(message ?? "\(fieldName) must be \(max) characters or less")
        }
        return self
    }

    /// Ensures the string meets minimum length
    @discardableResult
    func minLength(_ min: Int, message: String? = nil) throws -> Validator {
        guard value.count >= min else {
            throw ValidationError.invalid(message ?? "\(fieldName) must be at least \(min) characters")
        }
        return self
    }

    /// Ensures the string matches a regex pattern
    @discardableResult
    func matches(pattern: String, message: String? = nil) throws -> Validator {
        let regex = try NSRegularExpression(pattern: pattern)
        let range = NSRange(value.startIndex..<value.endIndex, in: value)
        guard regex.firstMatch(in: value, range: range) != nil else {
            throw ValidationError.invalid(message ?? "\(fieldName) has invalid format")
        }
        return self
    }

    /// Ensures the string contains no special characters that could be dangerous
    @discardableResult
    func noSpecialCharacters(message: String? = nil) throws -> Validator {
        let allowed = CharacterSet.alphanumerics
            .union(.whitespaces)
            .union(CharacterSet(charactersIn: ".,!?-'\"()"))
        guard value.unicodeScalars.allSatisfy({ allowed.contains($0) }) else {
            throw ValidationError.invalid(message ?? "\(fieldName) contains invalid characters")
        }
        return self
    }

    /// Returns the trimmed value
    func trimmed() -> String {
        return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Optional String Validation

extension Validator where T == String? {
    /// Validates optional string only if it has a value
    @discardableResult
    func ifPresent(_ validation: (Validator<String>) throws -> Void) throws -> Self {
        if let unwrapped = value {
            let validator = Validator<String>(unwrapped, fieldName: fieldName)
            try validation(validator)
        }
        return self
    }

    /// Returns the trimmed value if present
    func trimmed() -> String? {
        return value?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Numeric Validation

extension Validator where T: Comparable {
    /// Ensures the value is within a range
    @discardableResult
    func inRange(_ range: ClosedRange<T>, message: String? = nil) throws -> Validator {
        guard range.contains(value) else {
            throw ValidationError.invalid(message ?? "\(fieldName) must be between \(range.lowerBound) and \(range.upperBound)")
        }
        return self
    }
}

// MARK: - Int16 Validation (for Core Data)

extension Validator where T == Int16 {
    /// Ensures Int16 is within a range
    @discardableResult
    func inRange(_ range: ClosedRange<Int16>, message: String? = nil) throws -> Validator {
        guard range.contains(value) else {
            throw ValidationError.invalid(message ?? "\(fieldName) must be between \(range.lowerBound) and \(range.upperBound)")
        }
        return self
    }
}

// MARK: - Int32 Validation (for Core Data)

extension Validator where T == Int32 {
    /// Ensures Int32 is within a range
    @discardableResult
    func inRange(_ range: ClosedRange<Int32>, message: String? = nil) throws -> Validator {
        guard range.contains(value) else {
            throw ValidationError.invalid(message ?? "\(fieldName) must be between \(range.lowerBound) and \(range.upperBound)")
        }
        return self
    }
}

// MARK: - Array Validation

extension Validator where T: Collection {
    /// Ensures collection has maximum number of elements
    @discardableResult
    func maxCount(_ max: Int, message: String? = nil) throws -> Validator {
        guard value.count <= max else {
            throw ValidationError.invalid(message ?? "\(fieldName) can have at most \(max) items")
        }
        return self
    }
}

// MARK: - Validation Error

enum ValidationError: LocalizedError {
    case invalid(String)

    var errorDescription: String? {
        switch self {
        case .invalid(let message):
            return message
        }
    }
}
