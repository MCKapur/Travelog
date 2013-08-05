//
//  Database.m
//  Trvlogue
//
//  Created by Rohan Kapur on 6/2/13.
//  Copyright (c) 2013 UWCSEA. All rights reserved.
//

#import "Database.h"

#import "TrvlogueAppDelegate.h"

@interface NSArray (Indexing)

- (int)indexOfFlight:(TrvlogueFlight *)flight;

@end

@implementation NSArray (Indexing)

- (int)indexOfFlight:(TrvlogueFlight *)flight {
    
    int retVal = 2147483647;
    
    for (int i = 0; i <= self.count - 1; i++) {
        
        if ([((TrvlogueFlight *)self[i]).ID isEqualToString:flight.ID]) {
            
            retVal = i;
        }
    }
    
    return retVal;
}

@end

NSString *const WRONG_LOGIN = @"101";
NSString *const EMAIL_TAKEN = @"202";

@implementation Database

+ (void)trackAnalytics:(NSDictionary *)launchOptions {
    
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
}

#pragma mark Messaging Service

+ (void)createMessageHistory:(TrvlogueMessageHistory *)messageHistory withUserId:(NSString *)userId withCompletionHandler:(void (^)(BOOL success, NSError *error, NSString *callCode))callback {

}

+ (void)queueMessages:(NSMutableArray *)messageHistory withUserId:(NSString *)userId withCompletionHandler:(void (^)(BOOL success, NSError *error, NSString *callCode))callback {

}

+ (void)userHasReadAllMessagesInMessageHistory:(TrvlogueMessageHistory *)messageHistory withUserId:(NSString *)userId withCompletionHandler:(void (^)(BOOL success, NSError *error, NSString *callCode))callback {

}

+ (void)downloadMessageHistoriesWithUserId:(NSString *)userId withCompletionHandler:(void (^)(BOOL success, NSError *error, NSString *callCode, TrvlogueMessageHistory *messageHistory))callback {
}

#pragma mark Push Notifications

+ (void)pushNotificationToObjectId:(NSString *)objectId withData:(NSDictionary *)data {
    
    PFQuery *query = [PFInstallation query];
    [query whereKey:@"objectId" equalTo:objectId];
    
    [query setCachePolicy:kPFCachePolicyNetworkElseCache];
    
    PFPush *push = [[PFPush alloc] init];
    [push setQuery:query];
    [push setMessage:data[@"message"]];
    
    [push sendPushInBackground];
}

+ (void)setupPushNotifications:(NSData *)deviceToken {
    
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    
    [currentInstallation setDeviceTokenFromData:deviceToken];
    currentInstallation[@"objectId"] = [[PFUser currentUser] objectId];
    [currentInstallation saveInBackground];
}

+ (void)recievedLocalNotification:(NSDictionary *)userInfo {
    
    [PFPush handlePush:userInfo];
}

+ (void)updatePushNotificationsSetup {
    
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    currentInstallation[@"objectId"] = [[PFUser currentUser] objectId];
    [currentInstallation saveInBackground];
}

+ (void)removePushNotificationsSetup {
    
    [PFInstallation currentInstallation][@"objectId"] = @"";
    [[PFInstallation currentInstallation] saveInBackground];
}

#pragma mark Randomizers

NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

+ (NSString *)generateRandomKeyWithLength:(int)len {
    
    NSMutableString *randomString = [NSMutableString stringWithCapacity:len];
    
    for (int i = 0; i <= len; i++) {
        
        [randomString appendFormat:@"%c", [letters characterAtIndex:arc4random() % [letters length]]];
    }
    
    if (len == 15) {
        
        [randomString appendString:[[Database UUIDString] stringByReplacingOccurrencesOfString:@"-" withString:@""]];
    }
    
    return randomString;
}

+ (NSString *)UUIDString {
    
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    
    CFRelease(theUUID);
    
    return (__bridge NSString *)string;
}

#pragma mark Creating An Account

+ (void)isCreatingAnAccount:(BOOL)creatingAnAccount {
    
    [[NSUserDefaults standardUserDefaults] setBool:creatingAnAccount forKey:@"creatingAnAccount"];
}

+ (BOOL)creatingAnAccount {
    
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"creatingAnAccount"];
}

#pragma mark TravelData Packets

+ (void)removeTravelDataPacketWithID:(NSString *)_FlightID {
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"TravelDataPacket_%@", _FlightID]];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)addTravelDataPacketWithID:(NSString *)_FlightID andTravelDataObject:(TravelDataDownloader *)travelData {
    
    [Database removeTravelDataPacketWithID:_FlightID];
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:[travelData downloadedData]] forKey:[NSString stringWithFormat:@"TravelDataPacket_%@", _FlightID]];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)refreshTravelDataPacketWithID:(NSString *)_FlightID andTravelDataObject:(TravelDataDownloader *)travelData {

    [Database removeTravelDataPacketWithID:_FlightID];
    
    [Database addTravelDataPacketWithID:_FlightID andTravelDataObject:travelData];
}

