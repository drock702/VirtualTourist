//
//  TouristMapView.swift
//  Virtual Tourist
//
//  Created by Derrick Price on 3/12/16.
//  Copyright © 2016 DLP. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TouristMapView : UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    var locations = [Location]()
    var index = 1       // DLP TEMP
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Set map view delegate with controller
        self.mapView.delegate = self
        
        let longPressRecogniser = UILongPressGestureRecognizer(target: self, action: "handleLongPress:")
        
        longPressRecogniser.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(longPressRecogniser)
        
        // Invoke fetchedResultsController.performFetch() here, and add in the do, try, catch
        do {
            try fetchedResultsController.performFetch()
        } catch {}
        
        locations = fetchAllEvents ()
        print ("After fetching, #items: \(locations.count)")

        // Set the view controller as! the delegate
        fetchedResultsController.delegate = self
        
        // Add the map location
    }
    
    func fetchAllEvents() -> [Location] {
        
        // Create the Fetch Request
        let fetchRequest = NSFetchRequest(entityName: "Location")
        //fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        // Execute the Fetch Request
        do {
            return try sharedContext.executeFetchRequest(fetchRequest) as! [Location]
        } catch _ {
            return [Location]()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        loadSavedMapData ()
    }
    
    func loadSavedMapData () {
        print ("There should be \(locations.count) items from saved data!")
        
        dispatch_async(dispatch_get_main_queue()) {
            print ("Create annotation")
            // We will create an MKPointAnnotation for each dictionary in "locations". The
            // point annotations will be stored in this array, and then provided to the map view.
            var annotations = [MKPointAnnotation]()
            
            print ("iterate locations")
            for pinpoint in self.locations {
                
                print ("The location is being built lat: \(pinpoint.latitude), lon: \(pinpoint.longitude), name: \(pinpoint.name)")
                // Notice that the float values are being used to create CLLocationDegree values.
                // This is a version of the Double type.
                let lat = CLLocationDegrees(pinpoint.latitude )
                let long = CLLocationDegrees(pinpoint.longitude)
                
                // The lat and long are used to create a CLLocationCoordinates2D instance.
                let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
                
                // Here we create the annotation and set its coordiate, title, and subtitle properties
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinate
                annotation.title = pinpoint.name
                
                // Finally we place the annotation in an array of annotations.
                annotations.append(annotation)
            }
            
            // When the array is complete, we add the annotations to the map.
            self.mapView.addAnnotations(annotations)
        }
    }
    
    // Core Data Convenience. This will be useful for fetching. And for adding and saving objects as well.
    lazy var sharedContext: NSManagedObjectContext =  {
        return CoreDataStackManager.sharedInstance().managedObjectContext
        }()
    
    func saveContext() {
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    
    // Step 1: This would be a nice place to paste the lazy fetchedResultsController
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Location")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        print ("The fetch is complete")
        return fetchedResultsController
        
        }()
    
    func handleLongPress(getstureRecognizer : UIGestureRecognizer){
        if getstureRecognizer.state != .Began { return }
        
        let touchPoint = getstureRecognizer.locationInView(self.mapView)
        let touchMapCoordinate = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = touchMapCoordinate
        
        self.mapView.addAnnotation(annotation)
        
        // Add the map view
        // Debugging output
        print("Picked a location")
        
        let dictionary: [String : AnyObject] = [
            Location.Keys.Name : "my temp point" + String (index),      // DLP TEMP
            Location.Keys.Lon : annotation.coordinate.longitude,
            Location.Keys.Lat : annotation.coordinate.latitude
        ]
        
        // Now we create a new Location, using the shared Context
        _ = Location(dictionary: dictionary, context: sharedContext)
        
        print ("The location is being saved lat: \(annotation.coordinate.latitude), lon: \(annotation.coordinate.longitude)")
        index++     // DLP TEMP
        // Step 3: Do not add actors to the actors array.
        // This is no longer necessary once we are modifying our table through the
        // fetched results controller delefate methods
        //            self.actors.append(actorToBeAdded)
        
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    // MKMapViewDelegate
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        print ("Mapview delegate #1")
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.pinTintColor = MKPinAnnotationView.redPinColor ()
            pinView!.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    // This delegate method is implemented to respond to taps on the pin to launch photo view.
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        mapView.deselectAnnotation(view.annotation, animated: true)
        
        // Get coordinates from the pin
        guard let annotation = view.annotation else { /* no annotation */ return }
        let latitude = annotation.coordinate.latitude
        let longitude = annotation.coordinate.longitude
        let title = annotation.title
        mapView.deselectAnnotation(annotation, animated: true)
        
        
        // Launch the photo album view
//        var controller: UIViewController
        let controller = (self.storyboard!.instantiateViewControllerWithIdentifier("LocationPhotoAlbumViewID") ) as! PhotoAlbumView
        controller.mapLatitude = latitude
        controller.mapLongitude = longitude
        
        self.presentViewController(controller, animated: true, completion: nil)
        
        print ("Latitude \(latitude), Longitude \(longitude), title: \(title)")
        print ("Mapview delegate #2")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Step 7: You can implmement the delegate methods here. Or maybe above the table methods. Anywhere is fine.
    func controllerWillChangeContext (controller: NSFetchedResultsController) {
        //        self.tableView.beginUpdates()
        print ("controllerWillChangeContext called")
    }
    
    func controller(controller: NSFetchedResultsController,
        didChangeSection sectionInfo: NSFetchedResultsSectionInfo,
        atIndex sectionIndex: Int,
        forChangeType type: NSFetchedResultsChangeType) {
            
            switch type {
            case .Insert:
                print ("Controller Insert type called")
//                self.tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
                
            case .Delete:
                print ("Controller Delete type called")
//                self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
                
            default:
                return
            }
    }
    
    //
    // This is the most interesting method. Take particular note of way the that newIndexPath
    // parameter gets unwrapped and put into an array literal: [newIndexPath!]
    //
    func controller(controller: NSFetchedResultsController,
        didChangeObject anObject: AnyObject,
        atIndexPath indexPath: NSIndexPath?,
        forChangeType type: NSFetchedResultsChangeType,
        newIndexPath: NSIndexPath?) {
            
            switch type {
            case .Insert:
                print ("Insert type called")
//                tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
                
            case .Delete:
                print ("Delete type called")
//                tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
                
            case .Update:
                print ("Update type called")
//                let cell = tableView.cellForRowAtIndexPath(indexPath!) as! ActorTableViewCell
//                let actor = controller.objectAtIndexPath(indexPath!) as! Person
//                self.configureCell(cell, withActor: actor)
                
            case .Move:
                print ("Move type called")
//                tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
//                tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
                
            default:
                return
            }
    }
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
//        self.tableView.endUpdates()
        print ("controllerDidChangeContent called")
    }
    

    
}

