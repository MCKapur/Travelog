//
//  TVDatabase.m
//  Travelog
//
//  Created by Rohan Kapur on 6/2/13.
//  Copyright (c) 2013 UWCSEA. All rights reserved.
//

#import "TVDatabase.h"

#import "TVAppDelegate.h"

@interface NSArray (Indexing)

- (NSInteger)indexOfFlight:(TVFlight *)flight;

@end

@implementation NSArray (Indexing)

- (NSInteger)indexOfFlight:(TVFlight *)flight {
    
    NSInteger retVal = NSNotFound;
    
    for (NSInteger i = 0; i <= self.count - 1; i++) {
        
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

#pragma mark LinkedIn

+ (void)setLocalLinkedInRequestToken:(NSString *)linkedInRequestToken {
    
    [[EGOCache globalCache] setString:linkedInRequestToken forKey:@"linkedInRequestToken"];
}

+ (NSString *)localLinkedInRequestToken {
    
    return [[EGOCache globalCache] stringForKey:@"linkedInRequestToken"];
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
    
    NSInteger indexToReplace = NSNotFound;
    
    if ([[[TVDatabase currentAccount] person] messageHistories].count) {
        
        for (NSInteger i = 0; i <= [[[TVDatabase currentAccount] person] messageHistories].count - 1; i++) {
            
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
        
        for (NSInteger i = 0; i <= [messageHistoriesCopy count] - 1; i++) {
            
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
                    
                    [TVDatabase pushNotificationToObjectId:message.receiverId withData:[@{@"type": @(kPushNotificationReceivedMessage), @"alert": [NSString stringWithFormat:@"%@ sent you a message", [[[TVDatabase currentAccount] person] name]], @"messageHistoryID": messageHistory.ID, @"userId": message.senderId, @"sound": @"default", @"badge": @"Increment"} mutableCopy]];
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
    
    [query countObjectsInBackgroundWithBlock:^(NSInteger number, NSError *error) {
        
        if (!error) {
            
            if (!number) {
                
                PFObject *messageObject = [PFObject objectWithClassName:@"Messages"];
                
                messageObject[@"senderId"] = messageHistory.senderId;
                messageObject[@"receiverId"] = messageHistory.receiverId;
                
                messageObject[@"messageHistory"] = [NSKeyedArchiver archivedDataWithRootObject:messageHistory];
                
                [messageObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    
                    callback(succeeded, error, SEND_MESSAGE);
                    
                    [TVDatabase pushNotificationToObjectId:[messageHistory.receiverId isEqualToString:[[TVDatabase currentAccount] userId]] ? messageHistory.senderId : messageHistory.receiverId withData:[@{@"type": @(kPushNotificationReceivedMessage), @"alert": [NSString stringWithFormat:@"%@ sent you a message", [[[TVDatabase currentAccount] person] name]], @"messageHistoryID": messageHistory.ID, @"userId": message.senderId, @"badge": @"Increment", @"sound": @"default"} mutableCopy]];
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
    
    for (NSInteger i = 0; i <= [messageHistories count] - 1; i++) {
        
        if ([((TVMessageHistory *)account.person.messageHistories[i]).ID isEqualToString:messageHistory.ID]) {
            
            NSMutableArray *messages = [((TVMessageHistory *)account.person.messageHistories[i]).messages mutableCopy];
            
            for (NSInteger j = 0; j <= messages.count - 1; j++) {

                if (([[(TVMessage *)((TVMessageHistory *)account.person.messageHistories[i]).messages[j] receiverId] isEqualToString:[[TVDatabase currentAccount] userId]])) {
                    
                    [((TVMessage *)((TVMessageHistory *)account.person.messageHistories[i]).messages[j]) setReceiverRead:YES];
                    
                    [account.person.notifications removeNotification:[[TVNotification alloc] initWithType:(NotificationType *)kNotificationTypeUnreadMessages withUserId:[[[TVDatabase currentAccount] userId] isEqualToString:((TVMessage *)((TVMessageHistory *)account.person.messageHistories[i]).messages[j]).senderId] ? ((TVMessage *)((TVMessageHistory *)account.person.messageHistories[i]).messages[j]).receiverId : ((TVMessage *)((TVMessageHistory *)account.person.messageHistories[i]).messages[j]).senderId]];
                }
            }
        }
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [[NSNotificationCenter defaultCenter] postNotificationName:NSNotificationUpdateNotifications object:nil];
    });
    
    [TVDatabase updateMyCache:account];

    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        if (objects.count && !error) {
            
            for (NSInteger i = 0; i <= [messageHistories count] - 1; i++) {
                
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
        
        callback(objects ? YES : NO, error, DOWNLOAD_MESSAGE, messageHistories);
    }];
}

+ (void)downloadMessageHistoryBetweenRecipients:(NSMutableArray *)userIds withCompletionHandler:(void (^)(BOOL success, NSError *error, NSString *callCode, NSMutableArray *messageHistories))callback {
    
    PFQuery *queryScenario1 = [PFQuery queryWithClassName:@"Messages"];
    [queryScenario1 whereKey:@"senderId" equalTo:userIds[0]];
    [queryScenario1 whereKey:@"receiverId" equalTo:userIds[1]];
    
    PFQuery *queryScenario2 = [PFQuery queryWithClassName:@"Messages"];
    [queryScenario2 whereKey:@"senderId" equalTo:userIds[1]];
    [queryScenario2 whereKey:@"receiverId" equalTo:userIds[0]];
    
    PFQuery *query = [PFQuery orQueryWithSubqueries:@[queryScenario1, queryScenario2]];

    [query setCachePolicy:kPFCachePolicyNetworkOnly];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {

        NSMutableArray *messageHistories = [[NSMutableArray alloc] init];
        
        for (PFObject *messageObject in objects) {
            
            TVMessageHistory *messageHistory = [NSKeyedUnarchiver unarchiveObjectWithData:messageObject[@"messageHistory"]];
            
            [messageHistories addObject:messageHistory];
        }
        
        callback(objects ? YES : NO, error, DOWNLOAD_MESSAGE, messageHistories);
    }];
}

#pragma mark Push Notifications

+ (void)pushNotificationToObjectId:(NSString *)objectId withData:(NSMutableDictionary *)data {
    
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
        
        TVConnection *connection = [[TVConnection alloc] initWithSenderId:userInfo[@"userId"] receiverId:[[TVDatabase currentAccount] userId] andStatus:kConnectRequestPending];
        
        NSInteger indexToReplace = NSNotFound;
        
        if ([[[TVDatabase currentAccount] person] connections].count) {
            
            for (NSInteger i = 0; i <= [[[[TVDatabase currentAccount] person] connections] count] - 1; i++) {
                
                TVConnection *_connection = [[[TVDatabase currentAccount] person] connections][i];
                
                if ([connection.senderId isEqualToString:_connection.senderId] && [connection.receiverId isEqualToString:_connection.receiverId]) {
                    
                    indexToReplace = i;
                }
            }
        }
        
        if (indexToReplace == NSNotFound) {

            [newAccount.person.connections addObject:connection];
        }
        else {
            
            (newAccount.person.connections)[indexToReplace] = connection;
        }
        
        TVNotification *notification = [[TVNotification alloc] initWithType:kNotificationTypeConnectionRequest withUserId:connection.senderId];
        
        [newAccount.person.notifications addNotification:notification];
                
        dispatch_async(dispatch_get_main_queue(), ^{
           
            [[NSNotificationCenter defaultCenter] postNotificationName:NSNotificationUpdateNotifications object:nil];

            [[NSNotificationCenter defaultCenter] postNotificationName:NSNotificationReceivedConnectionRequest object:nil];
        });
    }
    else if ([userInfo[@"type"] intValue] == kPushNotificationAcceptedConnection) {
        
        TVConnection *connection = [[TVConnection alloc] initWithSenderId:[[TVDatabase currentAccount] userId] receiverId:userInfo[@"userId"] andStatus:(ConnectRequestStatus *)kConnectRequestAccepted];

        NSInteger indexToReplace = NSNotFound;
        
        if ([[[[TVDatabase currentAccount] person] connections] count]) {
            
            for (NSInteger i = 0; i <= [[[[TVDatabase currentAccount] person] connections] count] - 1; i++) {
                
                TVConnection *_connection = [[[TVDatabase currentAccount] person] connections][i];
                
                if ([connection.senderId isEqualToString:_connection.senderId] && [connection.receiverId isEqualToString:_connection.receiverId]) {
                    
                    indexToReplace = i;
                }
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
        if (!messageHistory) messageHistory = [[TVMessageHistory alloc] initWithSenderId:[userInfo[@"messageHistoryID"] componentsSeparatedByString:@"->"][0] andReceiverId:[userInfo[@"messageHistoryID"] componentsSeparatedByString:@"->"][1] andMessages:[@[] mutableCopy]];

        [TVDatabase downloadMessageHistoryBetweenRecipients:[@[messageHistory.senderId, messageHistory.receiverId] mutableCopy] withCompletionHandler:^(BOOL success, NSError *error, NSString *callCode, NSMutableArray *messageHistories) {
                        
            if (success && !error) {
                
                if (((UITabBarController *)((TVAppDelegate *)[UIApplication sharedApplication].delegate).window.rootViewController).selectedIndex != 1) {

                    [PFPush handlePush:userInfo];
                }

                TVNotification *notification = [[TVNotification alloc] initWithType:(NotificationType *)kNotificationTypeUnreadMessages withUserId:[messageHistory.senderId isEqualToString:[[TVDatabase currentAccount] userId]] ? messageHistory.receiverId : messageHistory.senderId];
                
                [newAccount.person.notifications addNotification:notification];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:NSNotificationUpdateNotifications object:nil];

                    [[NSNotificationCenter defaultCenter] postNotificationName:NSNotificationNewMessageIncoming object:nil userInfo:nil];
                });
            }
            else {
                
                [TVErrorHandler handleError:[NSError errorWithDomain:callCode code:200 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Could not %@", callCode]}]];
            }
        }];
    }
    
    [TVDatabase refreshAccountWithCompletionHandler:^(BOOL completed) {
        
    }];
    
    [TVDatabase updateMyCache:newAccount];
}

+ (void)updatePushNotificationsSetup {
    
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    currentInstallation[@"userId"] = ![[TVDatabase currentAccount] userId] ? @"" : [[TVDatabase currentAccount] userId];
        
    [currentInstallation setDeviceToken:![[EGOCache globalCache] stringForKey:@"deviceToken"] ? @"" : [[EGOCache globalCache] stringForKey:@"deviceToken"]];
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

+ (NSString *)generateRandomKeyWithLength:(NSInteger)len {
    
    NSMutableString *randomString = [NSMutableString stringWithCapacity:len];
    
    for (NSInteger i = 0; i <= len; i++) {
        
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

#pragma mark Travel Data Packets

+ (void)savePlace:(TVGooglePlace *)place withCity:(NSString *)city {

    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSMutableArray *places = [TVDatabase getSavedPlacesWithCity:city];
        
        NSInteger index = NSNotFound;
        
        if (places.count) {
            
            for (NSInteger i = 0; i <= places.count - 1; i++) {
                
                TVGooglePlace *googlePlace = places[i];
                
                if ([googlePlace.ID isEqualToString:place.ID]) {
                    
                    index = i;
                }
            }
        }
        
        if (index != NSNotFound)
            [places removeObjectAtIndex:index];
        
        [places insertObject:place atIndex:0];
        
        [[EGOCache globalCache] setObject:places forKey:[NSString stringWithFormat:@"Places->%@", city]];
    });
}

+ (NSMutableArray *)getSavedPlacesWithCity:(NSString *)city {

    return [(NSMutableArray *)[[EGOCache globalCache] objectForKey:[NSString stringWithFormat:@"Places->%@", city]] count] ? (NSMutableArray *)[[EGOCache globalCache] objectForKey:[NSString stringWithFormat:@"Places->%@", city]] : [[NSMutableArray alloc] init];
}

+ (void)removeTravelDataPacketWithID:(NSString *)_FlightID {
    
    dispatch_async(dispatch_get_main_queue(), ^{

        [[EGOCache globalCache] removeCacheForKey:[NSString stringWithFormat:@"TravelDataPacket_%@", _FlightID]];
    });
}

+ (void)addTravelDataPacketWithID:(NSString *)_FlightID andTravelDataObject:(TVTravelDataDownloader *)travelData {
    
    dispatch_async(dispatch_get_main_queue(), ^{

        [[EGOCache globalCache] setObject:[travelData downloadedData] forKey:[NSString stringWithFormat:@"TravelDataPacket_%@", _FlightID]];
    });
    
//    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)refreshTravelDataPacketWithID:(NSString *)_FlightID andTravelDataObject:(TVTravelDataDownloader *)travelData {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [TVDatabase addTravelDataPacketWithID:_FlightID andTravelDataObject:travelData];
    });
}

+ (NSMutableDictionary *)travelDataPacketWithID:(NSString *)_FlightID {
    
    return (NSMutableDictionary *)[[EGOCache globalCache] objectForKey:[NSString stringWithFormat:@"TravelDataPacket_%@", _FlightID]];
}

#pragma mark Account Management

+ (TVAccount *)nativeAccount {
    
    return (TVAccount *)[[EGOCache globalCache] objectForKey:@"nativeAccount"];
}

+ (void)setNativeAccount:(TVAccount *)account {
    
    [[EGOCache globalCache] setObject:account forKey:@"nativeAccount"];
    
//    [[NSUserDefaults standardUserDefaults] synchronize];
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
        
        [TVDatabase setLocalLinkedInRequestToken:nil];
        
        [TVDatabase updateMyCache:nil];

        [[EGOCache globalCache] setObject:nil forKey:@"shownAlert"];
        [[EGOCache globalCache] setObject:nil forKey:@"deviceToken"];
        
        [TVDatabase updatePushNotificationsSetup];

        [PFUser logOut];
    });
}

+ (TVAccount *)currentAccount {
    
    return [((TVAppDelegate *)[UIApplication sharedApplication].delegate) loggedInAccount];
}

+ (void)setCurrentAccount:(TVAccount *)account {
    
    [((TVAppDelegate *) [UIApplication sharedApplication].delegate) setLoggedInAccount:account];
    [TVDatabase setNativeAccount:account];
    
//    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)refreshFlights {
    
    if ([[[[TVDatabase currentAccount] person] flights] count]) {
        
        for (NSInteger i = [[[[TVDatabase currentAccount] person] flights] count] - 1; i >= 0; i--) {
            
            TVFlight *flight = [[[TVDatabase currentAccount] person] flights][i];
            
            [flight instantiateTravelData];
        }
    }
}

#pragma mark Connect

+ (NSMutableArray *)pendingUserConnections {
    
    NSMutableArray *connections = [[NSMutableArray alloc] init];
    
    for (TVConnection *connection in [[TVDatabase currentAccount].person connections]) {

        if (connection.status == (ConnectRequestStatus *)kConnectRequestPending) {
            
            if ([connection.receiverId isEqualToString:[[TVDatabase currentAccount] userId]]) {
                
                if (![connections containsObject:connection.senderId]) {

                    [connections addObject:!connection.senderId ? @"" : connection.senderId];
                }
            }
        }
    }
    
    for (TVConnection *connection in [[TVDatabase currentAccount].person connections]) {
        
        if (connection.status == (ConnectRequestStatus *)kConnectRequestPending) {
            
            if ([connection.senderId isEqualToString:[[TVDatabase currentAccount] userId]]) {
                
                if (![connections containsObject:connection.receiverId]) {
                    
                    [connections addObject:connection.receiverId];
                }
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
                
                if (![connections containsObject:connection.senderId]) {
                    
                    [connections addObject:connection.senderId];
                }
            }
            else {
            
                if (![connections containsObject:connection.receiverId]) {
                    
                    [connections addObject:connection.receiverId];
                }
            }
        }
    }
    
    return connections;
}

+ (NSMutableArray *)allUserConnections {
    
    NSMutableArray *connections = [[NSMutableArray alloc] init];
    
    for (TVConnection *connection in [[TVDatabase currentAccount].person connections]) {
        
        if ([connection.receiverId isEqualToString:[[TVDatabase currentAccount] userId]]) {
            
            if (![connections containsObject:connection.senderId]) {
                
                [connections addObject:!connection.senderId ? @"" : connection.senderId];
            }
        }
        else {
            
            if (![connections containsObject:connection.receiverId]) {
                
                [connections addObject:connection.receiverId];
            }
        }
    }
    
    return connections;
}

+ (void)findConnectionIDsInTheSameCity:(NSString *)FlightID withCompletionHandler:(void (^)(NSMutableArray *confirmedSameCity, NSMutableArray *possibleSameCity, NSError *error, NSString *callCode))callback {
    
    NSInteger dateDoesntExist = [[NSDate distantFuture] timeIntervalSinceReferenceDate];
    
    TVFlight *myFlight = [TVDatabase flightFromID:FlightID];
    
    NSInteger self_dayFliesTo = [[myFlight date] timeIntervalSinceReferenceDate];
    NSInteger self_dayFliesFrom;
    
    NSInteger indexOfMyFlight = [[[[[TVDatabase currentAccount] person] flights] sortedByDate] indexOfFlight:[TVDatabase flightFromID:FlightID]];
    
    if (!indexOfMyFlight) {
        
        self_dayFliesFrom = dateDoesntExist;
    }
    else {
        
        TVFlight *mostRecentFlight = [[[TVDatabase currentAccount] person] flights][indexOfMyFlight - 1];
        
        self_dayFliesFrom = [[mostRecentFlight date] timeIntervalSinceReferenceDate];
    }

    PFQuery *query = [PFQuery queryWithClassName:@"Flights"];
    [query whereKey:@"flightId" containedIn:[TVDatabase confirmedUserConnections]];
    
    [query setCachePolicy:kPFCachePolicyNetworkOnly];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *theirFlights, NSError *error) {

        NSMutableArray *possibleSameCity = [[NSMutableArray alloc] init];
        NSMutableArray *confirmedSameCity = [[NSMutableArray alloc] init];
        
        if (!error) {
            
            for (PFObject *flightObject in theirFlights) {
                
                NSMutableArray *theirFlights = [NSKeyedUnarchiver unarchiveObjectWithData:flightObject[@"flights"]];

                NSInteger possibility = 0;

                if (theirFlights.count) {
                    
                    for (NSInteger i = 0; i <= [theirFlights sortedByDate].count - 1; i++) {
                        
                        TVFlight *theirFlight = [theirFlights sortedByDate][i];

                        if ([[[theirFlight destinationCity] lowercaseString] isEqualToString:[[myFlight destinationCity] lowercaseString]] || ([[[theirFlight originCity] lowercaseString] isEqualToString:[[myFlight destinationCity] lowercaseString]] && !i)) {

                            NSInteger their_dayFliesTo = [[theirFlight date] timeIntervalSinceReferenceDate];
                            NSInteger their_dayFliesFrom;

                            if (!i) {
                                
                                their_dayFliesFrom = dateDoesntExist;
                                
                            }
                            else {
                                
                                their_dayFliesFrom = [[[theirFlights sortedByDate][i - 1] date] timeIntervalSinceReferenceDate];
                            }
                            
                            if (i == [theirFlights sortedByDate].count - 1) {
                            
                                if (their_dayFliesTo >= self_dayFliesTo) possibility = 1;
                            }

                            if (
                                (
                                 (their_dayFliesTo <= self_dayFliesTo && their_dayFliesFrom >= self_dayFliesFrom)
                                 ||
                                 (their_dayFliesTo <= self_dayFliesTo && their_dayFliesFrom >= self_dayFliesTo && their_dayFliesFrom <= self_dayFliesFrom)
                                 || (their_dayFliesTo >= self_dayFliesTo && their_dayFliesTo <= self_dayFliesFrom && their_dayFliesFrom >= self_dayFliesTo && their_dayFliesFrom <= self_dayFliesFrom)
                                 || ((their_dayFliesTo >= self_dayFliesTo && their_dayFliesTo <= self_dayFliesFrom) && their_dayFliesFrom >= self_dayFliesFrom) /* SEP */
                                || ( /* SEP */
                                    (self_dayFliesTo <= their_dayFliesTo && self_dayFliesFrom >= their_dayFliesFrom)
                                || (self_dayFliesTo <= their_dayFliesTo && self_dayFliesFrom >= their_dayFliesTo && self_dayFliesFrom <= their_dayFliesFrom)
                                || (self_dayFliesTo >= their_dayFliesTo && self_dayFliesTo <= their_dayFliesFrom && self_dayFliesFrom >= their_dayFliesTo && self_dayFliesFrom <= their_dayFliesFrom)
                                || ((self_dayFliesTo >= their_dayFliesTo && self_dayFliesTo <= their_dayFliesFrom) && self_dayFliesFrom >= their_dayFliesFrom))
                                )
                            ) {
                                NSLog(@"possible");
                                possibility = 2;
                            }
                        }
                    }
                }
                else {
                    
                    possibility = 1;
                }
                
                if (possibility == 2) {
                    
                    [confirmedSameCity addObject:flightObject[@"flightId"]];
                }
                else if (possibility == 1) {
                    
                    [possibleSameCity addObject:flightObject[@"flightId"]];
                }
            }
        }
        
        callback(confirmedSameCity, possibleSameCity, error, FINDING_CONNECTIONS);
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
        
        callback([connections mutableCopy], error, FINDING_CONNECTIONS);
    }];
}

+ (void)findUsersWithEmails:(NSMutableArray *)emails withCompletionHandler:(void (^)(NSMutableArray *objects, NSError *error, NSString *callCode))callback {

    for (NSString *email in emails) {

        if ([TVDatabase cachedAccountWithEmail:email]) {
            
            TVAccount *account = [TVDatabase cachedAccountWithEmail:email];
            
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
        
        callback([objects mutableCopy], error, FINDING_CONNECTIONS);
    }];
}

+ (void)findUsersWithName:(NSString *)name withCompletionHandler:(void (^)(NSMutableArray *objects, NSError *error, NSString *callCode))callback {
    
    if ([TVDatabase cachedAccountWithName:name]) {
        
        TVAccount *account = [TVDatabase cachedAccountWithName:name];
        
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
        
        callback([objects mutableCopy], error, FINDING_CONNECTIONS);
    }];
}

+ (void)downloadMyConnectionsWithCompletionHandler:(void (^)(NSMutableArray *objects, NSError *error, NSString *callCode))callback {
    
    PFQuery *query = [PFUser query];
    [query whereKey:@"objectId" containedIn:[TVDatabase allUserConnections]];
    
    [query setCachePolicy:kPFCachePolicyNetworkElseCache];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        callback([objects mutableCopy], nil, FINDING_CONNECTIONS);
    }];
}

