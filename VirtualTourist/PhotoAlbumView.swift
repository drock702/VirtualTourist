//
//  PhotoAlbumView.swift
//  Virtual Tourist
//
//  Created by Derrick Price on 3/12/16.
//  Copyright © 2016 DLP. All rights reserved.
//

import CoreData
import Foundation
import MapKit

class PhotoAlbumView : UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var displayLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var activityStatusIndicator: UIActivityIndicatorView!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    
    // The selected indexes array keeps all of the indexPaths for cells that are "selected". The array is
    // used inside cellForItemAtIndexPath to lower the alpha of selected cells.  You can see how the array
    // works by searchign through the code for 'selectedIndexes'
    var selectedIndexes = [NSIndexPath]()
    
    // Keep the changes. We will keep track of insertions, deletions, and updates.
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    
    // Variables for the latitude and longitude for the map.
    var mapLatitude: Double = 200.0
    var mapLongitude: Double = 200.0
    var locationPhotos: [[String: AnyObject]]?
    
    // Core Data Convenience. This will be useful for fetching. And for adding and saving objects as well.
    lazy var sharedContext: NSManagedObjectContext =  {
        return CoreDataStackManager.sharedInstance().managedObjectContext
        }()
    
    func saveContext() {
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
        // Start the fetched results controller
        var error: NSError?
        do {
            try fetchedResultsController.performFetch()
        } catch let error1 as NSError {
            error = error1
        }
        
        self.activityStatusIndicator.hidden = true
        self.newCollectionButton.enabled = false
        
        collectionView.dataSource = self
        // Configure the collection view.
        let screenSize = UIScreen.mainScreen().bounds
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: screenSize.width / 3, height: screenSize.width / 3)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        collectionView.setCollectionViewLayout(layout, animated: true)
        collectionView.registerClass(PhotoCellForCollectionView.self, forCellWithReuseIdentifier: "PhotoCellForCollectionView")
        
        fetchedResultsController.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func refreshPhotos ()
    {
        // Set pinpoint on map
        if self.mapLatitude < 200.0 && self.mapLongitude < 200.0
        {
            // Notice that the float values are being used to create CLLocationDegree values.
            // This is a version of the Double type.
            let lat = CLLocationDegrees(self.mapLatitude)
            let long = CLLocationDegrees(self.mapLongitude)
            
            // Zoom in on map
            // The lat and long are used to create a CLLocationCoordinates2D instance.
            let latDelta:CLLocationDegrees = 0.25
            let longDelta:CLLocationDegrees = 0.25
            
            let span:MKCoordinateSpan = MKCoordinateSpanMake(latDelta, longDelta)
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
            let location:CLLocationCoordinate2D = coordinate
            let region:MKCoordinateRegion = MKCoordinateRegionMake(location, span)
            
            self.mapView.setRegion(region, animated: true)
            
            // Here we create the annotation and set its coordiate, title, and subtitle properties
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            // When the array is complete, we add the annotations to the map.
            self.mapView.addAnnotation(annotation)
        }
        
        dispatch_async(dispatch_get_main_queue()) {
            self.activityStatusIndicator.hidden = false
            self.activityStatusIndicator.startAnimating()
        }
        
        // Are there any pictures to show?
        PhotoGrabber.sharedInstance().pictureSearchByLatitudeLongitude (self.mapLatitude, longitudeValue: self.mapLongitude) { (photos: [[String: AnyObject]]?, errorString: String?) in
            
            self.locationPhotos = photos
            print ("pictureSearchByLatitudeLongitude returned \(self.locationPhotos!.count) photos")
            dispatch_async(dispatch_get_main_queue()) {
                if let error = errorString {
                    print ("There was an error \(error)")
                    self.displayLabel.hidden = false
                }
                else {
                    self.displayLabel.hidden = true
                }
            }
            
            // End animation of status indicator
            self.activityStatusIndicator.hidden = true
            self.activityStatusIndicator.stopAnimating()
            // Enable the New Collection button
            
            self.newCollectionButton.enabled = true
            self.collectionView.reloadData()
            print ("Done retrieving photos")
            
            
//            guard let photosArray = photos as [[String:AnyObject]]? else {
//                print(errorString)
//                return
//            }
//            // DLP TEMP
//            for photo in self.locationPhotos!
//            {
//                print ("The photo object = \(photo.description)")
//                let f = photo["id"] as! String!
//                print ("The id is \(f)")
//                print("The f description: \(f)")
//            }
//            
//            let _ = photosArray.map() { (dictionary: [String:AnyObject]) in
//                //                // Need to create a Location object??    Photo.Keys.Location : annotation.coordinate.longitude
//                //                // Need to create a Location object??    Location.Keys.Lat : annotation.coordinate.latitude
//                // Amend Photo constructor to accept a location??  Or create ocatiopn in the Photo
//                let photo = Photo(dictionary: dictionary, context: self.sharedContext)
//            }
//            
//            self.saveContext()
//            return 
            // Get a photo to put in collection
            for photo in self.locationPhotos!
            {
                
                print ("The photo object = \(photo.description)")
                //_ = Photo (photo)
                
//                let dictionary: [String : AnyObject] = [
//                    Photo.Keys.Url : photo ["url_m"]
//                // Need to create a Location object??    Photo.Keys.Location : annotation.coordinate.longitude
//                // Need to create a Location object??    Location.Keys.Lat : annotation.coordinate.latitude
//                ]
                
                // Now we create a new Location, using the shared Context
//                _ = Location(dictionary: dictionary, context: self.sharedContext)
                 _ = Photo(dictionary: photo, context: self.sharedContext)
                
            }
            
            CoreDataStackManager.sharedInstance().saveContext()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.refreshPhotos ()
    }
    
    @IBAction func goBack(sender: UIBarButtonItem) {
        
        if((self.presentingViewController) != nil){
            self.dismissViewControllerAnimated(false, completion: nil)
            
            print("Done")
        }
    }
    
    @IBAction func newCollectionPress(sender: UIBarButtonItem) {
        print ("Create a new collection...")
        
        self.refreshPhotos ()
    }
    
    // MARK: - NSFetchedResultsController
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.sortDescriptors = []
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
        }()
    
    func configureCell(cell: PhotoCellForCollectionView, photo: Photo) {
        var placeholderImage = UIImage(named: "placeholder")
        
        cell.photoImage.image = nil
        
        // Set the Movie Poster Image
        
        if photo.image != nil {
            placeholderImage = photo.image!
        }
        
        cell.photoImage.image = placeholderImage
        
        
//        let photo = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
//        
//        print ("Photo description: \(photo.description)")
////        cell.photo = photo.url
////        print ("Configuring cell for photo: \(cell.photo)")
//        
//        // If the cell is "selected" it's color panel is grayed out
//        // we use the Swift `find` function to see if the indexPath is in the array
//        
////        if let index = selectedIndexes.indexOf(indexPath) {
////            cell.colorPanel.alpha = 0.05
////        } else {
////            cell.colorPanel.alpha = 1.0
////        }
////        cell.photoViewImage.image = nil
//        
//        // Set the Movie Poster Image
// // DLP - TODO
////        if photo.image != nil {
////            placeholderImage = photo.image!
////        }
////        
////        cell.photoImageView.image = placeholderImage
//        
//        var tempImage = UIImage(named: "tempPhoto")
//        
////        cell.photoViewImage.image = nil
//        
//        // Set the Movie Poster Image
//        
//        if photo.image != nil {
//            tempImage = photo.image!
//        }
//        
//        cell.photoImage.image = tempImage
    }

    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        
        print("number Of Cells: \(sectionInfo.numberOfObjects)")
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCellForCollectionView", forIndexPath: indexPath) as! PhotoCellForCollectionView
        
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        self.configureCell(cell, photo: photo)
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCellForCollectionView
        
        // Whenever a cell is tapped we will toggle its presence in the selectedIndexes array
        if let index = selectedIndexes.indexOf(indexPath) {
            selectedIndexes.removeAtIndex(index)
        } else {
            selectedIndexes.append(indexPath)
        }
        
        // Then reconfigure the cell
