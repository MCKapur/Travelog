//
//  Database.m
//  Trvlogue
//
//  Created by Rohan Kapur on 6/2/13.
//  Copyright (c) 2013 UWCSEA. All rights reserved.
//

#import "TVDatabase.h"

#import "TVAppDelegate.h"

@interface NSArray (Indexing)

- (int)indexOfFlight:(TVFlight *)flight;

@end

@implementation NSArray (Indexing)

- (int)indexOfFlight:(TVFlight *)flight {
    
    int retVal = NSNotFound;
    
    for (int i = 0; i <= self.count - 1; i++) {
        
        if ([((TVFlight *)self[i]).ID isEqualToString:flight.ID]) {
            
            retVal = i;
        }
    }
    
    return retVal;
}

@end

NSString *const WRONG_LOGIN = @"101";
NSString *const EMAIL_TAKEN = @"202";

@implementation TVDatabase

+ (void)trackAnalytics:(NSDictionary *)launchOptions {
    
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
}

#pragma mark Messaging Service

+ (TVMessageHistory *)messageHistoryFromID:(NSString *)ID {
    
    TVMessageHistory *retVal = nil;
    
    for (TVMessageHistory *messageHistory in [[[TVDatabase currentAccount] person] messageHistories]) {
        
        if ([messageHistory.ID isEqualToString:ID]) {
            
            retVal = messageHistory;
        }
    }
    
    return retVal;
}

+ (void)sendMessage:(TVMessage *)message toHistoryWithID:(NSString *)messageHistoryID withCompletionHandler:(void (^)(BOOL success, NSError *error, NSString *callCode))callback {
    
    TVAccount *account = [TVDatabase currentAccount];
    
    if (account.person.messageHistories.count) {
        
        for (int i = 0; i <= account.person.messageHistories.count - 1; i++) {
            
            if ([((TVMessageHistory *)account.person.messageHistories[i]).ID isEqualToString:messageHistoryID]) {
                
                [((TVMessageHistory *)account.person.messageHistories[i]).messages addObject:message];
            }
        }
    }
    
    [TVDatabase updateMyCache:account];
    
    PFQuery *query = [PFQuery queryWithClassName:@"Messages"];
    [query whereKey:@"senderId" equalTo:[TVDatabase messageHistoryFromID:messageHistoryID].senderId];
    [query whereKey:@"receiverId" equalTo:[TVDatabase messageHistoryFromID:messageHistoryID].receiverId];
        
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                
        if (objects.count && !error) {
            
            PFObject *messageObject = objects[0];

            TVMessageHistory *messageHistory = [NSKeyedUnarchiver unarchiveObjectWithData:messageObject[@"messageHistory"]];
                            
            [[messageHistory messages] addObject:messageObject];
            
            messageObject[@"messageHistory"] = [NSKeyedArchiver archivedDataWithRootObject:messageHistory];
            
            [messageObject saveEventually:^(BOOL succeeded, NSError *error) {
                
                [TVDatabase pushNotificationToObjectId:[[TVDatabase messageHistoryFromID:messageHistoryID].ID isEqualToString:[[PFUser currentUser] objectId]] ? [TVDatabase messageHistoryFromID:messageHistoryID].senderId : [TVDatabase messageHistoryFromID:messageHistoryID].receiverId withData:@{@"type": @(kPushNotificationReceivedMessage), @"message": [NSString stringWithFormat:@"%@ sent you a message: %@", [[[TVDatabase currentAccount] person] name], message.body], @"messageHistory": [NSKeyedArchiver archivedDataWithRootObject:messageHistory.ID], @"messageData": [NSKeyedArchiver archivedDataWithRootObject:message]}];
            }];
        }
        else {
            
            callback(NO, error, SEND_MESSAGE);
        }
    }];
}

+ (void)createMessageHistory:(TVMessageHistory *)messageHistory withCompletionHandler:(void (^)(BOOL success, NSError *error, NSString *callCode))callback {

    TVAccount *account = [TVDatabase currentAccount];
    [[[account person] messageHistories] addObject:messageHistory];
    
    [TVDatabase updateMyCache:account];
    
    PFQuery *query = [PFQuery queryWithClassName:@"Messages"];
    
    [query whereKey:@"senderId" equalTo:messageHistory.senderId];
    [query whereKey:@"receiverId" equalTo:messageHistory.receiverId];

    [query countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
        
        if (!error) {
            
            if (!number) {
                
                PFObject *messageObject = [PFObject objectWithClassName:@"Messages"];
                
                messageObject[@"senderId"] = messageHistory.senderId;
                messageObject[@"receiverId"] = messageHistory.receiverId;
                
                messageObject[@"messageHistory"] = [NSKeyedArchiver archivedDataWithRootObject:messageHistory];
                
                [messageObject saveEventually:^(BOOL succeeded, NSError *error) {
                    
                    callback(succeeded, error, SEND_MESSAGE);
                    
                    [TVDatabase pushNotificationToObjectId:[messageHistory.receiverId isEqualToString:[[PFUser currentUser] objectId]] ? messageHistory.senderId : messageHistory.receiverId withData:@{@"type": @(kPushNotificationReceivedMessage), @"message": [NSKeyedArchiver archivedDataWithRootObject:messageHistory.messages[0]]}];
                }];
            }
            else {
                
                callback(NO, error, SEND_MESSAGE);
            }
        }
        else {
            
            callback(NO, error, SEND_MESSAGE);
        }
    }];
}

