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

// MARK: - Trackable metric kinds for the MapView metrics drawer
enum MetricKind: String, CaseIterable, Identifiable, Codable {
    case distance
    case time
    case pace
    case speed
    case ruckWeight

    var id: String { rawValue }

    var title: String {
        switch self {
        case .distance: return "Distance"
        case .time: return "Time"
        case .pace: return "Pace"
        case .speed: return "Speed"
        case .ruckWeight: return "Ruck Weight"
        }
    }

    var unit: String {
        switch self {
        case .distance: return "mi"
        case .time: return ""
        case .pace: return "min/mi"
        case .speed: return "mph"
        case .ruckWeight: return "lb"
        }
    }

    var systemImage: String {
        switch self {
        case .distance: return "point.topleft.down.curvedto.point.bottomright.up"
        case .time: return "stopwatch"
        case .pace: return "speedometer"
        case .speed: return "gauge.with.needle"
        case .ruckWeight: return "duffle.bag"
        }
    }

    /// Formats the live value for this metric from current session state.
    func formattedValue(
        distanceMeters: Double,
        elapsedTime: TimeInterval,
        averageSpeedMph: Double,
        ruckWeight: Double
    ) -> String {
        switch self {
        case .distance:
            return String(format: "%.2f mi", distanceMeters / 1609.34)
        case .time:
            return MapView.timeString(elapsedTime)
        case .pace:
            let pace = MapViewModel.calculatePace(distanceMeters: distanceMeters, elapsedTime: elapsedTime)
            return pace > 0 ? String(format: "%.1f /mi", pace) : "--"
        case .speed:
            return String(format: "%.1f mph", averageSpeedMph)
        case .ruckWeight:
            return ruckWeight > 0 ? String(format: "%.0f lb", ruckWeight) : "--"
        }
    }
}
