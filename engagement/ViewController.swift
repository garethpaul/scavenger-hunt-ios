//
//  ViewController.swift
//  engagement
//
//  Created by Gareth Paul Jones on 12/1/16.
//  Copyright © 2016 Gareth Paul Jones. All rights reserved.
//

import UIKit
import Mapbox
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate, MGLMapViewDelegate {
    
    let locationManager = CLLocationManager()
    var mapView: MGLMapView!
    var logoView: UIImageView!
    private var didAddPrizeAnnotation = false
    private let demoMapCenterCoordinate = CLLocationCoordinate2D(latitude: 37.890576,
                                                                 longitude: -122.472104)
    private let demoPrizeCoordinate = CLLocationCoordinate2D(latitude: 37.826815,
                                                             longitude: -122.4992434)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        let initialAuthorizationStatus = CLLocationManager.authorizationStatus()
        if initialAuthorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        
        logoView = UIImageView(frame: CGRect(x: 0, y: 10, width: 55, height: 40))
        logoView.image = UIImage(named: "Logo")
        logoView.frame.origin.x = (view.frame.size.width - logoView.frame.size.width) / 2
        logoView.frame.origin.y = 20
        
        // Add the logo view to the navigation controller and bring it to the front.
        navigationController?.view.addSubview(logoView)
        navigationController?.view.bringSubview(toFront: logoView)
        
        // Setup Mapbox Treasure Map
        
        let styleURL = configuredMapStyleURL()
        mapView = MGLMapView(frame: view.bounds,
                                 styleURL: styleURL)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.logoView.isHidden = false
        mapView.attributionButton.isHidden = false

        let mapCenterCoordinate = configuredCoordinate(latitudeKey: "MAP_CENTER_LATITUDE",
                                                       longitudeKey: "MAP_CENTER_LONGITUDE",
                                                       fallback: demoMapCenterCoordinate)
        mapView.setCenter(mapCenterCoordinate, zoomLevel: 11, animated: false)
        mapView.delegate = self
        
        view.addSubview(mapView)
        updateUserTracking(for: initialAuthorizationStatus)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard !didAddPrizeAnnotation else {
            return
        }
        
        // Add marker for Hawk Hill
        let hawk = MGLPointAnnotation()
        hawk.coordinate = configuredCoordinate(latitudeKey: "PRIZE_LATITUDE",
                                               longitudeKey: "PRIZE_LONGITUDE",
                                               fallback: demoPrizeCoordinate)
        hawk.title = "Prize"
        mapView.addAnnotation(hawk)
        mapView.selectAnnotation(hawk, animated: true)
        didAddPrizeAnnotation = true
        
        
        
    }
    
    func mapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage? {
        
        let annotationTitle = annotation.title ?? nil
        let imageName = annotationTitle == "Prize" ? "pin3" : "BluePin"

        guard let baseImage = UIImage(named: imageName) else {
            return nil
        }
        
        let image = baseImage.withAlignmentRectInsets(UIEdgeInsetsMake(0, 0, baseImage.size.height/10, 0))
        
        let reuseIdentifier = annotationTitle ?? imageName
        let annotationImage = MGLAnnotationImage(image: image, reuseIdentifier: reuseIdentifier)
        
        return annotationImage
        
    }
    
    
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        // Always allow callouts to popup when annotations are tapped.
        return true
    }

    private func updateUserTracking(for status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            mapView?.userTrackingMode = .follow
        default:
            mapView?.userTrackingMode = .none
        }
    }

    private func configuredMapStyleURL() -> URL? {
        guard let styleURLString = Bundle.main.object(forInfoDictionaryKey: "MAPBOX_STYLE_URL") as? String else {
            return nil
        }

        let trimmedStyleURL = styleURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedStyleURL.isEmpty,
              !trimmedStyleURL.contains("$("),
              let styleURL = URL(string: trimmedStyleURL) else {
            return nil
        }

        let allowedStyleURLSchemes = ["mapbox", "https"]
        guard let styleURLScheme = styleURL.scheme?.lowercased(),
              allowedStyleURLSchemes.contains(styleURLScheme) else {
            return nil
        }

        guard styleURL.user == nil, styleURL.password == nil else {
            return nil
        }

        if let queryItems = URLComponents(url: styleURL, resolvingAgainstBaseURL: false)?.queryItems,
           queryItems.contains(where: { $0.name.lowercased() == "access_token" }) {
            return nil
        }

        if styleURLScheme == "mapbox" {
            guard styleURL.host?.lowercased() == "styles" else {
                return nil
            }
            let stylePathComponents = styleURL.pathComponents.filter { $0 != "/" }
            guard stylePathComponents.count >= 2 else {
                return nil
            }
        } else {
            guard let styleURLHost = styleURL.host, !styleURLHost.isEmpty else {
                return nil
            }
        }

        return styleURL
    }

    private func configuredCoordinate(latitudeKey: String,
                                      longitudeKey: String,
                                      fallback: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        guard let latitude = configuredCoordinateComponent(forInfoDictionaryKey: latitudeKey),
              let longitude = configuredCoordinateComponent(forInfoDictionaryKey: longitudeKey) else {
            return fallback
        }

        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        guard CLLocationCoordinate2DIsValid(coordinate) else {
            return fallback
        }

        return coordinate
    }

    private func configuredCoordinateComponent(forInfoDictionaryKey key: String) -> CLLocationDegrees? {
        guard let rawValue = Bundle.main.object(forInfoDictionaryKey: key) else {
            return nil
        }

        guard let stringValue = rawValue as? String else {
            return nil
        }

        let trimmedValue = stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty,
              !trimmedValue.contains("$("),
              let numericValue = Double(trimmedValue) else {
            return nil
        }

        return numericValue
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard locations.last != nil else {
            return
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        updateUserTracking(for: status)
    }


}
