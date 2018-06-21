//
//  VBLocation+CoreDataProperties.swift
//  Vaktija.ba
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension VBLocation {

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

}
