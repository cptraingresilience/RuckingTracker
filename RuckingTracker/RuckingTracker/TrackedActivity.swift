//  TrackedActivity.swift
//  Rux

import Foundation
import SwiftUI
import Combine

// 💡 This class is now the only definition for TrackedActivity,
// resolving the ObservableObject conformance error.
class TrackedActivity: ObservableObject, Identifiable, Codable {
    let id: UUID
    @Published var title: String
    @Published var notes: String
    var distance: Double      // in miles
    var duration: TimeInterval
    var pace: Double          // minutes per mile
    var startedAt: Date
    var endedAt: Date?
    @Published var packWeight: Double? // Added @Published to allow editing/observation
    @Published var rpe: Int?           // Rate of Perceived Exertion (1–10), captured post-ruck
    @Published var mapImageName: String?

    // Non-Published properties for DistanceDisplay to avoid optional issues
    var distance_no_optional: Double { distance }
    var duration_no_optional: TimeInterval { duration }
    var pace_no_optional: Double { pace }

    /// Average speed in miles per hour, derived from distance and duration.
    var averageSpeedMph: Double {
        guard duration > 0 else { return 0 }
        return distance / (duration / 3600)
    }

    init(id: UUID = UUID(),
         title: String = "",
         notes: String = "",
         distance: Double,
         duration: TimeInterval,
         pace: Double,
         startedAt: Date = Date(),
         endedAt: Date? = nil,
         packWeight: Double? = nil,
         rpe: Int? = nil,
         mapImageName: String? = nil) {
        self.id = id
        self.title = title
        self.notes = notes
        self.distance = distance
        self.duration = duration
        self.pace = pace
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.packWeight = packWeight
        self.rpe = rpe
        self.mapImageName = mapImageName
    }
    
    // Computed properties for display
    var distanceText: String { String(format: "%.2f", distance) }
    var timeText: String {
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 { return String(format: "%02d:%02d:%02d", hours, minutes, seconds) }
        else { return String(format: "%02d:%02d", minutes, seconds) }
    }
    var paceText: String { String(format: "%.2f", pace) }
    
    enum CodingKeys: CodingKey { case id, title, notes, distance, duration, pace, startedAt, endedAt, mapImageName, packWeight, rpe }
    
    // MARK: - Codable Implementation
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        notes = try container.decode(String.self, forKey: .notes)
        distance = try container.decode(Double.self, forKey: .distance)
        duration = try container.decode(TimeInterval.self, forKey: .duration)
        pace = try container.decode(Double.self, forKey: .pace)
        startedAt = try container.decode(Date.self, forKey: .startedAt)
        endedAt = try container.decodeIfPresent(Date.self, forKey: .endedAt)
        mapImageName = try container.decodeIfPresent(String.self, forKey: .mapImageName)
        packWeight = try container.decodeIfPresent(Double.self, forKey: .packWeight)
        rpe = try container.decodeIfPresent(Int.self, forKey: .rpe)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(notes, forKey: .notes)
        try container.encode(distance, forKey: .distance)
        try container.encode(duration, forKey: .duration)
        try container.encode(pace, forKey: .pace)
        try container.encode(startedAt, forKey: .startedAt)
        try container.encodeIfPresent(endedAt, forKey: .endedAt)
        try container.encodeIfPresent(mapImageName, forKey: .mapImageName)
        try container.encodeIfPresent(packWeight, forKey: .packWeight)
        try container.encodeIfPresent(rpe, forKey: .rpe)
    }
}