+ (NSMutableDictionary *)travelDataPacketWithID:(NSString *)_FlightID {
    
    if (![NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"TravelDataPacket_%@", _FlightID]]])
        NSLog(@"travel data");

    return [NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"TravelDataPacket_%@", _FlightID]]];
}

#pragma mark Account Management

+ (BOOL)staysLoggedIn {
    
    BOOL retVal = NO;
    
    if ([PFUser currentUser]) {
        
        retVal = YES;
    }
    
    return retVal;
}

+ (TrvlogueAccount *)nativeAccount {

    if (![Database unarchiveAccount:[[NSUserDefaults standardUserDefaults] objectForKey:@"nativeAccount"]])
        NSLog(@"native");
    
    return [Database unarchiveAccount:[[NSUserDefaults standardUserDefaults] objectForKey:@"nativeAccount"]];
}

+ (void)setNativeAccount:(TrvlogueAccount *)account {
    
    [[NSUserDefaults standardUserDefaults] setObject:[Database archiveAccount:account] forKey:@"nativeAccount"];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark Current Account Management

+ (TrvlogueFlight *)flightFromID:(NSString *)_FlightID {
    
    TrvlogueFlight *retVal = nil;
    
    for (TrvlogueFlight *flight in [[Database currentAccount] flights]) {
        
        if ([flight.ID isEqualToString:_FlightID]) {
            
            retVal = flight;
        }
    }
    
    return retVal;
}

+ (void)logout {
    
    dispatch_queue_t downloadQueue = dispatch_queue_create("Logout", NULL);
    
    dispatch_async(downloadQueue, ^{
        
        [Database removePushNotificationsSetup];
        
        [PFUser logOut];
        
        [Database updateMyCache:nil];
    });
}

+ (TrvlogueAccount *)currentAccount {
    
    if (![Database unarchiveAccount:[[NSUserDefaults standardUserDefaults] objectForKey:@"currentAccount"]])
        NSLog(@"current");
    
    return [Database unarchiveAccount:[[NSUserDefaults standardUserDefaults] objectForKey:@"currentAccount"]];
}

+ (void)setCurrentAccount:(TrvlogueAccount *)account {
    
    [[NSUserDefaults standardUserDefaults] setObject:[Database archiveAccount:account] forKey:@"currentAccount"];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)refreshAccount {
        
    [[PFUser currentUser] refreshInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        
        [Database getAccountFromUser:(PFUser *)object withCompletionHandler:^(TrvlogueAccount *account, BOOL allOperationsComplete, BOOL hasWrittenProfilePicture) {
            
            [Database updateMyCache:account];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshedAccount" object:nil];

            if (allOperationsComplete) {
                
                dispatch_queue_t downloadQueue = dispatch_queue_create("Downloading travel data", NULL);
                
                dispatch_async(downloadQueue, ^{
                    
                    for (int i = [Database currentAccount].flights.count - 1; i >= 0; i--) {
                        
                        TrvlogueFlight *flight = [[Database currentAccount] flights][i];
                        
                        [flight instantiateTravelData];
                    }
                });
            }
        }];
    }];
}

#pragma mark Connect

+ (NSMutableArray *)confirmedUserConnections {
    
    NSMutableArray *connections = [[NSMutableArray alloc] init];
    
    for (TrvlogueConnection *connection in [[Database currentAccount].person connections]) {
        
        if (connection.status == (ConnectRequestStatus *)kConnectRequestAccepted) {
            
            if ([connection.receiverId isEqualToString:[[PFUser currentUser] objectId]]) {
                
                [connections addObject:connection.senderId];
            }
            else {
                
                [connections addObject:connection.receiverId];
            }
        }
    }
    
    return connections;
}

+ (NSMutableArray *)allUserConnections {
 
    NSMutableArray *connections = [[NSMutableArray alloc] init];
    
    for (TrvlogueConnection *connection in [[Database currentAccount].person connections]) {
        
        if ([connection.receiverId isEqualToString:[[PFUser currentUser] objectId]]) {
            
            [connections addObject:connection.senderId];
        }
        else {
            
            [connections addObject:connection.receiverId];
        }
    }
        
    return connections;
}
                                   
