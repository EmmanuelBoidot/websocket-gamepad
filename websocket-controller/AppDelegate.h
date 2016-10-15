//
//  AppDelegate.h
//  websocket-controller
//
//  Created by Emmanuel Boidot on 10/15/16.
//  Copyright © 2016 Emmanuel Boidot. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;


@end

