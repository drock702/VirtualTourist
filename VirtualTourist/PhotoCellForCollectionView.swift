//
//  PhotoCell.swift
//  VirtualTourist
//
//  Created by Derrick Price on 4/3/16.
//  Copyright © 2016 DLP. All rights reserved.
//
//

import UIKit

class PhotoCellForCollectionView: UICollectionViewCell {
    
    @IBOutlet weak var photoImage: UIImageView!
    
    var taskToCancelifCellIsReused: NSURLSessionTask? {
        
        didSet {
            if let taskToCancel = oldValue {
                taskToCancel.cancel()
            }
        }
    }
}
