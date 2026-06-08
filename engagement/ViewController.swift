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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        logoView = UIImageView(frame: CGRect(x: 0, y: 10, width: 55, height: 40))
        logoView.image = UIImage(named: "Logo")
        logoView.frame.origin.x = (view.frame.size.width - logoView.frame.size.width) / 2
        logoView.frame.origin.y = 20
        
        // Add the logo view to the navigation controller and bring it to the front.
        navigationController?.view.addSubview(logoView)
        navigationController?.view.bringSubview(toFront: logoView)
        
        // Setup Mapbox Treasure Map
        
        let styleURL: URL? = nil
        mapView = MGLMapView(frame: view.bounds,
                                 styleURL: styleURL)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        mapView.setCenter(CLLocationCoordinate2D(latitude: 37.890576,
                                    longitude: -122.472104),
                                    zoomLevel: 11, animated: false)
        mapView.userTrackingMode = .follow
        mapView.delegate = self
        
        view.addSubview(mapView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
        // Add marker for Hawk Hill
        let hawk = MGLPointAnnotation()
        hawk.coordinate = CLLocationCoordinate2D(latitude: ("37.826815" as NSString).doubleValue,
                                                 longitude: ("-122.4992434" as NSString).doubleValue)
        hawk.title = "Prize"
        mapView.addAnnotation(hawk)
        mapView.selectAnnotation(hawk, animated: true)
        
        
        
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            return
        }

        let locValue: CLLocationCoordinate2D = location.coordinate
        print("locations = \(locValue.latitude) \(locValue.longitude)")
    }


}
