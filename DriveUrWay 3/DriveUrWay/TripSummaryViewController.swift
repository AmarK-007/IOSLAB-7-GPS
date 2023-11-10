//
//  TripSummaryViewController.swift
//  DriveUrWay
//
//  Created by Amarnath  Kathiresan on 2023-11-08.
//

import UIKit
import CoreLocation
import MapKit

class TripSummaryViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    // Initialisation of views
    @IBOutlet var routeMapView: MKMapView!
    @IBOutlet weak var currentSpeedLabel: UILabel!
    @IBOutlet weak var maxSpeedLabel: UILabel!
    @IBOutlet weak var averageSpeedLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var maxAccelerationLabel: UILabel!
    @IBOutlet weak var statusLabelView: UILabel!
    @IBOutlet weak var speedLabelView: UILabel!
    @IBOutlet weak var startTripButton: UIButton!
    @IBOutlet weak var stopTripButton: UIButton!
    
    // We set manager object to the CLLocationmanager -Delegate
    let locationManager = CLLocationManager()
    
    // Initialisating variables for startLocation, destinationlocation, startDate, traveledDistance, maxSpeed, averageSpeed and maxAcceleration
    var startLocationConestogaWaterloo = (latitude: 43.479614, longitude: -80.517181)
    var destinationLocationConestogaDoon = (latitude: 43.390241, longitude: -80.403609)
    var startLocation: CLLocation!
    var destinationLocation: CLLocation!
    var startDate: Date!
    var averageSpeed: Double = 0
    var traveledDistance: Double = 0
    var maxSpeed: Double = 0
    var maxAcceleration: Double = 0
    var isTripStarted: Bool = false
    // coordinates for the polyline
    var coordinatesforPolyLine: [CLLocationCoordinate2D] = []
    var distanceOverSpeedLimitValue: Double = 0
    var distanceOverSpeedLimitinKM: String!
    var isSpeedWithinLimit: Bool = true
    
    /* Start Trip Button function */
    @IBAction func startTripButton(_ sender: Any) {
        isTripStarted = true
        self.statusLabelView.backgroundColor = UIColor.green
        stopTripButton.isEnabled = true
        startTripButton.isEnabled = false
        print("Trip Started.")
    }
    
    /* End Trip Button function */
    @IBAction func endTripButton(_ sender: Any) {
        
        self.speedLabelView.backgroundColor = UIColor.green
        self.statusLabelView.backgroundColor = UIColor.gray
        self.currentSpeedLabel.text = String(format: "%.2f km/h", 0)
        
        isTripStarted = false
        stopTripButton.isEnabled = false
        startTripButton.isEnabled = true
        
        print("Trip Ended.")
        
    }
    
    /* viewDidLoad function */
    override func viewDidLoad() {
        super.viewDidLoad()
        // Disabling stop buttn initially
        stopTripButton.isEnabled = false
        
        // Do any additional setup after loading the view.
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        routeMapView.delegate = self
        
        // That's it for the initial setup. Everything else is handled in the
        // locationManagerDidChangeAuthorization method.
        locationManagerDidChangeAuthorization(locationManager)
    }
    
    /* locationManagerDidChangeAuthorization function - This is called as soon as the location manager is setup (in viewDidLoad)*/
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .notDetermined:
            // Request the appropriate authorization based on the needs of the app
            manager.requestWhenInUseAuthorization()
            // manager.requestAlwaysAuthorization()
        case .restricted:
            print("Sorry, restricted")
            // Optional: Offer to take user to app's settings screen
            //openSettingsPage()
        case .denied:
            print("Sorry, denied")
            // Optional: Offer to take user to app's settings screen
            //openSettingsPage()
        case .authorizedAlways, .authorizedWhenInUse:
            // The app has permission so start getting location updates
            print("Permission provided")
            setViewReady()
        @unknown default:
            print("Unknown status")
        }
    }
    
    /* setViewReady Function */
    func setViewReady(){
        locationManager.startUpdatingLocation()
        // distance filter to 5 meters
        locationManager.distanceFilter = 5
        // location and tracking mode on the MapView
        routeMapView.showsUserLocation = true
        routeMapView.userTrackingMode = .follow
    }
    
    /* openSettingsPage Function */
    func openSettingsPage(){
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    /* mapView function - Define a method to handle the map view's rendererFor delegate method */
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        // Check if the overlay is a polyline
        if let polyline = overlay as? MKPolyline {
            // Create a polyline renderer with the polyline
            let renderer = MKPolylineRenderer(polyline: polyline)
            // Set the stroke color and width of the renderer
            renderer.strokeColor = .blue
            renderer.lineWidth = 3
            return renderer
        } else {
            // Return a default renderer for other types of overlays
            return MKOverlayRenderer(overlay: overlay)
        }
    }
    
    /* locationManager function - Define a method to handle the location manager's didUpdateLocations delegate method */
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if isTripStarted {
            if startLocation == nil {
                startLocation = locations.first
                startDate = Date()
            } else if let location = locations.last {
                traveledDistance += destinationLocation.distance(from: location)
                let currentSpeed = location.speed
                
                // Converting the current speed to km/h by multiplying by 3.6
                let currentSpeedInKmH = currentSpeed * 3.6
                if currentSpeedInKmH > maxSpeed {
                    maxSpeed = currentSpeedInKmH
                }
                let elapsedTime = Date().timeIntervalSince(startDate)
                let elapsedTimeInHours = elapsedTime / 3600
                averageSpeed = traveledDistance / 1000 / elapsedTimeInHours
                
                // Calculating the acceleration by using the formula acceleration = (currentSpeed - destinationSpeed) / timeInterval
                let lastSpeed = destinationLocation.speed
                let timeInterval = location.timestamp.timeIntervalSince(destinationLocation.timestamp)
                let acceleration = (currentSpeed - lastSpeed) / timeInterval
                if acceleration > maxAcceleration {
                    maxAcceleration = acceleration
                }
                self.currentSpeedLabel.text = String(format: "%.2f km/h", currentSpeedInKmH)
                if currentSpeedInKmH > 115.0 {
                    self.speedLabelView.backgroundColor = UIColor.red
                    destinationLocation = locations.last
                    if(isSpeedWithinLimit){
                        isSpeedWithinLimit = false
                        let distanceOverSpeedLimit =  startLocation.distance(from: destinationLocation)
                        distanceOverSpeedLimitValue = distanceOverSpeedLimitValue + (distanceOverSpeedLimit / 1000)
                        distanceOverSpeedLimitinKM = String(format: "%.2f km", distanceOverSpeedLimitValue)
                    }
                } else {
                    self.speedLabelView.backgroundColor = UIColor.green
                    isSpeedWithinLimit = true
                }
                let distance = startLocation.distance(from: destinationLocation)
                
                // Converting the distance to km by dividing by 1000
                let distanceInKm = String(format: "%.2f km", (distance / 1000))
                
                // Updating the distanceLabel with the distance in km
                self.distanceLabel.text = distanceInKm
                self.maxSpeedLabel.text = String(format: "%.2f km/h", maxSpeed)
                self.averageSpeedLabel.text = String(format: "%.2f km/h", averageSpeed)
                self.maxAccelerationLabel.text = String(format: "%.2f m/s^2", maxAcceleration)
                
                print("----------------------------------------------")
                print("Current Speed : \(String(format: "%.2f km/h", currentSpeedInKmH))")
                print("Max Speed : \(String(format: "%.2f km/h", maxSpeed))")
                print("Average Speed : \(String(format: "%.2f km/h", averageSpeed))")
                print("Distance : \(distanceInKm)")
                print("Max Acceleration : \(String(format: "%.2f km/h", maxAcceleration))")
                print("Killometers travelled before exceeding 115km/h : \(String(format:distanceOverSpeedLimitinKM))")
            }
            
            destinationLocation = locations.last
            coordinatesforPolyLine.append(destinationLocation.coordinate)
            
            // Creating a polyline instance from the coordinates array
            let polyline = MKPolyline(coordinates: coordinatesforPolyLine, count: coordinatesforPolyLine.count)
            routeMapView.addOverlay(polyline)
            let region = MKCoordinateRegion(center: destinationLocation.coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
            routeMapView.setRegion(region, animated: true)
        }
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}
