//
//  QiblaViewController.swift
//  Vaktija.ba
//
//

import UIKit
import CoreLocation

class QiblaViewController: UIViewController, CLLocationManagerDelegate
{
    @IBOutlet weak var qiblaNeedleImageView: UIImageView!
    @IBOutlet weak var warningLabel: UILabel!
    @IBOutlet weak var settingsButton: UIButton!
    
    var locationManager = CLLocationManager()
    
    fileprivate var qiblaCoordinates = CLLocationCoordinate2D(latitude: 21.423333, longitude: 39.823333)
    fileprivate var qiblaAngleDegrees: CLLocationDegrees = 0.0
    
    // MARK: - View's Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
		navigationItem.title = "Kibla kompas"
		
		warningLabel.textColor = UIColor.errorColor
		settingsButton.setTitleColor(UIColor.actionColor, for: .normal)
		view.backgroundColor = UIColor.backgroundColor
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
		prepareLocationManager()
        prepareHeadingOrientation()
    }
    
    override func viewDidDisappear(_ animated: Bool)
    {
        super.viewDidDisappear(animated)
        
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }
    
    // MARK: Core Location Delegates
    
    func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool
    {
        return true
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        if !locations.isEmpty
        {
            calculateQiblaAngleDegrees(locations.first!.coordinate)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading)
    {
        if !qiblaNeedleImageView.isHidden
        {
            let rotateQiblaAngleRadians = CGFloat((qiblaAngleDegrees - newHeading.trueHeading)*Double.pi/180.0)
            
            UIView.animate(withDuration: 0.5, animations: {
                self.qiblaNeedleImageView.transform = CGAffineTransform(rotationAngle: rotateQiblaAngleRadians)
            })
            
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus)
    {
        switch status
        {
            case .denied:
                warningLabel.text = "Uključite Lokacija Servis da bi \"Vaktija.ba\" mogla da odredi vašu lokaciju!"
                warningLabel.isHidden = false
                settingsButton.isHidden = false
                qiblaNeedleImageView.isHidden = true
            
            case .notDetermined:
                warningLabel.text = "U Lokacija Servis za \"Vaktija.ba\" odaberite \"Dok se koristi\" opciju da bi omogućili Kibla kompas."
                warningLabel.isHidden = false
                settingsButton.isHidden = true
                qiblaNeedleImageView.isHidden = true
                
                locationManager.requestWhenInUseAuthorization()
            
            case .restricted:
                warningLabel.text = "Vi nemate dozvolu da koristite \"Lokacija Servis\"! Kibla kompas nije funkcionalan."
                warningLabel.isHidden = false
                settingsButton.isHidden = false
                qiblaNeedleImageView.isHidden = true
            
            case .authorizedWhenInUse:
                warningLabel.isHidden = true
                settingsButton.isHidden = true
                qiblaNeedleImageView.isHidden = false
                
                locationManager.startUpdatingLocation()
                locationManager.startUpdatingHeading()
            
            default:
                print(status.rawValue)
        }
    }
    
    // MARK: Button Delegates
    
    @IBAction func settingsButtonClick(_ sender: UIButton)
    {
        let settingsUrl = URL(string: UIApplication.openSettingsURLString)
        if UIApplication.shared.canOpenURL(settingsUrl!)
        {
            if #available(iOS 10.0, *)
            {
				UIApplication.shared.open(settingsUrl!, options: [:], completionHandler: nil)
            }
            else
            {
                UIApplication.shared.openURL(settingsUrl!)
            }
        }
    }
    
    // MARK: Private Functions
	
	fileprivate func prepareLocationManager() {
		locationManager = CLLocationManager()
		locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        locationManager.distanceFilter = 10
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
		qiblaNeedleImageView.layer.anchorPoint = CGPoint(x: 0.5, y: 0.95)
	}
    
    fileprivate func calculateQiblaAngleDegrees(_ currentCoordinates: CLLocationCoordinate2D)
    {
        let qiblaLatitudeRadians = qiblaCoordinates.latitude*Double.pi/180.0
        let qiblaLongitudeRadians = qiblaCoordinates.longitude*Double.pi/180.0
        let currentLatitudeRadians = currentCoordinates.latitude*Double.pi/180.0
        let currentLongitudeRadians = currentCoordinates.longitude*Double.pi/180.0
        
        qiblaAngleDegrees = 180.0/Double.pi*atan2(sin(qiblaLongitudeRadians - currentLongitudeRadians), cos(currentLatitudeRadians)*tan(qiblaLatitudeRadians) - sin(currentLatitudeRadians)*cos(qiblaLongitudeRadians - currentLongitudeRadians))
    }
    
    fileprivate func prepareHeadingOrientation()
    {
        let orientation = UIDevice.current.orientation
        if orientation.isValidInterfaceOrientation
        {
            if UIDevice.current.userInterfaceIdiom == .phone && orientation == .portraitUpsideDown
            {
                locationManager.headingOrientation = CLDeviceOrientation(rawValue: Int32(UIDeviceOrientation.portrait.rawValue))!
            }
            else
            {
                locationManager.headingOrientation = CLDeviceOrientation(rawValue: Int32(orientation.rawValue))!
            }
        }
    }
}
