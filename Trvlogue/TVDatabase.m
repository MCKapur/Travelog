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

+ (void)deleteMessageHistoryFromID:(NSString *)ID {
    
    int indexToReplace = NSNotFound;
    
    if ([[[TVDatabase currentAccount] person] messageHistories].count) {
        
        for (int i = 0; i <= [[[TVDatabase currentAccount] person] messageHistories].count - 1; i++) {
            
            TVMessageHistory *messageHistory = [[[TVDatabase currentAccount] person] messageHistories][i];
            
            if ([messageHistory.ID isEqualToString:ID]) {
                
                indexToReplace = i;
            }
        }
        
        if (indexToReplace != NSNotFound) {
            
            TVAccount *account = [TVDatabase currentAccount];
            [account.person.messageHistories removeObjectAtIndex:indexToReplace];
            [TVDatabase updateMyCache:account];
        }
    }
}

+ (NSString *)messageHistoryIDFromRecipients:(NSMutableArray *)recipients {
        
    NSString *retVal = nil;
    
    for (TVMessageHistory *messageHistory in [[[TVDatabase currentAccount] person] messageHistories]) {

        NSString *ID = [NSString stringWithFormat:@"%@->%@", recipients[0], recipients[1]];
        NSString *OtherID = [NSString stringWithFormat:@"%@->%@", recipients[1], recipients[0]];

        if ([messageHistory.ID isEqualToString:ID]) {
            
            retVal = ID;
        }
        else if ([messageHistory.ID isEqualToString:OtherID]) {
            
            retVal = OtherID;
        }
        
        break;
    }
    
    return retVal;
}

+ (void)sendMessage:(TVMessage *)message toHistoryWithID:(NSString *)messageHistoryID withCompletionHandler:(void (^)(BOOL success, NSError *error, NSString *callCode))callback {
    
    TVAccount *account = [TVDatabase currentAccount];

    if (account.person.messageHistories.count) {

        NSMutableArray *messageHistoriesCopy = [(TVMessageHistory *)account.person.messageHistories mutableCopy];
        
        for (int i = 0; i <= [messageHistoriesCopy count] - 1; i++) {
            
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
        
        if (!error) {

            if (objects.count) {
                
                PFObject *messageObject = objects[0];
                
                TVMessageHistory *messageHistory = [NSKeyedUnarchiver unarchiveObjectWithData:messageObject[@"messageHistory"]];
                
                [[messageHistory messages] addObject:message];
                
                messageObject[@"messageHistory"] = [NSKeyedArchiver archivedDataWithRootObject:messageHistory];
                
                [messageObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    
                    [TVDatabase pushNotificationToObjectId:[[TVDatabase messageHistoryFromID:messageHistoryID].ID isEqualToString:[[TVDatabase currentAccount] userId]] ? [TVDatabase messageHistoryFromID:messageHistoryID].senderId : [TVDatabase messageHistoryFromID:messageHistoryID].receiverId withData:@{@"type": @(kPushNotificationReceivedMessage), @"alert": [NSString stringWithFormat:@"%@: \"%@\"", [[[TVDatabase currentAccount] person] name], message.body], @"messageHistoryID": messageHistory.ID, @"messageBody": message.body, @"userId": message.senderId, @"sound": @"default", @"badge": @"Increment"}];
                }];
            }
            else {
                
                [TVDatabase createMessageHistory:[TVDatabase messageHistoryFromID:messageHistoryID] withCompletionHandler:^(BOOL success, NSError *error, NSString *callCode) {
                    
                    callback(success, error, SEND_MESSAGE);
                }];
            }
        }
        else {
            
            callback(NO, error, SEND_MESSAGE);
        }
    }];
}