+ (void)downloadConnectionsInTheSameCity:(NSString *)FlightID withCompletionHandler:(void (^)(NSMutableArray *objects, NSError *error, NSString *callCode))callback{

    TrvlogueFlight *flight = [Database flightFromID:FlightID];
    
    PFQuery *query = [PFQuery queryWithClassName:@"Flights"];
    [query whereKey:@"flightId" containedIn:[Database confirmedUserConnections]];
    
    [query setCachePolicy:kPFCachePolicyNetworkOnly];
        
    [query findObjectsInBackgroundWithBlock:^(NSArray *flights, NSError *error) {

        NSMutableArray *possibleSameCity = [[NSMutableArray alloc] init];
        NSMutableArray *confirmedSameCity = [[NSMutableArray alloc] init];

        NSMutableArray *allIDs = [[NSMutableArray alloc] init];
        
        for (PFObject *flightObject in flights) {
            
            NSMutableArray *flights = [NSKeyedUnarchiver unarchiveObjectWithData:flightObject[@"flights"]];
            
            int possibility = 0;

            if (flights.count) {
                
                int self_dayArrives = [[flight date] timeIntervalSinceReferenceDate];
                int self_dayLeaves;
                
                int indexOfOurFlight = [[[Database currentAccount] flights] indexOfFlight:[Database flightFromID:FlightID]];

                if (!indexOfOurFlight) {
                    
                    self_dayLeaves = -1;
                }
                else {
                    
                    TrvlogueFlight *flight = [[[Database currentAccount] flights] objectAtIndex:indexOfOurFlight - 1];
                    
                    self_dayLeaves = [[flight date] timeIntervalSinceReferenceDate];
                }

                for (int i = 0; i <= flights.count - 1; i++) {
                    
                    TrvlogueFlight *_flight = flights[i];
                    
                    int user_dayArrives;
                    int user_dayLeaves;
                    
                    user_dayArrives = [[flight date] timeIntervalSinceReferenceDate];
                    
                    if (!i) {
                        
                        user_dayLeaves = -1;
                    }
                    else {
                        
                        user_dayLeaves = [[((TrvlogueFlight *)flights[i - 1]) date] timeIntervalSinceReferenceDate];
                    }
                    
                    if (self_dayArrives >= user_dayArrives && self_dayLeaves <= user_dayLeaves && [flight.originCity isEqualToString:_flight.originCity]) {
                        
                        possibility = 2;
                    }
                }    
            }
            else {
                
                possibility = 1;
            }
            
            if (possibility == 2) {
                
                [confirmedSameCity addObject:flightObject[@"flightId"]];
                [allIDs addObject:flightObject[@"flightId"]];
            }
            else if (possibility == 1) {
                
                [possibleSameCity addObject:flightObject[@"flightId"]];
                [allIDs addObject:flightObject[@"flightId"]];
            }
        }
        
        [Database downloadUsersFromUserIds:allIDs withCompletionHandler:^(NSMutableArray *users, NSError *error, NSString *callCode) {
            
            if (!error) {
                
                for (PFUser *user in users) {
                    
                    if ([confirmedSameCity containsObject:[user objectId]]) {
                        
                        [Database getAccountFromUser:user withCompletionHandler:^(TrvlogueAccount *account, BOOL allOperationsComplete, BOOL hasWrittenProfilePicture) {
                            
                            if (hasWrittenProfilePicture) {
                                
                                callback([[NSArray arrayWithObject:account.person] mutableCopy], nil, nil);
                            }
                        }];
                    }
                    else {
                        
                        if ([user[@"originCity"] isEqualToString:flight.originCity]) {
                            
                            [Database getAccountFromUser:user withCompletionHandler:^(TrvlogueAccount *account, BOOL allOperationsComplete, BOOL hasWrittenProfilePicture) {
                                
                                if (hasWrittenProfilePicture) {
                                    
                                    callback([[NSArray arrayWithObject:account.person] mutableCopy], nil, nil);
                                }
                            }];
                        }
                    }
                }
            }
        }];
    }];
}

+ (void)findMyConnections:(void (^)(NSMutableArray *objects, NSError *error, NSString *callCode))callback {

    PFQuery *connectQuery1 = [PFQuery queryWithClassName:@"Connections"];
    [connectQuery1 whereKey:@"from" equalTo:[[PFUser currentUser] objectId]];

    PFQuery *connectQuery2 = [PFQuery queryWithClassName:@"Connections"];
    [connectQuery2 whereKey:@"to" equalTo:[[PFUser currentUser] objectId]];

    PFQuery *connectQuery = [PFQuery orQueryWithSubqueries:[NSArray arrayWithObjects:connectQuery1, connectQuery2, nil]];
    
    [connectQuery setCachePolicy:kPFCachePolicyNetworkElseCache];

    [connectQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        NSMutableArray *connections = [[NSMutableArray alloc] init];
        
        for (PFObject *connectionObject in objects) {
            
            TrvlogueConnection *connection = [[TrvlogueConnection alloc] initWithSenderId:connectionObject[@"from"] receiverId:connectionObject[@"to"] andStatus:(ConnectRequestStatus *)[connectionObject[@"status"] intValue]];
        
            [connections addObject:connection];
        }

        callback([connections mutableCopy], error, N_FINDING_PEOPLE);
    }];
}

