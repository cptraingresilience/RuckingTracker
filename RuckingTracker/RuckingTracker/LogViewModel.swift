///
//  LogViewModel.swift
//  Rux
//
//  Created by Picos on 11/11/25.
//

import Foundation
import Combine

@MainActor
class LogViewModel: ObservableObject {
    @Published var activities: [TrackedActivity] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    // FIX: Make the parameter optional (ActivityStore?) and remove the default assignment
    // to resolve the Swift 6 warning.
    init(activityStore: ActivityStore? = nil) {
        // Resolve dependency: use injected store or safely access the isolated static 'shared' property
        let store = activityStore ?? ActivityStore.shared
        
        // Automatically observe updates from ActivityStore
        store.$activities
            .receive(on: DispatchQueue.main)
            .assign(to: &$activities)
    }
    
    // MARK: - Aggregated Metrics
    var totalMiles: Double {
        activities.reduce(0) { $0 + $1.distance }
    }
    
    var avgPaceString: String {
        guard !activities.isEmpty else { return "0:00" }
        let totalPace = activities.reduce(0) { $0 + $1.pace }
        let avg = totalPace / Double(activities.count)
        let minutes = Int(avg)
        let seconds = Int((avg - Double(minutes)) * 60)
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var totalTimeString: String {
        let totalSeconds = Int(activities.reduce(0) { $0 + $1.duration })
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
    
    var bestRuckDistanceString: String {
        let maxDistance = activities.map { $0.distance }.max() ?? 0
        return String(format: "%.1f", maxDistance)
    }
}


