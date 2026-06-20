import CoreLocation
import Foundation

enum AppConfigurationPolicy {
    private static let maximumTokenLength = 1024
    private static let maximumStyleURLLength = 2048
    private static let allowedTokenCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._-")
    private static let sensitiveQueryNames: Set<String> = ["access_token", "api_key", "apikey", "key", "token"]

    static func coordinate(
        latitudeValue: Any?,
        longitudeValue: Any?,
        fallback: CLLocationCoordinate2D
    ) -> CLLocationCoordinate2D {
        guard let latitude = coordinateComponent(from: latitudeValue),
              let longitude = coordinateComponent(from: longitudeValue) else {
            return fallback
        }

        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        guard CLLocationCoordinate2DIsValid(coordinate),
              !(coordinate.latitude == 0 && coordinate.longitude == 0) else {
            return fallback
        }

        return coordinate
    }

    static func mapboxAccessToken(from rawValue: Any?) -> String? {
        guard let token = normalizedString(from: rawValue, maximumLength: maximumTokenLength),
              token.hasPrefix("pk."),
              token.rangeOfCharacter(from: allowedTokenCharacters.inverted) == nil else {
            return nil
        }

        return token
    }

    static func mapStyleURL(from rawValue: Any?) -> URL? {
        guard let rawURL = normalizedString(from: rawValue, maximumLength: maximumStyleURLLength),
              let components = URLComponents(string: rawURL),
              components.user == nil,
              components.password == nil,
              components.fragment == nil,
              let scheme = components.scheme?.lowercased() else {
            return nil
        }

        if let queryItems = components.queryItems,
           queryItems.contains(where: { sensitiveQueryNames.contains($0.name.lowercased()) }) {
            return nil
        }

        switch scheme {
        case "mapbox":
            guard components.host?.lowercased() == "styles",
                  components.port == nil,
                  components.query == nil,
                  validMapboxStylePath(components.percentEncodedPath) else {
                return nil
            }
        case "https":
            guard let host = components.host, !host.isEmpty else {
                return nil
            }
        default:
            return nil
        }

        return components.url
    }

    private static func coordinateComponent(from rawValue: Any?) -> CLLocationDegrees? {
        guard let value = normalizedString(from: rawValue, maximumLength: 64),
              let number = Double(value),
              number.isFinite else {
            return nil
        }

        return number
    }

    private static func normalizedString(from rawValue: Any?, maximumLength: Int) -> String? {
        guard let stringValue = rawValue as? String else {
            return nil
        }

        let value = stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty,
              value.utf8.count <= maximumLength,
              !value.contains("$("),
              value.rangeOfCharacter(from: .controlCharacters) == nil else {
            return nil
        }

        return value
    }

    private static func validMapboxStylePath(_ percentEncodedPath: String) -> Bool {
        let components = percentEncodedPath.split(separator: "/", omittingEmptySubsequences: true)
        guard components.count == 2 else {
            return false
        }

        return components.allSatisfy { component in
            guard let decoded = String(component).removingPercentEncoding,
                  !decoded.isEmpty,
                  decoded != ".",
                  decoded != "..",
                  decoded.rangeOfCharacter(from: .controlCharacters) == nil,
                  !decoded.contains("/"),
                  !decoded.contains("\\") else {
                return false
            }
            return true
        }
    }
}

enum LocationSamplePolicy {
    private static let maximumAge: TimeInterval = 30
    private static let maximumFutureSkew: TimeInterval = 5
    private static let maximumHorizontalAccuracy: CLLocationAccuracy = 100

    static func accepts(_ location: CLLocation, now: Date = Date()) -> Bool {
        let coordinate = location.coordinate
        let age = now.timeIntervalSince(location.timestamp)

        return CLLocationCoordinate2DIsValid(coordinate) &&
            !(coordinate.latitude == 0 && coordinate.longitude == 0) &&
            location.horizontalAccuracy.isFinite &&
            location.horizontalAccuracy >= 0 &&
            location.horizontalAccuracy <= maximumHorizontalAccuracy &&
            age >= -maximumFutureSkew &&
            age <= maximumAge
    }
}

enum LocationAuthorizationState {
    case notDetermined
    case restricted
    case denied
    case authorized
}

enum LocationTrackingPolicy {
    static func shouldRequestAuthorization(
        status: LocationAuthorizationState,
        isViewVisible: Bool,
        isMapReady: Bool,
        hasRequestedAuthorization: Bool
    ) -> Bool {
        return status == .notDetermined &&
            isViewVisible &&
            isMapReady &&
            !hasRequestedAuthorization
    }

    static func shouldStartUpdates(
        status: LocationAuthorizationState,
        isViewVisible: Bool,
        isMapReady: Bool
    ) -> Bool {
        return isAuthorized(status) && isViewVisible && isMapReady
    }

    static func shouldAccept(
        _ location: CLLocation,
        status: LocationAuthorizationState,
        isViewVisible: Bool,
        isAwaitingLocation: Bool,
        now: Date = Date()
    ) -> Bool {
        return isAuthorized(status) &&
            isViewVisible &&
            isAwaitingLocation &&
            LocationSamplePolicy.accepts(location, now: now)
    }

    private static func isAuthorized(_ status: LocationAuthorizationState) -> Bool {
        return status == .authorized
    }
}