+ (void)findUsersWithEmails:(NSMutableArray *)emails withCompletionHandler:(void (^)(NSMutableArray *objects, NSError *error, NSString *callCode))callback {
    
    PFQuery *emailQuery = [PFUser query];
    [emailQuery whereKey:@"email" containedIn:emails];
    
    [emailQuery setCachePolicy:kPFCachePolicyNetworkElseCache];
    
    [emailQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {

        if (objects.count && !error) {
        }
        else {
        }
        
        callback([objects mutableCopy], error, N_FINDING_PEOPLE);
    }];
}

+ (void)downloadMyConnectionsWithCompletionHandler:(void (^)(NSMutableArray *objects, NSError *error, NSString *callCode))callback {
    
    PFQuery *query = [PFUser query];
    [query whereKey:@"objectId" containedIn:[Database allUserConnections]];
    
    [query setCachePolicy:kPFCachePolicyNetworkElseCache];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        callback([objects mutableCopy], nil, N_FINDING_PEOPLE);
    }];
}

+ (void)findUsersWithLinkedInIds:(NSMutableArray *)linkedInIds withCompletionHandler:(void (^)(NSMutableArray *objects, NSError *error, NSString *callCode))callback {
    
    PFQuery *linkedInQuery = [PFUser query];
    [linkedInQuery whereKey:@"linkedInId" containedIn:linkedInIds];
    
    [linkedInQuery setCachePolicy:kPFCachePolicyNetworkElseCache];
    
    [linkedInQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        if (objects.count && !error) {
        }
        else {
        }
        
        callback([objects mutableCopy], error, N_FINDING_PEOPLE);
    }];
}

+ (void)connectWithUser:(PFUser *)user withCompletionHandler:(void (^)(NSString *callCode, BOOL success))callback {
    
    PFObject *connection = [PFObject objectWithClassName:@"Connections"];
    connection[@"from"] = [[PFUser currentUser] objectId];
    connection[@"to"] = [user objectId];
    connection[@"status"] = @(kConnectRequestPending);
    
    PFACL *connectACL = [PFACL ACLWithUser:[PFUser currentUser]];
    [connectACL setPublicReadAccess:YES];
    [connectACL setPublicWriteAccess:YES];
    connection.ACL = connectACL;
    
    [connection saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        
        if (!error && succeeded) {
            
            [Database pushNotificationToObjectId:[user objectId] withData:@{@"message":[NSString stringWithFormat:@"%@ wants to connect with you", [[Database currentAccount].person name]]}];
            
            TrvlogueAccount *newAccount = [Database currentAccount];
                        
            TrvlogueConnection *connection = [[TrvlogueConnection alloc] initWithSenderId:[[PFUser currentUser] objectId] receiverId:[user objectId] andStatus:kConnectRequestPending];
                        
            [[newAccount.person connections] addObject:connection];
                        
            [Database updateMyCache:newAccount];

            callback(N_SEND_CONNECTION_REQUEST, YES);
        }
        else {
            
            callback(N_SEND_CONNECTION_REQUEST, NO);
        }
    }];
}

+ (void)disconnectWithUserId:(NSString *)userId withCompletionHandler:(void (^)(NSError *error, NSString *callCode, BOOL success))callback {
        
    PFQuery *query = [PFQuery queryWithClassName:@"Connections"];
    [query whereKey:@"from" equalTo:[[PFUser currentUser] objectId]];
    [query whereKey:@"to" equalTo:userId];
    
    PFQuery *query2 = [PFQuery queryWithClassName:@"Connections"];
    [query2 whereKey:@"to" equalTo:[[PFUser currentUser] objectId]];
    [query2 whereKey:@"from" equalTo:userId];
    
    PFQuery *masterQuery = [PFQuery orQueryWithSubqueries:[NSArray arrayWithObjects:query, query2, nil]];
    
    [masterQuery setCachePolicy:kPFCachePolicyNetworkOnly];
    
    [masterQuery findObjectsInBackgroundWithBlock:^(NSArray *activities, NSError *error) {

        if (!error && activities.count) {
            
            for (PFObject *activity in activities) {
                
                [activity deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {

                    if (!error && succeeded) {
                        
                        TrvlogueAccount *newAccount = [Database currentAccount];
                        
                        for (TrvlogueConnection *connection in newAccount.person.connections) {

                            if ([connection.senderId isEqualToString:userId] || [connection.receiverId isEqualToString:userId]) {
                                
                                [[newAccount.person connections] removeObject:connection];
                            }
                            
                            [Database updateMyCache:newAccount];
                        }
                    }
                    else {
                    }
                    
                    callback(nil, N_DISCONNECTING_PEOPLE, succeeded);
                }];
            }
        }
        else {
            
            callback(error, N_DISCONNECTING_PEOPLE, NO);
        }
    }];
}

