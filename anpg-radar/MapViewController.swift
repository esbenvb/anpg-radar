//
//  MapViewController.swift
//  ANPG Radar
//
//  Created by Esben von Buchwald on 23/11/2016.
//  Copyright (c) 2016 Esben von Buchwald. All rights reserved.
//

import UIKit
import MapKit

// FIXME handle unload of view

// kig her https://github.com/MartinBergerDX/LocalNotifications_iOS10/blob/master/LocalNotification_iOS10/ViewController.swift

class MapViewController: UIViewController {
    @IBOutlet weak var followLocationButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var footerStackView: UIStackView!
    @IBOutlet weak var footerViewHeight: NSLayoutConstraint!
    @IBOutlet weak var footerViewBottom: NSLayoutConstraint!
    @IBOutlet weak var notificationSwitch: UISwitch!
    @IBAction func notificationSwitchChanged(_ sender: Any) {
        guard let svitch = sender as? UISwitch else {return}
        if svitch.isOn {
            guard CameraAlertManager.shared.enable(messageDelegate: self, grantedLocationCallback: {[weak self] in
                guard let sself = self else {return}
                svitch.isOn = true
                sself.notificationSwitchChanged(sself.notificationSwitch)
            }) else {
                svitch.isOn = false
                return
            }
        }
        else {
            CameraAlertManager.shared.disable()
        }
    }
    @IBAction func followLocationButtonClicked(_ sender: Any) {
        // enable following location
        followLocation = true
    }
    @IBAction func infoButtonClicked(_ sender: Any) {
        let vc = InfoPageViewController()
        let nc = UINavigationController(rootViewController: vc)
        present(nc, animated: true, completion: nil)
    }

    var camList: [CameraListItem] = [] {
        didSet {
            mapView.removeAnnotations(mapView.annotations)
            mapView.addAnnotations(camList)
            CameraAlertManager.shared.items = camList
            if camList.count > 0 {
                notificationSwitch.isEnabled = true
            }
        }
    }
    let bottomView = CameraBottomView.viewFromNib()
    var originalFooterBottomMargin: CGFloat = 0
    var followLocation = false {
        didSet {
            if followLocation {
                // force update
                guard locationSubscriber.enable() else {
                    self.followLocation = false
                    return
                }
                // update button focus
                followLocationButton.isSelected = true
                followLocationButton.alpha = 0.6
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
        let subscriber = CommonLocationSubscriber(messageDelegate: self)
        subscriber.accuracy = kCLLocationAccuracyHundredMeters
        subscriber.isLocationActiveInBackground = false
        subscriber.updateLocation = { [weak self] (location) in
            guard let sself = self else {return}
            sself.bottomView.currentPosition = location
            guard sself.followLocation else {return}
            sself.centerMap(location: location, radius: 1000.0)
        }
        subscriber.grantedAuthorization = { [weak self] in
            self?.followLocation = true
        }
        return subscriber
    }()
    
    lazy var headingSubscriber: CommonLocationSubscriber = {
        let subscriber = CommonLocationSubscriber(messageDelegate: self)
        subscriber.updateHeading = { [weak self] (heading) in
            guard let sself = self else {return}
            sself.bottomView.currentHeading = heading
            print(heading.description)
        }
        return subscriber
    }()
    
    var regionChangedByUser = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if UserDefaults().bool(forKey: Constants.notificationSettingIdentifier) {
            notificationSwitch.isOn = true
        } else {
            notificationSwitch.isEnabled = false
            notificationSwitch.isOn = false
        }
        
        followLocationButton.setTitle("My location", for: .normal)
        followLocationButton.setTitle("✅ My location", for: .selected)
        
        followLocation = false

        mapView.delegate = self

        footerStackView.addArrangedSubview(bottomView)
        originalFooterBottomMargin = footerViewBottom.constant
        hideFooter()
        
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(notify), name: Constants.cameraDetectedNotificationName, object: nil)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if followLocation {
            guard locationSubscriber.enable() else {
                followLocation = false
                return
            }
        }
        loadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let tracker = GAI.sharedInstance().defaultTracker else { return }
        tracker.set(kGAIScreenName, value: type(of: self).description())
        
        guard let builder = GAIDictionaryBuilder.createScreenView() else { return }
        tracker.send(builder.build() as [NSObject : AnyObject])

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
        if let expiresDate = UserDefaults.standard.object(forKey: Constants.cameraListExpiresKey) as? Date {
            let now = Date()
            if now.timeIntervalSince(expiresDate) < 0 {
                if let elements = CameraListItem.localList {
                    camList = elements
                    return
                }
            }
        }
        
        CameraListResponseModel.load(completion: { [weak self] (elements) in
            guard let sself = self else {return}
            CameraListItem.updateAddresses(elements: elements, completion: { (updatedElements) in
                sself.camList = elements
                CameraListItem.localList = elements
            })
            }, failure: { (error) in
                let ac = UIAlertController(title: "Error", message: "Could not load data. Retry?", preferredStyle: .alert)
                let closeAction = UIAlertAction(title: "Close", style: .cancel, handler: { _ in
                    ac.dismiss(animated: true, completion: nil)
                })
                ac.addAction(closeAction)
                let retryAction = UIAlertAction(title: "Retry", style: .default, handler: { _ in
                    self.loadData()
                })
                ac.addAction(retryAction)
                self.present(ac, animated: true, completion: nil)
                
                print(error?.localizedDescription ?? "Generic error")
        })
    }

    func centerMap(location: CLLocation, radius: CLLocationDistance) {
        let region = MKCoordinateRegionMakeWithDistance(location.coordinate, radius * 2, radius * 2)
        mapView.setRegion(region, animated: true)
    }

    func showFooter() {
        UIView.setAnimationsEnabled(true)
        UIView.animate(withDuration: 0.2) {
            self.footerViewBottom.constant = self.originalFooterBottomMargin
            self.footerView.alpha = 1
            self.view.layoutIfNeeded()
        }
        let _ = headingSubscriber.enable()
        let _ = locationSubscriber.enable()
    }

    func hideFooter() {
        UIView.setAnimationsEnabled(true)
        UIView.animate(withDuration: 0.2, animations: {
            self.footerViewBottom.constant = -(self.footerViewHeight.constant)
            self.footerView.alpha = 0
            self.view.layoutIfNeeded()
        })
        headingSubscriber.disable()
        if !followLocation {
            locationSubscriber.disable()
        }
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
        let mapPinImage = #imageLiteral(resourceName: "mapPin")
        pinView?.image = mapPinImage
        return pinView
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        print("DID SELECT")
        guard let cameraListItem = view.annotation as? CameraListItem else {return}
        bottomView.cameraListItem = cameraListItem
        showFooter()
        view.image = #imageLiteral(resourceName: "mapArrow")
    }

    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        print("DID DESELECT")
        hideFooter()
        view.image = #imageLiteral(resourceName: "mapPin")

    }

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if regionChangedByUser {
            regionChangedByUser = false
            // Avoid calling didSet every time we pan the map.
            if followLocation {
                followLocation = false
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        mapView.subviews.first?.gestureRecognizers?.forEach({ (gestureRecognizer) in
            switch gestureRecognizer.state {
            case .began, .ended:
                regionChangedByUser = true
                return
            default:
                return
            }
        })
        
    }
}
