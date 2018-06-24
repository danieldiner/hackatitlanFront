
import UIKit
import MapKit

class ViewController: UIViewController {

    @objc let locationManager = CLLocationManager()
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var lblLatitud: UILabel!
    @IBOutlet weak var lblLongitud: UILabel!
    
    @IBOutlet weak var lblAltitud: UILabel!
    @IBOutlet weak var lblPrecisionH: UILabel!
    
    @objc let geocoder = CLGeocoder()
    @objc var adress = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.showsUserLocation = true
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.startUpdatingLocation()
        
        let tapGesture = UILongPressGestureRecognizer(target: self, action: #selector(action(gestureRecognizer:)))
        mapView.addGestureRecognizer(tapGesture)
    }

    @IBAction func locaizame() {
        initLocation()
    }
    
    @objc func initLocation() {
        
        let permiso = CLLocationManager.authorizationStatus()
        
        if permiso == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else if permiso == .denied {
            alertLocation(tit: "Error de localización", men: "Actualmente tiene denegada la localización del dispositivo.")
        } else if permiso == .restricted {
            alertLocation(tit: "Error de localización", men: "Actualmente tiene restringida la localización del dispositivo.")
        } else {
            
            guard let currentCoordinate = locationManager.location?.coordinate else { return }
            
            let region = MKCoordinateRegion.init(center: currentCoordinate, latitudinalMeters: 500 , longitudinalMeters: 500)
            mapView.setRegion(region, animated: true)
        }
    }
    
    @objc func alertLocation(tit: String, men: String) {
        
        let alerta = UIAlertController(title: tit, message: men, preferredStyle: .alert)
        let action = UIAlertAction(title: "Aceptar", style: .default, handler: nil)
        alerta.addAction(action)
        self.present(alerta, animated: true, completion: nil)
    }

}

extension ViewController : CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error de localización")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        
        let userCoord = newLocation.coordinate
        let latitud = Double(userCoord.latitude)
        let longitud = Double(userCoord.longitude)
        
        let latSt = (latitud < 0) ? "S" : "N"
        let lonSt = (longitud < 0) ? "O" : "E"
        
        lblLatitud.text = "\(latSt) \(latitud)"
        lblLongitud.text = "\(lonSt) \(longitud)"
        
        let altitud = newLocation.altitude
        lblAltitud.text = String(format: "%.0f m", altitud)
        
        let precision = newLocation.horizontalAccuracy
        lblPrecisionH.text = String(format: "%.0f m", precision)
    }
    
    @objc func action(gestureRecognizer: UIGestureRecognizer) {
        
        self.mapView.removeAnnotations(mapView.annotations)
        
        let touchPoint = gestureRecognizer.location(in: mapView)
        let newCoords = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        
        geocoderLocation(newLocation: CLLocation(latitude: newCoords.latitude, longitude: newCoords.longitude))
 
        let latitud = String(format: "%.6f", newCoords.latitude)
        let longitud = String(format: "%.6f", newCoords.longitude)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = newCoords
        annotation.title = "PELIGROSO"
        //annotation.subtitle = "Latitud: \(latitud) Longitud: \(longitud)"
        annotation.subtitle = adress
        mapView.addAnnotation(annotation)
    }
    
    @objc func geocoderLocation(newLocation: CLLocation) {
        var dir  = ""
        geocoder.reverseGeocodeLocation(newLocation) { (placemarks, error) in
            if error == nil {
                dir = "No se ha podido determinar la dirección"
            }
            if let placemark = placemarks?.last {
                dir = self.stringFromPlacemark(placemark: placemark)
            }
            self.adress = dir
        }
        
    }
    
    @objc func stringFromPlacemark(placemark: CLPlacemark) -> String {
        var line = ""
        
        if let p = placemark.thoroughfare {
            line += p + ", "
        }
        if let p = placemark.subThoroughfare {
            line += p + " "
        }
        if let p = placemark.locality {
            line += " (" + p + ")"
        }
        return line
    }
}

extension ViewController : MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        let annotationID = "AnnotationID"
        
        var annotationView : MKAnnotationView?
        
        if let dequeuedAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationID) {
            annotationView = dequeuedAnnotationView
            annotationView?.annotation = annotation
        } else {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: annotationID)
        }
        
        if let annotationView = annotationView {
            annotationView.canShowCallout = true
            annotationView.image = UIImage(named: "cloud")
        }
        return annotationView
    }
}

