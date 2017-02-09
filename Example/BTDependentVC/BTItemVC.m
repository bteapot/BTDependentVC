//
//  BTItemVC.m
//  BTDependentVC
//
//  Created by Денис Либит on 07.02.2017.
//  Copyright © 2017 Денис Либит. All rights reserved.
//

#import "BTItemVC.h"


@interface BTItemVC ()

@property (nonatomic, strong) UILabel *label;

@end


@implementation BTItemVC

#pragma mark - Intialization

//
// -----------------------------------------------------------------------------
- (instancetype)initWithObject:(DBObject *)object
{
	self = [super init];
	
	if (!self) {
		return nil;
	}
	
	self.modalPresentationStyle = UIModalPresentationPopover;
	
	[self dvc_add:object];
	
	return self;
}


#pragma mark - Lifecycle

//
// -----------------------------------------------------------------------------
- (void)viewDidLoad
{
	self.view.backgroundColor = [UIColor colorWithHue:((CGFloat)arc4random_uniform(101) / 100) saturation:0.75 brightness:1.00 alpha:1.00];
	
	self.label = [[UILabel alloc] initWithFrame:CGRectZero];
	self.label.numberOfLines = 0;
	self.label.textAlignment = NSTextAlignmentCenter;
	self.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle1];
	self.label.textColor = [UIColor whiteColor];
	[self.view addSubview:self.label];
	
	[self updateInterfaceWithObject:(id)self.dvc_dependencies.anyObject];
}

//
// -----------------------------------------------------------------------------
- (void)viewWillLayoutSubviews
{
	CGRect bounds = self.view.bounds;
	
	[self.label sizeToFit];
	self.label.center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
	
	self.label.frame = bounds;
}


#pragma mark - Tools

//
// -----------------------------------------------------------------------------
- (void)updateInterfaceWithObject:(DBObject *)object
{
	self.title = object.title;
	
	NSString *mode =
		self.navigationController ?
			[NSString stringWithFormat:@"Pushed"] :
			[NSString stringWithFormat:@"Presented by\r<%@ %p>\r[%@]", [self.presentingViewController class], self.presentingViewController, self.presentingViewController.title];
	
	self.label.text = [NSString stringWithFormat:@"<%@ %p>\r[%@]\r\r%@", [self class], self, self.title, mode];
	
	[self.view setNeedsLayout];
}


#pragma mark - BTDependentVC protocol

//
// -----------------------------------------------------------------------------
- (void)dvc_updated:(NSManagedObject *)dependency
{
	if ([dependency isKindOfClass:[DBObject class]]) {
		[self updateInterfaceWithObject:(id)dependency];
	}
}

//
// -----------------------------------------------------------------------------
- (void)dvc_deleted:(NSManagedObject *)dependency
{
	NSLog(@"<%@ %p> deleted dependency [%@]", [self class], self, [(DBObject *)dependency title]);
}

@end
