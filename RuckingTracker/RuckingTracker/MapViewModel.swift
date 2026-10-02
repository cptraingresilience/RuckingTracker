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
    @Published var isPaused: Bool = false
    @Published var isReviewing: Bool = false
    @Published var currentActivity: TrackedActivity?
    @Published var draftActivity: TrackedActivity?
    @Published var showSaveActivity: Bool = false
    @Published var metrics: [Metric] = []
    @Published var distanceMeters: Double = 0
    @Published var elapsedTime: TimeInterval = 0
    @Published var route: [CLLocation] = []
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var statusMessage: String?

    /// Metrics the user has chosen to see live during a ruck (persisted).
    @Published var selectedMetrics: Set<MetricKind> {
        didSet { persistSelectedMetrics() }
    }

    /// Ruck (pack) weight in pounds, set from the metrics drawer (persisted).
    @Published var ruckWeight: Double {
        didSet { UserDefaults.standard.set(ruckWeight, forKey: Self.ruckWeightKey) }
    }

    private static let selectedMetricsKey = "rt_selected_metrics"
    private static let ruckWeightKey = "rt_ruck_weight"

    private let locationManager: LocationManager
    private let activityStore: ActivityStore
    private var cancellables = Set<AnyCancellable>()
    private var timer: Timer?
    private var sessionStartDate: Date?        // wall-clock start of the ruck
    private var accumulatedTime: TimeInterval = 0 // completed active segments
    private var segmentStart: Date?            // start of the current active segment

    init(
        locationManager: LocationManager? = nil,
        activityStore: ActivityStore? = nil
    ) {
        let locationManager = locationManager ?? LocationManager()
        self.locationManager = locationManager
        self.activityStore = activityStore ?? ActivityStore.shared
        authorizationStatus = locationManager.authorizationStatus

        // Restore persisted drawer preferences.
        if let data = UserDefaults.standard.data(forKey: Self.selectedMetricsKey),
           let kinds = try? JSONDecoder().decode(Set<MetricKind>.self, from: data) {
            selectedMetrics = kinds
        } else {
            selectedMetrics = [.distance, .time, .pace]
        }
        ruckWeight = UserDefaults.standard.double(forKey: Self.ruckWeightKey)

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
                    statusMessage = MapViewModel.authorizationGuidance(for: authorizationStatus)
                }
            }
            .store(in: &cancellables)

        statusMessage = Self.authorizationGuidance(for: authorizationStatus)
    }

    var isLocationAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    /// Current average speed in miles per hour, derived from live distance and elapsed time.
    var averageSpeedMph: Double {
        guard elapsedTime > 0 else { return 0 }
        let miles = distanceMeters / 1609.34
        return miles / (elapsedTime / 3600)
    }

    /// Selected metrics with live formatted values, in a stable display order.
    var liveMetrics: [(kind: MetricKind, value: String)] {
        MetricKind.allCases
            .filter { selectedMetrics.contains($0) }
            .map { kind in
                (kind, kind.formattedValue(
                    distanceMeters: distanceMeters,
                    elapsedTime: elapsedTime,
                    averageSpeedMph: averageSpeedMph,
                    ruckWeight: ruckWeight
                ))
            }
    }

    private func persistSelectedMetrics() {
        if let data = try? JSONEncoder().encode(selectedMetrics) {
            UserDefaults.standard.set(data, forKey: Self.selectedMetricsKey)
        }
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
        accumulatedTime = 0
        segmentStart = nil
        sessionStartDate = Date()
        isPaused = false
        isReviewing = false
        draftActivity = nil
        currentActivity = nil
        showSaveActivity = false
        statusMessage = Self.authorizationGuidance(for: authorizationStatus)

        locationManager.startTracking()
    }

    /// Pauses the active ruck. Banks the current segment's time and stops GPS consumption.
    func pauseSession() {
        guard isTracking, !isPaused else { return }

        if let segmentStart {
            accumulatedTime += Date().timeIntervalSince(segmentStart)
        }
        segmentStart = nil
        elapsedTime = accumulatedTime
        stopTimer()
        isPaused = true
        locationManager.pauseTracking()
        statusMessage = "Paused — resume to keep recording."
    }

    /// Resumes a paused ruck, opening a fresh time segment.
    func resumeSession() {
        guard isTracking, isPaused else { return }

        isPaused = false
        segmentStart = Date()
        startTimerIfNeeded()
        locationManager.resumeTracking()
        statusMessage = Self.foregroundOnlyTrackingMessage
    }

    func stopSession() {
        guard isTracking else { return }

        // Bank any in-flight segment before stopping.
        if !isPaused, let segmentStart {
            accumulatedTime += Date().timeIntervalSince(segmentStart)
        }
        segmentStart = nil
        elapsedTime = accumulatedTime

        locationManager.stopTracking() // triggers isTracking sink -> stopTimer()
        isPaused = false
        buildDraftForReview()
    }

    func handleAppMovedToBackground() {
        // Preserve the session by pausing rather than discarding it.
        guard isTracking, !isPaused else { return }
        pauseSession()
    }

    /// Persists the reviewed draft (local + backend sync) and clears live session state.
    func saveReviewedSession(title: String, notes: String, rpe: Int?) {
        guard let draft = draftActivity else { return }

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.title = trimmedTitle.isEmpty ? "Ruck" : trimmedTitle
        draft.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.rpe = rpe

        saveActivity(draft)
        currentActivity = draft
        showSaveActivity = true
        draftActivity = nil
        isReviewing = false
        resetSessionMetrics()
    }

    /// Throws away the draft without saving.
    func discardSession() {
        draftActivity = nil
        isReviewing = false
        showSaveActivity = false
        resetSessionMetrics()
        statusMessage = Self.authorizationGuidance(for: authorizationStatus)
    }

    private func buildDraftForReview() {
        guard distanceMeters > 0, elapsedTime > 0 else {
            // Nothing worth reviewing — reset quietly.
            resetSessionMetrics()
            return
        }

        let draft = TrackedActivity(
            id: UUID(),
            distance: distanceMeters / 1609.34,
            duration: elapsedTime,
            pace: Self.calculatePace(distanceMeters: distanceMeters, elapsedTime: elapsedTime),
            startedAt: sessionStartDate ?? Date(),
            endedAt: Date(),
            packWeight: ruckWeight > 0 ? ruckWeight : nil
        )
        draftActivity = draft
        isReviewing = true
    }

    private func resetSessionMetrics() {
        elapsedTime = 0
        distanceMeters = 0
        accumulatedTime = 0
        segmentStart = nil
        sessionStartDate = nil
        route.removeAll()
    }

    private func saveActivity(_ activity: TrackedActivity) {
        activityStore.addActivity(activity)
    }

    private func startTimerIfNeeded() {
        guard timer == nil else { return }

        if segmentStart == nil {
            segmentStart = Date()
        }

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.elapsedTime = self.currentElapsed()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    /// Total active elapsed time = banked segments + the current open segment.
    private func currentElapsed() -> TimeInterval {
        accumulatedTime + (segmentStart.map { Date().timeIntervalSince($0) } ?? 0)
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