+ (void)createMessageHistory:(TVMessageHistory *)messageHistory withCompletionHandler:(void (^)(BOOL success, NSError *error, NSString *callCode))callback {
    
    TVMessage *message = messageHistory.messages[0];
    
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
                
                [messageObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    
                    callback(succeeded, error, SEND_MESSAGE);
                    
                    [TVDatabase pushNotificationToObjectId:[messageHistory.receiverId isEqualToString:[[TVDatabase currentAccount] userId]] ? messageHistory.senderId : messageHistory.receiverId withData:@{@"type": @(kPushNotificationReceivedMessage), @"alert": [NSString stringWithFormat:@"%@: \"%@\"", [[[TVDatabase currentAccount] person] name], message.body], @"messageHistoryID": messageHistory.ID, @"messageBody": message.body, @"userId": message.senderId, @"badge": @"Increment", @"sound": @"default"}];
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

+ (void)confirmReceiverHasReadMessagesinMessageHistory:(TVMessageHistory *)messageHistory withCompletionHandler:(void (^)(BOOL success, NSError *error, NSString *callCode))callback {

    PFQuery *query = [PFQuery queryWithClassName:@"Messages"];
    
    [query whereKey:@"senderId" equalTo:messageHistory.senderId];
    [query whereKey:@"receiverId" equalTo:messageHistory.receiverId];
    
    TVAccount *account = [TVDatabase currentAccount];
    
    NSMutableArray *messageHistories = [(TVMessageHistory *)account.person.messageHistories mutableCopy];
    
    for (int i = 0; i <= [messageHistories count] - 1; i++) {
        
        if ([((TVMessageHistory *)account.person.messageHistories[i]).ID isEqualToString:messageHistory.ID]) {
            
            NSMutableArray *messages = [((TVMessageHistory *)account.person.messageHistories[i]).messages mutableCopy];
            
            for (int j = 0; j <= messages.count - 1; j++) {

                [((TVMessage *)((TVMessageHistory *)account.person.messageHistories[i]).messages[j]) setReceiverRead:YES];
                
                [account.person.notifications removeNotification:[[TVNotification alloc] initWithType:(NotificationType *)kNotificationTypeUnreadMessages withUserId:[messageHistory.senderId isEqualToString:[[TVDatabase currentAccount] userId]] ? messageHistory.receiverId : messageHistory.senderId]];
            }
        }
    }
    
    [TVDatabase updateMyCache:account];

    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        if (objects.count && !error) {
            
            for (int i = 0; i <= [messageHistories count] - 1; i++) {
                
                if ([((TVMessageHistory *)account.person.messageHistories[i]).ID isEqualToString:messageHistory.ID]) {
                    
                    objects[0][@"messageHistory"] = [NSKeyedArchiver archivedDataWithRootObject:account.person.messageHistories[i]];
                }
            }
            
            [objects[0] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {

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
    
    PFQuery *query = [PFQuery orQueryWithSubqueries:@[senderQuery, receiverQuery]];

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
    
    PFQuery *query = [PFQuery orQueryWithSubqueries:@[queryScenario1, queryScenario2]];
    
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
    [query whereKey:@"userId" equalTo:objectId];
    
    PFPush *push = [PFPush push];
    [push setQuery:query];
    [push setData:data];

    [push sendPushInBackground];
}

+ (void)receivedLocalNotification:(NSDictionary *)userInfo {

    TVAccount *newAccount = [TVDatabase currentAccount];
    
    if ([userInfo[@"type"] intValue] == kPushNotificationWantsToConnect) {
        
        [PFPush handlePush:userInfo];
        
        TVConnection *connection = [[TVConnection alloc] initWithSenderId:userInfo[@"userId"] receiverId:[[TVDatabase currentAccount] userId] andStatus:kConnectRequestPending];
        
        int indexToReplace = NSNotFound;
        
        for (int i = 0; i <= [[[[TVDatabase currentAccount] person] connections] count] - 1; i++) {
            
            TVConnection *_connection = [[[TVDatabase currentAccount] person] connections][i];
            
            if ([connection.senderId isEqualToString:_connection.senderId] && [connection.receiverId isEqualToString:_connection.receiverId]) {
                
                indexToReplace = i;
            }
        }
        
        if (indexToReplace != NSNotFound) {
            
            [newAccount.person.connections addObject:connection];
        }
        else {
            
            (newAccount.person.connections)[indexToReplace] = connection;
        }
        
        TVNotification *notification = [[TVNotification alloc] initWithType:kNotificationTypeConnectionRequest withUserId:connection.senderId];
        
        [newAccount.person.notifications addNotification:notification];
    }
    else if ([userInfo[@"type"] intValue] == kPushNotificationAcceptedConnection) {
        
        TVConnection *connection = [[TVConnection alloc] initWithSenderId:[[TVDatabase currentAccount] userId] receiverId:userInfo[@"userId"] andStatus:(ConnectRequestStatus *)kConnectRequestAccepted];

        int indexToReplace = NSNotFound;
        
        for (int i = 0; i <= [[[[TVDatabase currentAccount] person] connections] count] - 1; i++) {
            
            TVConnection *_connection = [[[TVDatabase currentAccount] person] connections][i];
            
            if ([connection.senderId isEqualToString:_connection.senderId] && [connection.receiverId isEqualToString:_connection.receiverId]) {
                
                indexToReplace = i;
            }
        }
        
        if (indexToReplace != NSNotFound) {
            
            [newAccount.person.connections addObject:connection];
        }
        else {
            
            (newAccount.person.connections)[indexToReplace] = connection;
        }
        
        [PFPush handlePush:userInfo];
    }
    else if ([userInfo[@"type"] intValue] == kPushNotificationReceivedMessage) {
        
        TVMessageHistory *messageHistory = [TVDatabase messageHistoryFromID:userInfo[@"messageHistoryID"]];
        
        TVMessage *message = [[TVMessage alloc] initWithBody:userInfo[@"message"] publishDate:[NSDate date] senderId:userInfo[@"userId"] andReceiverId:[[TVDatabase currentAccount] userId]];
        
        int indexToReplace = NSNotFound;
        
        for (int i = 0; i <= [[[[TVDatabase currentAccount] person] messageHistories] count] - 1; i++) {
            
            TVMessageHistory *_messageHistory = [[[TVDatabase currentAccount] person] messageHistories][i];
            
            if ([messageHistory.ID isEqualToString:_messageHistory.ID]) {
                
                indexToReplace = i;
            }
        }
        
        if (indexToReplace != NSNotFound) {
            
            [[((TVMessageHistory *)newAccount.person.messageHistories[indexToReplace]) messages] addObject:message];
        }
        else {
            
            [newAccount.person.messageHistories addObject:messageHistory];
        }
                
        if (![((UINavigationController *)((TVAppDelegate *)[UIApplication sharedApplication].delegate).window.rootViewController).topViewController isKindOfClass:[TVMessageDetailViewController class]]) {
            
            TVNotification *notification = [[TVNotification alloc] initWithType:(NotificationType *)kNotificationTypeUnreadMessages withUserId:message.senderId];
            
            [newAccount.person.notifications addNotification:notification];
            
            [PFPush handlePush:userInfo];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"IncomingMessage" object:nil userInfo:nil];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ManuallyRefreshAccount" object:nil userInfo:nil];
    
    [TVDatabase updateMyCache:newAccount];
}

+ (void)updatePushNotificationsSetup {

    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    currentInstallation[@"userId"] = [[TVDatabase currentAccount] userId];
        
    [currentInstallation setDeviceToken:![[NSUserDefaults standardUserDefaults] objectForKey:@"deviceToken"] ? @"" : [[NSUserDefaults standardUserDefaults] objectForKey:@"deviceToken"]];
    [currentInstallation saveInBackground];
}

+ (void)removePushNotificationsSetup {
    
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:nil];
    currentInstallation[@"userId"] = [[TVDatabase currentAccount] userId];
    [currentInstallation saveInBackground];
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
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSMutableDictionary *)travelDataPacketWithID:(NSString *)_FlightID {
    
    return [NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"TravelDataPacket_%@", _FlightID]]];
}

#pragma mark Account Management

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
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        [TVDatabase updateMyCache:nil];

        [TVDatabase setCanUpdate:NO];

        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"deviceToken"];
        
        [TVDatabase updatePushNotificationsSetup];
        
        [PFUser logOut];
    });
}

