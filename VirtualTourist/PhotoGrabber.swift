//
//  PhotoGrabber.swift
//  VirtualTourist
//
//  Created by Derrick Price on 4/2/16.
//  Copyright © 2016 DLP. All rights reserved.
//

import Foundation
import UIKit

// Global defines for the URL to use for Flickr
let BASE_URL = "https://api.flickr.com/services/rest/"
let METHOD_NAME = "flickr.photos.search"
let API_KEY = "519d52cdc4535b696a7bf81b9a3a5bc9"
let EXTRAS = "url_m"
let DATA_FORMAT = "json"
let NO_JSON_CALLBACK = "1"
let PHOTOS_PER_PAGE = "40"

var keyboardShowing = false
let BOUNDING_BOX_HALF_WIDTH = 1.0
let BOUNDING_BOX_HALF_HEIGHT = 1.0
let LAT_MIN = -90.0
let LAT_MAX = 90.0
let LON_MIN = -180.0
let LON_MAX = 180.0

class PhotoGrabber : NSObject {
    
    // Shared Instance
    class func sharedInstance() -> PhotoGrabber {
        
        struct Singleton {
            static var sharedInstance = PhotoGrabber()
        }
        
        return Singleton.sharedInstance
    }
    
    // Create the flickr search with the given arguments
    func doFlickrSearchWithArguments(methodArguments: [String : AnyObject], completionHandler: (photos: [[String: AnyObject]]?, errorString: String?) -> Void) {
    //-> array of photos
        /* 3 - Initialize session and url */
        let session = NSURLSession.sharedSession()
        let urlString = BASE_URL + escapedParameters(methodArguments)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        print("The URL: ", url)
        
        /* 4 - Initialize task for getting data */
        let task = session.dataTaskWithRequest(request) {(data, response, downloadError) in
            guard (downloadError == nil) else
            {
                print("Could not complete the request \(downloadError)")
                completionHandler (photos: nil, errorString: "Could not complete the request \(downloadError)")
                return
            }
            
            let parsedPhotosResult = try! NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments) as! NSDictionary
            
            if let prePhotoArray = parsedPhotosResult.valueForKey("photos") as? [String: AnyObject]//NSDictionary
            {
                var TotalNumOfPhotos = 0
                if let totalPhotos = prePhotoArray["total"] as? String
                {
                    TotalNumOfPhotos = (totalPhotos as NSString).integerValue
                }
                
                if (TotalNumOfPhotos == 0)
                {
                    // No pictures returned
                    print ( "No pictures found")
                    completionHandler (photos: nil, errorString: "No pictures found")
                }
                else
                {
                    // Show the number of photos returned
                    print("There are \(TotalNumOfPhotos) photos")
                    
                    /* GUARD: Is "photos" key in our result? */
                    guard let photosDictionary = parsedPhotosResult.valueForKey("photos") as? NSDictionary else {
                        print("Cannot find keys 'photos' in \(parsedPhotosResult.valueForKey)")
                        
                        completionHandler (photos: nil, errorString: "Cannot find keys 'photos' in \(parsedPhotosResult.valueForKey)")
                        return
                    }
                    
                    /* GUARD: Is "pages" key in the photosDictionary? */
                    guard let totalPages = photosDictionary["pages"] as? Int else {
                        print("Cannot find key 'pages' in \(photosDictionary)")
                        completionHandler (photos: nil, errorString: "Cannot find key 'pages' in \(photosDictionary)")
                        return
                    }
                    
                    /* Pick a random page! */
                    let pageLimit = min(totalPages, 40)
                    let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
                    print ("\n*****The page limit is \(pageLimit), the random page number is \(randomPage) *****")
                    
                    self.getImageFromFlickrBySearchWithPage(methodArguments, pageNumber: randomPage) { (photos, errorString) in
                        if let flickrPhotos = photos  {
                            
                            print ("There should be \(flickrPhotos.count) photos in doFlickrSearchWithArguments!")
                            // return the photos
                            completionHandler (photos: flickrPhotos, errorString: nil)
                            
                        } else {
                            print ("Unable to get photos from Flickr")
                            completionHandler (photos: nil, errorString: "Unable to get photos from Flickr")
                        }
                    }

                }
            }
            else
            {
                print ("Unable to parse results for photos")
            }
        }
        
