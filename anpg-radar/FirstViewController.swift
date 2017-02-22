//
//  MapViewController.swift
//  ANPG Radar
//
//  Created by Esben von Buchwald on 23/11/2016.
//  Copyright (c) 2016 Esben von Buchwald. All rights reserved.
//

import UIKit
import MapKit

//let feedUrlString = "https://anpg.dk/data.json"
let feedUrlString = "http://localhost:8000/data.json"


class FirstViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var footerStackView: UIStackView!
    @IBOutlet weak var footerViewHeight: NSLayoutConstraint!
    @IBOutlet weak var notificationSwitch: UISwitch!
    @IBAction func notificationSwitchChanged(_ sender: Any) {
        guard let svitch = sender as? UISwitch else {return}
        if svitch.isOn {
            camList.forEach({ (item) in
                startMonitoring(camListItem: item)
            })
        }
        else {
            stopMonitoringAll()
        }
    }

    var camList: [CameraListItem] = [] {
        didSet {
            mapView.removeAnnotations(mapView.annotations)
            mapView.addAnnotations(camList)
        }
    }
    let locationManager = CLLocationManager()
    let bottomView = CameraBottomView.viewFromNib()
    var originalFooterHeight: CGFloat = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        loadData()
        locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            locationManager.startUpdatingLocation()
        }
        mapView.delegate = self

        footerStackView.addArrangedSubview(bottomView)
        originalFooterHeight = footerViewHeight.constant
        hideFooter()

    }

    func loadData() {
        guard let url = URL(string: feedUrlString) else {return}
        URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            guard let data = data, error == nil else {
                print(error ?? "error")
                return
            }
            do {
                guard let parsedData = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {return}
                let responseModel = CameraListResponseModel(json: parsedData)
                self?.camList = responseModel?.elements ?? []
            } catch {

            }
        }.resume()

    }

    func centerMap(location: CLLocation, radius: CLLocationDistance) {
        let region = MKCoordinateRegionMakeWithDistance(location.coordinate, radius * 2, radius * 2)
        mapView.setRegion(region, animated: true)
        locationManager.stopUpdatingLocation()
    }

    func showFooter() {
        UIView.setAnimationsEnabled(true)
        UIView.animate(withDuration: 0.2) {
            self.footerViewHeight.constant = self.originalFooterHeight
            self.view.layoutIfNeeded()
        }
    }

    func hideFooter() {
        UIView.setAnimationsEnabled(true)
        UIView.animate(withDuration: 0.2, animations: {
            self.footerViewHeight.constant = 0
            self.view.layoutIfNeeded()
        })

    }
    
    func startMonitoring(camListItem: CameraListItem) {
        if !CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            print("NOT SUPPORTED ON DEVICE")
            return
        }
        if CLLocationManager.authorizationStatus() != .authorizedAlways {
            print ("NEEDS TO GRANT ACCESS")
        }
        
        locationManager.startMonitoring(for: camListItem.region)
    }
    
    func stopMonitoringAll() {
        locationManager.monitoredRegions.forEach { (region) in
            locationManager.stopMonitoring(for: region)
        }
    }
}

extension FirstViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print(locations)
        guard let location = manager.location else {return}
        print(location.coordinate.latitude)
        print(location.coordinate.longitude)
        centerMap(location: location, radius: 1000.0)
        bottomView.currentPosition = location
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("monitoring failed for ragion with ID \(region?.identifier)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("location manager failed with error \(error.localizedDescription)")
    }
}

extension FirstViewController: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let annotation = annotation as? CameraListItem else {return nil}
        let identifier = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        if pinView == nil {
            pinView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        }
        let mapPinImage = UIImage(named: "mapPin")
        pinView?.image = mapPinImage
        return pinView
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        print("DID SELECT")
        guard let cameraListItem = view.annotation as? CameraListItem else {return}
        bottomView.cameraListItem = cameraListItem
        showFooter()
        view.image = UIImage(named: "first")
    }

    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        print("DID DESELECT")
        hideFooter()
        view.image = UIImage(named: "mapPin")

    }

}

extension UIViewController {
    func notify(region: CLCircularRegion /*FIXME*/) {
       // guard let vc = self as? FirstViewController else {return}
        
        let ac = UIAlertController(title: "WARNING", message: region.identifier, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .cancel) { (action) in
            ac.dismiss(animated: true, completion: nil)
        }
        ac.addAction(okAction)
        present(ac, animated: true, completion: nil)
        
        // vc.select proper annontation view
        // play alert sound
    }
}
