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
@synthesize randomNumber, swipeColor, cachedAccounts, emails, loggedInAccount;

- (void)setCachedAccounts:(NSMutableArray *)_cachedAccounts {
    
    dispatch_async(dispatch_get_main_queue(), ^{
       
        cachedAccounts = _cachedAccounts;
    });
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {

    [self setLoggedInAccount:[TVDatabase nativeAccount]];

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

    [TVDatabase receivedLocalNotification:userInfo];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self setLoggedInAccount:[TVDatabase nativeAccount]];
    [self setCachedAccounts:[[NSMutableArray alloc] init]];
    
    [application setMinimumBackgroundFetchInterval:28800];
    
    [Helpshift installForApiKey:@"1a79986e6d8a587358d99d3e5cd78a5c" domainName:@"travelog.helpshift.com" appID:@"travelog_platform_20140128065429085-1932be27f93f387"];
    
    dispatch_async(dispatch_get_main_queue(), ^{

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTravelData) name:NSNotificationDownloadedConnections object:self];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:NSNotificationUpdateNotifications object:nil];
    });
    
    self.swipeColor = [UIColor randomFlatColor];
    
    // Should remove in production
    [TestFlight takeOff:@""];

    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
     UIRemoteNotificationTypeBadge |
     UIRemoteNotificationTypeAlert];
    
    [Parse setApplicationId:@"" clientKey:@""];
    
    [TVDatabase trackAnalytics:launchOptions];
        
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    
    TVLoginViewController *loginViewController = [[TVLoginViewController alloc] initWithNibName:@"TVLoginViewController" bundle:nil];
    
    TVFlightsViewController *flightsViewController = [[TVFlightsViewController alloc] init];
    flightsViewController.shouldRefresh = YES;
    
    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    
    tabBarController.tabBar.translucent = YES;

    [[UINavigationBar appearance] setTitleTextAttributes: @{NSFontAttributeName:[UIFont fontWithName:@"HelveticaNeue-Bold" size:20.0f]}];
    
    if ([[PFUser currentUser] objectId] && [[TVDatabase currentAccount] userId]) {
        
        [tabBarController setViewControllers:[NSArray arrayWithObjects:[[UINavigationController alloc] initWithRootViewController:flightsViewController], [[UINavigationController alloc] initWithRootViewController:[[TVMessageListViewController alloc] init]], [[UINavigationController alloc] initWithRootViewController:[[TVFlightRecorderViewController alloc] init]], [[UINavigationController alloc] initWithRootViewController:[[TVFindPeopleViewController alloc] init]], [[UINavigationController alloc] initWithRootViewController:[[TVSettingsViewController alloc] init]], nil]];

        self.window.rootViewController = tabBarController;
        
        if ([[TVDatabase currentAccount] isUsingLinkedIn]) {
            
            [LinkedInAuthorizer requestAccessTokenFromAuthorizationCode:[[TVDatabase currentAccount] linkedInAccessKey] withCompletionHandler:^(BOOL succeeded, NSError *error, NSString *accessToken) {
                
                if (succeeded && !error) {
                    
                    [TVDatabase setLocalLinkedInRequestToken:accessToken];
                }
            }];
        }
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

- (void)getEmailsWithCompletionHandler:(void (^)(BOOL success, NSMutableArray *emails))callback {
    
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);

    [self getAccessToAddressBook:addressBook withCompletionHandler:^(BOOL granted) {
        
        callback(granted, !granted ? nil : [self emailsFromAddressBook:addressBook]);
    }];
}

- (NSMutableArray *)emailsFromAddressBook:(ABAddressBookRef)addressBook {
    
    NSMutableArray *peopleEmails = [[NSMutableArray alloc] init];
    
    CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeople(addressBook);

    NSString *loggedInEmail = [[TVDatabase currentAccount] email];
    
    for (NSInteger i = 0; i < ABAddressBookGetPersonCount(addressBook); i++){
        
        ABRecordRef person = CFArrayGetValueAtIndex(allPeople, i);
        
        ABMultiValueRef emails = ABRecordCopyValue(person, kABPersonEmailProperty);
        
        for (CFIndex j = 0; j < ABMultiValueGetCount(emails); j++) {
            
            NSString *email = (__bridge NSString *)ABMultiValueCopyValueAtIndex(emails, j);
            
            if (![email isEqualToString:loggedInEmail]) {
                
                [peopleEmails addObject:email];
            }
        }
        
        CFRelease(person);
        CFRelease(emails);
    }
    
    CFRelease(allPeople);
    
    return peopleEmails;
}

- (void)getAccessToAddressBook:(ABAddressBookRef)addressBook withCompletionHandler:(void (^)(BOOL granted))callback {

    if (ABAddressBookRequestAccessWithCompletion != NULL) {

        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {

            if (granted) {
                
                callback(granted);
            }
            else {
                
                callback(granted);
            }
        });
    }
}

- (void)refreshTravelData {
    
    [TVDatabase refreshFlights];
}

- (void)didLogIn {
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

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
    
    [self getEmailsWithCompletionHandler:^(BOOL success, NSMutableArray *_emails) {

        self.emails = _emails;
    }];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark Push

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSString *_deviceToken = [[[[deviceToken description]
                                stringByReplacingOccurrencesOfString: @"<" withString: @""]
                               stringByReplacingOccurrencesOfString: @">" withString: @""]
                              stringByReplacingOccurrencesOfString: @" " withString: @""];
    
    [[EGOCache globalCache] setString:_deviceToken forKey:@"deviceToken"];

    if ([[PFUser currentUser] objectId]) {
        
        [TVDatabase updatePushNotificationsSetup];
    }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {

    [TVDatabase receivedLocalNotification:userInfo];
}

@end
