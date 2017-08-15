//
//  Flick+CoreDataProperties.swift
//  VirtualTourist-ObC
//
//  Created by Online Training on 8/13/17.
//  Copyright © 2017 Mitch Salcido. All rights reserved.
//

import Foundation
import CoreData


extension Flick {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Flick> {
        return NSFetchRequest<Flick>(entityName: "Flick")
    }

    @NSManaged public var urlString: String?
    @NSManaged public var imageData: NSData?
    @NSManaged public var pin: Pin?

}
