import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentLocation: CLLocation?
    @Published var isTracking: Bool = false
    @Published var route: [CLLocation] = []
    
    private let manager = CLLocationManager()
    
    override init() {
        super.init()
        manager.delegate = self
    }
    
    // Request location permission
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    // Start updating location
    func startTracking() {
        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            route.removeAll()
            isTracking = true
            manager.startUpdatingLocation()
        } else {
            requestPermission()
        }
    }
    
    // Stop updating location
    func stopTracking() {
        isTracking = false
        manager.stopUpdatingLocation()
    }
    
    // CLLocationManager Delegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isTracking else { return }
        route.append(contentsOf: locations)
        currentLocation = locations.last
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }
}
