//
//  ViewController.swift
//  RealTracking
//
//  Created by Yasir Iqbal on 07/07/2020.
//  Copyright © 2020 Yasir Iqbal. All rights reserved.
//

import UIKit
import SceneKit
import CoreLocation

class ViewController: UIViewController {
    
    @IBOutlet weak var txt_zone: UILabel!
    @IBOutlet weak var txt_glX: UILabel!
    @IBOutlet weak var txt_glY: UILabel!
    @IBOutlet weak var txt_glZ: UILabel!
    @IBOutlet weak var txt_llX: UILabel!
    @IBOutlet weak var txt_llY: UILabel!
    @IBOutlet weak var txt_llZ: UILabel!
    
    @IBOutlet weak var view_container: UIView!
    @IBOutlet weak var btn_startStop: UIButton!
    
    @IBOutlet weak var view_sliderX: UISlider!
    @IBOutlet weak var view_sliderY: UISlider!
    @IBOutlet weak var view_sliderZ: UISlider!
    
    @IBOutlet weak var lbl_width: UILabel!
    @IBOutlet weak var lbl_length: UILabel!
    @IBOutlet weak var lbl_height: UILabel!
    
    var logRows = [[String]]()
    
    let view_marker : UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.widthAnchor.constraint(equalToConstant: 16).isActive = true
        view.heightAnchor.constraint(equalToConstant: 16).isActive = true
        view.backgroundColor = UIColor.red
        view.layer.cornerRadius = 8
        view.clipsToBounds = true
        return view
    }()
    
    let locationManager = CLLocationManager()
    var floorPlan : FloorPlan!
    var beaconRegions = [CLBeaconRegion]()
    var devices = [Device]()
    
    let UPDATE_SECONDS : TimeInterval = 5
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.locationManager.requestAlwaysAuthorization()
        
        self.locationManager.delegate = self
        self.floorPlan = FloorPlan(fileName: "FloorPlan", ext: "json")
        
        // extract devices and beaconregions for later use
        for zone in self.floorPlan.zones {
            for device in zone.devices {
                self.devices.append(device)
                self.beaconRegions.append(device.asBeaconRegion())
            }
        }
        
        self.btn_startStop.layer.cornerRadius = self.btn_startStop.frame.width / 2.0
        
        self.view_marker.isHidden = true
        self.view_container.addSubview(self.view_marker)
        self.view_container.clipsToBounds = false
        
        self.view_sliderX.value = 0
        self.view_sliderY.value = 0
        self.view_sliderZ.value = 0
        self.view_sliderX.maximumValue = Float(self.floorPlan.zones[0].width)
        self.view_sliderY.maximumValue = Float(self.floorPlan.zones[0].length)
        self.view_sliderZ.maximumValue = Float(self.floorPlan.zones[0].height)
        
        let csvHeaderRow = ["sn", "time" ,"zone", "t_zone", "b1ID", "b2ID", "b3ID", "b1d", "b2d", "b3d", "x", "y", "z", "xt", "yt", "zt"]
        
    }
    
    
    // start region monitoring
    func startBeacons() {
        for beaconRegion in self.beaconRegions {
            if #available(iOS 13.0, *) {
                self.locationManager.startRangingBeacons(satisfying: beaconRegion.beaconIdentityConstraint)
            }
            else {
                self.locationManager.startRangingBeacons(in: beaconRegion)
            }
        }
        
        self.showBeacons()
    }
    
    
    var markers = [UIView]()
    
    func showBeacons() {
        
        for device in self.devices {
            
            let marker = UIView()
            marker.translatesAutoresizingMaskIntoConstraints = false
            marker.backgroundColor = UIColor.blue
            marker.widthAnchor.constraint(equalToConstant: 8).isActive = true
            marker.heightAnchor.constraint(equalToConstant: 8).isActive = true
            marker.layer.cornerRadius = 4
            self.markers.append(marker)
            self.view_container.addSubview(marker)
            self.view_container.bringSubviewToFront(marker)
            
            let totalWidth = CGFloat(self.floorPlan.floorWidth)
            let totalLength = CGFloat(self.floorPlan.floorLength)
            let ratioWidth = CGFloat(device.floorLoc.x) / CGFloat(totalWidth)
            let ratioLength = CGFloat(device.floorLoc.y) / CGFloat(totalLength)
            marker.center = CGPoint(x: ratioWidth + 8, y: ratioLength + 8)
            
        }
        
    }
    
    
    // stop region monitoring
    func stopBeacons() {
        
        for beaconRegion in self.beaconRegions {
            if #available(iOS 13.0, *) {
                self.locationManager.stopRangingBeacons(satisfying: beaconRegion.beaconIdentityConstraint)
            }
            else {
                self.locationManager.stopRangingBeacons(in: beaconRegion)
            }
        }
    }
    
    func compareDevice( device: Device, beacon : CLBeacon ) -> Bool {
        
        if device.uuid == beacon.proximityUUID && device.majorValue == beacon.major && device.minorValue == beacon.minor {
            return true
        }
        return false
    }
    
    var isStarted = false
    
    @IBAction func btn_startStop(_ sender: UIButton) {
        
        if self.isStarted == false {
            self.isStarted = true
            self.startBeacons()
            self.btn_startStop.setTitle("Stop", for: .normal)
        }
        else {
            self.isStarted = false
            self.stopBeacons()
            self.btn_startStop.setTitle("Start", for: .normal)
        }
    }
    
    
    var selectedZone = 0
    @IBAction func btn(_ sender: UISegmentedControl) {
        
        self.lbl_width.text = "X: 0"
        self.lbl_length.text = "Y: 0"
        self.lbl_height.text = "Z: 0"
        
        if sender.selectedSegmentIndex == 0 {
            
            self.selectedZone = 0
            if self.isStarted == true {
                self.btn_startStop(UIButton())
            }
            
            self.view_sliderX.value = 0
            self.view_sliderY.value = 0
            self.view_sliderZ.value = 0
            self.view_sliderX.maximumValue = Float(self.floorPlan.zones[0].width)
            self.view_sliderY.maximumValue = Float(self.floorPlan.zones[0].length)
            self.view_sliderZ.maximumValue = Float(self.floorPlan.zones[0].height)
        }
        else if sender.selectedSegmentIndex == 1 {
            
            self.selectedZone = 1
            if self.isStarted == true {
                self.btn_startStop(UIButton())
            }
            
            self.view_sliderX.value = 0
            self.view_sliderY.value = 0
            self.view_sliderZ.value = 0
            self.view_sliderX.maximumValue = Float(self.floorPlan.zones[1].width)
            self.view_sliderY.maximumValue = Float(self.floorPlan.zones[1].length)
            self.view_sliderZ.maximumValue = Float(self.floorPlan.zones[1].height)
        }
        else if sender.selectedSegmentIndex == 2 {
            
            self.selectedZone = 2
            if self.isStarted == true {
                self.btn_startStop(UIButton())
            }
            self.view_sliderX.value = 0
            self.view_sliderY.value = 0
            self.view_sliderZ.value = 0
            self.view_sliderX.maximumValue = Float(self.floorPlan.zones[2].width)
            self.view_sliderY.maximumValue = Float(self.floorPlan.zones[2].length)
            self.view_sliderZ.maximumValue = Float(self.floorPlan.zones[2].height)
        }
        
    }
    
    @IBAction func seg_width(_ sender: UISlider) {
        self.lbl_width.text = "X: \(sender.value)"
    }
    
    @IBAction func seg_length(_ sender: UISlider) {
        self.lbl_length.text = "Y: \(sender.value)"
    }
    
    @IBAction func seg_height(_ sender: UISlider) {
        self.lbl_height.text = "Z: \(sender.value)"
    }
    
}


