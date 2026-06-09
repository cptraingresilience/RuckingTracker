//
//  Date+Formatting.swift
//  Rux
//
//  Created by Picos on 11/12/25.
//

import Foundation

extension Date {
    /// Returns date as "MMM d, yyyy" (e.g., Nov 12, 2025)
    func formattedShort() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: self)
    }
    
    /// Returns date as "h:mm a" (e.g., 6:21 PM)
    func formattedTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: self)
    }
    
    /// Returns relative time (e.g., "2 days ago")
    func timeAgo() -> String {
        let interval = -self.timeIntervalSinceNow
        let min = 60.0, hour = 3600.0, day = 86400.0
        switch interval {
        case let x where x < min:
            return "\(Int(x))s ago"
        case let x where x < hour:
            return "\(Int(x/min))m ago"
        case let x where x < day:
            return "\(Int(x/hour))h ago"
        default:
            return "\(Int(interval/day))d ago"
        }
    }
}