+ (void)acceptConnection:(TrvlogueConnection *)connection withCompletionHandler:(void (^)(NSError *, NSString *, BOOL))callback {
    
    [Database pushNotificationToObjectId:connection.senderId withData:@{@"message":[NSString stringWithFormat:@"%@ accepted your connection request", [[Database currentAccount].person name]]}];
    
    TrvlogueAccount *account = [Database currentAccount];
    
    int index;
    
    for (int i = 0; i <= account.person.connections.count - 1; i++) {
        
        TrvlogueConnection *enumConnection = account.person.connections[i];
        
        if ([[enumConnection senderId] isEqualToString:[connection senderId]] && [[enumConnection receiverId] isEqualToString:[connection receiverId]]) {
            
            index = i;
        }
    }
        
    [connection setStatus:(ConnectRequestStatus *)kConnectRequestAccepted];
        
    [[[account person] connections] replaceObjectAtIndex:index withObject:connection];
    
    BOOL oneNotificationDeleted = NO;
    int notificationIndex;
    
    for (int i = 0; i <= account.person.notifications.count - 1; i++) {
        
        if (!oneNotificationDeleted) {
            
            TrvlogueNotification *notification = account.person.notifications[i];
            
            if (notification.type == kNotificationTypeConnectionRequest) {
                
                notificationIndex = i;
                
                oneNotificationDeleted = YES;
            }
        }
    }
    
    [[[account person] notifications] removeObjectAtIndex:notificationIndex];
    
    [Database updateMyCache:account];
    
    PFQuery *connectionQuery = [PFQuery queryWithClassName:@"Connections"];
    [connectionQuery whereKey:@"to" equalTo:connection.receiverId];
    [connectionQuery whereKey:@"from" equalTo:connection.senderId];
    
    [connectionQuery setCachePolicy:kPFCachePolicyNetworkOnly];

    [connectionQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        if (objects.count && !error) {
            
            for (PFObject *activity in objects) {
                
                activity[@"status"] = @(kConnectRequestAccepted);
                
                [activity saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    
                    if (succeeded && !error) {
                        
                    }
                    else {
                        
                    }
                    
                    callback(error, N_CONNECTING_PEOPLE, succeeded);
                }];
            }
        }
        else {
            
            callback(error, N_CONNECTING_PEOPLE, NO);
        }
    }];
}

+ (void)declineConnection:(TrvlogueConnection *)connection withCompletionHandler:(void (^)(NSError *error, NSString *callCode, BOOL success))callback {
        
    TrvlogueAccount *account = [Database currentAccount];
    
    int index;
    
    for (int i = 0; i <= account.person.connections.count - 1; i++) {
        
        TrvlogueConnection *enumConnection = account.person.connections[i];

        if ([[enumConnection senderId] isEqualToString:[connection senderId]] && [[enumConnection receiverId] isEqualToString:[connection receiverId]]) {
            
            index = i;
        }
    }
    
    [[[account person] connections] removeObjectAtIndex:index];

    BOOL oneNotificationDeleted = NO;
    int notificationIndex;
    
    for (int i = 0; i <= account.person.notifications.count - 1; i++) {
        
        if (!oneNotificationDeleted) {
            
            TrvlogueNotification *notification = account.person.notifications[i];
            
            if (notification.type == kNotificationTypeConnectionRequest) {
                
                notificationIndex = i;
                
                oneNotificationDeleted = YES;
            }
        }
    }
    
    [[[account person] notifications] removeObjectAtIndex:notificationIndex];
        
    [Database updateMyCache:account];

    [Database disconnectWithUserId:connection.senderId withCompletionHandler:^(NSError *error, NSString *callCode, BOOL success) {

        if (success && !error) {
            
        }
        else {
            
        }
        
        callback(error, callCode, success);
    }];
}

#pragma mark Photo Handling

+ (void)downloadProfilePicturesWithObjectIds:(NSArray *)objectIds withCompletionHandler:(void (^)(NSError *error, UIImage *profilePic))callback {

    PFQuery *query = [PFQuery queryWithClassName:@"ProfilePictures"];
    [query whereKey:@"photoId" containedIn:objectIds];
    
    [query setCachePolicy:kPFCachePolicyNetworkElseCache];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        if (!error) {
        
            for (PFObject *object in objects) {
            
                PFFile *file = object[@"profilePicture"];
                [file getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {

                    UIImage *profilePicture = nil;

                    if (!error && data) {
                        
                        profilePicture = [[UIImage alloc] initWithData:data];
                    }
                    
                    callback(error, profilePicture);
                }];
            }
        }
    }];
}