+ (void)confirmReceiverHasReadNewMessages:(NSMutableArray *)messages inMessageHistory:(TVMessageHistory *)messageHistory withCompletionHandler:(void (^)(BOOL success, NSError *error, NSString *callCode))callback {

    PFQuery *query = [PFQuery queryWithClassName:@"Messages"];
    
    [query whereKey:@"senderId" equalTo:messageHistory.senderId];
    [query whereKey:@"receiverId" equalTo:messageHistory.receiverId];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
       
        if (objects.count && !error) {
            
            TVMessageHistory *messageHistory = [NSKeyedUnarchiver unarchiveObjectWithData:objects[0][@"messageHistory"]];
            
            for (TVMessage *message in messageHistory.messages) {
                
                for (TVMessage *_message in messages) {
                    
                    if ([message.ID isEqualToString:_message.ID]) {
                    
                        message.receiverRead = YES;
                    }
                }
            }
            
            objects[0][@"messageHistory"] = [NSKeyedArchiver archivedDataWithRootObject:messageHistory];
            
            [objects[0] saveEventually:^(BOOL succeeded, NSError *error) {
                
                callback(succeeded, error, nil);
            }];
        }
        else {
            
            callback(NO, error, nil);
        }
    }];
}

+ (void)downloadMessageHistoriesWithUserId:(NSString *)userId withCompletionHandler:(void (^)(BOOL success, NSError *error, NSString *callCode, NSMutableArray *messageHistories))callback {
    
    PFQuery *senderQuery = [PFQuery queryWithClassName:@"Messages"];
    [senderQuery whereKey:@"senderId" equalTo:userId];
    
    PFQuery *receiverQuery = [PFQuery queryWithClassName:@"Messages"];
    [receiverQuery whereKey:@"receiverId" equalTo:userId];
    
    PFQuery *query = [PFQuery orQueryWithSubqueries:[NSArray arrayWithObjects:senderQuery, receiverQuery, nil]];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        NSMutableArray *messageHistories = [[NSMutableArray alloc] init];
        
        for (PFObject *messageObject in objects) {
            
            TVMessageHistory *messageHistory = [NSKeyedUnarchiver unarchiveObjectWithData:messageObject[@"messageHistory"]];
            
            [messageHistories addObject:messageHistory];
        }
        
        callback(objects.count ? YES : NO, error, DOWNLOAD_MESSAGE, messageHistories);
    }];
}

+ (void)downloadMessageHistoryBetweenRecipients:(NSMutableArray *)userIds withCompletionHandler:(void (^)(BOOL success, NSError *error, NSString *callCode, NSMutableArray *messageHistories))callback {
    
    PFQuery *queryScenario1 = [PFQuery queryWithClassName:@"Messages"];
    [queryScenario1 whereKey:@"senderId" equalTo:userIds[0]];
    [queryScenario1 whereKey:@"receiverId" equalTo:userIds[1]];
    
    PFQuery *queryScenario2 = [PFQuery queryWithClassName:@"Messages"];
    [queryScenario2 whereKey:@"senderId" equalTo:userIds[1]];
    [queryScenario1 whereKey:@"receiverId" equalTo:userIds[0]];

    PFQuery *query = [PFQuery orQueryWithSubqueries:[NSArray arrayWithObjects:queryScenario1, queryScenario2, nil]];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        NSMutableArray *messageHistories = [[NSMutableArray alloc] init];
        
        for (PFObject *messageObject in objects) {
            
            TVMessageHistory *messageHistory = [NSKeyedUnarchiver unarchiveObjectWithData:messageObject[@"messageHistory"]];
            
            [messageHistories addObject:messageHistory];
        }
        
        callback(objects.count ? YES : NO, error, DOWNLOAD_MESSAGE, messageHistories);
    }];
}

#pragma mark Push Notifications

