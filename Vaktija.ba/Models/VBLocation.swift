//
//  VBLocation.swift
//  Vaktija.ba
//
//

import Foundation
import CoreData

/// ### This class is used for manipulating data from VBOffset table in Core Data Stack.
class VBLocation: NSManagedObject {

// Insert code here to add functionality to your managed object subclass
    
    /*
     /**
     Unique id in VBLocation table.
     */
     @NSManaged var id: Int64
     /**
     Name of the location.
     */
     @NSManaged var location: String?
     /**
     Name of the region.
     */
     @NSManaged var region: String?
     /**
     Represents priority of the location.
     
     Small value has bigger priority.
     */
     @NSManaged var weight: Int64
     */

}
