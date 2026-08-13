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
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private static let isRunningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    private let store: ActivityStore
    private var cancellables = Set<AnyCancellable>()
    
    init(activityStore: ActivityStore? = nil) {
        self.store = activityStore ?? ActivityStore.shared
        
        store.$activities
            .receive(on: DispatchQueue.main)
            .assign(to: &$activities)

        store.$lastSyncError
            .receive(on: DispatchQueue.main)
            .assign(to: &$errorMessage)

        if !Self.isRunningTests {
            Task {
                await refresh()
            }
        }
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

    func refresh() async {
        isLoading = true
        await store.refreshFromBackendIfAvailable()
        isLoading = false
    }

    func deleteActivity(_ activity: TrackedActivity) {
        store.delete(activity)
    }

    func clearError() {
        store.clearSyncError()
    }
}