+ (void)findUsersWithLinkedInIds:(NSMutableArray *)linkedInIds withCompletionHandler:(void (^)(NSMutableArray *objects, NSError *error, NSString *callCode))callback {
    
    for (NSString *ID in linkedInIds) {
        
        if ([TVDatabase cachedAccountWithLinkedInId:ID]) {
            
            TVAccount *account = [TVDatabase cachedAccountWithLinkedInId:ID];
            
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
        
        callback([objects mutableCopy], error, FINDING_CONNECTIONS);
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
    
    TVAccount *newAccount = [TVDatabase currentAccount];
    
    TVConnection *cachedConnection = [[TVConnection alloc] initWithSenderId:[[TVDatabase currentAccount] userId] receiverId:userId andStatus:kConnectRequestPending];
    
    [[newAccount.person connections] addObject:cachedConnection];
    
    [TVDatabase updateMyCache:newAccount];

    [connection saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        
        if (!error && succeeded) {
            
            [TVDatabase pushNotificationToObjectId:userId withData:[@{@"badge": @"Increment", @"alert": [NSString stringWithFormat:@"%@ wants to connect with you", [[TVDatabase currentAccount].person name]], @"sound": @"default", @"type": @(kPushNotificationWantsToConnect), @"userId": cachedConnection.senderId} mutableCopy]];
            
            callback(CONNECTING_PEOPLE, YES);
        }
        else {
            
            TVAccount *newAccount = [TVDatabase currentAccount];
            
            TVConnection *connection = [[TVConnection alloc] initWithSenderId:[[TVDatabase currentAccount] userId] receiverId:userId andStatus:kConnectRequestPending];
            
            [[newAccount.person connections] removeObject:connection];
            
            [TVDatabase updateMyCache:newAccount];

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
    
    TVAccount *newAccount = [TVDatabase currentAccount];
    
    TVConnection *cachedConnection;

    if (newAccount.person.connections.count) {
        
        for (NSInteger i = 0; i <= newAccount.person.connections.count - 1; i++) {
            
            TVConnection *connection = newAccount.person.connections[i];
            
            if ([connection.senderId isEqualToString:userId] || [connection.receiverId isEqualToString:userId]) {
                
                cachedConnection = connection;
            }
        }
        
        [[newAccount.person connections] removeObject:cachedConnection];
        
        [TVDatabase updateMyCache:newAccount];
    }

    [masterQuery findObjectsInBackgroundWithBlock:^(NSArray *activities, NSError *error) {
        
        if (!error && activities) {
            
            for (PFObject *activity in activities) {
                
                [activity deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    
                    if (!error && succeeded) {
                        
                    }
                    else {
                        
                        [[newAccount.person connections] addObject:cachedConnection];
                        
                        [TVDatabase updateMyCache:newAccount];
                    }
                    
                    callback(nil, DISCONNECTING_PEOPLE, succeeded);
                }];
            }
        }
        else {
            
            [[newAccount.person connections] addObject:cachedConnection];
            
            [TVDatabase updateMyCache:newAccount];
            
            callback(error, DISCONNECTING_PEOPLE, NO);
        }
    }];
}

+ (void)acceptConnection:(TVConnection *)connection withCompletionHandler:(void (^)(NSError *, NSString *, BOOL))callback {
    
    TVAccount *account = [TVDatabase currentAccount];
    
    NSInteger index = NSNotFound;
    
    if (account.person.connections.count) {
        
        for (NSInteger i = 0; i <= account.person.connections.count - 1; i++) {
            
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
    
    TVNotification *notification = [[TVNotification alloc] initWithType:kNotificationTypeConnectionRequest withUserId:[[[TVDatabase currentAccount] userId] isEqualToString:connection.senderId] ? connection.receiverId : connection.senderId];
    [account.person.notifications removeNotification:notification];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [[NSNotificationCenter defaultCenter] postNotificationName:NSNotificationUpdateNotifications object:nil];
    });
    
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
                        
                        [TVDatabase pushNotificationToObjectId:connection.senderId withData:[@{@"alert": [NSString stringWithFormat:@"%@ accepted your connection request", [[TVDatabase currentAccount].person name]], @"type": @(kPushNotificationAcceptedConnection), @"userId": connection.receiverId, @"sound": @"default", @"badge": @"Increment"} mutableCopy]];
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
    
    NSInteger index = NSNotFound;
    
    if (account.person.connections.count) {
        
        for (NSInteger i = 0; i <= account.person.connections.count - 1; i++) {
            
            TVConnection *enumConnection = account.person.connections[i];
            
            if ([[enumConnection senderId] isEqualToString:[connection senderId]] && [[enumConnection receiverId] isEqualToString:[connection receiverId]]) {
                
                index = i;
            }
        }
    }
    
    if (index != NSNotFound) {
        
        [[[account person] connections] removeObjectAtIndex:index];
    }
    
    TVNotification *notification = [[TVNotification alloc] initWithType:kNotificationTypeConnectionRequest withUserId:[[[TVDatabase currentAccount] userId] isEqualToString:connection.senderId] ? connection.receiverId : connection.senderId];
    [account.person.notifications removeNotification:notification];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [[NSNotificationCenter defaultCenter] postNotificationName:NSNotificationUpdateNotifications object:nil];
    });
    
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
    
    [TVDatabase writeProfilePictureToDisk:profilePicture withUserId:objectId];
    
    PFQuery *query = [PFQuery queryWithClassName:@"ProfilePictures"];
    [query whereKey:@"photoId" equalTo:objectId];
    
    __block BOOL success = NO;
    __block NSError *callbackError = nil;
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        success = !objects ? NO : YES;
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
    
    [[EGOCache globalCache] setImage:image forKey:[NSString stringWithFormat:@"ProfilePicture_%@.jpg", userId] withTimeoutInterval:259200];

    dispatch_async(dispatch_get_main_queue(), ^{
    
        [[NSNotificationCenter defaultCenter] postNotificationName:NSNotificationWroteProfilePicture object:nil userInfo:nil];
        
        if ([[[TVDatabase currentAccount] userId] isEqualToString:userId]) {
            
            [[NSNotificationCenter defaultCenter] postNotificationName:NSNotificationWroteMyProfilePicture object:nil];
        }
    });
}

+ (UIImage *)locateProfilePictureOnDiskWithUserId:(NSString *)userId {
     
    UIImage *profilePicture = [[EGOCache globalCache] imageForKey:[NSString stringWithFormat:@"ProfilePicture_%@.jpg", userId]];

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
        
        if (!error && objects) {

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

+ (void)updateFlights:(NSArray *)flights withObjectId:(NSString *)objectId withCompletionHandler:(void (^)(NSError *error, BOOL succeeded))callback {
    
    PFQuery *query = [PFQuery queryWithClassName:@"Flights"];
    [query whereKey:@"flightId" equalTo:objectId];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        if (!error) {
            
            objects[0][@"flights"] = [NSKeyedArchiver archivedDataWithRootObject:flights];
            
            [objects[0] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                
                callback(error, succeeded);
            }];
        }
        else {
            
            callback(error, NO);
        }
    }];
}

