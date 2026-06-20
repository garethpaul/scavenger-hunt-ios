import CoreLocation
import Mapbox
import UIKit

final class ViewController: UIViewController, CLLocationManagerDelegate, MGLMapViewDelegate {
    private let locationManager = CLLocationManager()
    private var mapView: MGLMapView?
    private var didAddPrizeAnnotation = false
    private var hasRequestedAuthorization = false
    private var isAwaitingLocation = false
    private var isViewVisible = false

    private let demoMapCenterCoordinate = CLLocationCoordinate2D(
        latitude: 37.890576,
        longitude: -122.472104
    )
    private let demoPrizeCoordinate = CLLocationCoordinate2D(
        latitude: 37.826815,
        longitude: -122.4992434
    )

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.titleView = UIImageView(image: UIImage(named: "Logo"))
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = kCLDistanceFilterNone
        configureMap()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        isViewVisible = true
        addPrizeAnnotationIfNeeded()

        let status = CLLocationManager.authorizationStatus()
        let state = authorizationState(for: status)
        if LocationTrackingPolicy.shouldRequestAuthorization(
            status: state,
            isViewVisible: isViewVisible,
            isMapReady: mapView != nil,
            hasRequestedAuthorization: hasRequestedAuthorization
        ) {
            hasRequestedAuthorization = true
            locationManager.requestWhenInUseAuthorization()
        } else {
            synchronizeLocationTracking(for: status)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        isViewVisible = false
        stopLocationTracking()
    }

    private func configureMap() {
        guard let token = AppConfigurationPolicy.mapboxAccessToken(
            from: Bundle.main.object(forInfoDictionaryKey: "MGLMapboxAccessToken")
        ) else {
            showConfigurationError()
            return
        }

        MGLAccountManager.setAccessToken(token)
        let configuredMapView = MGLMapView(
            frame: view.bounds,
            styleURL: AppConfigurationPolicy.mapStyleURL(
                from: Bundle.main.object(forInfoDictionaryKey: "MAPBOX_STYLE_URL")
            )
        )
        configuredMapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        configuredMapView.logoView.isHidden = false
        configuredMapView.attributionButton.isHidden = false
        configuredMapView.delegate = self

        let center = AppConfigurationPolicy.coordinate(
            latitudeValue: Bundle.main.object(forInfoDictionaryKey: "MAP_CENTER_LATITUDE"),
            longitudeValue: Bundle.main.object(forInfoDictionaryKey: "MAP_CENTER_LONGITUDE"),
            fallback: demoMapCenterCoordinate
        )
        configuredMapView.setCenter(center, zoomLevel: 11, animated: false)
        view.addSubview(configuredMapView)
        mapView = configuredMapView
    }

    private func showConfigurationError() {
        let label = UILabel(frame: view.bounds.insetBy(dx: 24, dy: 24))
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        label.numberOfLines = 0
        label.textAlignment = .center
        label.text = "Add a valid public Mapbox token in the local MapboxSecrets.xcconfig file."
        view.addSubview(label)
    }

    private func addPrizeAnnotationIfNeeded() {
        guard let mapView = mapView, !didAddPrizeAnnotation else {
            return
        }

        let prize = MGLPointAnnotation()
        prize.coordinate = AppConfigurationPolicy.coordinate(
            latitudeValue: Bundle.main.object(forInfoDictionaryKey: "PRIZE_LATITUDE"),
            longitudeValue: Bundle.main.object(forInfoDictionaryKey: "PRIZE_LONGITUDE"),
            fallback: demoPrizeCoordinate
        )
        prize.title = "Prize"
        mapView.addAnnotation(prize)
        mapView.selectAnnotation(prize, animated: true)
        didAddPrizeAnnotation = true
    }

    private func synchronizeLocationTracking(for status: CLAuthorizationStatus) {
        let state = authorizationState(for: status)
        guard LocationTrackingPolicy.shouldStartUpdates(
            status: state,
            isViewVisible: isViewVisible,
            isMapReady: mapView != nil
        ) else {
            stopLocationTracking()
            return
        }

        guard !isAwaitingLocation else {
            return
        }

        isAwaitingLocation = true
        locationManager.startUpdatingLocation()
    }

    private func stopLocationTracking() {
        isAwaitingLocation = false
        locationManager.stopUpdatingLocation()
        mapView?.setUserTrackingMode(.none, animated: false)
        mapView?.showsUserLocation = false
    }

    private func authorizationState(for status: CLAuthorizationStatus) -> LocationAuthorizationState {
        switch status {
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .authorizedWhenInUse, .authorizedAlways:
            return .authorized
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async { [weak self] in
            self?.synchronizeLocationTracking(for: status)
        }
    }

    @available(iOS 14.0, *)
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        DispatchQueue.main.async { [weak self] in
            self?.synchronizeLocationTracking(for: status)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let status = CLLocationManager.authorizationStatus()
        let state = authorizationState(for: status)
        let now = Date()
        let candidate = locations
            .filter {
                LocationTrackingPolicy.shouldAccept(
                    $0,
                    status: state,
                    isViewVisible: isViewVisible,
                    isAwaitingLocation: isAwaitingLocation,
                    now: now
                )
            }
            .max { $0.timestamp < $1.timestamp }

        guard let location = candidate else {
            return
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  self.isViewVisible,
                  self.isAwaitingLocation else {
                return
            }

            self.isAwaitingLocation = false
            self.locationManager.stopUpdatingLocation()
            self.mapView?.setCenter(location.coordinate, animated: false)
            self.mapView?.showsUserLocation = true
            self.mapView?.setUserTrackingMode(.follow, animated: false)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.stopLocationTracking()
        }
    }

    func mapView(_ mapView: MGLMapView, didUpdate userLocation: MGLUserLocation?) {
        guard let location = userLocation?.location,
              LocationSamplePolicy.accepts(location) else {
            stopLocationTracking()
            return
        }
    }

    func mapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage? {
        let annotationTitle = annotation.title ?? nil
        let imageName = annotationTitle == "Prize" ? "pin3" : "BluePin"
        guard let baseImage = UIImage(named: imageName) else {
            return nil
        }

        let image = baseImage.withAlignmentRectInsets(
            UIEdgeInsetsMake(0, 0, baseImage.size.height / 10, 0)
        )
        return MGLAnnotationImage(
            image: image,
            reuseIdentifier: annotationTitle ?? imageName
        )
    }

    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        return true
    }
}
