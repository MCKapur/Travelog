//
//  TrvlogueAppDelegate.m
//  Trvlogue
//
//  Created by Rohan Kapur on 11/3/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import "TVAppDelegate.h"

#import "TVViewController.h"

#import "TVLoginViewController.h"

#import "TVViewController.h"

#import "Reachability.h"

#import "TestFlightSDK/TestFlight.h"

@implementation TVAppDelegate
@synthesize randomNumber, backgroundColor;

+ (UIColor *)generateRandomColor {
    
    NSArray *colors = @[[UIColor colorWithRed:67.0f/255.0f green:180.0f/255.0f blue:227.0f/255.0f alpha:1.0], [UIColor orangeColor], [UIColor colorWithRed:82.0f/255.0f green:199.0f/255.0f blue:0.0f/255.0f alpha:1], [UIColor redColor], [UIColor purpleColor], [UIColor magentaColor], [UIColor brownColor]];
    
    return colors[arc4random() % [colors count]];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Should remove in production
    [TestFlight takeOff:@"6c9526c1-d130-4ffe-95b7-898c408d014a"];

    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
     UIRemoteNotificationTypeBadge |
     UIRemoteNotificationTypeAlert |
     UIRemoteNotificationTypeSound];
    
    self.backgroundColor = [TVAppDelegate generateRandomColor];

    [Parse setApplicationId:@"tuE6sOcRNK3YSUaIgDM7mp4PgkMrnxuKKrvciTFw" clientKey:@"oWXDlTXcbIFfoePaVSdh0ZlmxBd8uSGBjtIOSowk"];
    
    [TVDatabase trackAnalytics:launchOptions];
        
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    
    self.loginViewController = [[TVLoginViewController alloc] initWithNibName:@"TVLoginViewController" bundle:nil];
    
    self.trvlogueViewController = [[TVViewController alloc] initWithNibName:@"TVViewController" bundle:nil];
    
    UINavigationController *controller;
    
    if ([[PFUser currentUser] objectId]) {
        
        controller = [[UINavigationController alloc] initWithRootViewController:self.trvlogueViewController];
    }
    else {
        
        controller = [[UINavigationController alloc] initWithRootViewController:self.loginViewController];
    }
        
    [controller.navigationBar setBackgroundImage:[UIImage imageNamed:TRVLOGUE_NAVIGATION_BAR] forBarMetrics:UIBarMetricsDefault];
    
    self.window.rootViewController = controller;
    
    [self.window makeKeyAndVisible];
    
    if (launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey]) {
        
        [TVDatabase receivedLocalNotification:launchOptions];
    }
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate:when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    application.applicationIconBadgeNumber = 0;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark Push

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    // Store the deviceToken in the current installation and save it to Parse.
    
    if ([[PFUser currentUser] objectId]) {

        [TVDatabase updatePushNotificationsSetup:deviceToken];
    }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    
    application.applicationIconBadgeNumber++;
    
    [TVDatabase receivedLocalNotification:userInfo];
}

@end
