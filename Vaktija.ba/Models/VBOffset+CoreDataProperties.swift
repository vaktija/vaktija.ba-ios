//
//  VBOffset+CoreDataProperties.swift
//  Vaktija.ba
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension VBOffset {

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
     
     This is foreign key for VBLocation table.
     */
    @NSManaged var locationId: Int64
    /**
     Month in the year.
     */
    @NSManaged var month: Int64

}
