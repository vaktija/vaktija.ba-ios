//
//  VBCoreDataStack.swift
//  Vaktija.ba
//
//

import CoreData

/**
 ### Class used for creating Core Data stack for the project.
 */
class VBCoreDataStack
{
    /**
     Singleton of the `VBCoreDataStack` class.
    */
    static let sharedInstance = VBCoreDataStack()
    
    /**
     The directory the application uses to store the Core Data store file. 
     
     This code uses a App Group named "group.ba.vaktija.Vaktija.ba" in the application's provisioning profile.
    */
    lazy var applicationDocumentsDirectory: URL? =
    {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.ba.vaktija.Vaktija.ba")
    }()
    
    /**
     The managed object model for the application. 
     
     This property is not optional. It is a fatal error for the application not to be able to find and load its model.
    */
    lazy var managedObjectModel: NSManagedObjectModel =
    {
        let modelURL = Bundle.main.url(forResource: "Vaktija_ba", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    /**
     The persistent store coordinator for the application. 
     
     This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
    */
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator =
    {
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory!.appendingPathComponent("Vaktija_ba.sqlite")
        
        var failureReason = "There was an error creating or loading the application's saved data."
        
        do
        {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
        }
        catch
        {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            
            print("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            
            //abort()
        }
        
        return coordinator
    }()
    
    /**
     Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application).
     
     This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
    */
    lazy var managedObjectContext: NSManagedObjectContext =
    {
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    /**
     Saves all changes made to Managed Object Context to the app's cache.
     */
    func saveContext ()
    {
        if managedObjectContext.hasChanges
        {
            do
            {
                try managedObjectContext.save()
            }
            catch
            {
                let nserror = error as NSError
                print("Unresolved error \(nserror), \(nserror.userInfo)")
                
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                //abort()
            }
        }
    }
}
