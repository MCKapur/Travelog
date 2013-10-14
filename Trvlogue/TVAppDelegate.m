//
//  TrvlogueAppDelegate.m
//  Trvlogue
//
//  Created by Rohan Kapur on 11/3/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import "TVAppDelegate.h"

#import "TVFlightsViewController.h"

#import "TVLoginViewController.h"

#import "TVFlightsViewController.h"
#import "TVMessageListViewController.h"
#import "TVFlightRecorderViewController.h"
#import "TVFindPeopleViewController.h"
#import "TVSettingsViewController.h"

#import "Reachability.h"

#import "TestFlightSDK/TestFlight.h"

#import <Crashlytics/Crashlytics.h>

@implementation TVAppDelegate
@synthesize randomNumber, swipeColor;

- (void)updateNotifications {

    int numberOfUnreadMessagesNotifications = 0;
    int numberOfConnectRequestNotifications = 0;
    
    for (TVNotification *notification in [[[TVDatabase currentAccount] person] notifications]) {
        
        if (notification.type == (NotificationType *)kNotificationTypeUnreadMessages) {
            
            numberOfUnreadMessagesNotifications++;
        }
        else {
            
            numberOfConnectRequestNotifications++;
        }
    }
    
    CustomBadge *unreadMessagesBadge = nil;
    
    for (UIView *view in self.window.subviews) {
        
        if ([[view accessibilityIdentifier] isEqualToString:@"MessagesBadge"]) {
            
            unreadMessagesBadge = (CustomBadge *)view;
        }
    }
    
    if (numberOfUnreadMessagesNotifications) {
        
        if (!unreadMessagesBadge) {
            
            unreadMessagesBadge = [CustomBadge customiOS7BadgeWithString:[NSString stringWithFormat:@"%i", numberOfUnreadMessagesNotifications]];
            
            [unreadMessagesBadge setFrame:CGRectMake(95, 519, unreadMessagesBadge.frame.size.width, unreadMessagesBadge.frame.size.height)];
            
            unreadMessagesBadge.userInteractionEnabled = NO;
            
            unreadMessagesBadge.accessibilityIdentifier = @"MessagesBadge";
            
            [self.window addSubview:unreadMessagesBadge];
        }
        else {
            
            [unreadMessagesBadge autoBadgeSizeWithString:[NSString stringWithFormat:@"%i", numberOfUnreadMessagesNotifications]];
            
            unreadMessagesBadge.badgeText = [NSString stringWithFormat:@"%i", numberOfUnreadMessagesNotifications];
        }
    }
    else {
        
        if (unreadMessagesBadge) {
            
            [unreadMessagesBadge removeFromSuperview];
        }
    }
    
    CustomBadge *connectBadge = nil;
    
    for (UIView *view in self.window.subviews) {
        
        if ([[view accessibilityIdentifier] isEqualToString:@"ConnectBadge"]) {
            
            connectBadge = (CustomBadge *)view;
        }
    }
    
    if (numberOfConnectRequestNotifications) {
        
        if (!connectBadge) {
            
            connectBadge = [CustomBadge customiOS7BadgeWithString:[NSString stringWithFormat:@"%i", numberOfConnectRequestNotifications]];
            
            [connectBadge setFrame:CGRectMake(223, 520, connectBadge.frame.size.width, connectBadge.frame.size.height)];
            
            connectBadge.userInteractionEnabled = NO;
            
            connectBadge.accessibilityIdentifier = @"ConnectBadge";
            
            [self.window addSubview:connectBadge];
        }
        else {
            
            [connectBadge autoBadgeSizeWithString:[NSString stringWithFormat:@"%i", numberOfConnectRequestNotifications]];
            
            connectBadge.badgeText = [NSString stringWithFormat:@"%i", numberOfConnectRequestNotifications];
        }
    }
    else {
        
        if (connectBadge) {
            
            [connectBadge removeFromSuperview];
        }
    }
}

- (void)hideNotifications {
    
    CustomBadge *connectBadge = nil;
    
    for (UIView *view in self.window.subviews) {
        
        if ([[view accessibilityIdentifier] isEqualToString:@"ConnectBadge"]) {
            
            connectBadge = (CustomBadge *)view;
        }
    }
    
    [connectBadge setHidden:YES];
    
    CustomBadge *unreadMessagesBadge = nil;
    
    for (UIView *view in self.window.subviews) {
        
        if ([[view accessibilityIdentifier] isEqualToString:@"MessagesBadge"]) {
            
            unreadMessagesBadge = (CustomBadge *)view;
        }
    }
    
    [unreadMessagesBadge setHidden:YES];
}