#pragma mark Account Download

+ (void)getAccountFromUser:(PFUser *)object isPerformingCacheRefresh:(BOOL)isPerformingCacheRefresh withCompletionHandler:(void (^)(TVAccount *account, NSMutableArray *downloadedTypes))callback {

    NSMutableArray *downloadedTypes = [[NSMutableArray alloc] init];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        if (!isPerformingCacheRefresh) {
            
            if ([TVDatabase cachedAccountWithId:[object objectId]]) {
                
                callback([TVDatabase cachedAccountWithId:[object objectId]],[@[@(kAccountDownloadedGeneralAttributes), @(kAccountDownloadedConnections), @(kAccountDownloadedFlights), @(kAccountDownloadedMessages), @(kAccountDownloadedProfilePicture)] mutableCopy]);
            }
        }
        
        TVAccount *account = [TVDatabase getGeneralFromUser:object];
        
        [TVDatabase cacheAccount:account];
        
        [downloadedTypes addObject:@(kAccountDownloadedGeneralAttributes)];
        
        callback(account, downloadedTypes);
        
        [TVDatabase downloadFlightsWithObjectIds:@[[object objectId]] withCompletionHandler:^(NSError *error, NSMutableArray *flights) {
            
            if (!error && flights) {
                
                [[account person] setFlights:[NSKeyedUnarchiver unarchiveObjectWithData:flights[0][@"flights"]]];
                
                [downloadedTypes addObject:@(kAccountDownloadedFlights)];
                
                [TVDatabase cacheAccount:account];
                
                callback(account, downloadedTypes);
            }
        }];
        
        [TVDatabase findConnectionsFromId:[object objectId] withCompletionHandler:^(NSMutableArray *objects, NSError *error, NSString *callCode) {
            
            if (!error) {
                
                [account.person.notifications clearNotificationOfType:kNotificationTypeConnectionRequest];
                
                for (TVConnection *connection in objects) {
                    
                    if (connection.status == kConnectRequestPending && [connection.receiverId isEqualToString:[[TVDatabase currentAccount] userId]]) {
                        
                        TVNotification *connectNotification = [[TVNotification alloc] initWithType:kNotificationTypeConnectionRequest withUserId:connection.senderId];
                        
                        [account.person.notifications addNotification:connectNotification];
                    }
                }
                
                [downloadedTypes addObject:@(kAccountDownloadedConnections)];
                
                [account.person setConnections:objects];
                
                [TVDatabase cacheAccount:account];
                
                callback(account, downloadedTypes);
            }
        }];
        
        [TVDatabase downloadMessageHistoriesWithUserId:[object objectId] withCompletionHandler:^(BOOL success, NSError *error, NSString *callCode, NSMutableArray *messageHistories) {
            
            if (success && !error) {
                
                [downloadedTypes addObject:@(kAccountDownloadedMessages)];
                
                [account.person setMessageHistories:messageHistories];
                
                [account.person.notifications clearNotificationOfType:kNotificationTypeUnreadMessages];
                
                NSMutableArray *IDs = [[NSMutableArray alloc] init];
                
                for (TVMessageHistory *messageHistory in messageHistories) {
                    
                    [IDs addObject:[[TVDatabase currentAccount] userId] ? messageHistory.receiverId : messageHistory.senderId];
                    
                    if (![[messageHistory.sortedMessages lastObject] receiverRead] && ![[[TVDatabase currentAccount] userId] isEqualToString:[((TVMessage *)[messageHistory.sortedMessages lastObject]) senderId]]) {
                        
                        TVNotification *notification = [[TVNotification alloc] initWithType:(NotificationType *)kNotificationTypeUnreadMessages withUserId:[[[TVDatabase currentAccount] userId] isEqualToString:messageHistory.receiverId] ? messageHistory.senderId : messageHistory.receiverId];
                        
                        [account.person.notifications addNotification:notification];
                    }
                }
                
                [TVDatabase downloadUsersFromUserIds:IDs withCompletionHandler:^(NSMutableArray *users, NSError *error, NSString *callCode) {
                }];
            }
            else {
                
            }
                        
            [TVDatabase cacheAccount:account];
            
            callback(account, downloadedTypes);
        }];
        
        [TVDatabase downloadProfilePicturesWithObjectIds:@[[object objectId]] withCompletionHandler:^(NSError *error, UIImage *profilePic) {
            
            if (!error && profilePic) {
            }
            else {
                
                profilePic = [UIImage imageNamed:@"anonymous_person.png"];
            }
            
            [downloadedTypes addObject:@(kAccountDownloadedProfilePicture)];
            
            [TVDatabase cacheAccount:account];
            
            callback(account, downloadedTypes);
        }];
    });
}

