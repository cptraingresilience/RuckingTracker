//
//  Color+Theme.swift
//  Rux
//
//  Created by Picos on 11/12/25.
//

import SwiftUI

extension Color {
    static let ruxPrimary = Color("ruxPrimary") // define in Assets.xcassets
    static let ruxAccent = Color.orange
    static let metricCardBG = Color(UIColor.systemGray5)
    
    static func statusColor(for score: Int) -> Color {
        switch score {
        case let x where x > 150: return .green
        case let x where x > 100: return .yellow
        default: return .red
        }
    }
}
