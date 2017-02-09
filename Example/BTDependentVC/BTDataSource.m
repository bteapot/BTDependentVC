//
//  BTDataSource.m
//  BTDependentVC
//
//  Created by Денис Либит on 07.02.2017.
//  Copyright © 2017 Денис Либит. All rights reserved.
//

#import "BTDataSource.h"


@interface BTDataSource ()

@property (nonatomic, strong) NSPersistentStoreCoordinator *coordinator;
@property (nonatomic, strong) NSManagedObjectContext *mainContext;
@property (nonatomic, strong) NSManagedObjectContext *backgroundContext;

@end


@implementation BTDataSource

//
// -----------------------------------------------------------------------------
+ (instancetype)shared
{
	static dispatch_once_t onceToken;
	static id _singleton;
	dispatch_once(&onceToken, ^{
		_singleton = [[self alloc] initInternal];
	});

	return _singleton;
}

//
// -----------------------------------------------------------------------------
- (instancetype)init
{
	NSLog(@"no 'alloc] init]'! Use singleton [DataSource shared].");
	abort();
	return nil;
}

//
// -----------------------------------------------------------------------------
- (instancetype)initInternal
{
	self = [super init];

	if (!self) {
		return nil;
	}
	
	NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Model" withExtension:@"momd"];
	NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];

	self.coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];

	NSURL *documentsURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
	NSURL *storeURL = [documentsURL URLByAppendingPathComponent:@"Data.sqlite"];
	NSError *error = nil;

	NSDictionary *options = @{
		NSMigratePersistentStoresAutomaticallyOption: @YES,
		NSInferMappingModelAutomaticallyOption: @YES,
	};

	NSPersistentStore *store = [self.coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error];

	if (!store) {
		error = [NSError errorWithDomain:@"MY-OWN-ERROR-DOMAIN" code:9999 userInfo:@{
			NSLocalizedDescriptionKey: @"Can't add persistent store.",
			NSUnderlyingErrorKey: error,
		}];
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
	}

	self.mainContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
	self.mainContext.persistentStoreCoordinator = self.coordinator;

	self.backgroundContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
	self.backgroundContext.persistentStoreCoordinator = self.coordinator;

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:self.mainContext];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(backgroundContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:self.backgroundContext];

	return self;
}

//
// -----------------------------------------------------------------------------
- (void)mainContextDidSave:(NSNotification *)notification
{
	[self.backgroundContext performBlock:^{
		[self.backgroundContext mergeChangesFromContextDidSaveNotification:notification];
	}];
}

//
// -----------------------------------------------------------------------------
- (void)backgroundContextDidSave:(NSNotification *)notification
{
	[self.mainContext performBlock:^{
		[self.mainContext mergeChangesFromContextDidSaveNotification:notification];
	}];
}

@end