+ (TVAccount *)getGeneralFromUser:(PFUser *)object {
    
    TVAccount *account = [[TVAccount alloc] init];
    
    if ([object.objectId isEqualToString:[[TVDatabase currentAccount] userId]]) {
        
        account = ![TVDatabase currentAccount] ? [[TVAccount alloc] init] : [TVDatabase currentAccount];
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
    
    return account;
}

+ (void)downloadUsersFromUserIds:(NSArray *)userIds withCompletionHandler:(void (^)(NSMutableArray *users, NSError *error, NSString *callCode))callback {

    for (NSString *ID in userIds) {

        if ([TVDatabase cachedAccountWithId:ID]) {
            
            TVAccount *account = [TVDatabase cachedAccountWithId:ID];

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
        
        if (!error && objects) {
            
            callback([objects mutableCopy], error, DOWNLOADING_ACCOUNTS_FROM_IDS);
        }
        else {
            
        }
    }];
}

+ (NSMutableArray *)cachedAccounts {
    
    return [((TVAppDelegate *)[UIApplication sharedApplication].delegate) cachedAccounts];
}

+ (void)cacheAccount:(TVAccount *)account {

    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSMutableArray *cachedAccounts = [[TVDatabase cachedAccounts] mutableCopy];
        
        if ([TVDatabase cachedAccounts]) {
            
            if ([TVDatabase indexOfCachedAccountWithUserId:account.userId] != NSNotFound) {
                
                cachedAccounts[[TVDatabase indexOfCachedAccountWithUserId:account.userId]] = account;
            }
            else {
                
                [cachedAccounts addObject:account];
            }
        }
        
        [((TVAppDelegate *)[UIApplication sharedApplication].delegate) setCachedAccounts:cachedAccounts];
    });
}

