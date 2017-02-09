//
//  BTControllersTVC.m
//  BTDependentVC
//
//  Created by Денис Либит on 07.02.2017.
//  Copyright © 2017 Денис Либит. All rights reserved.
//

#import "BTControllersTVC.h"
#import "BTRootVC.h"
#import "BTItemVC.h"


@interface BTControllersTVC ()

@property (nonatomic, weak) BTRootVC *rootVC;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSArray *controllers;
@property (nonatomic, assign) CGSize previousSize;

@end


@implementation BTControllersTVC

#pragma mark - Intialization

//
// -----------------------------------------------------------------------------
- (instancetype)initWithRootVC:(BTRootVC *)rootVC
{
	self = [super init];
	
	if (!self) {
		return nil;
	}
	
	self.rootVC = rootVC;
	self.timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(reload) userInfo:nil repeats:YES];
	
	self.title = @"View controllers";
	self.toolbarItems = @[
		[[UIBarButtonItem alloc] initWithTitle:@"Modal" style:UIBarButtonItemStylePlain target:self action:@selector(modal)],
		[[UIBarButtonItem alloc] initWithTitle:@"Popover" style:UIBarButtonItemStylePlain target:self action:@selector(popover)],
		[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
		[[UIBarButtonItem alloc] initWithTitle:@"Push" style:UIBarButtonItemStylePlain target:self action:@selector(push)],
	];
	
	return self;
}

//
// -----------------------------------------------------------------------------
- (void)dealloc
{
	[self.timer invalidate];
}


#pragma mark - Lifecycle

//
// -----------------------------------------------------------------------------
- (void)viewDidLoad
{
	[super viewDidLoad];
	
	UILabel *footerLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	footerLabel.text = [NSString stringWithFormat:@"Add view controllers by pushing them\rinto UINavigationController stack\ror by presenting them over current context or modally.\r\rEach view controller\rwill have a newly inserted\rCore Data object as dependency.\r\rSelect row to pop\rcorresponding view controller.\r\rThis list refreshed every %0.2f seconds.", self.timer.timeInterval];
	footerLabel.numberOfLines = 0;
	footerLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
	footerLabel.textAlignment = NSTextAlignmentCenter;
	footerLabel.textColor = [UIColor lightGrayColor];
	
	self.tableView.tableFooterView = footerLabel;
}

//
// -----------------------------------------------------------------------------
- (void)viewWillLayoutSubviews
{
	[super viewWillLayoutSubviews];
	
	CGSize size = self.view.bounds.size;
	
	if (!CGSizeEqualToSize(size, self.previousSize)) {
		self.previousSize = size;
		
		UILabel *footerLabel = (id)self.tableView.tableFooterView;
		
		CGRect textRect = [footerLabel.attributedText boundingRectWithSize:CGSizeMake(size.width, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading) context:nil];
		footerLabel.frame = CGRectMake(0, 0, size.width, ceil(textRect.size.height + 20));
		self.tableView.tableFooterView = footerLabel;
	}
}


#pragma mark - Tools

