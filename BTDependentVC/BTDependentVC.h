//
//  BTDependentVC.h
//  BTDependentVC
//
//  Created by Денис Либит on 11.07.2016.
//  Copyright © 2016 Денис Либит. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>


#pragma mark - BTDependentVC protocol

/**
 Methods of that protocol can be implemented by `UIViewController` subclasses to receive notifications on dependeciy changes and deletions.
 */
@protocol BTDependentVCDelegate <NSObject>

@optional

/**
 This method will be called when specific `NSManagedObject` that receiver depends on was deleted, its `NSManagedObjectContext` was reset or its `NSPersistentStore` was removed from `NSPersistentStoreCoordinator`.
 @param dependency `NSManagedObject` that was deleted.
 */
- (void)dvc_deleted:(NSManagedObject *)dependency;

/**
 This method will be called when there were changes in property values of specific `NSManagedObject` that receiver depends on.
 @param dependency `NSManagedObject` that was updated.
 */
- (void)dvc_updated:(NSManagedObject *)dependency;

@end


#pragma mark - UIViewController category

/**
 UIViewController category that detects and reports changes in NSManagedObject's state and properties and gracefully handles deletions.
 */
@interface UIViewController (BTDependentVC) <BTDependentVCDelegate>

/// Class property. Defines default behaviour of newly instantiated controllers. Default value is `YES`.
@property (class, nonatomic, assign) BOOL dvc_defaultAutoDismiss;
/// Will dismiss view controller when the value of this property is `YES` and any of its dependencies deleted.
@property (nonatomic, assign) BOOL dvc_autoDismiss;
/// `YES` to animate dismissal.
@property (nonatomic, assign) BOOL dvc_autoDismissAnimated;
/// List of view controller's dependencies.
@property (nonatomic, readonly) NSSet *dvc_dependencies;

/**
 Adds specified `NSManagedObject` to the list of dependencies and begins to watch for changes in its state and properties.
 @param dependency `NSManagedObject` that receiver should depend on.
 */
- (void)dvc_add:(NSManagedObject *)dependency;
/**
 Removes specified `NSManagedObject` from the list of dependencies and no longer tracks its changes.
 @param dependency `NSManagedObject` that receiver should no longer depend on.
 */
- (void)dvc_remove:(NSManagedObject *)dependency;
/**
 Removes all dependencies.
 */
- (void)dvc_removeAll;
/**
 Returns `YES` if specified `NSManagedObject` is currently listed as receiver's dependency.
 @param dependency `NSManagedObject` to check for.
 @return `YES` if the receiver depends on specified object, otherwise NO.
 */
- (BOOL)dvc_contains:(NSManagedObject *)dependency;

@end
