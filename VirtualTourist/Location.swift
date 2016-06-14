//
//  Location.swift
//  VirtualTourist
//
//  Created by Derrick Price on 3/15/16.
//  Copyright © 2016 DLP. All rights reserved.
//

// 1. Import CoreData
import CoreData

// 2. Make Location a subclass of NSManagedObject
class Location : NSManagedObject {
    
    struct Keys {
        static let Name = "name"
        static let Lat = "latitude"
        static let Lon = "longitude"
        static let Photos = "photos"
    }
    
    // 3. We are promoting these four from simple properties, to Core Data attributes
    @NSManaged var name: String
    @NSManaged var latitude: NSNumber
    @NSManaged var longitude: NSNumber
    @NSManaged var photos: [Photo]
    
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
        let entity =  NSEntityDescription.entityForName("Location", inManagedObjectContext: context)!
        
        // Now we can call an init method that we have inherited from NSManagedObject. Remember that
        // the Person class is a subclass of NSManagedObject. This inherited init method does the
        // work of "inserting" our object into the context that was passed in as a parameter
        super.init(entity: entity,insertIntoManagedObjectContext: context)
        
        // After the Core Data work has been taken care of we can init the properties from the
        // dictionary. This works in the same way that it did before we started on Core Data
        name = dictionary[Keys.Name] as! String
        latitude = dictionary[Keys.Lat] as! Double
        longitude = dictionary[Keys.Lon] as! Double
    }
}


