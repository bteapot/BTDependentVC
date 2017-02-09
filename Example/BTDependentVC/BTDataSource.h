//
//  BTDataSource.h
//  BTDependentVC
//
//  Created by Денис Либит on 07.02.2017.
//  Copyright © 2017 Денис Либит. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface BTDataSource : NSObject

@property (class, nonatomic, readonly) BTDataSource *shared;
@property (nonatomic, readonly) NSPersistentStoreCoordinator *coordinator;
@property (nonatomic, readonly) NSManagedObjectContext *mainContext;
@property (nonatomic, readonly) NSManagedObjectContext *backgroundContext;

@end
