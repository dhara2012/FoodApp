//
//  Formatters.swift
//  FoodApp
//
//  Created by Shubham Trivedi on 03/10/26.
//

import Foundation

extension Decimal {
    /// 560 -> "₹560", 28.5 -> "₹28.5"
    var inr: String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 2
        return "₹" + (f.string(from: self as NSDecimalNumber) ?? "\(self)")
    }
}
