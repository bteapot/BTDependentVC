//
//  BTDependentVC.m
//  BTDependentVC
//
//  Created by Денис Либит on 11.07.2016.
//  Copyright © 2016 Денис Либит. All rights reserved.
//

#import "BTDependentVC.h"
#import <objc/runtime.h>


#pragma mark - Internal interfaces

@interface BTDVCController : NSObject

@property (class, nonatomic, assign) BOOL defaultAutoDismiss;
@property (nonatomic, weak) UIViewController *vc;
@property (nonatomic, assign) BOOL autoDismiss;
@property (nonatomic, assign) BOOL autoDismissAnimated;
@property (nonatomic, strong) NSMapTable *repo;
@property (nonatomic, readonly) NSSet *dependencies;

@end


@interface UIViewController (BTDVCInternal)

@property (nonatomic, readonly) BTDVCController *dvc_controller;

- (void)dvc_dismiss:(BOOL)animated;

@end


#pragma mark - BTDVCController implementation

@implementation BTDVCController

#pragma mark - Class properties

static BOOL _defaultAutoDismiss;

//
// -----------------------------------------------------------------------------
+ (BOOL)defaultAutoDismiss
{
	return _defaultAutoDismiss;
}

//
// -----------------------------------------------------------------------------
+ (void)setDefaultAutoDismiss:(BOOL)defaultAutoDismiss
{
	_defaultAutoDismiss = defaultAutoDismiss;
}


#pragma mark - Class initializing

//
// -----------------------------------------------------------------------------
+ (void)initialize
{
	if (self == [UIViewController self]) {
		self.defaultAutoDismiss = YES;
	}
}


#pragma mark - Lifecycle

//
// -----------------------------------------------------------------------------
- (instancetype)initWithVC:(UIViewController *)vc
{
	self = [super init];
	
	if (!self) {
		return nil;
	}
	
	self.vc = vc;
	self.autoDismiss = BTDVCController.defaultAutoDismiss;
	self.autoDismissAnimated = YES;
	self.repo = [NSMapTable strongToStrongObjectsMapTable];
	
	return self;
}

//
// -----------------------------------------------------------------------------
- (void)dealloc
{
	[self removeAll];
}


#pragma mark - Dependencies

//
// -----------------------------------------------------------------------------
- (NSSet *)dependencies
{
	NSMutableSet *set = [NSMutableSet setWithCapacity:self.repo.count];
	
	for (NSManagedObject *dependency in self.repo) {
		[set addObject:dependency];
	}
	
	return [set copy];
}

//
// -----------------------------------------------------------------------------
- (void)add:(NSManagedObject *)dependency
{
	// valid object?
	NSManagedObjectContext *context = dependency.managedObjectContext;
	
	if (!dependency || !context) {
		return;
	}
	
	#ifdef DEBUG
	NSAssert(context.concurrencyType == NSMainQueueConcurrencyType, @"dvc error: only accepting objects of contexts with NSMainQueueConcurrencyType.");
	#endif
	
	// already subscribed to changes in that context?
	BOOL subscribed = NO;
	
	for (NSManagedObject *d in self.repo) {
		NSManagedObjectContext *c = [self.repo objectForKey:d];
		
		if (c == context) {
			subscribed = YES;
			break;
		}
	}
	
	// should subscribe to changes in that context?
	if (!subscribed) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contextDidChange:) name:NSManagedObjectContextObjectsDidChangeNotification object:context];
	}
	
	// add object and its context to list
	[self.repo setObject:context forKey:dependency];
}

//
// -----------------------------------------------------------------------------
- (void)remove:(NSManagedObject *)dependency
{
	// valid object?
	if (!dependency) {
		return;
	}
	
	// dependency already in the list?
	NSManagedObjectContext *context = [self.repo objectForKey:dependency];
	
	if (!context) {
		return;
	}
	
	// remove dependency from list
	[self.repo removeObjectForKey:dependency];
	
	// it was the last dependency of that context?
	BOOL unsubscribe = YES;
	
	for (NSManagedObject *d in self.repo) {
		NSManagedObjectContext *c = [self.repo objectForKey:d];
		
		if (c == context) {
			unsubscribe = NO;
			break;
		}
	}
	
	// should unsubscribe from changes in that context?
	if (unsubscribe) {
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextObjectsDidChangeNotification object:context];
	}
}

//
// -----------------------------------------------------------------------------
- (void)removeAll
{
	// dependencies list
	NSMutableSet *dependencies = [NSMutableSet setWithCapacity:self.repo.count];
	
	for (NSManagedObject *dependency in self.repo) {
		[dependencies addObject:dependency];
	}
	
	// remove all dependencies
	for (NSManagedObject *dependency in dependencies) {
		[self remove:dependency];
	}
}

//
// -----------------------------------------------------------------------------
- (BOOL)contains:(NSManagedObject *)dependency
{
	return [self.repo objectForKey:dependency] != nil;
}


#pragma mark - Context changes

//
// -----------------------------------------------------------------------------
- (void)contextDidChange:(NSNotification *)notification
{
	NSManagedObjectContext *context = notification.object;
	
	if (context.concurrencyType == NSMainQueueConcurrencyType) {
		[self processContextChanges:notification];
	} else {
		dispatch_async(dispatch_get_main_queue(), ^{
			[self processContextChanges:notification];
		});
	}
}