+ (void)uploadProfilePicture:(UIImage *)profilePicture withObjectId:(NSString *)objectId {
        
    PFObject *object = [PFObject objectWithClassName:@"ProfilePictures"];
    object[@"photoId"] = [[PFUser currentUser] objectId];
    
    PFFile *profilePictureFile = [PFFile fileWithData:UIImageJPEGRepresentation(profilePicture, 1.0)];
    object[@"profilePicture"] = profilePictureFile;
    
    PFACL *photoACL = [PFACL ACLWithUser:[PFUser currentUser]];
    [photoACL setPublicReadAccess:YES];
    [photoACL setPublicWriteAccess:NO];
    object.ACL = photoACL;
    
    [object saveInBackground];
}

+ (void)updateProfilePicture:(UIImage *)profilePicture withObjectId:(NSString *)objectId withCompletionHandler:(void (^)(BOOL succeeded, NSError *error, NSString *callCode))callback {
    
    PFQuery *query = [PFQuery queryWithClassName:@"ProfilePictures"];
    [query whereKey:@"photoId" equalTo:objectId];
    
    __block BOOL success = NO;
    __block NSError *callbackError = nil;
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        success = !objects.count ? NO : YES;
        callbackError = error;
        
        if (!error) {
            
            PFFile *updatedProfilePictureFile = [PFFile fileWithData:UIImageJPEGRepresentation(profilePicture, 1.0)];
            objects[0][@"profilePicture"] = updatedProfilePictureFile;
            
            [objects[0] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                
                callbackError = error;
                success = succeeded;
                
                callback(success, callbackError, N_UPLOADING_PHOTO);
            }];
        }
        else {
            
            callback(success, callbackError, N_UPLOADING_PHOTO);
        }
    }];
}

#pragma mark Flight Handling

+ (void)downloadFlightsWithObjectIds:(NSArray *)objectIds withCompletionHandler:(void (^)(NSError *error, NSMutableArray *flights))callback {

    PFQuery *query = [PFQuery queryWithClassName:@"Flights"];
    [query whereKey:@"flightId" containedIn:objectIds];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        if (!error && objects.count) {
            
            callback(nil, [objects mutableCopy]);
        }
        else {
            
            callback(error, nil);
        }
    }];
}

+ (void)uploadFlights:(NSArray *)flights withObjectId:(NSString *)objectId {
    
    PFObject *flightsObject = [PFObject objectWithClassName:@"Flights"];
    [flightsObject setObject:[NSKeyedArchiver archivedDataWithRootObject:flights] forKey:@"flights"];
    [flightsObject setObject:objectId forKey:@"flightId"];
    
    PFACL *flightACL = [PFACL ACLWithUser:[PFUser currentUser]];
    [flightACL setPublicReadAccess:YES];
    [flightACL setPublicWriteAccess:NO];
    flightsObject.ACL = flightACL;

    [flightsObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
    }];
}

+ (void)updateFlights:(NSArray *)flights withObjectId:(NSString *)objectId {
    
    PFQuery *query = [PFQuery queryWithClassName:@"Flights"];
    [query whereKey:@"flightId" equalTo:objectId];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
       
        objects[0][@"flights"] = [NSKeyedArchiver archivedDataWithRootObject:flights];
        
        [objects[0] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        }];
    }];
}

#pragma mark Account Download

