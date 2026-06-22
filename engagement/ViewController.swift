import CoreLocation
import Mapbox
import UIKit

fileprivate protocol LocationAcquisitionSessionDelegate: class {
    func locationAcquisitionSession(
        _ session: LocationAcquisitionSession,
        didUpdateLocations locations: [CLLocation]
    )
    func locationAcquisitionSession(
        _ session: LocationAcquisitionSession,
        didFailWithError error: Error
    )
}

fileprivate final class LocationAcquisitionSession: NSObject, CLLocationManagerDelegate {
    let generation: UInt64

    private weak var delegate: LocationAcquisitionSessionDelegate?
    private let manager: CLLocationManager

    init(generation: UInt64, delegate: LocationAcquisitionSessionDelegate) {
        self.generation = generation
        self.delegate = delegate
        manager = CLLocationManager()
        super.init()

        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = kCLDistanceFilterNone
    }

    func start() {
        manager.startUpdatingLocation()
    }

    func stop() {
        manager.stopUpdatingLocation()
        manager.delegate = nil
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        delegate?.locationAcquisitionSession(self, didUpdateLocations: locations)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        delegate?.locationAcquisitionSession(self, didFailWithError: error)
    }
}

final class ViewController: UIViewController, CLLocationManagerDelegate, MGLMapViewDelegate,
    LocationAcquisitionSessionDelegate {
    private let authorizationManager = CLLocationManager()
    private var locationAcquisitionSession: LocationAcquisitionSession?
    private var mapView: MGLMapView?
    private var didAddPrizeAnnotation = false
    private var hasRequestedAuthorization = false
    private var isViewVisible = false
    private var locationTrackingCoordinator = LocationTrackingCoordinator()

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
        authorizationManager.delegate = self
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
            authorizationManager.requestWhenInUseAuthorization()
        } else {
            synchronizeLocationTracking(for: status)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        isViewVisible = false
        stopLocationTracking(reason: .viewDisappeared)
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
        if state == .restricted || state == .denied {
            stopLocationTracking(reason: .authorizationLost)
            return
        }
        guard LocationTrackingPolicy.shouldStartUpdates(
            status: state,
            isViewVisible: isViewVisible,
            isMapReady: mapView != nil
        ) else {
            return
        }

        guard let generation = locationTrackingCoordinator.startAwaitingOwnManagerLocation() else {
            return
        }

        let session = LocationAcquisitionSession(generation: generation, delegate: self)
        locationAcquisitionSession = session
        session.start()
    }

    private func stopLocationTracking(reason: LocationTrackingStopReason) {
        locationTrackingCoordinator.stop(reason: reason)
        locationAcquisitionSession?.stop()
        locationAcquisitionSession = nil
        stopMapboxPresentation()
    }

    private func stopMapboxPresentation() {
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

    fileprivate func locationAcquisitionSession(
        _ session: LocationAcquisitionSession,
        didUpdateLocations locations: [CLLocation]
    ) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }

            let status = CLLocationManager.authorizationStatus()
            let state = self.authorizationState(for: status)
            let now = Date()
            let candidate = locations
                .filter {
                    LocationTrackingPolicy.shouldAccept(
                        $0,
                        status: state,
                        isViewVisible: self.isViewVisible,
                        isAwaitingLocation: self.locationTrackingCoordinator.isAwaitingOwnManagerLocation,
                        now: now
                    )
                }
                .max { $0.timestamp < $1.timestamp }

            guard let location = candidate,
                  self.locationAcquisitionSession === session,
                  self.locationTrackingCoordinator.acceptOwnManagerSample(
                      generation: session.generation
                  ) else {
                return
            }

            session.stop()
            self.locationAcquisitionSession = nil
            self.mapView?.setCenter(location.coordinate, animated: false)
            self.mapView?.showsUserLocation = true
            self.mapView?.setUserTrackingMode(.follow, animated: false)
        }
    }

    fileprivate func locationAcquisitionSession(
        _ session: LocationAcquisitionSession,
        didFailWithError error: Error
    ) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }

            let result = self.locationTrackingCoordinator.handleOwnManagerFailure(
                generation: session.generation,
                isRecoverable: LocationManagerErrorPolicy.isRecoverable(error)
            )
            guard result == .stopped, self.locationAcquisitionSession === session else {
                return
            }

            session.stop()
            self.locationAcquisitionSession = nil
            self.stopMapboxPresentation()
        }
    }

    func mapView(_ mapView: MGLMapView, didUpdate userLocation: MGLUserLocation?) {
        guard locationTrackingCoordinator.handleMapboxSample(userLocation?.location) == .accepted else {
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
