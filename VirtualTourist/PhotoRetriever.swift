//
//  PhotoRetriever.swift
//  VirtualTourist
//
//  Created by Derrick Price on 5/28/16.
//  Copyright © 2016 DLP. All rights reserved.
//

import Foundation

class PhotoRetriever : NSObject {
    
    typealias CompletionHander = (result: AnyObject!, error: NSError?) -> Void
    
    var session: NSURLSession
    
    override init() {
        session = NSURLSession.sharedSession()
        super.init()
    }
    
    
    // MARK: - All purpose task method for data
    
//    func taskForResource(resource: String, parameters: [String : AnyObject], completionHandler: CompletionHander) -> NSURLSessionDataTask {
//        
//        var mutableParameters = parameters
//        var mutableResource = resource
//        
//        // Add in the API Key
//        mutableParameters["api_key"] = Constants.ApiKey
//        
//        // Substitute the id parameter into the resource
//        if resource.rangeOfString(":id") != nil {
//            assert(parameters[Keys.ID] != nil)
//            
//            mutableResource = mutableResource.stringByReplacingOccurrencesOfString(":id", withString: "\(parameters[Keys.ID]!)")
//            mutableParameters.removeValueForKey(Keys.ID)
//        }
//        
//        let urlString = Constants.BaseUrlSSL + mutableResource + TheMovieDB.escapedParameters(mutableParameters)
//        let url = NSURL(string: urlString)!
//        let request = NSURLRequest(URL: url)
//        
//        print(url)
//        
//        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
//            
//            if let error = downloadError {
//                let newError = TheMovieDB.errorForData(data, response: response, error: error)
//                completionHandler(result: nil, error: newError)
//            } else {
//                print("Step 3 - taskForResource's completionHandler is invoked.")
//                TheMovieDB.parseJSONWithCompletionHandler(data!, completionHandler: completionHandler)
//            }
//        }
//        
//        task.resume()
//        
//        return task
//    }
    
    // Task method for photo images from url
    
    func tasktoGetPhotoImage(fileURL: String, completionHandler: (imageData: NSData?, error: NSError?) ->  Void) -> NSURLSessionTask {
        
        let url = NSURL(string: fileURL)!
        let request = NSURLRequest(URL: url)
        
        print("URL for photo image: \(url)")
        
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            
            if let error = downloadError {
                let newError = PhotoRetriever.errorForData(data, response: response, error: error)
                completionHandler(imageData: nil, error: newError)
            } else {
                completionHandler(imageData: data, error: nil)
            }
        }
        
        task.resume()
        
        return task
    }
    
    // Try to make a better error, based on the status_message from TheMovieDB. If we cant then return the previous error
    
    class func errorForData(data: NSData?, response: NSURLResponse?, error: NSError) -> NSError {
        
        if data == nil {
            return error
        }
        
        do {
            let parsedResult = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)
            
            if let parsedResult = parsedResult as? [String : AnyObject], errorMessage = parsedResult["status_message"] as? String {
                let userInfo = [NSLocalizedDescriptionKey : errorMessage]
                return NSError(domain: "Photo Retriever Error", code: 1, userInfo: userInfo)
            }
            
        } catch _ {}
        
        return error
    }
    
    // Parsing the JSON
    
    class func parseJSONWithCompletionHandler(data: NSData, completionHandler: CompletionHander) {
        var parsingError: NSError? = nil
        
        let parsedResult: AnyObject?
        do {
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
        } catch let error as NSError {
            parsingError = error
            parsedResult = nil
        }
        
        if let error = parsingError {
            completionHandler(result: nil, error: error)
        } else {
            print("Step 4 - parseJSONWithCompletionHandler is invoked.")
            completionHandler(result: parsedResult, error: nil)
        }
    }
    
    // URL Encoding a dictionary into a parameter string
    
    class func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            // make sure that it is a string value
            let stringValue = "\(value)"
            
            // Escape it
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            // Append it
            
            if let unwrappedEscapedValue = escapedValue {
                urlVars += [key + "=" + "\(unwrappedEscapedValue)"]
            } else {
                print("Warning: trouble excaping string \"\(stringValue)\"")
            }
        }
        
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }
    
    
    // MARK: - Shared Instance of the Retriever
    
    class func sharedInstance() -> PhotoRetriever {
        
        struct Singleton {
            static var sharedInstance = PhotoRetriever()
        }
        
        return Singleton.sharedInstance
    }

}