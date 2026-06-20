import CoreLocation
import XCTest
@testable import ScavengerHuntPolicies

final class AppConfigurationPolicyTests: XCTestCase {
    private let fallback = CLLocationCoordinate2D(latitude: 37.890576, longitude: -122.472104)

    func testCoordinateAcceptsACompleteFinitePair() {
        let coordinate = AppConfigurationPolicy.coordinate(
            latitudeValue: "37.1",
            longitudeValue: "-122.2",
            fallback: fallback
        )

        XCTAssertEqual(coordinate.latitude, 37.1)
        XCTAssertEqual(coordinate.longitude, -122.2)
    }

    func testCoordinateRejectsNullIslandSentinel() {
        let coordinate = AppConfigurationPolicy.coordinate(
            latitudeValue: "0",
            longitudeValue: "-0.0",
            fallback: fallback
        )

        XCTAssertEqual(coordinate.latitude, fallback.latitude)
        XCTAssertEqual(coordinate.longitude, fallback.longitude)
    }

    func testCoordinateRejectsNonFiniteValues() {
        let coordinate = AppConfigurationPolicy.coordinate(
            latitudeValue: "nan",
            longitudeValue: "-122.2",
            fallback: fallback
        )

        XCTAssertEqual(coordinate.latitude, fallback.latitude)
        XCTAssertEqual(coordinate.longitude, fallback.longitude)
    }

    func testCoordinateRejectsOutOfRangeValues() {
        let coordinate = AppConfigurationPolicy.coordinate(
            latitudeValue: "90.0001",
            longitudeValue: "-122.2",
            fallback: fallback
        )

        XCTAssertEqual(coordinate.latitude, fallback.latitude)
        XCTAssertEqual(coordinate.longitude, fallback.longitude)
    }

    func testCoordinateRejectsPartialOrUnresolvedValues() {
        let partial = AppConfigurationPolicy.coordinate(
            latitudeValue: "37.1",
            longitudeValue: nil,
            fallback: fallback
        )
        let unresolved = AppConfigurationPolicy.coordinate(
            latitudeValue: "$(MAP_CENTER_LATITUDE)",
            longitudeValue: "-122.2",
            fallback: fallback
        )

        XCTAssertEqual(partial.latitude, fallback.latitude)
        XCTAssertEqual(unresolved.latitude, fallback.latitude)
    }

    func testMapboxTokenAcceptsAReasonablePublicToken() {
        XCTAssertEqual(
            AppConfigurationPolicy.mapboxAccessToken(from: "pk.example_123-ABC.def"),
            "pk.example_123-ABC.def"
        )
    }

    func testMapboxTokenRejectsSecretsPlaceholdersAndControlCharacters() {
        XCTAssertNil(AppConfigurationPolicy.mapboxAccessToken(from: "sk.secret"))
        XCTAssertNil(AppConfigurationPolicy.mapboxAccessToken(from: "replace-with-mapbox-public-token"))
        XCTAssertNil(AppConfigurationPolicy.mapboxAccessToken(from: "pk.value\nsecond-line"))
    }

    func testMapboxTokenRejectsOversizedValues() {
        XCTAssertNil(AppConfigurationPolicy.mapboxAccessToken(from: "pk." + String(repeating: "a", count: 1024)))
    }

    func testMapStyleURLAcceptsCredentialFreeMapboxAndHTTPSStyles() {
        XCTAssertEqual(
            AppConfigurationPolicy.mapStyleURL(from: "mapbox://styles/owner/style")?.absoluteString,
            "mapbox://styles/owner/style"
        )
        XCTAssertEqual(
            AppConfigurationPolicy.mapStyleURL(from: "https://maps.example.test/styles/event.json")?.absoluteString,
            "https://maps.example.test/styles/event.json"
        )
    }

    func testMapStyleURLRejectsCredentialsAndSensitiveQueryItems() {
        XCTAssertNil(AppConfigurationPolicy.mapStyleURL(from: "https://user:pass@maps.example.test/style"))
        XCTAssertNil(AppConfigurationPolicy.mapStyleURL(from: "https://maps.example.test/style?Access_Token=value"))
        XCTAssertNil(AppConfigurationPolicy.mapStyleURL(from: "https://maps.example.test/style?api_key=value"))
    }

    func testMapStyleURLRejectsFragmentsAndOversizedValues() {
        XCTAssertNil(AppConfigurationPolicy.mapStyleURL(from: "https://maps.example.test/style#token=value"))
        XCTAssertNil(AppConfigurationPolicy.mapStyleURL(from: "https://maps.example.test/" + String(repeating: "a", count: 2048)))
    }

    func testMapboxStyleURLRequiresExactlyOwnerAndStylePathComponents() {
        XCTAssertNil(AppConfigurationPolicy.mapStyleURL(from: "mapbox://styles/owner"))
        XCTAssertNil(AppConfigurationPolicy.mapStyleURL(from: "mapbox://styles/owner/style/extra"))
        XCTAssertNil(AppConfigurationPolicy.mapStyleURL(from: "mapbox://styles/../style"))
    }
}

