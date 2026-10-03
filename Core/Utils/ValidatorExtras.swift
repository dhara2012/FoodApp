import Foundation

extension Validator {
    static func name(_ value: String) -> ValidationResult {
        let v = value.trimmingCharacters(in: .whitespaces)
        if v.isEmpty { return .invalid("Name is required") }
        return v.count < 2 ? .invalid("Enter your full name") : .valid
    }

    static func confirmPassword(_ password: String, _ confirm: String) -> ValidationResult {
        if confirm.isEmpty { return .invalid("Confirm your password") }
        return password == confirm ? .valid : .invalid("Passwords do not match")
    }
}
