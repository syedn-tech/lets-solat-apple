import Foundation
import CoreLocation
import Combine

public final class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    public static let shared = LocationService()
    
    private let manager = CLLocationManager()
    
    @Published public var currentLocation: CLLocation?
    @Published public var authorizationStatus: CLAuthorizationStatus
    @Published public var locationError: String?
    
    public override init() {
        self.authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }
    
    public func requestAuthorization() {
        #if os(macOS)
        // On macOS, calling startUpdatingLocation or requestLocation triggers the system prompt
        manager.startUpdatingLocation()
        #else
        manager.requestWhenInUseAuthorization()
        #endif
    }
    
    public func requestCurrentLocation() {
        #if os(macOS)
        manager.startUpdatingLocation()
        #else
        if authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
        manager.requestLocation()
        #endif
    }
    
    public func startUpdatingLocation() {
        manager.startUpdatingLocation()
    }
    
    public func stopUpdatingLocation() {
        manager.stopUpdatingLocation()
    }
    
    // MARK: - CLLocationManagerDelegate
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
            #if os(macOS)
            if manager.authorizationStatus == .authorized || manager.authorizationStatus == .authorizedAlways {
                manager.startUpdatingLocation()
            }
            #else
            if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
                manager.requestLocation()
            }
            #endif
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        #if os(macOS)
        manager.stopUpdatingLocation()
        #endif
        DispatchQueue.main.async {
            self.currentLocation = location
            self.locationError = nil
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.locationError = error.localizedDescription
        }
    }
}