+ (void)getAccountFromUser:(PFUser *)object withCompletionHandler:(void (^)(TrvlogueAccount *account, BOOL allOperationsComplete, BOOL hasWrittenProfilePicture))callback {

    __block BOOL profilePictureWritten = NO;
    
    __block int totalOperations = 4;
    __block int operationCount = 0;
    
    TrvlogueAccount *account;
    
    if ([object.objectId isEqualToString:[PFUser currentUser].objectId]) {
        
        account = [Database currentAccount];
    }
    else {
        
        account = [[TrvlogueAccount alloc] init];
    }
        
    [account setEmail:object[@"email"]];
    [account setPassword:object[@"password"]];
    [account setIsUsingLinkedIn:[object[@"isUsingLinkedIn"] boolValue]];
    [account setLinkedInAccessKey:object[@"linkedInAccessKey"]];
    [account setLinkedInId:object[@"linkedInId"]];
    [account.person setEmail:object[@"email"]];
    [account.person setKnownDestinationPreferences:[[NSMutableDictionary alloc] init]];
    [account.person setName:object[@"name"]];
    [account.person setPosition:object[@"position"]];
    [account.person setMiles:[object[@"miles"] doubleValue]];
    [account.person setOriginCity:object[@"originCity"]];

    operationCount++;
        
    callback(account, operationCount == totalOperations ? YES : NO, profilePictureWritten);
        
    [Database downloadFlightsWithObjectIds:[NSArray arrayWithObject:[object objectId]] withCompletionHandler:^(NSError *error, NSMutableArray *flights) {
        
        if (!error && flights) {
            
            [account setFlights:[NSKeyedUnarchiver unarchiveObjectWithData:flights[0][@"flights"]]];
            
            operationCount++;
            
            callback(account, operationCount == totalOperations ? YES : NO, profilePictureWritten);
        }
    }];
    
    [Database findMyConnections:^(NSMutableArray *objects, NSError *error, NSString *callCode) {
        
        NSMutableArray *notifications = [[NSMutableArray alloc] init];
        
        for (TrvlogueConnection *connection in objects) {
            
            if (connection.status == kConnectRequestPending && [connection.receiverId isEqualToString:[[PFUser currentUser] objectId]]) {
                
                TrvlogueNotification *connectNotification = [[TrvlogueNotification alloc] initWithTitle:@"People want to connect with you" andType:kNotificationTypeConnectionRequest];
                
                [notifications addObject:connectNotification];
            }
        }

        [account.person setConnections:objects];
        
        [account.person setNotifications:notifications];
        
        operationCount++;
        
        callback(account, operationCount == totalOperations ? YES : NO, profilePictureWritten);
    }];
    
    [Database downloadProfilePicturesWithObjectIds:[NSArray arrayWithObject:[object objectId]] withCompletionHandler:^(NSError *error, UIImage *profilePic) {
                
        if (!error && profilePic) {
        }
        else {
            
            profilePic = [UIImage imageNamed:@"anonymous_person.png"];
        }
        
        [account.person writeProfilePictureLocally:profilePic];
        
        operationCount++;
        
        profilePictureWritten = YES;

        callback(account, operationCount == totalOperations ? YES : NO, profilePictureWritten);
    }];
}

+ (void)downloadUsersFromUserIds:(NSArray *)userIds withCompletionHandler:(void (^)(NSMutableArray *users, NSError *error, NSString *callCode))callback {
    
    PFQuery *objectIdQuery = [PFUser query];
    
    [objectIdQuery whereKey:@"objectId" containedIn:userIds];
    
    [objectIdQuery setCachePolicy:kPFCachePolicyNetworkElseCache];
    
    [objectIdQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        if (!error && objects.count) {
            
            callback([objects mutableCopy], error, N_DOWNLOADING_ACCOUNTS_FROM_IDS);
        }
        else {
        
        }
    }];
}

#pragma mark Email

+ (NSDictionary *)emailParameters:(NSMutableDictionary *)dictionary {
    
    SESContent *messageBody = [[SESContent alloc] init];
    messageBody.data = dictionary[@"data"];
    
    SESContent *subject = [[SESContent alloc] init];
    subject.data = dictionary[@"subject"];
    
    SESBody *body = [[SESBody alloc] init];
    body.html = messageBody;
    
    SESMessage *message = [[SESMessage alloc] init];
    message.subject = subject;
    message.body = body;
    
    SESDestination *destination = [[SESDestination alloc] init];
    [destination.toAddresses addObject:dictionary[@"toAddress"]];
    
    return @{@"message":message, @"destination":destination};
}

+ (void)sendEmail:(NSMutableDictionary *)dictionary withCompletionHandler:(void (^)(BOOL success, NSError *error, NSString *callCode))callback {
    
    AmazonSESClient *sesClient = [[AmazonSESClient alloc] initWithAccessKey:AWS_ACCESS_KEY_ID withSecretKey:AWS_SECRET_KEY];
    
    [Database isCreatingAnAccount:NO];
    
    NSDictionary *paramDict = [Database emailParameters:dictionary];
    
    SESSendEmailRequest *ser = [[SESSendEmailRequest alloc] init];
    
    ser.source = VERIFIED_EMAIL;
    ser.destination = paramDict[@"destination"];
    ser.message = paramDict[@"message"];
    
    ser.requestTag = YN_SENDING_REQUEST_EMAIL;
    
    SESSendEmailResponse *response = [sesClient sendEmail:ser];
    
    BOOL success = NO;
    
    if (!response.error) {
        
        success = YES;
    }
    
    callback(success, response.error, ser.requestTag);
}

#pragma mark Operations

+ (void)loginToAccountWithEmail:(NSString *)email andPassword:(NSString *)password withCompletionHandler:(void (^)(BOOL success, BOOL correctCredentials, NSError *error, NSString *callCode))callback {
    
    [PFUser logInWithUsernameInBackground:email password:password block:^(PFUser *user, NSError *error) {
        
        __block BOOL success = NO;
        __block BOOL correctCredentials = NO;
        
        if (user && !error) {
            
            success = YES;
            
            correctCredentials = YES;
            
            callback(success, correctCredentials, error, N_LOGGING_IN);
            
            [Database getAccountFromUser:user withCompletionHandler:^(TrvlogueAccount *account, BOOL allOperationsComplete, BOOL hasWrittenProfilePicture) {
                                
                if (allOperationsComplete) {
                    
                    [Database updatePushNotificationsSetup];
                }
                
                [Database updateMyCache:account];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshedAccount" object:nil];
            }];
        }
        else {
            
            if ([error.userInfo[@"code"] intValue] == [WRONG_LOGIN intValue]) {
                
                success = YES;
                
                error = nil;
                
                correctCredentials = NO;
            }
            
            callback(success, correctCredentials, error, N_LOGGING_IN);
        }
    }];
}