+ (void)pushNotificationToObjectId:(NSString *)objectId withData:(NSDictionary *)data {
    
    PFQuery *query = [PFInstallation query];
    [query whereKey:@"objectId" equalTo:objectId];
    
    [query setCachePolicy:kPFCachePolicyNetworkElseCache];
    
    PFPush *push = [[PFPush alloc] init];
    [push setQuery:query];
    [push setMessage:data[@"message"]];
    [push setData:data];
    
    [push sendPushInBackground];
}

+ (void)setupPushNotifications:(NSData *)deviceToken {
    
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    
    [currentInstallation setDeviceTokenFromData:deviceToken];
    currentInstallation[@"objectId"] = [[PFUser currentUser] objectId];
    [currentInstallation saveEventually];
}

+ (void)receivedLocalNotification:(NSDictionary *)userInfo {
    
    TVAccount *newAccount = [TVDatabase currentAccount];

    if ([userInfo[@"type"] intValue] == kPushNotificationWantsToConnect) {
        
        [PFPush handlePush:userInfo];
        
        TVConnection *connection = [NSKeyedUnarchiver unarchiveObjectWithData:userInfo[@"connection"]];

        TVNotification *notification = [[TVNotification alloc] initWithType:kNotificationTypeConnectionRequest withUserId:connection.senderId];
        
        [newAccount.person.notifications addNotification:notification];
    }
    else if ([userInfo[@"type"] intValue] == kPushNotificationAcceptedConnection) {
        
        [PFPush handlePush:userInfo];
    }
    else if ([userInfo[@"type"] intValue] == kPushNotificationReceivedMessage) {
        
        TVMessage *message = [NSKeyedUnarchiver unarchiveObjectWithData:userInfo[@"messageData"]];
        
        TVNotification *notification = [[TVNotification alloc] initWithType:(NotificationType *)kNotificationTypeUnreadMessages withUserId:message.senderId];
        
        [newAccount.person.notifications addNotification:notification];
        
        if (![((UINavigationController *)((TVAppDelegate *)[UIApplication sharedApplication].delegate).window.rootViewController).topViewController isKindOfClass:[TVMessageDetailViewController class]]) {
                        
            [PFPush handlePush:userInfo];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"IncomingMessage" object:nil userInfo:nil];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ManuallyRefreshAccount" object:nil userInfo:nil];
    
    [TVDatabase updateMyCache:newAccount];
}

+ (void)updatePushNotificationsSetup {
    
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    currentInstallation[@"objectId"] = [[PFUser currentUser] objectId];
    [currentInstallation saveEventually];
}

+ (void)removePushNotificationsSetup {
    
    [PFInstallation currentInstallation][@"objectId"] = @"";
    [[PFInstallation currentInstallation] saveEventually];
}

#pragma mark Randomizers

NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

+ (NSString *)generateRandomKeyWithLength:(int)len {
    
    NSMutableString *randomString = [NSMutableString stringWithCapacity:len];
    
    for (int i = 0; i <= len; i++) {
        
        [randomString appendFormat:@"%c", [letters characterAtIndex:arc4random() % [letters length]]];
    }
    
    if (len == 15) {
        
        [randomString appendString:[[TVDatabase UUIDString] stringByReplacingOccurrencesOfString:@"-" withString:@""]];
    }
    
    return randomString;
}

+ (NSString *)UUIDString {
    
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    
    CFRelease(theUUID);
    
    return (__bridge NSString *)string;
}

#pragma mark TravelData Packets

+ (void)removeTravelDataPacketWithID:(NSString *)_FlightID {
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"TravelDataPacket_%@", _FlightID]];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)addTravelDataPacketWithID:(NSString *)_FlightID andTravelDataObject:(TVTravelDataDownloader *)travelData {
    
    [TVDatabase removeTravelDataPacketWithID:_FlightID];
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:[travelData downloadedData]] forKey:[NSString stringWithFormat:@"TravelDataPacket_%@", _FlightID]];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)refreshTravelDataPacketWithID:(NSString *)_FlightID andTravelDataObject:(TVTravelDataDownloader *)travelData {
        
    [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:[travelData downloadedData]] forKey:[NSString stringWithFormat:@"TravelDataPacket_%@", _FlightID]];
}

