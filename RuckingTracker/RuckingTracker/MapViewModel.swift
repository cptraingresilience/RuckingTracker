//
//  MapViewModel.swift
//  Rux
//
//  Created by Picos on 11/11/25.
//


import Foundation
import Combine
import CoreLocation

@MainActor // 1. Added @MainActor to resolve the 'shared' property warning
class MapViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var selectedTab: Int = 0
    @Published var isTracking: Bool = false
    @Published var currentActivity: TrackedActivity?
    @Published var showSaveActivity: Bool = false
    @Published var metrics: [Metric] = []
    @Published var distanceMeters: Double = 0
    @Published var elapsedTime: TimeInterval = 0
    @Published var route: [CLLocation] = []

    private let locationManager: LocationManager
    private let activityStore: ActivityStore
    private var cancellables = Set<AnyCancellable>()
    private var timer: Timer?
    private var activityStartTime: Date?

    // MARK: - Init
    init(
        locationManager: LocationManager = LocationManager(),
        activityStore: ActivityStore = ActivityStore.shared
    ) {
        self.locationManager = locationManager
        self.activityStore = activityStore

        // Bind location updates
        locationManager.$route
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newRoute in
                self?.route = newRoute
                self?.distanceMeters = Self.calculateDistance(for: newRoute)
            }
            .store(in: &cancellables)

        locationManager.$isTracking
            .receive(on: DispatchQueue.main)
            .assign(to: &$isTracking)
    }

    // MARK: - Tracking Session
    func startSession() {
        activityStartTime = Date()
        elapsedTime = 0
        route.removeAll()
        distanceMeters = 0

        locationManager.startTracking()
        isTracking = true

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            // FIX: Use Task { @MainActor in ... } to correctly access isolated properties
            Task { @MainActor in
                guard let self = self, let start = self.activityStartTime else { return }
                self.elapsedTime = Date().timeIntervalSince(start)
            }
        }
    }

    func stopSession() {
        locationManager.stopTracking()
        isTracking = false
        timer?.invalidate()
        timer = nil

        // Save activity
        if distanceMeters > 0 && elapsedTime > 0 {
            let newActivity = TrackedActivity(
                id: UUID(),
                distance: distanceMeters / 1609.34, // meters to miles
                duration: elapsedTime,
                pace: Self.calculatePace(distanceMeters: distanceMeters, elapsedTime: elapsedTime),
                startedAt: activityStartTime ?? Date())
            currentActivity = newActivity
            saveActivity(newActivity)
            showSaveActivity = true
        }
    }

    private func saveActivity(_ activity: TrackedActivity) {
        // 2. Removed Task/await. Since both ViewModels are @MainActor,
        // the synchronous call to addActivity is safe and executes directly on the main thread.
        activityStore.addActivity(activity)
    }

    // MARK: - Metric Helpers
    static func calculateDistance(for route: [CLLocation]) -> Double {
        guard route.count > 1 else { return 0 }
        var total: Double = 0
        for i in 1..<route.count {
            total += route[i].distance(from: route[i-1])
        }
        return total
    }

    static func calculatePace(distanceMeters: Double, elapsedTime: TimeInterval) -> Double {
        let miles = distanceMeters / 1609.34
        guard miles > 0 else { return 0 }
        let minutes = elapsedTime / 60
        return minutes / miles // min/mi
    }
}
