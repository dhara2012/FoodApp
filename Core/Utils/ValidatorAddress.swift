import Foundation

extension Validator {
    static func required(_ value: String, _ field: String) -> ValidationResult {
        value.trimmingCharacters(in: .whitespaces).isEmpty ? .invalid("\(field) is required") : .valid
    }
}