+ (NSInteger)indexOfCachedAccountWithUserId:(NSString *)userId {

    NSInteger index = NSNotFound;

    if ([TVDatabase cachedAccounts]) {
        
        NSMutableArray *cachedAccounts = [TVDatabase cachedAccounts];

        if ([TVDatabase cachedAccounts].count) {
            
            for (NSInteger i = 0; i <= cachedAccounts.count - 1; i++) {
                
                TVAccount *_account = [TVDatabase cachedAccounts][i];
                
                if ([_account.userId isEqualToString:userId]) {
                    
                    index = i;
                }
            }
        }
    }
    
    return index;
}

+ (NSInteger)indexOfCachedAccountWithName:(NSString *)name {
    
    NSInteger index = NSNotFound;
    
    if ([TVDatabase cachedAccounts]) {
        
        NSMutableArray *cachedAccounts = [TVDatabase cachedAccounts];

        if ([TVDatabase cachedAccounts].count) {
            
            for (NSInteger i = 0; i <= cachedAccounts.count - 1; i++) {
                
                TVAccount *_account = [TVDatabase cachedAccounts][i];
                
                if ([_account.person.name rangeOfString:name options:NSCaseInsensitiveSearch].location != NSNotFound || [_account.person.name soundsLikeString:name]) {
                    
                    index = i;
                }
            }
        }
    }
    
    return index;
}

