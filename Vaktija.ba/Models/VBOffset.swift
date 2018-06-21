//
//  VBOffset.swift
//  Vaktija.ba
//
//

import Foundation
import CoreData

/** 
 ### This class is used for manipulating data from VBOffset table in Core Data Stack.
 
 It contains information about offsets for prayer times for specific location.
*/

class VBOffset: NSManagedObject {

// Insert code here to add functionality to your managed object subclass
    
    /*
     
     /**
     Unique id in VBOffset table.
     */
     @NSManaged var id: Int64
     /**
     Offset for fajr and sunrise prayers.
     */
     @NSManaged var fajr: Int64
     /**
     Offset for dhuhr and jumuah prayers.
     */
     @NSManaged var dhuhr: Int64
     /**
     Offset for asr, maghrib and isha prayers.
     */
     @NSManaged var asr: Int64
     /**
     Id of the location.
     */
     @NSManaged var locationId: Int64
     /**
     Month in the year.
     */
     @NSManaged var month: Int64
     
    */

}