        /* 9 - Resume (execute) the task */
        task.resume()
    }
    
    func getImageFromFlickrBySearchWithPage(methodArguments: [String : AnyObject], pageNumber: Int, completionHandler: (photos: [[String: AnyObject]]?, errorString: String?) -> Void)
    {
        
        /* Add the page to the method's arguments */
        var withPageDictionary = methodArguments
        withPageDictionary["page"] = pageNumber
        
        let session = NSURLSession.sharedSession()
        let urlString = BASE_URL + escapedParameters(withPageDictionary)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                print("There was an error with your request: \(error)")
                completionHandler (photos: nil, errorString: "There was an error with your request: \(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                if let response = response as? NSHTTPURLResponse {
                    print("Your request returned an invalid response! Status code: \(response.statusCode)!")
                } else if let response = response {
                    print("Your request returned an invalid response! Response: \(response)!")
                } else {
                    print("Your request returned an invalid response!")
                }
                
                completionHandler (photos: nil, errorString: "HTTP request failure")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                print("No data was returned by the request!")
                
                completionHandler (photos: nil, errorString: "No data was returned by the request!")
                return
            }
            
            /* Parse the data! */
            let parsedResult: AnyObject!
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
                parsedResult = nil
                print("Could not parse the data as JSON: '\(data)'")
                completionHandler (photos: nil, errorString: "Could not parse the data as JSON: '\(data)'")
                return
            }
            
            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = parsedResult["stat"] as? String where stat == "ok" else {
                print("Flickr API returned an error. See error code and message in \(parsedResult)")
                completionHandler (photos: nil, errorString: "Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            /* GUARD: Is the "photos" key in our result? */
            guard let photosDictionary = parsedResult["photos"] as? NSDictionary else {
                print("Cannot find key 'photos' in \(parsedResult)")
                completionHandler (photos: nil, errorString: "Cannot find key 'photos' in \(parsedResult)")
                return
            }
            
            /* GUARD: Is the "total" key in photosDictionary? */
            guard let totalPhotosVal = (photosDictionary["total"] as? NSString)?.integerValue else {
                print("Cannot find key 'total' in \(photosDictionary)")
                completionHandler (photos: nil, errorString: "Cannot find key 'total' in \(photosDictionary)")
                return
            }
            
            if totalPhotosVal > 0 {
                
                /* GUARD: Is the "photo" key in photosDictionary? */
                guard let photosArray = photosDictionary["photo"] as? [[String: AnyObject]] else {
                    print("Cannot find key 'photo' in \(photosDictionary)")
                    completionHandler (photos: nil, errorString: "Cannot find key 'photo' in \(photosDictionary)")
                    return
                }
                
//                print ("totalPhotosVal = \(totalPhotosVal), found \(photosArray.count) pictures")

                // Photo array
                completionHandler (photos: photosArray, errorString: nil)
                
            } else {
                print ("No Photos Found. Search Again.")
            }
        }
        
        task.resume()
    }
    
    /* Helper function: Given a dictionary of parameters, convert to a string for a url */
    func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            
            /* Escape it */
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            /* Append it */
            urlVars += [key + "=" + "\(escapedValue!)"]
            
        }
        
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }
    
    func pictureSearchByLatitudeLongitude (latitudeValue: Double, longitudeValue: Double, completionHandler: (photos: [[String: AnyObject]]?, errorString: String?) -> Void) {
    
        guard (latitudeValue > -90.0 && latitudeValue < 90.0) else
        {
            print ("Invalid latitude value")
            completionHandler (photos: nil, errorString: "Invalid latitude value")
            return
        }
        
        guard (longitudeValue > -180.0 && longitudeValue < 180.0) else
        {
            print ("Invalid longitude value")
            completionHandler (photos: nil, errorString: "Invalid longitude value")
            return
        }
        
        // Arguments used for URL
        let methodArguments: [String: String!] =
        [
            "method": METHOD_NAME,
            "api_key": API_KEY,
            "bbox": createBoundingBoxString(latitudeValue, lon: longitudeValue),
            "format": DATA_FORMAT,
            "extras":EXTRAS,
            "nojsoncallback": NO_JSON_CALLBACK,
            "per_page": PHOTOS_PER_PAGE
        ]
        
        // Make call to search
        doFlickrSearchWithArguments (methodArguments) { (photos, errorString) in
            if let flickrPhotos = photos  {
                
                print ("There should be \(flickrPhotos.count) photos from search!")
                // return the photos
                completionHandler (photos: flickrPhotos, errorString: nil)
                
            } else {
                print ("Unable to get photos from Flickr")
                completionHandler (photos: nil, errorString: "Unable to get photos from Flickr")
            }
        }
    }
    
    // Code to get the photo image from the URL
    func getPhotoImageFromDownload(photo: Photo, completionHandler: (imageData: NSData?, errorString: String?) -> Void) {
       
        let session = NSURLSession.sharedSession()
//        let urlString = BASE_URL + photo.url
//        let url = NSURL(string: urlString)!
        let url = NSURL(string: photo.url)!
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                print("There was an error with your request: \(error)")
                completionHandler(imageData: data, errorString: "Error retrieving photo: \(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                if let response = response as? NSHTTPURLResponse {
                    print("Your request returned an invalid response! Status code: \(response.statusCode)!")
                } else if let response = response {
                    print("Your request returned an invalid response! Response: \(response)!")
                } else {
                    print("Your request returned an invalid response!")
                }
                
                completionHandler(imageData: data, errorString: "HTTP request failure")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                print("No data was returned by the request!")
                
                completionHandler(imageData: nil, errorString: "No data was returned by the request!")
                return
            }
            
            completionHandler(imageData: data, errorString: nil)
        }
        
        task.resume()
    }
    
    func createBoundingBoxString(lat: Double, lon: Double) -> String {
        
        /* Fix added to ensure box is bounded by minimum and maximums */
        let bottom_left_lon = max(lon - BOUNDING_BOX_HALF_WIDTH, LON_MIN)
        let bottom_left_lat = max(lat - BOUNDING_BOX_HALF_HEIGHT, LAT_MIN)
        let top_right_lon = min(lon + BOUNDING_BOX_HALF_HEIGHT, LON_MAX)
        let top_right_lat = min(lat + BOUNDING_BOX_HALF_HEIGHT, LAT_MAX)
        
        return "\(bottom_left_lon),\(bottom_left_lat),\(top_right_lon),\(top_right_lat)"
    }
}

