import Foundation

enum ValidationResult: Equatable {
    case valid
    case invalid(String)
    var message: String? { if case .invalid(let m) = self { return m } else { return nil } }
    var isValid: Bool { self == .valid }
}

enum Validator {
    static func email(_ value: String) -> ValidationResult {
        let v = value.trimmingCharacters(in: .whitespaces)
        if v.isEmpty { return .invalid("Email is required") }
        let regex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return v.range(of: regex, options: .regularExpression) == nil
            ? .invalid("Enter a valid email") : .valid
    }

    static func password(_ value: String) -> ValidationResult {
        if value.isEmpty { return .invalid("Password is required") }
        if value.count < 8 { return .invalid("Minimum 8 characters") }
        if value.range(of: "[0-9]", options: .regularExpression) == nil ||
           value.range(of: "[A-Za-z]", options: .regularExpression) == nil {
            return .invalid("Use letters and numbers")
        }
        return .valid
    }

    static func mobile(_ value: String) -> ValidationResult {
        value.range(of: #"^[6-9][0-9]{9}$"#, options: .regularExpression) == nil
            ? .invalid("Enter a valid 10 digit mobile number") : .valid
    }

    static func pincode(_ value: String) -> ValidationResult {
        value.range(of: #"^[1-9][0-9]{5}$"#, options: .regularExpression) == nil
            ? .invalid("Enter a valid 6 digit pincode") : .valid
    }

    static func otp(_ value: String) -> ValidationResult {
        value.range(of: #"^[0-9]{6}$"#, options: .regularExpression) == nil
            ? .invalid("Enter the 6 digit OTP") : .valid
    }
}
