//
//  BTRootVC.h
//  BTDependentVC
//
//  Created by Денис Либит on 07.02.2017.
//  Copyright © 2017 Денис Либит. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface BTRootVC : UIViewController

@property (nonatomic, readonly) UINavigationController *ncStack;

- (instancetype)initWithObject:(DBObject *)object;

@end
