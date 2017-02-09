//
//  BTObjectsTVC.m
//  BTDependentVC
//
//  Created by Денис Либит on 07.02.2017.
//  Copyright © 2017 Денис Либит. All rights reserved.
//

#import "BTObjectsTVC.h"
#import "BTRootVC.h"


@interface BTObjectsTVC () <NSFetchedResultsControllerDelegate>

@property (nonatomic, weak) BTRootVC *rootVC;
@property (nonatomic, strong) NSFetchedResultsController *frc;
@property (nonatomic, strong) UIBarButtonItem *buttonClear;
@property (nonatomic, assign) CGSize previousSize;

@end


@implementation BTObjectsTVC

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
	
	self.title = @"Core Data objects";
	
	self.buttonClear = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(clear)];
	
	self.navigationItem.rightBarButtonItems = @[
		self.buttonClear,
		//self.editButtonItem,
	];
	
	NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([DBObject class])];
	request.sortDescriptors = @[
		[NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(date)) ascending:YES],
	];
	
	self.frc = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:BTDataSource.shared.mainContext sectionNameKeyPath:nil cacheName:nil];
	self.frc.delegate = self;
	
	[self.frc performFetch:nil];
	
	self.buttonClear.enabled = self.frc.fetchedObjects.count > 0;
	
	return self;
}

//
// -----------------------------------------------------------------------------
- (void)dealloc
{
	self.frc.delegate = nil;
}


#pragma mark - Lifecycle

//
// -----------------------------------------------------------------------------
- (void)viewDidLoad
{
	[super viewDidLoad];
	
	UILabel *footerLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	footerLabel.text = @"Delete Core Data objects\rby right-to-left swipe on cells.\r\rRename objects\rby tapping cell's accessory button.";
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
- (void)clear
{
	[BTDataSource.shared.backgroundContext performBlock:^{
		NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([DBObject class])];
		NSArray *objects = [BTDataSource.shared.backgroundContext executeFetchRequest:request error:nil];
		
		for (DBObject *object in objects) {
			[BTDataSource.shared.backgroundContext deleteObject:object];
		}
		
		[BTDataSource.shared.backgroundContext save:nil];
	}];
}


#pragma mark - NSFetchedResultsController delegate

//
// -----------------------------------------------------------------------------
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
	[self.tableView beginUpdates];
}

//
// -----------------------------------------------------------------------------
- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
	switch (type) {
		case NSFetchedResultsChangeInsert:
			[self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
			break;
		case NSFetchedResultsChangeDelete:
			[self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
			break;
		case NSFetchedResultsChangeUpdate:
		case NSFetchedResultsChangeMove:
			break;
	}
}

//
// -----------------------------------------------------------------------------
- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(DBObject *)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
	switch(type) {
		case NSFetchedResultsChangeInsert:
			[self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;
		case NSFetchedResultsChangeDelete:
			[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;
		case NSFetchedResultsChangeUpdate:
			[self configureCell:[self.tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
			break;
		case NSFetchedResultsChangeMove:
			[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
			[self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;
	}
}

//
// -----------------------------------------------------------------------------
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
	[self.tableView endUpdates];
	self.buttonClear.enabled = self.frc.fetchedObjects.count > 0;
}


#pragma mark - UITableView data source

//
// -----------------------------------------------------------------------------
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return self.frc.sections.count;
}

//
// -----------------------------------------------------------------------------
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	id <NSFetchedResultsSectionInfo> sectionInfo = self.frc.sections[section];
	return [sectionInfo numberOfObjects];
}

//
// -----------------------------------------------------------------------------
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
	DBObject *object = [self.frc objectAtIndexPath:indexPath];
	
	cell.textLabel.text = object.title;
	cell.detailTextLabel.text = [NSDateFormatter localizedStringFromDate:object.date dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterMediumStyle];
}

//
// -----------------------------------------------------------------------------
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"objectsCellID"];
	
	if (!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"objectsCellID"];
		cell.accessoryType = UITableViewCellAccessoryDetailButton;
	}
	
	[self configureCell:cell atIndexPath:indexPath];
	
	return cell;
}


#pragma mark - UITableView delegate

//
// -----------------------------------------------------------------------------
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

//
// -----------------------------------------------------------------------------
- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
	DBObject *object = [self.frc objectAtIndexPath:indexPath];
	object.title = [NSString stringWithFormat:@"Renamed %@", @(arc4random_uniform(1000))];
	[BTDataSource.shared.mainContext save:nil];
}

//
// -----------------------------------------------------------------------------
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	switch (editingStyle) {
		case UITableViewCellEditingStyleDelete: {
			DBObject *object = [self.frc objectAtIndexPath:indexPath];
			[BTDataSource.shared.mainContext deleteObject:object];
			[BTDataSource.shared.mainContext save:nil];
			break;
		}
		case UITableViewCellEditingStyleNone:
		case UITableViewCellEditingStyleInsert:
			break;
	}
}

@end