+ (NSInteger)indexOfCachedAccountWithEmail:(NSString *)email {

    NSInteger index = NSNotFound;
    
    NSMutableArray *cachedAccounts = [TVDatabase cachedAccounts];
    
    if (cachedAccounts) {
        
        if (cachedAccounts.count) {
            
            for (NSInteger i = 0; i <= cachedAccounts.count - 1; i++) {
                
                TVAccount *_account = [TVDatabase cachedAccounts][i];
                
                if ([[_account.person.email lowercaseString] isEqualToString:[email lowercaseString]]) {
                    
                    index = i;
                }
            }
        }
    }
    
    return index;
}

+ (NSInteger)indexOfCachedAccountWithLinkedIn:(NSString *)linkedInId {
    
    NSInteger index = NSNotFound;
    
    if ([TVDatabase cachedAccounts]) {
        
        NSMutableArray *cachedAccounts = [TVDatabase cachedAccounts];

        if ([TVDatabase cachedAccounts].count) {
            
            for (NSInteger i = 0; i <= cachedAccounts.count - 1; i++) {
                
                TVAccount *_account = [TVDatabase cachedAccounts][i];
                
                if ([_account isUsingLinkedIn] && [_account.linkedInId isEqualToString:linkedInId]) {
                    
                    index = i;
                }
            }
        }
    }
    
    return index;
}