+ (NSMutableArray *)attributesWithAccount:(TrvlogueAccount *)accountObj {

    NSDictionary *nameAttribute = @{@"key":@"name", @"value":[accountObj.person name]};
    
    NSDictionary *originCityAttribute = @{@"key":@"originCity", @"value":[accountObj.person originCity]};
    
    NSDictionary *positionAttribute = @{@"key":@"position", @"value":[accountObj.person position]};
    
    NSDictionary *milesAttribute = @{@"key":@"miles", @"value":@([accountObj.person miles])};
    
    BOOL usingLinkedIn = NO;
    
    NSMutableArray *attributes = [NSMutableArray arrayWithObjects:nameAttribute, originCityAttribute, positionAttribute, milesAttribute, nil];
    
    if ([accountObj isUsingLinkedIn]) {
        
        NSDictionary *linkedInIDAttribute = @{@"key":@"linkedInId", @"value":[accountObj linkedInId]};
        NSDictionary *linkedInAccessKey = @{@"key":@"linkedInAccessKey", @"value":[accountObj linkedInAccessKey]};
        usingLinkedIn = YES;
        
        [attributes addObject:linkedInIDAttribute];
        [attributes addObject:linkedInAccessKey];
    }
    
    NSMutableDictionary *isUsingLinkedIn = [@{@"key":@"isUsingLinkedIn", @"value":@(usingLinkedIn)} mutableCopy];
    [attributes addObject:isUsingLinkedIn];
    
    return attributes;
}

+ (NSData *)archiveAccount:(TrvlogueAccount *)accountObj {
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:accountObj];
    
    return data;
}

+ (TrvlogueAccount *)unarchiveAccount:(NSData *)data {
    
    TrvlogueAccount *accountObj = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    return accountObj;
}

+ (void)updateMyCache:(TrvlogueAccount *)accountObj {
    
    [Database setNativeAccount:accountObj];
    [Database setCurrentAccount:accountObj];
}

+ (void)updateMyAccount:(TrvlogueAccount *)accountObj withCompletionHandler:(void (^)(BOOL succeeded, NSError *error, NSString *callCode))callback {
    
    NSString *reqTag;
    reqTag = N_UPDATING_MY_ACCOUNT;

    [Database updateMyCache:accountObj];
    
    for (NSDictionary *attribute in [self attributesWithAccount:accountObj]) {
        
        [[PFUser currentUser] setObject:attribute[@"value"] forKey:attribute[@"key"]];
    }
    
    [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        
        if (!error && succeeded) {
            
            [Database updateFlights:accountObj.flights withObjectId:[[PFUser currentUser] objectId]];
            [Database updatePushNotificationsSetup];
        }
        
        callback(succeeded, error, reqTag);
    }];
}

+ (void)uploadAccount:(TrvlogueAccount *)trvlogueAccount withCompletionHandler:(void (^)(BOOL success, NSError *error, NSString *callCode))callback {

    UIImage *profilePicture = [trvlogueAccount.person getProfilePic];
    
    PFUser *user = [PFUser user];
        
    user.username = trvlogueAccount.email;
    user.email = trvlogueAccount.email;
    user.password = trvlogueAccount.password;
    
    for (NSDictionary *attribute in [self attributesWithAccount:trvlogueAccount]) {
        
        [user setObject:attribute[@"value"] forKey:attribute[@"key"]];
    }
    
    [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        
        if (!error && succeeded) {
                                    
            PFACL *ACL = [PFACL ACLWithUser:[PFUser currentUser]];
            [ACL setPublicReadAccess:YES];
            [ACL setPublicWriteAccess:NO];
            [PFUser currentUser].ACL = ACL;
            [[PFUser currentUser] saveInBackground];
                        
            [Database uploadFlights:trvlogueAccount.flights withObjectId:[[PFUser currentUser] objectId]];
            [Database uploadProfilePicture:profilePicture withObjectId:[[PFUser currentUser] objectId]];
            
            [Database updatePushNotificationsSetup];

            [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
             UIRemoteNotificationTypeBadge |
             UIRemoteNotificationTypeAlert |
             UIRemoteNotificationTypeSound];
            
            [Database updateMyCache:trvlogueAccount];
        }
        
        callback(succeeded, error, Y_CREATING_ACCOUNT);
    }];
}

@end