//
// -----------------------------------------------------------------------------
- (void)processContextChanges:(NSNotification *)notification
{
	NSDictionary *userInfo = notification.userInfo;
	
	NSArray *invalidatedAll	= userInfo[NSInvalidatedAllObjectsKey];
	NSSet *invalidated		= userInfo[NSInvalidatedObjectsKey];
	NSSet *deleted			= userInfo[NSDeletedObjectsKey];
	NSSet *updated			= userInfo[NSUpdatedObjectsKey];
	NSSet *refreshed		= userInfo[NSRefreshedObjectsKey];
	
	// dependencies list
	NSMutableSet *dependencies = [NSMutableSet setWithCapacity:self.repo.count];
	
	for (NSManagedObject *dependency in self.repo) {
		[dependencies addObject:dependency];
	}
	
	// reset
	if (invalidatedAll) {
		for (NSManagedObject *dependency in dependencies) {
			[self remove:dependency];
			[self deleted:dependency];
			[self dismiss];
		}
		
		return;
	}
	
	// invalidated
	for (NSManagedObject *dependency in dependencies) {
		if ([invalidated containsObject:dependency]) {
			[self remove:dependency];
			[self deleted:dependency];
			[self dismiss];
		}
	}
	
	
	// deleted
	for (NSManagedObject *dependency in dependencies) {
		if ([deleted containsObject:dependency]) {
			[self remove:dependency];
			[self deleted:dependency];
			[self dismiss];
		}
	}
	
	// refreshed
	for (NSManagedObject *dependency in dependencies) {
		if ([refreshed containsObject:dependency]) {
			[dependency willAccessValueForKey:nil];
			[self updated:dependency];
		}
	}
	
	// updated
	for (NSManagedObject *dependency in dependencies) {
		if ([updated containsObject:dependency]) {
			[self updated:dependency];
		}
	}
}


#pragma mark - Reaction to changes

//
// -----------------------------------------------------------------------------
- (void)deleted:(NSManagedObject *)dependency
{
	UIViewController *vc = self.vc;
	
	if (vc && [vc respondsToSelector:@selector(dvc_deleted:)]) {
		[vc dvc_deleted:dependency];
	}
}

//
// -----------------------------------------------------------------------------
- (void)updated:(NSManagedObject *)dependency
{
	UIViewController *vc = self.vc;
	
	if (vc && [vc respondsToSelector:@selector(dvc_updated:)]) {
		[vc dvc_updated:dependency];
	}
}

//
// -----------------------------------------------------------------------------
- (void)dismiss
{
	UIViewController *vc = self.vc;
	
	if (vc) {
		[vc dvc_dismiss:self.autoDismissAnimated];
	}
}

@end


#pragma mark - BTDependentVC category implementation

@implementation UIViewController (BTDependentVC)

#pragma mark - Class properties

//
// -----------------------------------------------------------------------------
+ (BOOL)dvc_defaultAutoDismiss
{
	return BTDVCController.defaultAutoDismiss;
}

//
// -----------------------------------------------------------------------------
+ (void)setDvc_defaultAutoDismiss:(BOOL)dvc_defaultAutoDismiss
{
	BTDVCController.defaultAutoDismiss = dvc_defaultAutoDismiss;
}


#pragma mark - Instance properties

//
// -----------------------------------------------------------------------------
- (BTDVCController *)dvc_controller
{
	BTDVCController *controller = objc_getAssociatedObject(self, @selector(dvc_controller));
	
	if (!controller) {
		controller = [[BTDVCController alloc] initWithVC:self];
		objc_setAssociatedObject(self, @selector(dvc_controller), controller, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
	
	return controller;
}

//
// -----------------------------------------------------------------------------
- (NSSet *)dvc_dependencies
{
	return self.dvc_controller.dependencies;
}

//
// -----------------------------------------------------------------------------
- (BOOL)dvc_autoDismiss
{
	return self.dvc_controller.autoDismiss;
}

//
// -----------------------------------------------------------------------------
- (void)setDvc_autoDismiss:(BOOL)dvc_autoDismiss
{
	self.dvc_controller.autoDismiss = dvc_autoDismiss;
}

//
// -----------------------------------------------------------------------------
- (BOOL)dvc_autoDismissAnimated
{
	return self.dvc_controller.autoDismissAnimated;
}

//
// -----------------------------------------------------------------------------
- (void)setDvc_autoDismissAnimated:(BOOL)dvc_autoDismissAnimated
{
	self.dvc_controller.autoDismissAnimated = dvc_autoDismissAnimated;
}


#pragma mark - Instance methods

//
// -----------------------------------------------------------------------------
- (void)dvc_add:(NSManagedObject *)dependency
{
	[self.dvc_controller add:dependency];
}

//
// -----------------------------------------------------------------------------
- (void)dvc_remove:(NSManagedObject *)dependency
{
	[self.dvc_controller remove:dependency];
}

//
// -----------------------------------------------------------------------------
- (void)dvc_removeAll
{
	[self.dvc_controller removeAll];
}

//
// -----------------------------------------------------------------------------
- (BOOL)dvc_contains:(NSManagedObject *)dependency
{
	return [self.dvc_controller contains:dependency];
}

//
// -----------------------------------------------------------------------------
- (void)dvc_dismiss:(BOOL)animated
{
	UIViewController *presentingVC = self.presentingViewController;
	UINavigationController *navigationVC = self.navigationController;
	
	if (navigationVC) {
		NSArray *viewControllers = navigationVC.viewControllers;
		NSUInteger index = [viewControllers indexOfObject:self];
		
		switch (index) {
			case 0: {
				if (navigationVC.presentingViewController) {
					[navigationVC.presentingViewController dismissViewControllerAnimated:animated completion:nil];
				} else {
					[navigationVC setViewControllers:@[] animated:animated];
				}
				break;
			}
			case NSNotFound: {
				break;
			}
			default: {
				UIViewController *previousVC = viewControllers[index - 1];
				[navigationVC popToViewController:previousVC animated:animated];
				break;
			}
		}
	} else {
		[presentingVC dismissViewControllerAnimated:animated completion:nil];
	}
}

@end