//        configureCell(cell, atIndexPath: indexPath)
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        configureCell(cell, photo: photo)
        
        // And update the buttom button
        updateBottomButton()
    }
    
    func updateBottomButton () {
        
    }

    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        print ("Will change content called")
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        print ("did change called")

        switch type {
        case .Insert:
            print ("... insert")
            //recordedChanges.append((.Insert,newIndexPath!))
        case .Delete:
            print ("... delete")
            //recordedChanges.append((.Delete,indexPath!))
        default:
            print ("... other")
            return
        }
    }
    
    // When endUpdates() is invoked, the table makes the changes visible.
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        print ("content all changed")
        
//        // rerun all the updates in a single batch
//        photoAlbumView.performBatchUpdates({
//            for (type,index) in self.recordedChanges {
//                switch type {
//                case .Insert:
//                    self.photoAlbumView.insertItemsAtIndexPaths([index])
//                case .Delete:
//                    self.photoAlbumView.deleteItemsAtIndexPaths([index])
//                default:
//                    continue
//                }
//            }
//            }, completion: {done in
//                dispatch_async(dispatch_get_main_queue(), {
//                    self.newCollection.enabled = true  // finally reanble the new collection button
//                })
//        })
    }
    
    @IBAction func NewCollectionButton(sender: UIBarButtonItem) {
    }
    
}