+ (TVAccount *)cachedAccountWithId:(NSString *)userId {
    
    TVAccount *retVal = nil;

    if ([TVDatabase indexOfCachedAccountWithUserId:userId] != NSNotFound && [TVDatabase cachedAccounts]) {
        
        retVal = [TVDatabase cachedAccounts][[TVDatabase indexOfCachedAccountWithUserId:userId]];
    }
    
    return retVal;
}

+ (TVAccount *)cachedAccountWithName:(NSString *)name {
    
    TVAccount *retVal = nil;
    
    if ([TVDatabase indexOfCachedAccountWithName:name] != NSNotFound && [TVDatabase cachedAccounts]) {
        
        retVal = [TVDatabase cachedAccounts][[TVDatabase indexOfCachedAccountWithName:name]];
    }
    
    return retVal;
}

+ (TVAccount *)cachedAccountWithEmail:(NSString *)email {
    
    TVAccount *retVal = nil;
    
    if ([TVDatabase indexOfCachedAccountWithEmail:email] != NSNotFound && [TVDatabase cachedAccounts]) {
        
        retVal = [TVDatabase cachedAccounts][[TVDatabase indexOfCachedAccountWithEmail:email]];
    }
    
    return retVal;
}

+ (TVAccount *)cachedAccountWithLinkedInId:(NSString *)linkedInId {
    
    TVAccount *retVal = nil;
    
    if ([TVDatabase indexOfCachedAccountWithLinkedIn:linkedInId] != NSNotFound && [TVDatabase cachedAccounts]) {
        
        retVal = [TVDatabase cachedAccounts][[TVDatabase indexOfCachedAccountWithLinkedIn:linkedInId]];
    }
    
    return retVal;
}

