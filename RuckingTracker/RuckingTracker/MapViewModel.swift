//
//  MapViewModel.swift
//  Rux
//
//  Created by Picos on 11/11/25.
//


import Foundation
import Combine
import CoreLocation
import UIKit

@MainActor
final class MapViewModel: ObservableObject {
    static let foregroundOnlyTrackingMessage = LocationManager.foregroundOnlyTrackingMessage

    @Published var selectedTab: Int = 0
    @Published var isTracking: Bool = false
    @Published var currentActivity: TrackedActivity?
    @Published var showSaveActivity: Bool = false
    @Published var metrics: [Metric] = []
    @Published var distanceMeters: Double = 0
    @Published var elapsedTime: TimeInterval = 0
    @Published var route: [CLLocation] = []
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var statusMessage: String?

    private let locationManager: LocationManager
    private let activityStore: ActivityStore
    private var cancellables = Set<AnyCancellable>()
    private var timer: Timer?
    private var activityStartTime: Date?

    init(
        locationManager: LocationManager = LocationManager(),
        activityStore: ActivityStore = ActivityStore.shared
    ) {
        self.locationManager = locationManager
        self.activityStore = activityStore
        authorizationStatus = locationManager.authorizationStatus

        locationManager.$route
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newRoute in
                self?.route = newRoute
                self?.distanceMeters = Self.calculateDistance(for: newRoute)
            }
            .store(in: &cancellables)

        locationManager.$isTracking
            .receive(on: DispatchQueue.main)
            .sink { [weak self] tracking in
                guard let self else { return }
                isTracking = tracking

                if tracking {
                    currentActivity = nil
                    showSaveActivity = false
                    statusMessage = Self.foregroundOnlyTrackingMessage
                    startTimerIfNeeded()
                } else {
                    stopTimer()
                }
            }
            .store(in: &cancellables)

        locationManager.$authorizationStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self else { return }
                authorizationStatus = status
                if !isTracking {
                    statusMessage = locationManager.lastErrorMessage ?? Self.authorizationGuidance(for: status)
                }
            }
            .store(in: &cancellables)

        locationManager.$lastErrorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                guard let self else { return }

                if let message {
                    statusMessage = message
                } else if !isTracking {
                    statusMessage = authorizationGuidance(for: authorizationStatus)
                }
            }
            .store(in: &cancellables)

        statusMessage = Self.authorizationGuidance(for: authorizationStatus)
    }

    var isLocationAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    var permissionButtonTitle: String {
        switch authorizationStatus {
        case .notDetermined:
            return "Allow Location Access"
        case .denied, .restricted:
            return "Open Settings"
        case .authorizedAlways, .authorizedWhenInUse:
            return "Start Ruck"
        @unknown default:
            return "Location Unavailable"
        }
    }

    func startSession() {
        guard !isTracking else { return }

        if authorizationStatus == .denied || authorizationStatus == .restricted {
            statusMessage = Self.authorizationGuidance(for: authorizationStatus)
            openAppSettings()
            return
        }

        elapsedTime = 0
        route.removeAll()
        distanceMeters = 0
        activityStartTime = nil
        currentActivity = nil
        showSaveActivity = false
        statusMessage = Self.authorizationGuidance(for: authorizationStatus)

        locationManager.startTracking()
    }

    func stopSession() {
        guard isTracking else { return }

        locationManager.stopTracking()
        finalizeSession()
    }

    func handleAppMovedToBackground() {
        guard isTracking else { return }

        locationManager.stopTrackingBecauseAppLeftForeground()
        finalizeSession()
    }

    private func saveActivity(_ activity: TrackedActivity) {
        activityStore.addActivity(activity)
    }

    private func startTimerIfNeeded() {
        guard timer == nil else { return }

        if activityStartTime == nil {
            activityStartTime = Date()
        }

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let start = self.activityStartTime else { return }
                self.elapsedTime = Date().timeIntervalSince(start)
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func finalizeSession() {
        if let start = activityStartTime {
            elapsedTime = Date().timeIntervalSince(start)
        }

        defer {
            activityStartTime = nil
        }

        guard distanceMeters > 0, elapsedTime > 0 else { return }

        let newActivity = TrackedActivity(
            id: UUID(),
            distance: distanceMeters / 1609.34,
            duration: elapsedTime,
            pace: Self.calculatePace(distanceMeters: distanceMeters, elapsedTime: elapsedTime),
            startedAt: activityStartTime ?? Date()
        )
        currentActivity = newActivity
        saveActivity(newActivity)
        showSaveActivity = true
    }

    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private static func authorizationGuidance(for status: CLAuthorizationStatus) -> String {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            return foregroundOnlyTrackingMessage
        case .notDetermined:
            return "Allow While Using the App location access before starting a ruck."
        case .denied:
            return "Location access is off. Open Settings and allow While Using the App to record distance and route."
        case .restricted:
            return "Location access is restricted on this device."
        @unknown default:
            return "Location access is unavailable right now."
        }
    }

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