+ (TVAccount *)currentAccount {
    
    return [TVDatabase unarchiveAccount:[[NSUserDefaults standardUserDefaults] objectForKey:@"currentAccount"]];
}

+ (void)setCurrentAccount:(TVAccount *)account {
    
    [[NSUserDefaults standardUserDefaults] setObject:[TVDatabase archiveAccount:account] forKey:@"currentAccount"];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)refreshFlights {
    
    if ([[[[TVDatabase currentAccount] person] flights] count]) {
        
        for (int i = [[[[TVDatabase currentAccount] person] flights] count] - 1; i >= 0; i--) {
            
            TVFlight *flight = [[[TVDatabase currentAccount] person] flights][i];
            
            [flight instantiateTravelData];
        }
    }
}

+ (void)refreshAccountWithCompletionHandler:(void (^)(BOOL completed))callback {

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        [TVDatabase refreshCachedPeople];
        [TVDatabase refreshFlights];
        
        [[PFUser currentUser] refreshInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            
            if (!error) {
                
                [TVDatabase getAccountFromUser:(PFUser *)object isPerformingCacheRefresh:YES withCompletionHandler:^(TVAccount *account, BOOL downloadedFlights, BOOL downloadedProfilePicture, BOOL downloadedConnections, BOOL downloadedMessages) {
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        [TVDatabase updateMyCache:account];
                        
                        [TVDatabase updatePushNotificationsSetup];
                        
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshedAccount" object:nil];
                        
                        if (downloadedFlights) {
                            
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshedFlights" object:nil];
                        }
                        
                        if (downloadedFlights && downloadedProfilePicture && downloadedConnections && downloadedMessages && account) {
                            
                            [TVDatabase refreshFlights];
                            
                            callback(YES);
                        }
                        else {
                            
                            callback(NO);
                        }
                    });
                }];
            }
            else {
                
                callback(YES);
            }
        }];
    });
}

#pragma mark Connect

+ (NSMutableArray *)pendingUserConnections {
    
    NSMutableArray *connections = [[NSMutableArray alloc] init];
    
    for (TVConnection *connection in [[TVDatabase currentAccount].person connections]) {
        
        if (connection.status == (ConnectRequestStatus *)kConnectRequestPending) {
            
            if ([connection.receiverId isEqualToString:[[TVDatabase currentAccount] userId]]) {
                
                [connections addObject:connection.senderId];
            }
            else {
                
                [connections addObject:connection.receiverId];
            }
        }
    }
    
    return connections;
}