+ (NSMutableDictionary *)travelDataPacketWithID:(NSString *)_FlightID {
    
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

+ (TVAccount *)nativeAccount {
    
    return [TVDatabase unarchiveAccount:[[NSUserDefaults standardUserDefaults] objectForKey:@"nativeAccount"]];
}

+ (void)setNativeAccount:(TVAccount *)account {
    
    [[NSUserDefaults standardUserDefaults] setObject:[TVDatabase archiveAccount:account] forKey:@"nativeAccount"];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark Current Account Management

+ (TVFlight *)flightFromID:(NSString *)_FlightID {
    
    TVFlight *retVal = nil;
    
    for (TVFlight *flight in [[[TVDatabase currentAccount] person] flights]) {
        
        if ([flight.ID isEqualToString:_FlightID]) {
            
            retVal = flight;
        }
    }
    
    return retVal;
}

+ (void)logout {
    
    dispatch_queue_t downloadQueue = dispatch_queue_create("Logout", NULL);
    
    dispatch_async(downloadQueue, ^{
        
        [TVDatabase removePushNotificationsSetup];
        
        [PFUser logOut];
        
        [TVDatabase updateMyCache:nil];
    });
}

+ (TVAccount *)currentAccount {
    
    return [TVDatabase unarchiveAccount:[[NSUserDefaults standardUserDefaults] objectForKey:@"currentAccount"]];
}

+ (void)setCurrentAccount:(TVAccount *)account {
    
    [[NSUserDefaults standardUserDefaults] setObject:[TVDatabase archiveAccount:account] forKey:@"currentAccount"];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)refreshAccountWithCompletionHandler:(void (^)(BOOL completed))callback {
    
    [[PFUser currentUser] refreshInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        
        [TVDatabase getAccountFromUser:(PFUser *)object withCompletionHandler:^(TVAccount *account, BOOL allOperationsComplete, BOOL hasWrittenProfilePicture) {

            [TVDatabase updateMyCache:account];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshedAccount" object:nil];
            
            if (allOperationsComplete) {
                
                callback(YES);
                
                dispatch_queue_t downloadQueue = dispatch_queue_create("Downloading travel data", NULL);
                
                dispatch_async(downloadQueue, ^{
                    
                    if ([[[[TVDatabase currentAccount] person] flights] count]) {
                        
                        for (int i = [[[[TVDatabase currentAccount] person] flights] count] - 1; i >= 0; i--) {
                            
                            TVFlight *flight = [[[TVDatabase currentAccount] person] flights][i];
                            
                            [flight instantiateTravelData];
                        }
                    }
                });
            }
        }];
    }];
}

#pragma mark Connect

+ (NSMutableArray *)confirmedUserConnections {
    
    NSMutableArray *connections = [[NSMutableArray alloc] init];
    
    for (TVConnection *connection in [[TVDatabase currentAccount].person connections]) {
        
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
    
    for (TVConnection *connection in [[TVDatabase currentAccount].person connections]) {
        
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
    
    TVFlight *flight = [TVDatabase flightFromID:FlightID];
    
    PFQuery *query = [PFQuery queryWithClassName:@"Flights"];
    [query whereKey:@"flightId" containedIn:[TVDatabase confirmedUserConnections]];
    
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
                
                int indexOfOurFlight = [[[[TVDatabase currentAccount] person] flights] indexOfFlight:[TVDatabase flightFromID:FlightID]];
                
                if (!indexOfOurFlight) {
                    
                    self_dayLeaves = -1;
                }
                else {
                    
                    TVFlight *flight = [[[TVDatabase currentAccount] person] flights][indexOfOurFlight - 1];
                    
                    self_dayLeaves = [[flight date] timeIntervalSinceReferenceDate];
                }
                
                for (int i = 0; i <= flights.count - 1; i++) {
                    
                    TVFlight *_flight = flights[i];
                    
                    int user_dayArrives;
                    int user_dayLeaves;
                    
                    user_dayArrives = [[flight date] timeIntervalSinceReferenceDate];
                    
                    if (!i) {
                        
                        user_dayLeaves = -1;
                    }
                    else {
                        
                        user_dayLeaves = [[((TVFlight *)flights[i - 1]) date] timeIntervalSinceReferenceDate];
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
        
        [TVDatabase downloadUsersFromUserIds:allIDs withCompletionHandler:^(NSMutableArray *users, NSError *error, NSString *callCode) {
            
            if (!error) {
                
                for (PFUser *user in users) {
                    
                    if ([confirmedSameCity containsObject:[user objectId]]) {
                        
                        [TVDatabase getAccountFromUser:user withCompletionHandler:^(TVAccount *account, BOOL allOperationsComplete, BOOL hasWrittenProfilePicture) {
                            
                            if (hasWrittenProfilePicture) {
                                
                                account.person.accessibilityValue = user.objectId;
                                
                                callback([@[account.person] mutableCopy], nil, nil);
                            }
                        }];
                    }
                    else {
                                                
                        if ([user[@"originCity"] isEqualToString:flight.destinationCity]) {
                            
                            [TVDatabase getAccountFromUser:user withCompletionHandler:^(TVAccount *account, BOOL allOperationsComplete, BOOL hasWrittenProfilePicture) {
                                
                                if (hasWrittenProfilePicture) {
                                    
                                    account.person.accessibilityValue = user.objectId;

                                    callback([@[account.person] mutableCopy], nil, nil);
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
    
    PFQuery *connectQuery = [PFQuery orQueryWithSubqueries:@[connectQuery1, connectQuery2]];
    
    [connectQuery setCachePolicy:kPFCachePolicyNetworkElseCache];
    
    [connectQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        NSMutableArray *connections = [[NSMutableArray alloc] init];
        
        for (PFObject *connectionObject in objects) {
            
            TVConnection *connection = [[TVConnection alloc] initWithSenderId:connectionObject[@"from"] receiverId:connectionObject[@"to"] andStatus:(ConnectRequestStatus *)[connectionObject[@"status"] intValue]];
            
            [connections addObject:connection];
        }
        
        callback([connections mutableCopy], error, FINDING_PEOPLE);
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
        
        callback([objects mutableCopy], error, FINDING_PEOPLE);
    }];
}

+ (void)downloadMyConnectionsWithCompletionHandler:(void (^)(NSMutableArray *objects, NSError *error, NSString *callCode))callback {
    
    PFQuery *query = [PFUser query];
    [query whereKey:@"objectId" containedIn:[TVDatabase allUserConnections]];
    
    [query setCachePolicy:kPFCachePolicyNetworkElseCache];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        callback([objects mutableCopy], nil, FINDING_PEOPLE);
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
        
        callback([objects mutableCopy], error, FINDING_PEOPLE);
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
    
    [connection saveEventually:^(BOOL succeeded, NSError *error) {
        
        if (!error && succeeded) {
                        
            TVAccount *newAccount = [TVDatabase currentAccount];
                        
            TVConnection *connection = [[TVConnection alloc] initWithSenderId:[[PFUser currentUser] objectId] receiverId:[user objectId] andStatus:kConnectRequestPending];
                        
            [[newAccount.person connections] addObject:connection];
                        
            [TVDatabase updateMyCache:newAccount];
            
            [TVDatabase pushNotificationToObjectId:[user objectId] withData:@{@"message":[NSString stringWithFormat:@"%@ wants to connect with you", [[TVDatabase currentAccount].person name]], @"type": @(kPushNotificationWantsToConnect), @"connection": [NSKeyedArchiver archivedDataWithRootObject:connection]}];

            callback(CONNECTING_PEOPLE, YES);
        }
        else {
            
            callback(CONNECTING_PEOPLE, NO);
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
    
    PFQuery *masterQuery = [PFQuery orQueryWithSubqueries:@[query, query2]];
    
    [masterQuery setCachePolicy:kPFCachePolicyNetworkOnly];
    
    [masterQuery findObjectsInBackgroundWithBlock:^(NSArray *activities, NSError *error) {

        if (!error && activities.count) {
            
            for (PFObject *activity in activities) {
                
                [activity deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {

                    if (!error && succeeded) {
                        
                        TVAccount *newAccount = [TVDatabase currentAccount];
                        
                        for (TVConnection *connection in newAccount.person.connections) {

                            if ([connection.senderId isEqualToString:userId] || [connection.receiverId isEqualToString:userId]) {
                                
                                [[newAccount.person connections] removeObject:connection];
                            }
                            
                            [TVDatabase updateMyCache:newAccount];
                        }
                    }
                    else {
                    }
                    
                    callback(nil, DISCONNECTING_PEOPLE, succeeded);
                }];
            }
        }
        else {
            
            callback(error, DISCONNECTING_PEOPLE, NO);
        }
    }];
}

+ (void)acceptConnection:(TVConnection *)connection withCompletionHandler:(void (^)(NSError *, NSString *, BOOL))callback {
        
    TVAccount *account = [TVDatabase currentAccount];
    
    int index = NSNotFound;
    
    if (account.person.connections.count) {
        
        for (int i = 0; i <= account.person.connections.count - 1; i++) {
            
            TVConnection *enumConnection = account.person.connections[i];
            
            if ([[enumConnection senderId] isEqualToString:[connection senderId]] && [[enumConnection receiverId] isEqualToString:[connection receiverId]]) {
                
                index = i;
            }
        }
    }
    
    [connection setStatus:(ConnectRequestStatus *)kConnectRequestAccepted];
    
    if (index != NSNotFound) {
        
        [[account person] connections][index] = connection;
    }
    

    TVNotification *notification = [[TVNotification alloc] initWithType:kNotificationTypeConnectionRequest withUserId:connection.senderId];
    [account.person.notifications removeNotification:notification];
    
    [TVDatabase updateMyCache:account];
    
    PFQuery *connectionQuery = [PFQuery queryWithClassName:@"Connections"];
    [connectionQuery whereKey:@"to" equalTo:connection.receiverId];
    [connectionQuery whereKey:@"from" equalTo:connection.senderId];
    
    [connectionQuery setCachePolicy:kPFCachePolicyNetworkOnly];

    [connectionQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        if (objects.count && !error) {
            
            for (PFObject *activity in objects) {
                
                activity[@"status"] = @(kConnectRequestAccepted);
                
                [activity saveEventually:^(BOOL succeeded, NSError *error) {
                    
                    if (succeeded && !error) {
                     
                        [TVDatabase pushNotificationToObjectId:connection.senderId withData:@{@"message":[NSString stringWithFormat:@"%@ accepted your connection request", [[TVDatabase currentAccount].person name]], @"type": @(kPushNotificationAcceptedConnection), @"connection": [NSKeyedArchiver archivedDataWithRootObject:connection]}];
                    }
                    else {
                        
                    }
                    
                    callback(error, CONNECTING_PEOPLE, succeeded);
                }];
            }
        }
        else {
            
            callback(error, CONNECTING_PEOPLE, NO);
        }
    }];
}

+ (void)declineConnection:(TVConnection *)connection withCompletionHandler:(void (^)(NSError *error, NSString *callCode, BOOL success))callback {
        
    TVAccount *account = [TVDatabase currentAccount];
    
    int index = NSNotFound;
    
    if (account.person.connections.count) {
        
        for (int i = 0; i <= account.person.connections.count - 1; i++) {
            
            TVConnection *enumConnection = account.person.connections[i];
            
            if ([[enumConnection senderId] isEqualToString:[connection senderId]] && [[enumConnection receiverId] isEqualToString:[connection receiverId]]) {
                
                index = i;
            }
        }
    }
    
    if (index != NSNotFound) {
        
        [[[account person] connections] removeObjectAtIndex:index];
    }
    
    TVNotification *notification = [[TVNotification alloc] initWithType:kNotificationTypeConnectionRequest withUserId:connection.senderId];
    [account.person.notifications removeNotification:notification];

    [TVDatabase updateMyCache:account];

    [TVDatabase disconnectWithUserId:connection.senderId withCompletionHandler:^(NSError *error, NSString *callCode, BOOL success) {

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
                    
                    [TVDatabase writeProfilePictureToDisk:profilePicture withUserId:[object objectId]];
                    
                    callback(error, profilePicture);
                }];
            }
        }
    }];
}

+ (void)uploadProfilePicture:(UIImage *)profilePicture withObjectId:(NSString *)objectId {
    
    [TVDatabase writeProfilePictureToDisk:profilePicture withUserId:objectId];
    
    PFObject *object = [PFObject objectWithClassName:@"ProfilePictures"];
    object[@"photoId"] = [[PFUser currentUser] objectId];
    
    CGSize newSize = CGSizeMake(profilePicture.size.width * 0.25, profilePicture.size.height * 0.25);
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [profilePicture drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *small = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    PFFile *profilePictureFile = [PFFile fileWithData:UIImageJPEGRepresentation(small, 1.0)];
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
            
            CGSize newSize = CGSizeMake(profilePicture.size.width * 0.25, profilePicture.size.height * 0.25);
            UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
            [profilePicture drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
            UIImage *small = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();

            PFFile *profilePictureFile = [PFFile fileWithData:UIImageJPEGRepresentation(small, 1.0)];
            objects[0][@"profilePicture"] = profilePictureFile;
            
            [objects[0] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                
                callbackError = error;
                success = succeeded;
                
                callback(success, callbackError, UPLOADING_PHOTO);
            }];
        }
        else {
            
            callback(success, callbackError, UPLOADING_PHOTO);
        }
    }];
}

+ (void)writeProfilePictureToDisk:(UIImage *)image withUserId:(NSString *)userId {
    
    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/ProfilePicture_%@.png", userId]];
    
    [UIImageJPEGRepresentation(image, 1.0) writeToFile:path atomically:NO];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ProfilePictureWritten" object:nil userInfo:nil];
}

+ (UIImage *)locateProfilePictureOnDiskWithUserId:(NSString *)userId {
    
    UIImage *profilePicture = [UIImage imageWithContentsOfFile:[NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/ProfilePicture_%@.png", userId]]];
    
    if (!profilePicture) {
        
        profilePicture = [UIImage imageNamed:@"anonymous_person.png"];
    }
    
    return profilePicture;
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
        
    flightsObject[@"flights"] = [NSKeyedArchiver archivedDataWithRootObject:flights];
    flightsObject[@"flightId"] = objectId;
    
    PFACL *flightACL = [PFACL ACLWithUser:[PFUser currentUser]];
    [flightACL setPublicReadAccess:YES];
    [flightACL setPublicWriteAccess:NO];
    flightsObject.ACL = flightACL;

    [flightsObject saveInBackground];
}

+ (void)updateFlights:(NSArray *)flights withObjectId:(NSString *)objectId {
    
    PFQuery *query = [PFQuery queryWithClassName:@"Flights"];
    [query whereKey:@"flightId" equalTo:objectId];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
       
        objects[0][@"flights"] = [NSKeyedArchiver archivedDataWithRootObject:flights];
        
        [objects[0] saveEventually:^(BOOL succeeded, NSError *error) {
        }];
    }];
}

#pragma mark Account Download

+ (void)getAccountFromUser:(PFUser *)object withCompletionHandler:(void (^)(TVAccount *account, BOOL allOperationsComplete, BOOL hasWrittenProfilePicture))callback {

    __block BOOL profilePictureWritten = NO;
    
    __block int totalOperations = 5;
    __block int operationCount = 0;
    
    TVAccount *account;
    
    if ([object.objectId isEqualToString:[PFUser currentUser].objectId]) {
        
        account = ![TVDatabase currentAccount] ? [[TVAccount alloc] init] : [TVDatabase currentAccount];
    }
    else {
        
        account = [[TVAccount alloc] init];
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
    
    [TVDatabase downloadFlightsWithObjectIds:@[[object objectId]] withCompletionHandler:^(NSError *error, NSMutableArray *flights) {
        
        if (!error && flights) {
            
            [[account person] setFlights:[NSKeyedUnarchiver unarchiveObjectWithData:flights[0][@"flights"]]];
            
            operationCount++;
            
            callback(account, operationCount == totalOperations ? YES : NO, profilePictureWritten);
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshedFlights" object:nil userInfo:nil];
        }
    }];
    
    [TVDatabase findMyConnections:^(NSMutableArray *objects, NSError *error, NSString *callCode) {
        
        [account.person.notifications clearNotificationOfType:kNotificationTypeConnectionRequest];
        
        for (TVConnection *connection in objects) {
                        
            if (connection.status == kConnectRequestPending && [connection.receiverId isEqualToString:[[PFUser currentUser] objectId]]) {

                TVNotification *connectNotification = [[TVNotification alloc] initWithType:kNotificationTypeConnectionRequest withUserId:connection.senderId];
                
                [account.person.notifications addNotification:connectNotification];
            }
        }
        
        [account.person setConnections:objects];
                
        operationCount++;
        
        callback(account, operationCount == totalOperations ? YES : NO, profilePictureWritten);
    }];

    [TVDatabase downloadMessageHistoriesWithUserId:[[PFUser currentUser] objectId] withCompletionHandler:^(BOOL success, NSError *error, NSString *callCode, NSMutableArray *messageHistories) {
        
        if (success && !error) {
            
            [account.person setMessageHistories:messageHistories];
            
            [account.person.notifications clearNotificationOfType:(NotificationType *)kNotificationTypeUnreadMessages];

            for (TVMessageHistory *messageHistory in messageHistories) {
                
                if (![messageHistory.sortedMessages[0] receiverRead] && ![[[PFUser currentUser] objectId] isEqualToString:[((TVMessage *)messageHistory.sortedMessages[0]) senderId]]) {                    
                    
                    TVNotification *notification = [[TVNotification alloc] initWithType:(NotificationType *)kNotificationTypeUnreadMessages withUserId:messageHistory.senderId];
                    
                    [account.person.notifications addNotification:notification];
                }
            }
        }
        else {
            
        }
        
        operationCount++;
        
        callback(account, operationCount == totalOperations ? YES : NO, profilePictureWritten);
    }];
    
    [TVDatabase downloadProfilePicturesWithObjectIds:@[[object objectId]] withCompletionHandler:^(NSError *error, UIImage *profilePic) {
                
        if (!error && profilePic) {
        }
        else {
            
            profilePic = [UIImage imageNamed:@"anonymous_person.png"];
        }
        
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
            
            callback([objects mutableCopy], error, DOWNLOADING_ACCOUNTS_FROM_IDS);
        }
        else {
        
        }
    }];
}

+ (NSMutableArray *)cachedPeople {
    
    return ![[NSUserDefaults standardUserDefaults] objectForKey:@"cachedPeople"] ? [[NSMutableArray alloc] init] : [[NSUserDefaults standardUserDefaults] objectForKey:@"cachedPeople"];
}

+ (void)cachePeople:(TVAccount *)account {
    
}

+ (TVAccount *)cachedPersonWithId:(NSString *)userId {
    
}

+ (void)refreshCachedPeople {
    
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
        
    NSDictionary *paramDict = [TVDatabase emailParameters:dictionary];
    
    SESSendEmailRequest *ser = [[SESSendEmailRequest alloc] init];
    
    ser.source = VERIFIED_EMAIL;
    ser.destination = paramDict[@"destination"];
    ser.message = paramDict[@"message"];
    
    ser.requestTag = SENDING_REQUEST_EMAIL;
    
    SESSendEmailResponse *response = [sesClient sendEmail:ser];
    
    BOOL success = NO;
    
    if (!response.error) {
        
        success = YES;
    }
    
    callback(success, response.error, ser.requestTag);
}

#pragma mark Logging in

+ (void)loginToAccountWithEmail:(NSString *)email andPassword:(NSString *)password withCompletionHandler:(void (^)(BOOL success, BOOL correctCredentials, NSError *error, NSString *callCode))callback {
    
    [PFUser logInWithUsernameInBackground:email password:password block:^(PFUser *user, NSError *error) {
        
        __block BOOL success = NO;
        __block BOOL correctCredentials = NO;
        
        if (user && !error) {
            
            success = YES;
            
            correctCredentials = YES;
            
            callback(success, correctCredentials, error, LOGGING_IN);
        }
        else {
            
            if ([error.userInfo[@"code"] intValue] == [WRONG_LOGIN intValue]) {
                
                success = YES;
                
                error = nil;
                
                correctCredentials = NO;
            }
            
            callback(success, correctCredentials, error, LOGGING_IN);
        }
    }];
}

+ (void)requestForNewPassword:(NSString *)email withCompletionHandler:(void (^)(BOOL succeeded, NSError *error, NSString *callCode))callback {

    [PFUser requestPasswordResetForEmailInBackground:email block:^(BOOL succeeded, NSError *error) {
       
        callback(succeeded, error, REQUEST_FORGOT_PASSWORD);
    }];
}

#pragma mark Operations

+ (NSMutableArray *)attributesWithAccount:(TVAccount *)accountObj {

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

+ (NSData *)archiveAccount:(TVAccount *)accountObj {
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:accountObj];
    
    return data;
}

+ (TVAccount *)unarchiveAccount:(NSData *)data {
    
    TVAccount *accountObj = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    return accountObj;
}

+ (void)updateMyCache:(TVAccount *)accountObj {
    
    [TVDatabase setNativeAccount:accountObj];
    [TVDatabase setCurrentAccount:accountObj];
}

+ (void)updateMyAccount:(TVAccount *)accountObj withCompletionHandler:(void (^)(BOOL succeeded, NSError *error, NSString *callCode))callback {
    
    NSString *reqTag = UPDATING_MY_ACCOUNT;

    [TVDatabase updateMyCache:accountObj];
        
    for (NSDictionary *attribute in [self attributesWithAccount:accountObj]) {
        
        [PFUser currentUser][attribute[@"key"]] = attribute[@"value"];
    }
    
    [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        
        if (!error && succeeded) {
            
            [TVDatabase updateFlights:[[accountObj person] flights] withObjectId:[[PFUser currentUser] objectId]];
            [TVDatabase updatePushNotificationsSetup];
        }
        
        callback(succeeded, error, reqTag);
    }];
}

+ (void)uploadAccount:(TVAccount *)trvlogueAccount withProfilePicture:(UIImage *)profilePicture andCompletionHandler:(void (^)(BOOL, NSError *, NSString *))callback {
    
    PFUser *user = [PFUser user];
        
    user.username = trvlogueAccount.email;
    user.email = trvlogueAccount.email;
    user.password = trvlogueAccount.password;
    
    for (NSDictionary *attribute in [self attributesWithAccount:trvlogueAccount]) {
        
        user[attribute[@"key"]] = attribute[@"value"];
    }
    
    [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        
        if (!error && succeeded) {
                                    
            PFACL *ACL = [PFACL ACLWithUser:[PFUser currentUser]];
            [ACL setPublicReadAccess:YES];
            [ACL setPublicWriteAccess:NO];
            [PFUser currentUser].ACL = ACL;
            [[PFUser currentUser] saveInBackground];
                        
            [TVDatabase uploadFlights:[[trvlogueAccount person] flights] withObjectId:[[PFUser currentUser] objectId]];
            [TVDatabase uploadProfilePicture:profilePicture withObjectId:[[PFUser currentUser] objectId]];
            
            [TVDatabase updatePushNotificationsSetup];

            [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
             UIRemoteNotificationTypeBadge |
             UIRemoteNotificationTypeAlert |
             UIRemoteNotificationTypeSound];
            
            [TVDatabase updateMyCache:trvlogueAccount];
        }
        
        callback(succeeded, error, CREATING_ACCOUNT);
    }];
}

@end