- (void)showNotifications {
    
    CustomBadge *connectBadge = nil;
    
    for (UIView *view in self.window.subviews) {
        
        if ([[view accessibilityIdentifier] isEqualToString:@"ConnectBadge"]) {
            
            connectBadge = (CustomBadge *)view;
        }
    }
    
    [connectBadge setHidden:NO];
    
    CustomBadge *unreadMessagesBadge = nil;
    
    for (UIView *view in self.window.subviews) {
        
        if ([[view accessibilityIdentifier] isEqualToString:@"MessagesBadge"]) {
            
            unreadMessagesBadge = (CustomBadge *)view;
        }
    }
    
    [unreadMessagesBadge setHidden:NO];
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    
    [TVDatabase refreshAccountWithCompletionHandler:^(BOOL completed) {
       
        if (completed) {
            
            completionHandler(UIBackgroundFetchResultNewData);
        }
        else {
            
            completionHandler(UIBackgroundFetchResultFailed);
        }
    }];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    
    [TVDatabase refreshAccountWithCompletionHandler:^(BOOL completed) {
        
        if (completed) {
            
            completionHandler(UIBackgroundFetchResultNewData);
        }
        else {
            
            completionHandler(UIBackgroundFetchResultFailed);
        }
    }];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    [application setMinimumBackgroundFetchInterval:18000];
    
    [Crashlytics startWithAPIKey:@"37253ba37a9099cfee6144ff25daf5ad9148d8ac"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateNotifications) name:NSNotificationUpdateNotifications object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTravelData) name:NSNotificationDownloadedConnections object:self];

    [self updateNotifications];
    
    self.swipeColor = [UIColor randomFlatColor];
    
    // Should remove in production
    [TestFlight takeOff:@"6308d30f-5be4-4bf7-8fed-ac33bdf8f39c"];

    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
     UIRemoteNotificationTypeBadge |
     UIRemoteNotificationTypeAlert];
    
    [Parse setApplicationId:@"tuE6sOcRNK3YSUaIgDM7mp4PgkMrnxuKKrvciTFw" clientKey:@"oWXDlTXcbIFfoePaVSdh0ZlmxBd8uSGBjtIOSowk"];
    
    [TVDatabase trackAnalytics:launchOptions];
        
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    
    TVLoginViewController *loginViewController = [[TVLoginViewController alloc] initWithNibName:@"TVLoginViewController" bundle:nil];
    
    TVFlightsViewController *flightsViewController = [[TVFlightsViewController alloc] init];
    flightsViewController.shouldRefresh = YES;
    
    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    
    if ([[TVDatabase currentAccount] userId]) {
        
        TVFindPeopleViewController *findPeopleViewController = [[TVFindPeopleViewController alloc] init];
        [findPeopleViewController findPeople];
        
        [tabBarController setViewControllers:[NSArray arrayWithObjects:[[UINavigationController alloc] initWithRootViewController:flightsViewController], [[UINavigationController alloc] initWithRootViewController:[[TVMessageListViewController alloc] init]], [[UINavigationController alloc] initWithRootViewController:[[TVFlightRecorderViewController alloc] init]], [[UINavigationController alloc] initWithRootViewController:findPeopleViewController], [[UINavigationController alloc] initWithRootViewController:[[TVSettingsViewController alloc] init]], nil]];
    }
    
    tabBarController.tabBar.translucent = YES;

    [[UINavigationBar appearance] setTitleTextAttributes: @{NSFontAttributeName:[UIFont fontWithName:@"HelveticaNeue-Bold" size:20.0f]}];

    if ([[PFUser currentUser] objectId]) {
        
        self.window.rootViewController = tabBarController;
    }
    else {
        
        self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:loginViewController];
    }
    
    [self.window makeKeyAndVisible];
    
    if (launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey]) {
        
        [TVDatabase receivedLocalNotification:launchOptions];
    }
    
    [TVDatabase refreshAccountWithCompletionHandler:^(BOOL completed) {
        
    }];

    return YES;
}

- (void)refreshTravelData {
    
    [TVDatabase refreshFlights];
}

- (void)didLogIn {
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    
    TVFlightsViewController *flightsViewController = [[TVFlightsViewController alloc] init];
    flightsViewController.shouldRefresh = YES;
    
    UITabBarController *tabBarController = [[UITabBarController alloc] init];

    [tabBarController setViewControllers:[NSArray arrayWithObjects:[[UINavigationController alloc] initWithRootViewController:flightsViewController], [[UINavigationController alloc] initWithRootViewController:[[TVMessageListViewController alloc] init]], [[UINavigationController alloc] initWithRootViewController:[[TVFlightRecorderViewController alloc] init]], [[UINavigationController alloc] initWithRootViewController:[[TVFindPeopleViewController alloc] init]], [[UINavigationController alloc] initWithRootViewController:[[TVSettingsViewController alloc] init]], nil]];

    tabBarController.tabBar.translucent = YES;
    
    [[UINavigationBar appearance] setTitleTextAttributes: @{NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Bold" size:20.0f]}];
    
    self.window.rootViewController = tabBarController;
    
    [self.window makeKeyAndVisible];
}

- (void)didLogOut {
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    
    TVLoginViewController *loginViewController = [[TVLoginViewController alloc] initWithNibName:@"TVLoginViewController" bundle:nil];

    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:loginViewController];
    
    [self.window makeKeyAndVisible];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [[NSUserDefaults standardUserDefaults] synchronize];

    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate:when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [[NSUserDefaults standardUserDefaults] synchronize];

    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    application.applicationIconBadgeNumber = 0;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NSNotificationReloadPeople object:nil];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [[NSUserDefaults standardUserDefaults] synchronize];

    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark Push

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSString *_deviceToken = [[[[deviceToken description]
                                stringByReplacingOccurrencesOfString: @"<" withString: @""]
                               stringByReplacingOccurrencesOfString: @">" withString: @""]
                              stringByReplacingOccurrencesOfString: @" " withString: @""];
    
    [[NSUserDefaults standardUserDefaults] setObject:_deviceToken forKey:@"deviceToken"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    if ([[PFUser currentUser] objectId]) {
        
        [TVDatabase updatePushNotificationsSetup];
    }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    
    application.applicationIconBadgeNumber++;
    
    [TVDatabase receivedLocalNotification:userInfo];
}

@end
