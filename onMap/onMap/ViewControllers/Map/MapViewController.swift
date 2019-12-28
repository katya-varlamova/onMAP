//
//  MapViewController.swift
//  onMap


import UIKit
import MapKit

final class MapViewController: UIViewController {
    var textUsername = ""
    let locationManager = CLLocationManager()
    var theMessenger: MessengerOnMap = FirestoreMessenger.shared

    var annotationsArray: [MKAnnotation] = [MKAnnotation]() {
        didSet (oldValue) {
             //для удаление с map при удалении из массива
            if oldValue.count > self.annotationsArray.count {
                for i in 0..<annotationsArray.count {
                    if oldValue[i].title != self.annotationsArray[i].title {
                        mapView.removeAnnotation(oldValue[i])
                        break
                    }
                }
                mapView.removeAnnotation(oldValue[oldValue.count - 1])
            }
        }
    }
    @IBOutlet weak var mapView: MKMapView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // скрытие навигатион контроллера
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        
        checkLocationAuthorizationStatus()
        //Account.shared.loadData()
        
        setupMap()
        let initialLocation = CLLocation(latitude: 55.766, longitude: 37.684)
        let regionRadius: CLLocationDistance = 1000
        func centerMapOnLocation(location: CLLocation) {
            let coordinateRegion = MKCoordinateRegion(center: location.coordinate,
                                                      latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
          mapView.setRegion(coordinateRegion, animated: true)
        }
        
        centerMapOnLocation(location: initialLocation)
        
        theMessenger.loadChatInfoArray {
            self.setupAnotations()
        }
        
        theMessenger.setupObserverChats {
            self.setupAnotations()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.mapView.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.delegate = self
        DispatchQueue.main.async {
            self.locationManager.startUpdatingLocation()
        }
    }
    
    func setupMap() {
        mapView.delegate = self
        mapView.mapType = .standard
        mapView.showsUserLocation = true
    }
    
    func checkLocationAuthorizationStatus() {
        if CLLocationManager.authorizationStatus() == .authorizedAlways {
            mapView.showsUserLocation = false
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func setupAnotations() {
            annotationsArray.removeAll()
            let size = theMessenger.numberOfChats
            for i in 0..<size {
                let info = theMessenger.getInfoAboutChat(index: i)
                let pin = PinChat(title: info.name, locationName: "беседа", coordinate: CLLocationCoordinate2D(latitude: info.xCoordinate, longitude: info.yCoordinate))
                annotationsArray.append(pin)
                self.mapView.addAnnotation(pin)
            }
    //        DispatchQueue.main.async {
    //            self.mapView.addAnnotations(self.annotationsArray)
    //        }
        }

    @IBAction func didLongPressMap(_ sender: Any) {
        let pressPoint = (sender as AnyObject).location(in: mapView)
                let pressCoordinate = mapView.convert(pressPoint, toCoordinateFrom: mapView)
               
                let composeAlert = UIAlertController(title: "New chatroom", message: "Enter name of chat", preferredStyle: .alert)
                composeAlert.addTextField { (textField: UITextField) in
                    textField.placeholder = "Name of chat"
                }
                
                composeAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                composeAlert.addAction(UIAlertAction(title: "Create", style: .default, handler: { (action: UIAlertAction) in
                    if let name = composeAlert.textFields?.first?.text {
                        if (self.theMessenger.addChat(nameDiscussion: name, xCoordinate: pressCoordinate.latitude, yCoordinate: pressCoordinate.longitude)) {
        //                    let pressPin = PinChat(title: name, locationName: "DiscussionRoom", coordinate: pressCoordinate)
        //                    self.mapView.addAnnotation(pressPin)
                            let pin = CustomPointAnnotation()
                            pin.coordinate = pressCoordinate
                            pin.title = name
                            //pin.imageName = #imageLiteral(resourceName: "thePinImage")
                            self.mapView.addAnnotation(pin)
                        } else {
                            //вызвать алерт с ошибкой
                        }
                    }
                                   
                }))
                self.present(composeAlert, animated: true, completion: nil)
    }
}

extension MapViewController: CLLocationManagerDelegate {
}

extension MapViewController: MKMapViewDelegate {
}