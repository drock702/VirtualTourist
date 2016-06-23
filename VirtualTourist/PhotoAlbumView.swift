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
    var blockOperations: [NSBlockOperation] = []
    
    // Variables for the latitude and longitude for the map.
    var mapLatitude: Double = 200.0
    var mapLongitude: Double = 200.0
    var locationPhotos: [[String: AnyObject]]?
    var currentLocation: Location?
    
    // Core Data Convenience. This will be useful for fetching. And for adding and saving objects as well.
    lazy var sharedContext: NSManagedObjectContext =  {
        return CoreDataStackManager.sharedInstance().managedObjectContext
        }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.activityStatusIndicator.hidden = true
        self.newCollectionButton.enabled = false
        
        // Connect up delegates
        collectionView.delegate = self
        collectionView.dataSource = self
        fetchedResultsController.delegate = self
        
        // Configure the collection view.
        let screenSize = UIScreen.mainScreen().bounds
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: screenSize.width / 3, height: screenSize.width / 3)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        collectionView.setCollectionViewLayout(layout, animated: true)
        
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
            
            self.mapView.delegate = self
            self.mapView.zoomEnabled = false
            self.mapView.scrollEnabled = false
            self.mapView.pitchEnabled = false
            self.mapView.rotateEnabled = false
            
            self.mapView.setRegion(region, animated: true)
            
            // Here we create the annotation and set its coordiate, title, and subtitle properties
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            // When the array is complete, we add the annotations to the map.
            self.mapView.addAnnotation(annotation)
        }
        
        // Get the photos
        self.photoRefresh ()
        
        // Retrieve cached data
        if let fetchedobjects = self.fetchedResultsController.fetchedObjects?.count {
            if (fetchedobjects == 0) {
                
                print ("No photos cached, get fresh")
                // Clear the collection?
                collectionView.reloadData()
                self.retrieveFlickrPhotos ()
            }
            else {
                self.newCollectionButton.enabled = true
            }
        }
        else {
            self.newCollectionButton.enabled = true
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func saveContext() {
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    func photoRefresh () {
        // Start the fetched results controller
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print("Error performing fetch \(error)")
        }
    }
    
    func retrieveFlickrPhotos ()
    {
        // Start the animation
        dispatch_async(dispatch_get_main_queue()) {
            self.activityStatusIndicator.hidden = false
            self.activityStatusIndicator.startAnimating()
        }
        
        // Get pictures from Flickr to show
        FlickrClient.sharedInstance.pictureSearchByLatitudeLongitude (self.mapLatitude, longitudeValue: self.mapLongitude) { (photos: [[String: AnyObject]]?, errorString: String?) in
            
            if let newphotos = photos {
                self.locationPhotos = newphotos
                print ("pictureSearchByLatitudeLongitude - lat: \(self.mapLatitude), lon: \(self.mapLongitude) returned \(self.locationPhotos!.count) photos")
                
                // Get a photo to put in collection
                for photo in self.locationPhotos!
                {
                    // Now we create a new Photo, using the shared Context
                    let newphoto = Photo(dictionary: photo, context: self.sharedContext)
                    newphoto.place = self.currentLocation
                    
                    // Get the photo images
                    FlickrClient.sharedInstance.getPhotoImageFromDownload(newphoto) { (imageData, errorString)  in
                            
                        guard let imageData = imageData else {
                            print(errorString)
                            return
                        }
                        
                        let image = UIImage(data: imageData)
                        newphoto.image = image
                        
//                        dispatch_async(dispatch_get_main_queue()) {
//                            
//                            self.saveContext()
//                        }
                    }
                }
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                
                if let error = errorString {
                    print ("There was an error \(error)")
                }
                
                // End animation of status indicator
                self.activityStatusIndicator.hidden = true
                self.activityStatusIndicator.stopAnimating()
                
                // Enable the New Collection button
                self.newCollectionButton.enabled = true
            }
        }
    }
    
    @IBAction func goBack(sender: UIBarButtonItem) {
        
        if((self.presentingViewController) != nil){
            self.dismissViewControllerAnimated(false, completion: nil)
        }
    }
    
    @IBAction func newCollectionPress(sender: UIBarButtonItem) {
        print ("Create a new collection...")
         
//        for photo in (self.currentLocation?.photos)! {
//            self.sharedContext.deleteObject(photo as! NSManagedObject)
//        }
        
        // Delete current photos from the album
        for photo in fetchedResultsController.sections![0].objects as! [Photo] {
            self.sharedContext.deleteObject(photo)
        }
        
        // Delete local pictures?
       
        
        // Reset the array
        self.currentLocation?.photos = NSOrderedSet ()
        self.saveContext()
        self.retrieveFlickrPhotos ()
        self.collectionView.reloadData()
    }

    
    // MARK: - NSFetchedResultsController
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.sortDescriptors = []
        // Need to filter the photos y the location
        fetchRequest.predicate = NSPredicate(format: "place == %@", self.currentLocation!)
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    
    func fetchAllPhotos() -> [Photo] {
        
        print ("Call fetchAllPhotos!!\n\n")
        // Create the Fetch Request
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        
        // Execute the Fetch Request
        do {
            return try sharedContext.executeFetchRequest(fetchRequest) as! [Photo]
        } catch _ {
            return [Photo]()
        }
    }
    
    func configureCell(cell: PhotoCellForCollectionView, photo: Photo) {
        var placeholderImage = UIImage(named: "PlaceholderImage")
        
        if photo.image != nil {
            placeholderImage = photo.image!
        }
        
//        if cell.photoImage!.image != nil {
//            placeholderImage = cell.photoImage!.image!
//        }
        
        // Download the images
        let task = PhotoRetriever.sharedInstance().tasktoGetPhotoImage(photo.url) { data, error in
            
            if let error = error {
                print("Photo image download error: \(error.localizedDescription)")
            }
            
            if let data = data {
                // Create the image
                let image = UIImage(data: data)
                
                // update the photo, so it gets cached
                photo.image = image
                
                // update the cell on the main thread
                dispatch_async(dispatch_get_main_queue()) {
                    cell.photoImage!.image = image
                }
            }
        }
        
        // This is the custom property on this cell. See TaskCancelingTableViewCell.swift for details.
        cell.taskToCancelifCellIsReused = task
        
        cell.photoImage.image = placeholderImage
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        let numberOfObjects = self.fetchedResultsController.sections![section].numberOfObjects
        if numberOfObjects > 0 {
            self.displayLabel.hidden = true
        } else {
            self.displayLabel.hidden = false
        }
        return numberOfObjects
        
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCellForCollectionView", forIndexPath: indexPath) as! PhotoCellForCollectionView
        
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
//        print ("Get the cell at index \(indexPath) - the photo is \(photo.description)")
        
        self.configureCell(cell, photo: photo)
        
        return cell
    }
    
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        print("Delete didSelectItemAtIndexPath")
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        sharedContext.deleteObject(photo)
        saveContext()
        self.photoRefresh ()
        self.collectionView.reloadData()
    }

    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        blockOperations.removeAll(keepCapacity: false)
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        
        switch type {
        case .Insert:
            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        print("Calling to insert section")
                        this.collectionView!.insertSections(NSIndexSet(index: sectionIndex))
                    }
                    })
            )
        case .Delete:
            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        print("Calling to delete section")
                        this.collectionView!.deleteSections(NSIndexSet(index: sectionIndex))
                    }
                    })
            )
        default:
            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        print("Calling to reload (default) section")
                        this.collectionView!.reloadSections(NSIndexSet(index: sectionIndex))
                    }
                    })
            )
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type {
        case .Insert:
            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        print("Calling to insert object")
                        this.collectionView!.insertItemsAtIndexPaths([newIndexPath!])
                    }
                    })
            )
        case .Delete:
            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        print("Calling to delete object")
                        this.collectionView!.deleteItemsAtIndexPaths([indexPath!])
                    }
                    })
            )
        case .Update:
            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        print("Calling to reload object")
                        this.collectionView!.reloadItemsAtIndexPaths([indexPath!])
                    }
                    })
            )
        case .Move:
            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        print("Calling to move object")
                        this.collectionView!.moveItemAtIndexPath(indexPath!, toIndexPath: newIndexPath!)
                    }
                    })
            )
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        collectionView.performBatchUpdates({ () -> Void in
            for blockOperation in self.blockOperations {
                blockOperation.start()
            }
            }, completion: { (finished) -> Void in
//                print("Calling to remove all")
                self.blockOperations.removeAll(keepCapacity: false)
        })
        
    }
    
}