+ (void)refreshCachedAccounts {
    
    NSMutableArray *reference = [TVDatabase cachedAccounts];

    if (reference) {

        if (reference.count) {
            
            for (NSInteger i = 0; i <= reference.count - 1; i++) {
                
                TVAccount *account = reference[i];
                
                [TVDatabase downloadUsersFromUserIds:@[account.userId] withCompletionHandler:^(NSMutableArray *users, NSError *error, NSString *callCode) {
                    
                    if (users.count && !error) {
                        
                        if (users[0]) {
                            
                            [TVDatabase getAccountFromUser:users[0] isPerformingCacheRefresh:YES withCompletionHandler:^(TVAccount *account, NSMutableArray *downloadedTypes) {
                            }];
                        }
                    }
                    else {
                        
                    }
                }];
            }
        }
    }
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

+ (void)sendEmail:(NSMutableDictionary *)dictionary withAttachementData:(NSDictionary *)data withCompletionHandler:(void (^)(BOOL success, NSError *error, NSString *callCode))callback {

    if (data) {
        
        NSString *rawMessageString = [NSString stringWithFormat:@"MIME-Version: 1.0\nContent-Transfer-Encoding: 7bit\nContent-Type: multipart/mixed; boundary=\"__MY_BOUNDARY__\"\nSubject: %@\nTo: %@\n\nThis is a multi-part message in MIME format.\n\n--__MY_BOUNDARY__\nMIME-Version: 1.0\nContent-Transfer-Encoding: 7bit\nContent-Type: text/plain; charset=\"UTF-8\"\n\%@\n\n--__MY_BOUNDARY__\nMIME-Version: 1.0\nContent-Disposition: attachment; filename=\"%@\"\nContent-Transfer-Encoding: base64\nContent-Type: %@; name=\"%@\"\n\n%@--__MY_BOUNDARY__", dictionary[@"subject"], dictionary[@"toAddress"], dictionary[@"data"], data[@"filename"], data[@"fileType"], data[@"filename"], [data[@"data"] base64EncodedString]];

        SESRawMessage *rawMessage = [[SESRawMessage alloc] init];
        rawMessage.data = [rawMessageString dataUsingEncoding:NSUTF8StringEncoding];
        
        SESSendRawEmailRequest *ser = [[SESSendRawEmailRequest alloc] init];
        
        ser.source = VERIFIED_EMAIL_TEST;
        [ser addDestination:dictionary[@"toAddress"]];
        
        ser.rawMessage = rawMessage;
        
        ser.requestTag = SENDING_REQUEST_EMAIL;
        
        SESSendRawEmailResponse *response = [[AmazonClientManager ses] sendRawEmail:ser];
        
        BOOL success = NO;
        
        if (!response.error) {
            
            success = YES;
        }

        callback(success, response.error, ser.requestTag);
    }
    else {
        
        NSDictionary *paramDict = [TVDatabase emailParameters:dictionary];
        
        SESSendEmailRequest *ser = [[SESSendEmailRequest alloc] init];
        
        ser.source = VERIFIED_EMAIL;
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
}

#pragma mark Logging in

+ (void)loginToAccountWithEmail:(NSString *)email andPassword:(NSString *)password withCompletionHandler:(void (^)(BOOL success, BOOL correctCredentials, NSError *error, NSString *callCode))callback {
    
    [PFUser logInWithUsernameInBackground:email password:password block:^(PFUser *user, NSError *error) {
        NSLog(@"%@ %@", error, user);
        __block BOOL success = NO;
        __block BOOL correctCredentials = NO;
        
        if (user && !error) {
            
            [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
             UIRemoteNotificationTypeBadge |
             UIRemoteNotificationTypeAlert |
             UIRemoteNotificationTypeSound];
            
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

    [TVDatabase setCurrentAccount:accountObj];
}

+ (void)updateMyAccount:(TVAccount *)accountObj immediatelyCache:(BOOL)immediatelyCache withCompletionHandler:(void (^)(BOOL succeeded, NSError *error, NSString *callCode))callback {

    NSString *reqTag = UPDATING_MY_ACCOUNT;
    
    if (immediatelyCache) {
        
        [TVDatabase updateMyCache:accountObj];
    }
    
    for (NSDictionary *attribute in [TVDatabase attributesWithAccount:accountObj]) {
        
        [PFUser currentUser][attribute[@"key"]] = attribute[@"value"];
    }
    
    [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        
        if (!error && succeeded) {
            
            [TVDatabase updateFlights:[[accountObj person] flights] withObjectId:[[TVDatabase currentAccount] userId] withCompletionHandler:^(NSError *error, BOOL succeeded) {
                
                [TVDatabase updateMyCache:accountObj];
                
                callback(succeeded, error, reqTag);
            }];
        }
        
        callback(succeeded, error, reqTag);
    }];
}

+ (void)uploadAccount:(TVAccount *)travelogAccount withProfilePicture:(UIImage *)profilePicture andCompletionHandler:(void (^)(BOOL, NSError *, NSString *))callback {
    
    PFUser *user = [PFUser user];
    
    user.username = travelogAccount.email;
    user.email = travelogAccount.email;
    user.password = travelogAccount.accessibilityValue;

    for (NSDictionary *attribute in [TVDatabase attributesWithAccount:travelogAccount]) {
        
        user[attribute[@"key"]] = attribute[@"value"];
    }
    
    [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        
        if (!error && succeeded) {
                        
            travelogAccount.userId = user.objectId;
            [TVDatabase updateMyCache:travelogAccount];

            PFACL *ACL = [PFACL ACLWithUser:[PFUser currentUser]];
            [ACL setPublicReadAccess:YES];
            [ACL setPublicWriteAccess:NO];
            [PFUser currentUser].ACL = ACL;
            [[PFUser currentUser] saveInBackground];

            [TVDatabase uploadFlights:[[travelogAccount person] flights] withObjectId:[[TVDatabase currentAccount] userId]];
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

+ (void)refreshAccountWithCompletionHandler:(void (^)(BOOL completed))callback {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        [TVDatabase refreshCachedAccounts];
        [TVDatabase refreshFlights];
        
        [[PFUser currentUser] refreshInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            
            if (!error) {
                
                [TVDatabase getAccountFromUser:(PFUser *)object isPerformingCacheRefresh:YES withCompletionHandler:^(TVAccount *account, NSMutableArray *downloadedTypes) {
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        [TVDatabase updateMyCache:account];
                        
                        [TVDatabase updatePushNotificationsSetup];
                        
                        if ([[downloadedTypes lastObject] isEqual:@(kAccountDownloadedFlights)]) {
                            
                            dispatch_async(dispatch_get_main_queue(), ^{
                                
                                [[NSNotificationCenter defaultCenter] postNotificationName:NSNotificationDownloadedFlights object:nil];
                            });
                        }
                        else if ([[downloadedTypes lastObject] isEqual:@(kAccountDownloadedMessages)]) {
                            
                            dispatch_async(dispatch_get_main_queue(), ^{
                                
                                [[NSNotificationCenter defaultCenter] postNotificationName:NSNotificationDownloadedMessages object:nil];
                            });
                        }
                        else if ([[downloadedTypes lastObject] isEqual:@(kAccountDownloadedProfilePicture)]) {
                            
                        }
                        else if ([[downloadedTypes lastObject] isEqual:@(kAccountDownloadedConnections)]) {
                            
                            dispatch_async(dispatch_get_main_queue(), ^{
                                
                                [[NSNotificationCenter defaultCenter] postNotificationName:NSNotificationDownloadedConnections  object:nil];
                            });
                        }
                        
                        if ([downloadedTypes count] == 5) {
                            
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

@end