+ (NSMutableArray *)confirmedUserConnections {
    
    NSMutableArray *connections = [[NSMutableArray alloc] init];
    
    for (TVConnection *connection in [[TVDatabase currentAccount].person connections]) {
        
        if (connection.status == (ConnectRequestStatus *)kConnectRequestAccepted) {
            
            if ([connection.receiverId isEqualToString:[[TVDatabase currentAccount] userId]]) {
                
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
        
        if ([connection.receiverId isEqualToString:[[TVDatabase currentAccount] userId]]) {
            
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
                    
                    if (self_dayArrives >= user_dayArrives && self_dayLeaves <= user_dayLeaves && [flight.destinationCity isEqualToString:_flight.destinationCity]) {
                        
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
                        
                        [TVDatabase getAccountFromUser:user isPerformingCacheRefresh:NO withCompletionHandler:^(TVAccount *account, BOOL downloadedFlights, BOOL downloadedProfilePicture, BOOL downloadedConnections, BOOL downloadedMessages) {
            
                            if (downloadedProfilePicture) {
                                
                                callback([@[account] mutableCopy], nil, nil);
                            }
                        }];
                    }
                    else {
                        
                        if ([user[@"originCity"] isEqualToString:flight.destinationCity]) {
                            
                            [TVDatabase getAccountFromUser:user isPerformingCacheRefresh:NO withCompletionHandler:^(TVAccount *account, BOOL downloadedFlights, BOOL downloadedProfilePicture, BOOL downloadedConnections, BOOL downloadedMessages) {
                                
                                if (downloadedProfilePicture) {
                                    
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

+ (void)findConnectionsFromId:(NSString *)userId withCompletionHandler:(void (^)(NSMutableArray *objects, NSError *error, NSString *callCode))callback {
    
    PFQuery *connectQuery1 = [PFQuery queryWithClassName:@"Connections"];
    [connectQuery1 whereKey:@"from" equalTo:userId];
    
    PFQuery *connectQuery2 = [PFQuery queryWithClassName:@"Connections"];
    [connectQuery2 whereKey:@"to" equalTo:userId];
    
    PFQuery *connectQuery = [PFQuery orQueryWithSubqueries:@[connectQuery1, connectQuery2]];
    
    [connectQuery setCachePolicy:kPFCachePolicyNetworkElseCache];
    
    [connectQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        NSMutableArray *connections = [[NSMutableArray alloc] init];
        
        NSMutableArray *IDs = [[NSMutableArray alloc] init];
        
        for (PFObject *connectionObject in objects) {
            
            [IDs addObject:[connectionObject[@"from"] isEqualToString:userId] ? connectionObject[@"to"] : connectionObject[@"from"]];

            TVConnection *connection = [[TVConnection alloc] initWithSenderId:connectionObject[@"from"] receiverId:connectionObject[@"to"] andStatus:(ConnectRequestStatus *)[connectionObject[@"status"] intValue]];
                        
            [connections addObject:connection];
        }
        
        if ([[[TVDatabase currentAccount] userId] isEqualToString:userId]) {
            
            [TVDatabase downloadUsersFromUserIds:IDs withCompletionHandler:^(NSMutableArray *users, NSError *error, NSString *callCode) {
                
            }];
        }
        
        callback([connections mutableCopy], error, FINDING_PEOPLE);
    }];
}

+ (void)findUsersWithEmails:(NSMutableArray *)emails withCompletionHandler:(void (^)(NSMutableArray *objects, NSError *error, NSString *callCode))callback {

    for (NSString *email in emails) {

        if ([TVDatabase cachedPersonWithEmail:email]) {
            
            TVAccount *account = [TVDatabase cachedPersonWithEmail:email];
            
            PFUser *user = [PFUser user];
            
            user.objectId = account.userId;
            user.username = account.email;
            user.email = account.email;
            
            for (NSDictionary *attribute in [TVDatabase attributesWithAccount:account]) {
                
                user[attribute[@"key"]] = attribute[@"value"];
            }
            
            callback([@[user] mutableCopy], nil, DOWNLOADING_ACCOUNTS_FROM_IDS);
        }
    }

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

+ (void)findUsersWithName:(NSString *)name withCompletionHandler:(void (^)(NSMutableArray *objects, NSError *error, NSString *callCode))callback {
    
    if ([TVDatabase cachedPersonWithName:name]) {
        
        TVAccount *account = [TVDatabase cachedPersonWithName:name];
        
        PFUser *user = [PFUser user];
        
        user.objectId = account.userId;
        user.username = account.email;
        user.email = account.email;
        
        for (NSDictionary *attribute in [TVDatabase attributesWithAccount:account]) {
            
            user[attribute[@"key"]] = attribute[@"value"];
        }
        
        callback([@[user] mutableCopy], nil, DOWNLOADING_ACCOUNTS_FROM_IDS);
    }

    PFQuery *emailQuery = [PFUser query];
    [emailQuery whereKey:@"name" containsString:name];
    
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
    
    for (NSString *ID in linkedInIds) {
        
        if ([TVDatabase cachedPersonWithLinkedInId:ID]) {
            
            TVAccount *account = [TVDatabase cachedPersonWithLinkedInId:ID];
            
            PFUser *user = [PFUser user];
            
            user.objectId = account.userId;
            user.username = account.email;
            user.email = account.email;
            
            for (NSDictionary *attribute in [TVDatabase attributesWithAccount:account]) {
                
                user[attribute[@"key"]] = attribute[@"value"];
            }
            
            callback([@[user] mutableCopy], nil, DOWNLOADING_ACCOUNTS_FROM_IDS);
        }
    }
    
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

+ (void)connectWithUserId:(NSString *)userId withCompletionHandler:(void (^)(NSString *callCode, BOOL success))callback {
    
    PFObject *connection = [PFObject objectWithClassName:@"Connections"];
    connection[@"from"] = [[TVDatabase currentAccount] userId];
    connection[@"to"] = userId;
    connection[@"status"] = @(kConnectRequestPending);
    
    PFACL *connectACL = [PFACL ACLWithUser:[PFUser currentUser]];
    [connectACL setPublicReadAccess:YES];
    [connectACL setPublicWriteAccess:YES];
    connection.ACL = connectACL;
    
    [connection saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        
        if (!error && succeeded) {
            
            TVAccount *newAccount = [TVDatabase currentAccount];
            
            TVConnection *connection = [[TVConnection alloc] initWithSenderId:[[TVDatabase currentAccount] userId] receiverId:userId andStatus:kConnectRequestPending];
            
            [[newAccount.person connections] addObject:connection];
            
            [TVDatabase updateMyCache:newAccount];
            
            [TVDatabase pushNotificationToObjectId:userId withData:@{@"badge": @"Increment", @"alert": [NSString stringWithFormat:@"%@ wants to connect with you", [[TVDatabase currentAccount].person name]], @"sound": @"default", @"type": @(kPushNotificationWantsToConnect), @"userId": connection.senderId}];
            
            callback(CONNECTING_PEOPLE, YES);
        }
        else {
            
            callback(CONNECTING_PEOPLE, NO);
        }
    }];
}

+ (void)disconnectWithUserId:(NSString *)userId withCompletionHandler:(void (^)(NSError *error, NSString *callCode, BOOL success))callback {
    
    PFQuery *query = [PFQuery queryWithClassName:@"Connections"];
    [query whereKey:@"from" equalTo:[[TVDatabase currentAccount] userId]];
    [query whereKey:@"to" equalTo:userId];
    
    PFQuery *query2 = [PFQuery queryWithClassName:@"Connections"];
    [query2 whereKey:@"to" equalTo:[[TVDatabase currentAccount] userId]];
    [query2 whereKey:@"from" equalTo:userId];
    
    PFQuery *masterQuery = [PFQuery orQueryWithSubqueries:@[query, query2]];
    
    [masterQuery setCachePolicy:kPFCachePolicyNetworkOnly];
    
    [masterQuery findObjectsInBackgroundWithBlock:^(NSArray *activities, NSError *error) {
        
        if (!error && activities.count) {
            
            for (PFObject *activity in activities) {
                
                [activity deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    
                    if (!error && succeeded) {
                        
                        TVAccount *newAccount = [TVDatabase currentAccount];
                        
                        NSMutableIndexSet *set = [[NSMutableIndexSet alloc] init];
                        
                        for (int i = 0; i <= newAccount.person.connections.count - 1; i++) {
                            
                            TVConnection *connection = newAccount.person.connections[i];
                            
                            if ([connection.senderId isEqualToString:userId] || [connection.receiverId isEqualToString:userId]) {
                                
                                [set addIndex:i];
                            }
                            
                            [[newAccount.person connections] removeObject:connection];

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
                
                [activity saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    
                    if (succeeded && !error) {
                        
                        [TVDatabase pushNotificationToObjectId:connection.senderId withData:@{@"alert": [NSString stringWithFormat:@"%@ accepted your connection request", [[TVDatabase currentAccount].person name]], @"type": @(kPushNotificationAcceptedConnection), @"userId": connection.receiverId, @"sound": @"default", @"badge": @"Increment"}];
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
                    else {
                        
                        profilePicture = [UIImage imageNamed:@"anonymous_person.png"];
                    }
                    
                    [TVDatabase writeProfilePictureToDisk:profilePicture withUserId:object[@"photoId"]];
                    
                    callback(error, profilePicture);
                }];
            }
        }
    }];
}

+ (void)uploadProfilePicture:(UIImage *)profilePicture withObjectId:(NSString *)objectId {
    
    [TVDatabase writeProfilePictureToDisk:profilePicture withUserId:objectId];
    
    PFObject *object = [PFObject objectWithClassName:@"ProfilePictures"];
    object[@"photoId"] = [[TVDatabase currentAccount] userId];
    
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
    
    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/ProfilePicture_%@.jpg", userId]];
    
    [UIImageJPEGRepresentation(image, 1.0) writeToFile:path atomically:NO];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ProfilePictureWritten" object:nil userInfo:nil];
}

+ (UIImage *)locateProfilePictureOnDiskWithUserId:(NSString *)userId {
    
    UIImage *profilePicture = [UIImage imageWithContentsOfFile:[NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/ProfilePicture_%@.jpg", userId]]];

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
        
        [objects[0] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        }];
    }];
}

#pragma mark Account Download

+ (void)getAccountFromUser:(PFUser *)object isPerformingCacheRefresh:(BOOL)isPerformingCacheRefresh withCompletionHandler:(void (^)(TVAccount *account, BOOL downloadedFlights, BOOL downloadedProfilePicture, BOOL downloadedConnections, BOOL downloadedMessages))callback {

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        if (!isPerformingCacheRefresh) {
            
            if ([TVDatabase cachedPersonWithId:[object objectId]]) {
                
                callback([TVDatabase cachedPersonWithId:[object objectId]], YES, YES, YES, YES);
            }
        }
        
        __block BOOL downloadedProfilePicture = NO;
        __block BOOL downloadedFlights = NO;
        __block BOOL downloadedConnections = NO;
        __block BOOL downloadedMessages = NO;
                
        TVAccount *account;
        
        if ([[TVDatabase currentAccount] userId]) {
            
            if ([object.objectId isEqualToString:[[TVDatabase currentAccount] userId]]) {
                
                account = ![TVDatabase currentAccount] ? [[TVAccount alloc] init] : [TVDatabase currentAccount];
            }
            else {
                
                account = [[TVAccount alloc] init];
            }
        }
        else {
            
            account = [[TVAccount alloc] init];
        }
        

        [account setUserId:[object objectId]];
        [account setEmail:object[@"email"]];
        [account setIsUsingLinkedIn:[object[@"isUsingLinkedIn"] boolValue]];
        [account setLinkedInAccessKey:object[@"linkedInAccessKey"]];
        [account setLinkedInId:object[@"linkedInId"]];
        [account.person setEmail:object[@"email"]];
        [account.person setKnownDestinationPreferences:[[NSMutableDictionary alloc] init]];
        [account.person setName:object[@"name"]];
        [account.person setPosition:object[@"position"]];
        [account.person setMiles:[object[@"miles"] doubleValue]];
        [account.person setOriginCity:object[@"originCity"]];
                
        [TVDatabase cachePerson:account];
        
        callback(account, downloadedFlights, downloadedProfilePicture, downloadedConnections, downloadedMessages);

        [TVDatabase downloadFlightsWithObjectIds:@[[object objectId]] withCompletionHandler:^(NSError *error, NSMutableArray *flights) {
            
            if (!error && flights) {
                
                [[account person] setFlights:[NSKeyedUnarchiver unarchiveObjectWithData:flights[0][@"flights"]]];
                
                downloadedFlights = YES;
                
                [TVDatabase cachePerson:account];
                
                callback(account, downloadedFlights, downloadedProfilePicture, downloadedConnections, downloadedMessages);
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshedFlights" object:nil userInfo:nil];
            }
        }];
        
        [TVDatabase findConnectionsFromId:[object objectId] withCompletionHandler:^(NSMutableArray *objects, NSError *error, NSString *callCode) {
            
            [account.person.notifications clearNotificationOfType:kNotificationTypeConnectionRequest];
            
            for (TVConnection *connection in objects) {
                
                if (connection.status == kConnectRequestPending && [connection.receiverId isEqualToString:[[TVDatabase currentAccount] userId]]) {
                    
                    TVNotification *connectNotification = [[TVNotification alloc] initWithType:kNotificationTypeConnectionRequest withUserId:connection.senderId];
                    
                    [account.person.notifications addNotification:connectNotification];
                }
            }
            
            downloadedConnections = YES;
            
            [account.person setConnections:objects];
            
            [TVDatabase cachePerson:account];
            
            callback(account, downloadedFlights, downloadedProfilePicture, downloadedConnections, downloadedMessages);
        }];
        
        [TVDatabase downloadMessageHistoriesWithUserId:[object objectId] withCompletionHandler:^(BOOL success, NSError *error, NSString *callCode, NSMutableArray *messageHistories) {
            
            if (success && !error) {
                
                downloadedMessages = YES;
                
                [account.person setMessageHistories:messageHistories];
                
                [account.person.notifications clearNotificationOfType:kNotificationTypeUnreadMessages];
                
                NSMutableArray *IDs = [[NSMutableArray alloc] init];
                
                for (TVMessageHistory *messageHistory in messageHistories) {
                    
                    [IDs addObject:[[TVDatabase currentAccount] userId] ? messageHistory.receiverId : messageHistory.senderId];
                    
                    if (![[messageHistory.sortedMessages lastObject] receiverRead] && ![[[TVDatabase currentAccount] userId] isEqualToString:[((TVMessage *)[messageHistory.sortedMessages lastObject]) senderId]]) {
                        
                        TVNotification *notification = [[TVNotification alloc] initWithType:(NotificationType *)kNotificationTypeUnreadMessages withUserId:messageHistory.senderId];
                        
                        [account.person.notifications addNotification:notification];
                    }
                }
                
                [TVDatabase downloadUsersFromUserIds:IDs withCompletionHandler:^(NSMutableArray *users, NSError *error, NSString *callCode) {
                }];
            }
            else {
                
            }
                        
            [TVDatabase cachePerson:account];
            
            callback(account, downloadedFlights, downloadedProfilePicture, downloadedConnections, downloadedMessages);
        }];
        
        [TVDatabase downloadProfilePicturesWithObjectIds:@[[object objectId]] withCompletionHandler:^(NSError *error, UIImage *profilePic) {
            
            if (!error && profilePic) {
            }
            else {
                
                profilePic = [UIImage imageNamed:@"anonymous_person.png"];
            }
            
            downloadedProfilePicture = YES;
            
            [TVDatabase cachePerson:account];
            
            callback(account, downloadedFlights, downloadedProfilePicture, downloadedConnections, downloadedMessages);
        }];
    });
}

+ (void)downloadUsersFromUserIds:(NSArray *)userIds withCompletionHandler:(void (^)(NSMutableArray *users, NSError *error, NSString *callCode))callback {

    for (NSString *ID in userIds) {

        if ([TVDatabase cachedPersonWithId:ID]) {
            
            TVAccount *account = [TVDatabase cachedPersonWithId:ID];

            PFUser *user = [PFUser user];
            user.objectId = account.userId;

            user.username = account.email;
            user.email = account.email;
            
            for (NSDictionary *attribute in [TVDatabase attributesWithAccount:account]) {
                
                user[attribute[@"key"]] = attribute[@"value"];
            }

            callback([@[user] mutableCopy], nil, DOWNLOADING_ACCOUNTS_FROM_IDS);
        }
    }
    
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

+ (void)cachePerson:(TVAccount *)account {

    NSMutableArray *cachedPeople = [[TVDatabase cachedPeople] mutableCopy];

    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:account];

    if ([TVDatabase indexOfCachedPersonWithUserId:account.userId] != NSNotFound) {
        
        cachedPeople[[TVDatabase indexOfCachedPersonWithUserId:account.userId]] = data;
    }
    else {
        
        [cachedPeople addObject:data];
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:cachedPeople forKey:@"cachedPeople"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (int)indexOfCachedPersonWithUserId:(NSString *)userId {

    int index = NSNotFound;

    if ([TVDatabase cachedPeople].count) {
        
        for (int i = 0; i <= [TVDatabase cachedPeople].count - 1; i++) {
            
            TVAccount *_account = [NSKeyedUnarchiver unarchiveObjectWithData:[TVDatabase cachedPeople][i]];

            if ([_account.userId isEqualToString:userId]) {

                index = i;
            }
        }
    }
    
    return index;
}

+ (int)indexOfCachedPersonWithName:(NSString *)name {
    
    int index = NSNotFound;
    
    if ([TVDatabase cachedPeople].count) {
        
        for (int i = 0; i <= [TVDatabase cachedPeople].count - 1; i++) {
            
            TVAccount *_account = [NSKeyedUnarchiver unarchiveObjectWithData:[TVDatabase cachedPeople][i]];

            if ([_account.person.name rangeOfString:name options:NSCaseInsensitiveSearch].location != NSNotFound || [_account.person.name soundsLikeString:name]) {

                index = i;
            }
        }
    }
    
    return index;
}

+ (int)indexOfCachedPersonWithEmail:(NSString *)email {

    int index = NSNotFound;
    
    if ([TVDatabase cachedPeople].count) {
        
        for (int i = 0; i <= [TVDatabase cachedPeople].count - 1; i++) {
            
            TVAccount *_account = [NSKeyedUnarchiver unarchiveObjectWithData:[TVDatabase cachedPeople][i]];
            
            if ([[_account.person.email lowercaseString] isEqualToString:[email lowercaseString]]) {

                index = i;
            }
        }
    }
    
    return index;
}

+ (int)indexOfCachedPersonWithLinkedIn:(NSString *)linkedInId {
    
    int index = NSNotFound;
    
    if ([TVDatabase cachedPeople].count) {
        
        for (int i = 0; i <= [TVDatabase cachedPeople].count - 1; i++) {
            
            TVAccount *_account = [NSKeyedUnarchiver unarchiveObjectWithData:[TVDatabase cachedPeople][i]];
            
            if ([_account isUsingLinkedIn] && [_account.linkedInId isEqualToString:linkedInId]) {
                
                index = i;
            }
        }
    }
    
    return index;
}

+ (TVAccount *)cachedPersonWithId:(NSString *)userId {
    
    TVAccount *retVal = nil;

    if ([TVDatabase indexOfCachedPersonWithUserId:userId] != NSNotFound) {
        
        retVal = [NSKeyedUnarchiver unarchiveObjectWithData:[TVDatabase cachedPeople][[TVDatabase indexOfCachedPersonWithUserId:userId]]];
    }
    
    return retVal;
}

+ (TVAccount *)cachedPersonWithName:(NSString *)name {
    
    TVAccount *retVal = nil;
    
    if ([TVDatabase indexOfCachedPersonWithName:name] != NSNotFound) {
        
        retVal = [NSKeyedUnarchiver unarchiveObjectWithData:[TVDatabase cachedPeople][[TVDatabase indexOfCachedPersonWithName:name]]];
    }
    
    return retVal;
}

+ (TVAccount *)cachedPersonWithEmail:(NSString *)email {
    
    TVAccount *retVal = nil;
    
    if ([TVDatabase indexOfCachedPersonWithEmail:email] != NSNotFound) {
        
        retVal = [NSKeyedUnarchiver unarchiveObjectWithData:[TVDatabase cachedPeople][[TVDatabase indexOfCachedPersonWithEmail:email]]];
    }
    
    return retVal;
}

+ (TVAccount *)cachedPersonWithLinkedInId:(NSString *)linkedInId {
    
    TVAccount *retVal = nil;
    
    if ([TVDatabase indexOfCachedPersonWithLinkedIn:linkedInId] != NSNotFound) {
        
        retVal = [NSKeyedUnarchiver unarchiveObjectWithData:[TVDatabase cachedPeople][[TVDatabase indexOfCachedPersonWithLinkedIn:linkedInId]]];
    }
    
    return retVal;
}

+ (void)refreshCachedPeople {
    
    NSMutableArray *reference = [[TVDatabase cachedPeople] mutableCopy];

    if (reference.count) {

        for (int i = 0; i <= reference.count - 1; i++) {
            
            TVAccount *account = [NSKeyedUnarchiver unarchiveObjectWithData:reference[i]];

            [TVDatabase downloadUsersFromUserIds:@[account.userId] withCompletionHandler:^(NSMutableArray *users, NSError *error, NSString *callCode) {
                
                if (users.count && !error) {
                    
                    if (users[0]) {
                        
                        [TVDatabase getAccountFromUser:users[0] isPerformingCacheRefresh:YES withCompletionHandler:^(TVAccount *account, BOOL downloadedFlights, BOOL downloadedProfilePicture, BOOL downloadedConnections, BOOL downloadedMessages) {
                        }];
                    }
                }
                else {
                    
                }
            }];
        }
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:reference forKey:@"cachedPeople"];
    [[NSUserDefaults standardUserDefaults] synchronize];
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

    NSDictionary *paramDict = [TVDatabase emailParameters:dictionary];

    SESSendEmailRequest *ser = [[SESSendEmailRequest alloc] init];
    
    ser.source = VERIFIED_EMAIL_TEST;
    ser.destination = paramDict[@"destination"];
    ser.message = paramDict[@"message"];
    
    ser.requestTag = SENDING_REQUEST_EMAIL;
    
    SESSendEmailResponse *response = [[AmazonClientManager ses] sendEmail:ser];

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
            
            [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
             UIRemoteNotificationTypeBadge |
             UIRemoteNotificationTypeAlert |
             UIRemoteNotificationTypeSound];
            
            [TVDatabase setCanUpdate:YES];

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

    if ([TVDatabase canUpdate]) {
        
        [TVDatabase setNativeAccount:accountObj];
        [TVDatabase setCurrentAccount:accountObj];
    }
}

+ (BOOL)canUpdate {
 
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"canUpdate"];
}

+ (void)setCanUpdate:(BOOL)canUpdate {
    
    [[NSUserDefaults standardUserDefaults] setBool:canUpdate forKey:@"canUpdate"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)updateMyAccount:(TVAccount *)accountObj withCompletionHandler:(void (^)(BOOL succeeded, NSError *error, NSString *callCode))callback {
    
    NSString *reqTag = UPDATING_MY_ACCOUNT;
    
    [TVDatabase updateMyCache:accountObj];
    
    for (NSDictionary *attribute in [TVDatabase attributesWithAccount:accountObj]) {
        
        [PFUser currentUser][attribute[@"key"]] = attribute[@"value"];
    }
    
    [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        
        if (!error && succeeded) {
            
            [TVDatabase updateFlights:[[accountObj person] flights] withObjectId:[[TVDatabase currentAccount] userId]];
        }
        
        callback(succeeded, error, reqTag);
    }];
}

+ (void)uploadAccount:(TVAccount *)trvlogueAccount withProfilePicture:(UIImage *)profilePicture andCompletionHandler:(void (^)(BOOL, NSError *, NSString *))callback {
    
    PFUser *user = [PFUser user];
    
    user.username = trvlogueAccount.email;
    user.email = trvlogueAccount.email;
    user.password = trvlogueAccount.accessibilityValue;

    for (NSDictionary *attribute in [TVDatabase attributesWithAccount:trvlogueAccount]) {
        
        user[attribute[@"key"]] = attribute[@"value"];
    }
    
    [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        
        if (!error && succeeded) {
            
            [TVDatabase setCanUpdate:YES];
            
            trvlogueAccount.userId = user.objectId;
            [TVDatabase updateMyCache:trvlogueAccount];

            PFACL *ACL = [PFACL ACLWithUser:[PFUser currentUser]];
            [ACL setPublicReadAccess:YES];
            [ACL setPublicWriteAccess:NO];
            [PFUser currentUser].ACL = ACL;
            [[PFUser currentUser] saveInBackground];

            [TVDatabase uploadFlights:[[trvlogueAccount person] flights] withObjectId:[[TVDatabase currentAccount] userId]];
            [TVDatabase uploadProfilePicture:profilePicture withObjectId:[[TVDatabase currentAccount] userId]];
            
            [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
             UIRemoteNotificationTypeBadge |
             UIRemoteNotificationTypeAlert |
             UIRemoteNotificationTypeSound];
            
            [TVDatabase updatePushNotificationsSetup];
        }
        
        callback(succeeded, error, CREATING_ACCOUNT);
    }];
}

@end