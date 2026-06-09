//
//  Metric.swift
//  Rux
//
//  Created by Picos on 11/11/25.
//

import Foundation

// MARK: - Metric Model
struct Metric: Identifiable {
    let id = UUID()
    var title: String
    var value: String
    var unit: String?
    var isVisible: Bool
    var isEditable: Bool = false
}
