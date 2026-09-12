import Foundation
import CoreLocation
import Combine

@MainActor
final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let foregroundOnlyTrackingMessage = "Tracking works only while Rux stays open and the iPhone remains unlocked for this MVP."

    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    @Published private(set) var currentLocation: CLLocation?
    @Published private(set) var isTracking: Bool = false
    @Published private(set) var route: [CLLocation] = []
    @Published private(set) var lastErrorMessage: String?

    let supportsBackgroundTracking = false

    private let manager: CLLocationManager
    private var pendingStartAfterAuthorization = false

    override init() {
        let manager = CLLocationManager()
        self.manager = manager
        authorizationStatus = manager.authorizationStatus
        currentLocation = manager.location

        super.init()

        manager.delegate = self
        manager.activityType = .fitness
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 5
        manager.pausesLocationUpdatesAutomatically = false
        manager.allowsBackgroundLocationUpdates = false
        if #available(iOS 11.0, *) {
            manager.showsBackgroundLocationIndicator = false
        }
    }

    func requestPermission() {
        lastErrorMessage = nil

        switch authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied:
            lastErrorMessage = "Location access is off. Enable While Using the App in Settings to record a ruck."
        case .restricted:
            lastErrorMessage = "Location access is restricted on this device."
        case .authorizedAlways, .authorizedWhenInUse:
            break
        @unknown default:
            lastErrorMessage = "Location access is unavailable right now."
        }
    }

    func startTracking() {
        lastErrorMessage = nil

        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            pendingStartAfterAuthorization = false
            route.removeAll()
            currentLocation = manager.location
            isTracking = true
            manager.startUpdatingLocation()
        case .notDetermined:
            pendingStartAfterAuthorization = true
            requestPermission()
        case .denied:
            pendingStartAfterAuthorization = false
            isTracking = false
            lastErrorMessage = "Location access is off. Enable While Using the App in Settings to record a ruck."
        case .restricted:
            pendingStartAfterAuthorization = false
            isTracking = false
            lastErrorMessage = "Location access is restricted on this device."
        @unknown default:
            pendingStartAfterAuthorization = false
            isTracking = false
            lastErrorMessage = "Location access is unavailable right now."
        }
    }

    func stopTracking() {
        pendingStartAfterAuthorization = false
        isTracking = false
        manager.stopUpdatingLocation()
    }

    func stopTrackingBecauseAppLeftForeground() {
        guard isTracking else { return }
        stopTracking()
        lastErrorMessage = "Tracking stopped because Rux left the foreground. Keep the app open and unlocked during a ruck."
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isTracking else { return }

        let validLocations = locations.filter {
            $0.horizontalAccuracy >= 0 && abs($0.timestamp.timeIntervalSinceNow) <= 15
        }

        guard !validLocations.isEmpty else { return }

        route.append(contentsOf: validLocations)
        currentLocation = validLocations.last
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        lastErrorMessage = error.localizedDescription
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            if pendingStartAfterAuthorization {
                startTracking()
            }
        case .denied:
            pendingStartAfterAuthorization = false
            if isTracking {
                stopTracking()
            }
            lastErrorMessage = "Location access is off. Enable While Using the App in Settings to record a ruck."
        case .restricted:
            pendingStartAfterAuthorization = false
            if isTracking {
                stopTracking()
            }
            lastErrorMessage = "Location access is restricted on this device."
        case .notDetermined:
            break
        @unknown default:
            pendingStartAfterAuthorization = false
            lastErrorMessage = "Location access is unavailable right now."
        }
    }
}