final class LocationSamplePolicyTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 10_000)

    func testAcceptsFreshAccurateLocation() {
        let location = makeLocation(latitude: 37.1, longitude: -122.2, accuracy: 25, age: 5)

        XCTAssertTrue(LocationSamplePolicy.accepts(location, now: now))
    }

    func testRejectsStaleLocation() {
        let location = makeLocation(latitude: 37.1, longitude: -122.2, accuracy: 25, age: 31)

        XCTAssertFalse(LocationSamplePolicy.accepts(location, now: now))
    }

    func testRejectsImplausiblyFutureLocation() {
        let location = makeLocation(latitude: 37.1, longitude: -122.2, accuracy: 25, age: -6)

        XCTAssertFalse(LocationSamplePolicy.accepts(location, now: now))
    }

    func testRejectsInvalidOrInaccurateLocation() {
        let invalidAccuracy = makeLocation(latitude: 37.1, longitude: -122.2, accuracy: -1, age: 5)
        let poorAccuracy = makeLocation(latitude: 37.1, longitude: -122.2, accuracy: 101, age: 5)
        let sentinel = makeLocation(latitude: 0, longitude: 0, accuracy: 25, age: 5)

        XCTAssertFalse(LocationSamplePolicy.accepts(invalidAccuracy, now: now))
        XCTAssertFalse(LocationSamplePolicy.accepts(poorAccuracy, now: now))
        XCTAssertFalse(LocationSamplePolicy.accepts(sentinel, now: now))
    }

    private func makeLocation(
        latitude: CLLocationDegrees,
        longitude: CLLocationDegrees,
        accuracy: CLLocationAccuracy,
        age: TimeInterval
    ) -> CLLocation {
        CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            altitude: 0,
            horizontalAccuracy: accuracy,
            verticalAccuracy: 0,
            timestamp: now.addingTimeInterval(-age)
        )
    }
}

final class LocationTrackingPolicyTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 10_000)

    func testAuthorizationRequestWaitsForVisibleConfiguredMap() {
        XCTAssertFalse(LocationTrackingPolicy.shouldRequestAuthorization(
            status: .notDetermined,
            isViewVisible: false,
            isMapReady: true,
            hasRequestedAuthorization: false
        ))
        XCTAssertFalse(LocationTrackingPolicy.shouldRequestAuthorization(
            status: .notDetermined,
            isViewVisible: true,
            isMapReady: false,
            hasRequestedAuthorization: false
        ))
        XCTAssertTrue(LocationTrackingPolicy.shouldRequestAuthorization(
            status: .notDetermined,
            isViewVisible: true,
            isMapReady: true,
            hasRequestedAuthorization: false
        ))
    }

    func testAuthorizationRequestIsNotRepeatedOrRequestedAfterDecision() {
        XCTAssertFalse(LocationTrackingPolicy.shouldRequestAuthorization(
            status: .notDetermined,
            isViewVisible: true,
            isMapReady: true,
            hasRequestedAuthorization: true
        ))
        XCTAssertFalse(LocationTrackingPolicy.shouldRequestAuthorization(
            status: .denied,
            isViewVisible: true,
            isMapReady: true,
            hasRequestedAuthorization: false
        ))
    }

    func testLocationUpdatesRequireVisibleAuthorizedConfiguredMap() {
        XCTAssertTrue(LocationTrackingPolicy.shouldStartUpdates(
            status: .authorized,
            isViewVisible: true,
            isMapReady: true
        ))
        XCTAssertFalse(LocationTrackingPolicy.shouldStartUpdates(
            status: .authorized,
            isViewVisible: false,
            isMapReady: true
        ))
        XCTAssertFalse(LocationTrackingPolicy.shouldStartUpdates(
            status: .denied,
            isViewVisible: true,
            isMapReady: true
        ))
    }

    func testStaleSessionCallbackIsRejected() {
        let location = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 37.1, longitude: -122.2),
            altitude: 0,
            horizontalAccuracy: 25,
            verticalAccuracy: 0,
            timestamp: now.addingTimeInterval(-5)
        )

        XCTAssertFalse(LocationTrackingPolicy.shouldAccept(
            location,
            status: .authorized,
            isViewVisible: false,
            isAwaitingLocation: true,
            now: now
        ))
        XCTAssertFalse(LocationTrackingPolicy.shouldAccept(
            location,
            status: .authorized,
            isViewVisible: true,
            isAwaitingLocation: false,
            now: now
        ))
        XCTAssertTrue(LocationTrackingPolicy.shouldAccept(
            location,
            status: .authorized,
            isViewVisible: true,
            isAwaitingLocation: true,
            now: now
        ))
    }
}
