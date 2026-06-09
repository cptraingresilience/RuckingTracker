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
    @Published var packWeight: Double? // Added @Published to allow editing/observation
    @Published var mapImageName: String?
    
    // Non-Published properties for DistanceDisplay to avoid optional issues
    var distance_no_optional: Double { distance }
    var duration_no_optional: TimeInterval { duration }
    var pace_no_optional: Double { pace }

    init(id: UUID = UUID(),
         title: String = "",
         notes: String = "",
         distance: Double,
         duration: TimeInterval,
         pace: Double,
         startedAt: Date = Date(),
         packWeight: Double? = nil,
         mapImageName: String? = nil) {
        self.id = id
        self.title = title
        self.notes = notes
        self.distance = distance
        self.duration = duration
        self.pace = pace
        self.startedAt = startedAt
        self.packWeight = packWeight
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
    
    enum CodingKeys: CodingKey { case id, title, notes, distance, duration, pace, startedAt, mapImageName, packWeight }
    
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
        mapImageName = try container.decodeIfPresent(String.self, forKey: .mapImageName)
        packWeight = try container.decodeIfPresent(Double.self, forKey: .packWeight)
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
        try container.encodeIfPresent(mapImageName, forKey: .mapImageName)
        try container.encodeIfPresent(packWeight, forKey: .packWeight)
    }
}
