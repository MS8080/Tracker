import Foundation

// MARK: - Validator Framework

/// A generic validation framework for ensuring data integrity and security
struct Validator<T> {
    let value: T
    let fieldName: String

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

    /// Ensures the string contains only alphanumeric characters and optionally spaces
    @discardableResult
    func alphanumeric(allowSpaces: Bool = false, message: String? = nil) throws -> Validator {
        var allowed = CharacterSet.alphanumerics
        if allowSpaces {
            allowed = allowed.union(.whitespaces)
        }
        guard value.unicodeScalars.allSatisfy({ allowed.contains($0) }) else {
            throw ValidationError.invalid(message ?? "\(fieldName) can only contain letters, numbers\(allowSpaces ? ", and spaces" : "")")
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

    /// Ensures the string is within a length range
    @discardableResult
    func lengthInRange(_ range: ClosedRange<Int>, message: String? = nil) throws -> Validator {
        guard range.contains(value.count) else {
            throw ValidationError.invalid(message ?? "\(fieldName) must be between \(range.lowerBound) and \(range.upperBound) characters")
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

    /// Ensures the value is greater than a minimum
    @discardableResult
    func greaterThan(_ minimum: T, message: String? = nil) throws -> Validator {
        guard value > minimum else {
            throw ValidationError.invalid(message ?? "\(fieldName) must be greater than \(minimum)")
        }
        return self
    }

    /// Ensures the value is greater than or equal to a minimum
    @discardableResult
    func greaterThanOrEqual(_ minimum: T, message: String? = nil) throws -> Validator {
        guard value >= minimum else {
            throw ValidationError.invalid(message ?? "\(fieldName) must be at least \(minimum)")
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

    /// Ensures Int32 is positive
    @discardableResult
    func positive(message: String? = nil) throws -> Validator {
        guard value > 0 else {
            throw ValidationError.invalid(message ?? "\(fieldName) must be positive")
        }
        return self
    }
}

// MARK: - Array Validation

extension Validator where T: Collection {
    /// Ensures collection is not empty
    @discardableResult
    func notEmpty(message: String? = nil) throws -> Validator {
        guard !value.isEmpty else {
            throw ValidationError.invalid(message ?? "\(fieldName) cannot be empty")
        }
        return self
    }

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
    case multipleErrors([String])

    var errorDescription: String? {
        switch self {
        case .invalid(let message):
            return message
        case .multipleErrors(let messages):
            return messages.joined(separator: "\n")
        }
    }
}

// MARK: - Validation Result Builder

/// Collects multiple validation errors instead of failing fast
struct ValidationCollector {
    private var errors: [String] = []

    mutating func validate(_ validation: () throws -> Void) {
        do {
            try validation()
        } catch let error as ValidationError {
            if case .invalid(let message) = error {
                errors.append(message)
            }
        } catch {
            errors.append(error.localizedDescription)
        }
    }

    func validate() throws {
        guard errors.isEmpty else {
            throw ValidationError.multipleErrors(errors)
        }
    }
}
