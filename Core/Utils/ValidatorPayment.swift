import Foundation

extension Validator {
    /// Luhn algorithm થી card number ચકાસણી
    static func cardNumber(_ value: String) -> ValidationResult {
        let digits = value.filter(\.isNumber)
        guard (13...19).contains(digits.count) else { return .invalid("Enter a valid card number") }
        var sum = 0
        for (i, ch) in digits.reversed().enumerated() {
            var n = ch.wholeNumberValue ?? 0
            if i % 2 == 1 { n *= 2; if n > 9 { n -= 9 } }
            sum += n
        }
        return sum % 10 == 0 ? .valid : .invalid("Enter a valid card number")
    }

    /// Format MM/YY, અને expire ન થયેલ હોવું જોઈએ
    static func expiry(_ value: String, now: Date = Date()) -> ValidationResult {
        let parts = value.split(separator: "/")
        guard parts.count == 2, let month = Int(parts[0]), let yy = Int(parts[1]),
              (1...12).contains(month), parts[1].count == 2 else { return .invalid("Use MM/YY format") }
        let c = Calendar.current.dateComponents([.year, .month], from: now)
        let year = 2000 + yy
        if year < (c.year ?? 0) || (year == c.year && month < (c.month ?? 0)) { return .invalid("Card has expired") }
        return .valid
    }

    static func cvv(_ value: String) -> ValidationResult {
        value.range(of: #"^[0-9]{3,4}$"#, options: .regularExpression) == nil
            ? .invalid("Enter a valid CVV") : .valid
    }

    static func upi(_ value: String) -> ValidationResult {
        value.range(of: #"^[a-zA-Z0-9.\-_]{2,}@[a-zA-Z]{2,}$"#, options: .regularExpression) == nil
            ? .invalid("Enter a valid UPI ID (e.g. name@upi)") : .valid
    }
}
