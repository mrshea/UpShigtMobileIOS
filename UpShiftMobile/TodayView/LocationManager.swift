//
//  LocationManager.swift
//  UpShiftMobile
//
//  Created by Michael Shea on 12/3/25.
//

internal import CoreLocation
import Combine
import UIKit

@MainActor
class LocationManager: NSObject, ObservableObject {
  @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
  @Published var currentLocation: CLLocation?
  @Published var isUpdatingLocation = false
  @Published var locationError: LocationError?

  private let locationManager = CLLocationManager()
  private var locationContinuation: CheckedContinuation<CLLocation, Error>?

  static let requiredProximityRadius: Double = 100.0 // meters
  static let checkInWindowBefore: TimeInterval = 15 * 60 // 15 minutes
  static let checkInWindowAfter: TimeInterval = 30 * 60 // 30 minutes

  override init() {
    super.init()
    locationManager.delegate = self
    locationManager.desiredAccuracy = kCLLocationAccuracyBest
    locationManager.distanceFilter = 10
    authorizationStatus = locationManager.authorizationStatus
  }

  func requestWhenInUseAuthorization() {
    locationManager.requestWhenInUseAuthorization()
  }

  func getCurrentLocation() async throws -> CLLocation {
    guard authorizationStatus == .authorizedWhenInUse ||
          authorizationStatus == .authorizedAlways else {
      throw LocationError.unauthorized
    }

    isUpdatingLocation = true
    defer { isUpdatingLocation = false }

    return try await withCheckedThrowingContinuation { continuation in
      self.locationContinuation = continuation
      locationManager.requestLocation()
    }
  }

  func verifyProximity(
    userLocation: CLLocation,
    shiftLocation: ShiftLocation
  ) -> LocationVerification {
    let shiftCLLocation = CLLocation(
      latitude: shiftLocation.latitude,
      longitude: shiftLocation.longitude
    )

    let distance = userLocation.distance(from: shiftCLLocation)
    let isWithin = distance <= shiftLocation.radius

    return LocationVerification(
      isWithinRadius: isWithin,
      distanceInMeters: distance,
      userLatitude: userLocation.coordinate.latitude,
      userLongitude: userLocation.coordinate.longitude
    )
  }

  func openSettings() {
    if let url = URL(string: UIApplication.openSettingsURLString) {
      UIApplication.shared.open(url)
    }
  }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
  nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    Task { @MainActor in
      authorizationStatus = manager.authorizationStatus
    }
  }

  nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    Task { @MainActor in
      guard let location = locations.last else { return }
      currentLocation = location

      if let continuation = locationContinuation {
        locationContinuation = nil
        continuation.resume(returning: location)
      }
    }
  }

  nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    Task { @MainActor in
      locationError = .updateFailed(error.localizedDescription)

      if let continuation = locationContinuation {
        locationContinuation = nil
        continuation.resume(throwing: LocationError.updateFailed(error.localizedDescription))
      }
    }
  }
}

// MARK: - Location Error

enum LocationError: LocalizedError {
  case unauthorized
  case updateFailed(String)
  case outsideRadius(Double)
  case timeout

  var errorDescription: String? {
    switch self {
    case .unauthorized:
      return "Location access is required to check in. Please enable location services in Settings."
    case .updateFailed(let message):
      return "Failed to get your location: \(message)"
    case .outsideRadius(let distance):
      let distanceStr = distance < 1000 ?
        "\(Int(distance))m" :
        String(format: "%.1fkm", distance / 1000)
      return "You are \(distanceStr) from the shift location. Please move closer to check in."
    case .timeout:
      return "Location request timed out. Please try again."
    }
  }
}
