# BTDependentVC

[![CI Status](http://img.shields.io/travis/bteapot/BTDependentVC.svg?style=flat)](https://travis-ci.org/bteapot/BTDependentVC)
[![Version](https://img.shields.io/cocoapods/v/BTDependentVC.svg?style=flat)](http://cocoapods.org/pods/BTDependentVC)
[![License](https://img.shields.io/cocoapods/l/BTDependentVC.svg?style=flat)](http://cocoapods.org/pods/BTDependentVC)
[![Platform](https://img.shields.io/cocoapods/p/BTDependentVC.svg?style=flat)](http://cocoapods.org/pods/BTDependentVC)

UIViewController category that detects and reports changes in NSManagedObject's state and properties and gracefully handles deletions.

### Features

- Integrates into every `UIViewController` subclass – `UITableViewController`, `UINavigationController`, etc.
- Tracks changes in multiple `NSManagedObject`s that can be of different Core Data entities, in contradistinction to `NSFetchedResultsController`.
- When one of its dependencies – `NSManagedObject`s – has been deleted:
	- Automatically dismisses itself if it was presented.
	- Pops to previous view controller if it was embedded in `UINavigationController`'s stack.
- Reports about deletions of dependencies and changes to they properties. 

### Usage scenario

The following `UITableViewController` subclass represents a customer form. It can be pushed into `UINavigationController`'s stack when user selects a row in customers list, or it can be presented as popover.

It will automatically change its title and values of interface elements when represented Core Data object changes, and will dismiss itself when that object removed from context.

``` objc
@interface BTCustomerVC : UIViewController

- (instancetype)initWithCustomer:(DBCustomer *)customer;

@end
```
``` objc
@implementation BTCustomerVC

- (instancetype)initWithCustomer:(DBCustomer *)customer
{
	self = [super init];
	
	if (!self) {
		return nil;
	}
	
	self.modalPresentationStyle = UIModalPresentationPopover;
	
	// add customer object as dependency
	[self dvc_add:customer];
	
	return self;
}

// optional method that will be called when dependency changed
- (void)dvc_updated:(NSManagedObject *)dependency
{
	if ([dependency isKindOfClass:[DBCustomer class]]) {
		DBCustomer *customer = (id)dependency;
		self.title = customer.name;
		self.positionLabel.text = customer.position;
	}
}
```

## Interface

### Properties

| Property | Type | Description |
|:---------|------|:------------|
| `dvc_defaultAutoDismiss` | `BOOL` | Class property. Defines default behaviour of newly instantiated controllers. Default value is `YES`. |
| `dvc_autoDismiss` | `BOOL` | Will dismiss view controller when the value of this property is `YES` and any of its dependencies deleted. |
| `dvc_autoDismissAnimated` | `BOOL` | `YES` to animate dismissal. |
| `dvc_dependencies` | `NSSet` | List of view controller's dependencies. |

### Methods

| Method | Description |
|:-------|:------------|
| `dvc_add:` | Adds specified `NSManagedObject` to the list of dependencies and begins to watch for changes in its state and properties. |
| `dvc_remove:` | Removes specified `NSManagedObject` from the list of dependencies and no longer tracks its changes. |
| `dvc_removeAll` | Removes all dependencies. |
| `dvc_contains:` | Returns `YES` if specified `NSManagedObject` is currently listed as receiver's dependency. |

### Optional methods

The following methods can be implemented in UIViewController's subclass.

| Method | Description |
|:-------|:------------|
| `dvc_deleted:` | This method will be called when specific `NSManagedObject` that receiver depends on was deleted, its `NSManagedObjectContext` was reset or its `NSPersistentStore` was removed from `NSPersistentStoreCoordinator`. |
| `dvc_updated:` | Will be called when there were changes in property values of specific `NSManagedObject`. |


## Requirements

- iOS 9.0+.
- Accepts `NSManagedObject`s that belongs to contexts of `NSMainQueueConcurrencyType`.

## Installation

BTDependentVC is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "BTDependentVC"
```

To run the example project, clone the repo, and run `pod install` from the Example directory first.

Import pod's header:

``` objc
#import <BTDependentVC/BTDependentVC.h>
```

## Author

Денис Либит,  
bteapot@me.com

## License

BTDependentVC is available under the MIT license. See the LICENSE file for more info.