//
// -----------------------------------------------------------------------------
- (void)reload
{
	[self.tableView beginUpdates];
	
	NSArray *oldControllers = self.controllers;
	NSMutableArray *newControllers = [NSMutableArray arrayWithArray:self.rootVC.ncStack.viewControllers];
	
	UIViewController *presentedVC = self.rootVC.ncStack.presentedViewController;
	
	while (presentedVC) {
		[newControllers addObject:presentedVC];
		presentedVC = presentedVC.presentedViewController;
	}
	
	for (NSUInteger row = 0; row < oldControllers.count; row++) {
		UIViewController *vc = oldControllers[row];
		
		if (![newControllers containsObject:vc]) {
			[self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:row inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
		}
	}
	
	for (NSUInteger row = 0; row < newControllers.count; row++) {
		UIViewController *vc = newControllers[row];
		NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
		
		if (![oldControllers containsObject:vc]) {
			[self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
		}
	}
	
	self.controllers = [newControllers copy];
	
	[self.tableView endUpdates];
	
	
	for (NSIndexPath *indexPath in self.tableView.indexPathsForVisibleRows) {
		UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
		UIViewController *vc = newControllers[indexPath.row];
		[self configureCell:cell withVC:vc];
	}
}

//
// -----------------------------------------------------------------------------
- (UIImage *)patchWithColor:(UIColor *)color
{
	CGSize size = CGSizeMake(24, 24);
	
	UIGraphicsBeginImageContextWithOptions(size, NO, 0);
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	CGContextSaveGState(ctx);
	
	CGRect rect = CGRectMake(0, 0, size.width, size.height);
	CGContextSetFillColorWithColor(ctx, color.CGColor);
	CGContextFillEllipseInRect(ctx, rect);
	
	CGContextRestoreGState(ctx);
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return image;
}

//
// -----------------------------------------------------------------------------
- (void)modal
{
	DBObject *object = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([DBObject class]) inManagedObjectContext:BTDataSource.shared.mainContext];
	
	object.title = [NSString stringWithFormat:@"Object %@", @(arc4random_uniform(1000))];
	object.date = [NSDate date];
	
	[BTDataSource.shared.mainContext save:nil];
	
	BTRootVC *vc = [[BTRootVC alloc] initWithObject:object];
	
	UIViewController *presenterVC = self.rootVC.ncStack.viewControllers.lastObject;
	
	if (!presenterVC) {
		presenterVC = self.rootVC.ncStack;
	}
	
	while (presenterVC.presentedViewController) {
		presenterVC = presenterVC.presentedViewController;
	}
	
	[presenterVC presentViewController:vc animated:YES completion:nil];
}

//
// -----------------------------------------------------------------------------
- (void)popover
{
	DBObject *object = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([DBObject class]) inManagedObjectContext:BTDataSource.shared.mainContext];
	
	object.title = [NSString stringWithFormat:@"Object %@", @(arc4random_uniform(1000))];
	object.date = [NSDate date];
	
	[BTDataSource.shared.mainContext save:nil];
	
	BTRootVC *vc = [[BTRootVC alloc] initWithObject:object];
	
	UIViewController *presenterVC = self.rootVC.ncStack.viewControllers.lastObject;
	
	if (!presenterVC) {
		presenterVC = self.rootVC.ncStack;
	}
	
	while (presenterVC.presentedViewController) {
		presenterVC = presenterVC.presentedViewController;
	}
	
	UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:vc];
	nc.modalPresentationStyle = UIModalPresentationPopover;
	nc.view.backgroundColor = [UIColor brownColor];
	
	[presenterVC presentViewController:nc animated:YES completion:nil];
	
	UIPopoverPresentationController *ppc = nc.popoverPresentationController;
	ppc.barButtonItem = self.toolbarItems.lastObject;
}

//
// -----------------------------------------------------------------------------
- (void)push
{
	DBObject *object = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([DBObject class]) inManagedObjectContext:BTDataSource.shared.mainContext];
	
	object.title = [NSString stringWithFormat:@"Object %@", @(arc4random_uniform(1000))];
	object.date = [NSDate date];
	
	[BTDataSource.shared.mainContext save:nil];
	
	BTItemVC *vc = [[BTItemVC alloc] initWithObject:object];
	[self.rootVC.ncStack pushViewController:vc animated:YES];
}


#pragma mark - UITableView data source

//
// -----------------------------------------------------------------------------
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

//
// -----------------------------------------------------------------------------
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return self.controllers.count;
}

//
// -----------------------------------------------------------------------------
- (void)configureCell:(UITableViewCell *)cell withVC:(UIViewController *)vc
{
	NSString *mode = vc.navigationController ? @"Pushed" : @"Presented";
	cell.textLabel.text = [NSString stringWithFormat:@"<%@ %p>", [vc class], vc];
	cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ [%@]", mode, vc.title];
	cell.imageView.image = [self patchWithColor:vc.view.backgroundColor];
}

//
// -----------------------------------------------------------------------------
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"controllersCellID"];
	
	if (!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"controllersCellID"];
		cell.textLabel.numberOfLines = 1;
		cell.textLabel.adjustsFontSizeToFitWidth = YES;
		cell.textLabel.minimumScaleFactor = 0.1;
		cell.detailTextLabel.numberOfLines = 1;
		cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
		cell.detailTextLabel.minimumScaleFactor = 0.1;
	}
	
	UIViewController *vc = self.controllers[indexPath.row];
	[self configureCell:cell withVC:vc];
	
	return cell;
}


#pragma mark - UITableView delegate

//
// -----------------------------------------------------------------------------
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	UIViewController *vc = self.controllers[indexPath.row];
	
	if (vc.presentingViewController) {
		[vc.presentingViewController dismissViewControllerAnimated:YES completion:nil];
	} else {
		if (indexPath.row == 0) {
			[self.rootVC.ncStack setViewControllers:@[] animated:YES];
		} else {
			UIViewController *vc = self.controllers[indexPath.row - 1];
			[self.rootVC.ncStack popToViewController:vc animated:YES];
		}
	}
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
