//
//  MapViewController.swift
//  ANPG Radar
//
//  Created by Esben von Buchwald on 23/11/2016.
//  Copyright (c) 2016 Esben von Buchwald. All rights reserved.
//

import UIKit
import MapKit

#if (arch(i386) || arch(x86_64))
    let feedUrlString = "http://localhost:8000/data.json?aa"
#else
    let feedUrlString = "https://anpg.dk/data.json"
#endif


// FIXME handle unload of view

// kig her https://github.com/MartinBergerDX/LocalNotifications_iOS10/blob/master/LocalNotification_iOS10/ViewController.swift

class MapViewController: UIViewController {
    @IBAction func mapPinched(_ sender: Any) {
        handleUserMovedMap(sender)
    }
    @IBAction func mapRotated(_ sender: Any) {
        handleUserMovedMap(sender)
    }
    @IBAction func mapPanned(_ sender: Any) {
        handleUserMovedMap(sender)
    }
    @IBOutlet weak var followLocationButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var footerStackView: UIStackView!
    @IBOutlet weak var footerViewHeight: NSLayoutConstraint!
    @IBOutlet weak var notificationSwitch: UISwitch!
    @IBAction func notificationSwitchChanged(_ sender: Any) {
        guard let svitch = sender as? UISwitch else {return}
        if svitch.isOn {
            CameraAlertManager.shared.enable()
            UserDefaults().set(true, forKey: Constants.notificationSettingIdentifier)
        }
        else {
            CameraAlertManager.shared.disable()
            UserDefaults().set(false, forKey: Constants.notificationSettingIdentifier)
        }
    }
    @IBAction func followLocationButtonClicked(_ sender: Any) {
        // enable following location
        followLocation = true
    }

    var camList: [CameraListItem] = [] {
        didSet {
            mapView.removeAnnotations(mapView.annotations)
            mapView.addAnnotations(camList)
            CameraAlertManager.shared.items = camList
        }
    }
    let bottomView = CameraBottomView.viewFromNib()
    var originalFooterHeight: CGFloat = 0
    var followLocation = true {
        didSet {
            if followLocation {
                // update button focus
                followLocationButton.isSelected = true
                followLocationButton.alpha = 0.6
                // force update
                locationSubscriber.enable()
            } else  {
                // update button focus
                followLocationButton.isSelected = false
                followLocationButton.alpha = 1
                // stop update
                locationSubscriber.disable()

            }
        }
    }
    
    lazy var locationSubscriber: CommonLocationSubscriber = {
        let subscriber = CommonLocationSubscriber()
        subscriber.accuracy = kCLLocationAccuracyBestForNavigation
        subscriber.isLocationActiveInBackground = false
        subscriber.updateLocation = { (location) in
            self.centerMap(location: location, radius: 1000.0)
            self.bottomView.currentPosition = location
        }
        return subscriber
    }()
    
    func handleUserMovedMap(_ sender: Any) { // FIXME: does not work perfectly
        guard let gr = sender as? UIGestureRecognizer else {return}
        print (gr.state)
        print(gr.numberOfTouches)
//        if gr.state == .ended {
            followLocation = false
//        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if UserDefaults().bool(forKey: Constants.notificationSettingIdentifier) {
            notificationSwitch.isOn = true
        } else {
            notificationSwitch.isEnabled = false
            notificationSwitch.isOn = false
        }
        
        followLocationButton.setTitle("Follow", for: .normal)
        followLocationButton.setTitle("✅ Follow", for: .selected)
        
        followLocation = true

        mapView.delegate = self

        footerStackView.addArrangedSubview(bottomView)
        originalFooterHeight = footerViewHeight.constant
        hideFooter()
        
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(notify), name: Constants.cameraDetectedNotificationName, object: nil)

        loadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if followLocation {
            locationSubscriber.enable()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        locationSubscriber.disable()
    }
    
    deinit {
        locationSubscriber.disable()
        let nc = NotificationCenter.default
        nc.removeObserver(self, name: Constants.cameraDetectedNotificationName, object: nil)
    }

    func loadData() {
        let ud = UserDefaults.standard

        if let elements = ud.array(forKey: "camList") as? [CameraListItem] {
            camList = elements
            return
        }
        
        guard let url = URL(string: feedUrlString) else {return}
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
        URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) in
            guard let data = data, error == nil else {
                print(error ?? "error")
                return
            }
            do {
                guard let parsedData = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {return}
                let responseModel = CameraListResponseModel(json: parsedData)
                let elements = responseModel?.elements ?? []
                self?.camList = elements
                if elements.count > 0 {
                    self?.notificationSwitch.isEnabled = true
                }
                self?.saveDataLocally(elements: elements)
            } catch {

            }
        }.resume()

    }

    func saveDataLocally(elements: [CameraListItem]) {
        let ud = UserDefaults.standard
        let elementsSerialized: [Data] = elements.map { NSKeyedArchiver.archivedData(withRootObject: $0) }
        ud.set(elementsSerialized, forKey: "camList")
        ud.synchronize()

    }
    
    func centerMap(location: CLLocation, radius: CLLocationDistance) {
        let region = MKCoordinateRegionMakeWithDistance(location.coordinate, radius * 2, radius * 2)
        mapView.setRegion(region, animated: true)
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

    func notify(notification: NSNotification) {
        guard let item = notification.object as? CameraListItem else {return}
        

        selectAnnotation(byId: item.id)
        // play alert sound
    }

    func selectAnnotation(byId id: String) {
        let filteredList = mapView.annotations.filter{ (annotation) -> Bool in
            guard let annotation = annotation as? CameraListItem else { return false }
            return id == annotation.id
        }
        guard let item = filteredList.first else { return }
        mapView.selectAnnotation(item, animated: true)
        centerMap(location: CLLocation(latitude: item.coordinate.latitude, longitude: item.coordinate.longitude), radius: 2000) // FIXME RADIUS
        followLocation = false
    }
    
}

extension MapViewController: MKMapViewDelegate {

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
