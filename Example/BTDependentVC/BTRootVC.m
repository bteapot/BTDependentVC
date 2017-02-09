//
//  BTRootVC.m
//  BTDependentVC
//
//  Created by Денис Либит on 07.02.2017.
//  Copyright © 2017 Денис Либит. All rights reserved.
//

#import "BTRootVC.h"
#import "BTControllersTVC.h"
#import "BTObjectsTVC.h"
#import "BTItemVC.h"


@interface BTRootVC ()

@property (nonatomic, strong) UINavigationController *ncObjects;
@property (nonatomic, strong) UINavigationController *ncControllers;
@property (nonatomic, strong) UINavigationController *ncStack;
@property (nonatomic, strong) UIView *separatorV;
@property (nonatomic, strong) UIView *separatorH;

@end


@implementation BTRootVC

#pragma mark - Intialization

//
// -----------------------------------------------------------------------------
- (instancetype)initWithObject:(DBObject *)object
{
	self = [super init];
	
	if (!self) {
		return nil;
	}
	
	self.modalPresentationStyle = UIModalPresentationPageSheet;
	self.preferredContentSize = UIEdgeInsetsInsetRect([[UIScreen mainScreen] bounds], UIEdgeInsetsMake(80, 80, 80, 80)).size;
	self.edgesForExtendedLayout = UIRectEdgeNone;
	
	[self dvc_add:object];
	
	return self;
}


#pragma mark - Lifecycle

//
// -----------------------------------------------------------------------------
- (void)viewDidLoad
{
	self.view.backgroundColor = [UIColor lightGrayColor];
	
	if (self.dvc_dependencies.count > 0) {
		DBObject *object = self.dvc_dependencies.anyObject;
		self.title = object.title;
	}
	
	// stack controller
	self.ncStack = [[UINavigationController alloc] init];
	
	[self addChildViewController:self.ncStack];
	[self.view addSubview:self.ncStack.view];
	[self.ncStack didMoveToParentViewController:self];
	
	// objects table
	self.ncObjects = [[UINavigationController alloc] initWithRootViewController:[[BTObjectsTVC alloc] initWithRootVC:self]];
	
	[self addChildViewController:self.ncObjects];
	[self.view addSubview:self.ncObjects.view];
	[self.ncObjects didMoveToParentViewController:self];
	
	// controllers table
	self.ncControllers = [[UINavigationController alloc] initWithRootViewController:[[BTControllersTVC alloc] initWithRootVC:self]];
	self.ncControllers.toolbarHidden = NO;
	
	[self addChildViewController:self.ncControllers];
	[self.view addSubview:self.ncControllers.view];
	[self.ncControllers didMoveToParentViewController:self];
	
	// separators
	self.separatorV = [[UIView alloc] initWithFrame:CGRectZero];
	self.separatorV.backgroundColor = [UIColor lightGrayColor];
	[self.view addSubview:self.separatorV];
	
	self.separatorH = [[UIView alloc] initWithFrame:CGRectZero];
	self.separatorH.backgroundColor = [UIColor lightGrayColor];
	[self.view addSubview:self.separatorH];
}

//
// -----------------------------------------------------------------------------
- (void)viewWillLayoutSubviews
{
	CGRect bounds					= self.view.bounds;
	CGFloat separatorWidth			= 1;
	CGFloat leftPartWidth			= ceil(bounds.size.width * 0.5);
	CGFloat rightPartWidth			= bounds.size.width - leftPartWidth - separatorWidth;
	CGFloat halfHeight				= ceil(bounds.size.height / 2);
	
	self.ncObjects.view.frame		= CGRectMake(0, bounds.origin.y, leftPartWidth, halfHeight - separatorWidth);
	self.ncControllers.view.frame	= CGRectMake(0, halfHeight, leftPartWidth, halfHeight);
	self.ncStack.view.frame			= CGRectMake(leftPartWidth + separatorWidth, 0, rightPartWidth, bounds.size.height);
	
	self.separatorV.frame			= CGRectMake(leftPartWidth, 0, separatorWidth, bounds.size.height);
	self.separatorH.frame			= CGRectMake(0, halfHeight, leftPartWidth, separatorWidth);
}


#pragma mark - BTDependentVC protocol

//
// -----------------------------------------------------------------------------
- (void)dvc_updated:(NSManagedObject *)dependency
{
	if ([dependency isKindOfClass:[DBObject class]]) {
		DBObject *object = (id)dependency;
		self.title = object.title;
	}
}

//
// -----------------------------------------------------------------------------
- (void)dvc_deleted:(NSManagedObject *)dependency
{
	NSLog(@"<%@ %p> deleted dependency [%@]", [self class], self, [(DBObject *)dependency title]);
}

@end
