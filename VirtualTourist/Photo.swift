//
//  Photo.swift
//  VirtualTourist
//
//  Created by Derrick Price on 3/22/16.
//  Copyright © 2016 DLP. All rights reserved.
//
// 1. Import CoreData
import CoreData
import UIKit

// 2. Make Location a subclass of NSManagedObject
class Photo : NSManagedObject {
    
    struct Keys {
        static let Photo_id = "id"
        static let Url = "url_m"
        static let Location = "location"
        static let Height = "height_m"
        static let Width = "width_m"
        static let Title = "title"
    }
    
    // 3. We are promoting these four from simple properties, to Core Data attributes
    @NSManaged var url: String
//    @NSManaged var location: Location?
    @NSManaged var id: String
    @NSManaged var title: String
    @NSManaged var height: String
    @NSManaged var width: String
    
    // 4. Include this standard Core Data init method.
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    /**
    * 5. The two argument init method
    *
    * The Two argument Init method. The method has two goals:
    *  - insert the new Person into a Core Data Managed Object Context
    *  - initialze the Person's properties from a dictionary
    */
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        // Get the entity associated with the "Person" type.  This is an object that contains
        // the information from the Model.xcdatamodeld file. We will talk about this file in
        // Lesson 4.
        let entity =  NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        
        // Now we can call an init method that we have inherited from NSManagedObject. Remember that
        // the Person class is a subclass of NSManagedObject. This inherited init method does the
        // work of "inserting" our object into the context that was passed in as a parameter
        super.init(entity: entity,insertIntoManagedObjectContext: context)
        
        // After the Core Data work has been taken care of we can init the properties from the
        // dictionary. This works in the same way that it did before we started on Core Data
        url = dictionary[Keys.Url] as! String
        id = dictionary[Keys.Photo_id] as! String!
        title = dictionary[Keys.Title] as! String!
        height = dictionary[Keys.Height] as! String!
        width = dictionary[Keys.Width] as! String!
        // DLP - Any reason to store the location?
//        location = newLocation
    }
    
    var image: UIImage? {
        get {
            return ImageCache.sharedInstance().imageWithIdentifier(id)
        }
        
        set {
            ImageCache.sharedInstance().storeImage(newValue, withIdentifier: id)
        }
    }
}


