//
//  VBSchedule.swift
//  Vaktija.ba
//
//

import Foundation
import CoreData

/// ### This class is used for manipulating data from VBOffset table in Core Data Stack.
class VBSchedule: NSManagedObject {

// Insert code here to add functionality to your managed object subclass
    
    /*
     /*
     Unique id in VBSchedule table.
     
     Also, represents day in the year with 366 days.
     */
     @NSManaged var id: Int64
     /*
     Day in the month.
     */
     @NSManaged var day: Int64
     /*
     Time in format `hours:minutes` for fajr prayer.
     */
     @NSManaged var fajr: String?
     /*
     Time in format `hours:minutes` for sunrise prayer.
     */
     @NSManaged var sunrise: String?
     /*
     Time in format `hours:minutes` for dhuhr prayer.
     
     Also, if day happens to be friday, this is time for jumah prayer.
     */
     @NSManaged var dhuhr: String?
     /*
     Time in format `hours:minutes` for asr prayer.
     */
     @NSManaged var asr: String?
     /*
     Time in format `hours:minutes` for maghrib prayer.
     */
     @NSManaged var maghrib: String?
     /*
     Time in format `hours:minutes` for isha prayer.
     */
     @NSManaged var isha: String?
     /*
     Month in the year.
     */
     @NSManaged var month: Int64
    */

}