extension ViewController : CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, rangingBeaconsDidFailFor region: CLBeaconRegion, withError error: Error) {
        print("rangingBeaconsDidFailFor", error.localizedDescription)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("didFailWithError: \(error.localizedDescription)")
    }
    
    @available(iOS 13.0, *)
    func locationManager(_ manager: CLLocationManager, didRange beacons: [CLBeacon], satisfying beaconConstraint: CLBeaconIdentityConstraint) {
        self.updateBeacons(beacons: beacons)
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        print("Count: \(beacons.count)")
        self.updateBeacons(beacons: beacons)
    }
    
    func updateBeacons( beacons : [CLBeacon] ) {
        
        for clBeacon in beacons {
            let detectedDevices = self.devices.filter { (device) -> Bool in
                if self.compareDevice(device: device, beacon: clBeacon) {   // devices in beacon above
                    return true
                }
                else {
                    return false
                }
            }
            
            for device in detectedDevices {
                device.beacon = clBeacon
            }
        }
        
        // get latest updated devices in 5 seconds
        let currentTime = Date().timeIntervalSince1970
        let currentDevices = self.devices.filter { (device) -> Bool in
            if device.updateTime == nil {
                return false
            }
            
            if currentTime <= (device.updateTime + self.UPDATE_SECONDS) {
                return true
            }
            else {
                return false
            }
        }
        
        // filtering out beacons with nearest distance
        let nearestSortedBeacons = currentDevices.sorted { $0.distance < $1.distance }
        
        if nearestSortedBeacons.count < 3 {
            
            self.txt_zone.text = "Devices < 3"
            self.txt_llX.text = "X: -"
            self.txt_llY.text = "Y: -"
            self.txt_llZ.text = "Z: -"
            
            return
        }
        
        let finalBeacons = Array(nearestSortedBeacons[0...2])
        
        Trilaterator.shared.trilaterate(finalBeacons, success: { (global : SCNVector3! ) in
            
            
            let row = [String]()
            
            
            let pos = SCNVector3( abs(global.x),
                                  abs(global.y),
                                  abs(global.z))
            
            self.setPosition(pos: pos)
            self.txt_glX.text = "X: \(pos.x)"
            self.txt_glY.text = "Y: \(pos.y)"
            self.txt_glZ.text = "Z: \(pos.z)"
            
            self.txt_zone.text = "Zone: -"
            
            let inZone = self.floorPlan.zones.filter { (zone) -> Bool in
                
                if zone.contains(point: pos) {
                    return true
                }
                else {
                    return false
                }
                
            }.first
            
            if inZone == nil {
                // TODO
                self.txt_zone.text = "Zone: -"
                self.txt_llX.text = "X: -"
                self.txt_llY.text = "Y: -"
                self.txt_llZ.text = "Z: -"
                
                return
            }
            
            self.txt_zone.text = "Zone: \(inZone!.name!)"
            
            let locX = pos.x -  inZone!.originPt.x
            let locY = pos.y -  inZone!.originPt.y
            let locZ = pos.z -  inZone!.originPt.z
            
            self.txt_llX.text = "X: \(locX)"
            self.txt_llY.text = "Y: \(locY)"
            self.txt_llZ.text = "Z: \(locZ)"
            
        }) { (error) in
            print("Error")
        }
        
    }
    
    
    func setPosition(pos : SCNVector3!) {
        
        self.view_marker.isHidden = false
        let totalWidth = CGFloat(self.floorPlan.floorWidth)
        let totalLength = CGFloat(self.floorPlan.floorLength)
        let ratioWidth = CGFloat(pos.x) / CGFloat(totalWidth)
        let ratioLength = CGFloat(pos.y) / CGFloat(totalLength)
        self.view_marker.center = CGPoint(x: ratioWidth + 8, y: ratioLength + 8)
        
    }
    
    
}

