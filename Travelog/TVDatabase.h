//
//  Database.h
//  Trvlogue
//
//  Created by Rohan Kapur on 6/2/13.
//  Copyright (c) 2013 UWCSEA. All rights reserved.
//

extern NSString *const WRONG_LOGIN;
extern NSString *const EMAIL_TAKEN;

#define DAY_MONTH_YEAR @"dd - MM - yyyy"
#define MONTH_DAY_YEAR @"MM - dd - yyyy"
#define DAY_MONTH @"dd/MM"
#define MONTH_DAY @"dd/MM"

#define TRVLOGUE_NAVIGATION_BAR @"TrvlogueNavigationBar.png"

#define APPLE_DEV @"noreplyappledev14@gmail.com"
#define VERIFIED_EMAIL_TEST @"me@rohankapur.com"
#define VERIFIED_EMAIL @"support@travelogapp.com"

#define LOGGING_IN @"log in"
#define CREATING_ACCOUNT @"create your account"
#define CHECK_IF_EMAIL_HAS_BEEUSED @"register your email"
#define CHECK_IF_EMAIL_HAS_BEEUSED @"register your email"
#define DOWNLOADING_ACCOUNTS_FROM_EMAILS @"download the accounts"
#define DOWNLOADING_ACCOUNTS_FROM_EMAILS @"download the accounts"
#define DOWNLOADING_ACCOUNTS_FROM_IDS @"download the accounts"
#define UPDATING_MY_ACCOUNT @"update your account"
#define UPLOADING_PHOTO @"upload your photo"
#define SENDING_REQUEST_EMAIL @"send you an email"
#define CONNECTING_PEOPLE @"connect with this person"
#define DISCONNECTING_PEOPLE @"disconnect with this person"
#define FINDING_CONNECTIONS @"find connections"
#define GET_LINKEDIN @"retrieve LinkedIn info"
#define GET_LINKEDIN @"retrieve LinkedIn info"
#define REQUEST_FORGOT_PASSWORD @"request a new password"
#define SEND_MESSAGE @"send the message"
#define DOWNLOAD_MESSAGE @"download messages"

#define NSNotificationRecordedNewFlight @"RecordedNewFlight"
#define NSNotificationDownloadedFlights @"DownloadedFlights"
#define NSNotificationTravelDataPacketUpdated @"TravelDataPacketUpdated"
#define NSNotificationWroteProfilePicture @"WroteProfilePicture"
#define NSNotificationWroteMyProfilePicture @"WroteMyProfilePicture"
#define NSNotificationDownloadedMessages @"DownloadedMessages"
#define NSNotificationSentMessage @"SentMessage"
#define NSNotificationNewMessageIncoming @"NewMessageIncoming"
#define NSNotificationDownloadedConnections @"DownloadedConnections"
#define NSNotificationReceivedConnectionRequest @"ReceivedConnectionRequest"
#define NSNotificationReloadPeople @"ReloadPeople"
#define NSNotificationUpdateNotifications @"UpdateNotifications"
#define NSNotificationAutomateConnectWithLinkedIn @"ConnectWithLinkedInAutomated"

typedef enum {
    
    kAccountDownloadedGeneralAttributes = 0,
    kAccountDownloadedFlights,
    kAccountDownloadedProfilePicture,
    kAccountDownloadedConnections,
    kAccountDownloadedMessages
    
} AccountDownloadTypes;

typedef enum {
    
    kEmailCouldNotSend = 0,
    kEmailSent = 1
    
} EmailSendRequestResult;

typedef enum {
    
    kPushNotificationWantsToConnect = 0,
    kPushNotificationAcceptedConnection,
    kPushNotificationReceivedMessage

} PushNotificationType;

#import <Foundation/Foundation.h>

#import "TVAccount.h"

#import <Parse/Parse.h>

#import <AWSSES/AWSSES.h>

#import "TVMessageHistory.h"

#import "TVNotification.h"

#import "TVConnection.h"

#import "TVFindPeopleViewController.h"

#import "TVMessageDetailViewController.h"

#import "TVPerson.h"

#import "TestFlight.h"
#import "TestFlight+AsyncLogging.h"

#import "NSString+Soundex.h"

#import "AmazonClientManager.h"

#import "TVGooglePlace.h"

#include <execinfo.h>

@interface NSMutableArray (ContainsPerson)

- (BOOL)containsUser:(PFUser *)user;
- (NSInteger)indexOfUser:(PFUser *)user;

- (BOOL)containsAccount:(TVAccount *)account;
- (NSInteger)indexOfAccount:(TVAccount *)account;

- (BOOL)containsPerson:(TVPerson *)_person;

@end

@implementation NSMutableArray (ContainsPerson)

- (BOOL)containsPerson:(TVPerson *)_person {
    
    BOOL contains = NO;
    
    for (TVPerson *person in self) {
        
        if ([person.email isEqualToString:_person.email]) {
            
            contains = YES;
        }
    }
    
    return contains;
}

- (BOOL)containsAccount:(TVAccount *)account {
    
    BOOL retVal = NO;
    
    if ([self indexOfAccount:account] != NSNotFound) {
        
        retVal = YES;
    }
    
    return retVal;
}

- (NSInteger)indexOfAccount:(TVAccount *)account {

    NSInteger retVal = NSNotFound;
    
    if (self.count) {
        
        for (NSInteger i = 0; i <= self.count - 1; i++) {

            if ([((TVAccount *)self[i]).userId isEqualToString:account.userId]) {
                
                retVal = i;
            }
        }
    }
    
    return retVal;
}

- (BOOL)containsUser:(PFUser *)userToSearch {
    
    BOOL retVal = NO;
    
    if ([self indexOfUser:userToSearch] != NSNotFound) {
        
        retVal = YES;
    }
    
    return retVal;
}

- (NSInteger)indexOfUser:(PFUser *)user {
    
    NSInteger retVal = NSNotFound;
    
    if (self.count) {
        
        for (NSInteger i = 0; i <= self.count - 1; i++) {
            
            if ([((PFUser *)self[i]).objectId isEqualToString:user.objectId]) {
                
                retVal = i;
            }
        }
    }
    
    return retVal;
}

@end
 
@class TVCreateAccountViewController;

@interface TVDatabase : NSObject

+ (NSMutableArray *)attributesWithAccount:(TVAccount *)accountObj;

+ (void)setCurrentAccount:(TVAccount *)account;

+ (TVMessageHistory *)messageHistoryFromID:(NSString *)ID;
+ (NSString *)messageHistoryIDFromRecipients:(NSMutableArray *)recipients;
+ (void)deleteMessageHistoryFromID:(NSString *)ID;

+ (void)createMessageHistory:(TVMessageHistory *)messageHistory withCompletionHandler:(void (^)(BOOL success, NSError *error, NSString *callCode))callback;
+ (void)sendMessage:(TVMessage *)message toHistoryWithID:(NSString *)messageHistoryID withCompletionHandler:(void (^)(BOOL success, NSError *error, NSString *callCode))callback;
+ (void)confirmReceiverHasReadMessagesinMessageHistory:(TVMessageHistory *)messageHistory withCompletionHandler:(void (^)(BOOL success, NSError *error, NSString *callCode))callback;
+ (void)downloadMessageHistoriesWithUserId:(NSString *)userId withCompletionHandler:(void (^)(BOOL success, NSError *error, NSString *callCode, NSMutableArray *messageHistories))callback;
+ (void)downloadMessageHistoryBetweenRecipients:(NSMutableArray *)userIds withCompletionHandler:(void (^)(BOOL success, NSError *error, NSString *callCode, NSMutableArray *messageHistories))callback;

+ (void)downloadProfilePicturesWithObjectIds:(NSArray *)objectIds withCompletionHandler:(void (^)(NSError *error, UIImage *profilePic))callback;
+ (void)uploadProfilePicture:(UIImage *)profilePicture withObjectId:(NSString *)objectId; // Doesn't really need a callback/completion handler but I guess I should add it...
+ (void)updateProfilePicture:(UIImage *)profilePicture withObjectId:(NSString *)objectId withCompletionHandler:(void (^)(BOOL succeeded, NSError *error, NSString *callCode))callback; // Doesn't really need a callback/completion handler but I guess I should add it...
+ (void)writeProfilePictureToDisk:(UIImage *)image withUserId:(NSString *)userId;
+ (UIImage *)locateProfilePictureOnDiskWithUserId:(NSString *)userId;

+ (void)downloadFlightsWithObjectIds:(NSArray *)objectIds withCompletionHandler:(void (^)(NSError *error, NSMutableArray *flights))callback;
+ (void)uploadFlights:(NSArray *)flights withObjectId:(NSString *)objectId; // Doesn't really need a callback/completion handler but I guess I should add it...
+ (void)updateFlights:(NSArray *)flights withObjectId:(NSString *)objectId withCompletionHandler:(void (^)(NSError *error, BOOL succeeded))callback; // Doesn't really need a callback/completion handler but I guess I should add it...

+ (void)findUsersWithEmails:(NSMutableArray *)emails withCompletionHandler:(void (^)(NSMutableArray *objects, NSError *error, NSString *callCode))callback;
+ (void)findUsersWithName:(NSString *)name withCompletionHandler:(void (^)(NSMutableArray *objects, NSError *error, NSString *callCode))callback;
+ (void)findUsersWithLinkedInIds:(NSMutableArray *)linkedInIds withCompletionHandler:(void (^)(NSMutableArray *objects, NSError *error, NSString *callCode))callback;
+ (void)downloadMyConnectionsWithCompletionHandler:(void (^)(NSMutableArray *objects, NSError *error, NSString *callCode))callback;
+ (void)connectWithUserId:(NSString *)userId withCompletionHandler:(void (^)(NSString *callCode, BOOL success))callback;
+ (void)disconnectWithUserId:(NSString *)userId withCompletionHandler:(void (^)(NSError *error, NSString *callCode, BOOL success))callback;
+ (void)findConnectionsFromId:(NSString *)userId withCompletionHandler:(void (^)(NSMutableArray *objects, NSError *error, NSString *callCode))callback;
+ (void)findConnectionIDsInTheSameCity:(NSString *)FlightID withCompletionHandler:(void (^)(NSMutableArray *confirmedSameCity, NSMutableArray *possibleSameCity, NSError *error, NSString *callCode))callback;
+ (void)acceptConnection:(TVConnection *)connection withCompletionHandler:(void (^)(NSError *error, NSString *callCode, BOOL success))callback;
+ (void)declineConnection:(TVConnection *)connection withCompletionHandler:(void (^)(NSError *error, NSString *callCode, BOOL success))callback;
+ (NSMutableArray *)pendingUserConnections;
+ (NSMutableArray *)confirmedUserConnections;
+ (NSMutableArray *)allUserConnections;

+ (NSMutableArray *)cachedAccounts;
+ (void)cacheAccount:(TVAccount *)account;
+ (TVAccount *)cachedAccountWithId:(NSString *)userId;
+ (void)refreshCachedAccounts;

+ (void)savePlace:(TVGooglePlace *)place withCity:(NSString *)city;
+ (NSMutableArray *)getSavedPlacesWithCity:(NSString *)city;

+ (void)removeTravelDataPacketWithID:(NSString *)_FlightID;
+ (void)addTravelDataPacketWithID:(NSString *)_FlightID andTravelDataObject:(TVTravelDataDownloader *)travelData;
+ (void)refreshTravelDataPacketWithID:(NSString *)_FlightID andTravelDataObject:(TVTravelDataDownloader *)travelData;
+ (NSMutableDictionary *)travelDataPacketWithID:(NSString *)_FlightID;

+ (TVFlight *)flightFromID:(NSString *)_FlightID;

+ (NSString *)generateRandomKeyWithLength:(NSInteger)len;

+ (void)logout;

+ (void)sendEmail:(NSMutableDictionary *)dictionary withAttachementData:(NSDictionary *)data withCompletionHandler:(void (^)(BOOL success, NSError *error, NSString *callCode))callback;

+ (void)trackAnalytics:(NSDictionary *)launchOptions;

+ (void)receivedLocalNotification:(NSDictionary *)userInfo;
+ (void)updatePushNotificationsSetup;
+ (void)pushNotificationToObjectId:(NSString *)objectId withData:(NSMutableDictionary *)data;
+ (void)removePushNotificationsSetup;

+ (TVAccount *)nativeAccount;
+ (TVAccount *)currentAccount;

+ (void)downloadUsersFromUserIds:(NSArray *)userIds withCompletionHandler:(void (^)(NSMutableArray *users, NSError *error, NSString *callCode))callback;
+ (void)getAccountFromUser:(PFUser *)object isPerformingCacheRefresh:(BOOL)isPerformingCacheRefresh withCompletionHandler:(void (^)(TVAccount *account,NSMutableArray *downloadedTypes))callback;
+ (TVAccount *)getGeneralFromUser:(PFUser *)object;
+ (void)refreshAccountWithCompletionHandler:(void (^)(BOOL completed))callback;
+ (void)refreshFlights;

+ (void)uploadAccount:(TVAccount *)trvlogueAccount withProfilePicture:(UIImage *)profilePicture andCompletionHandler:(void (^)(BOOL success, NSError *error, NSString *callCode))callback;
+ (void)updateMyAccount:(TVAccount *)accountObj immediatelyCache:(BOOL)immediatelyCache withCompletionHandler:(void (^)(BOOL succeeded, NSError *error, NSString *callCode))callback;
+ (void)updateMyCache:(TVAccount *)accountObj;

+ (void)loginToAccountWithEmail:(NSString *)email andPassword:(NSString *)password withCompletionHandler:(void (^)(BOOL success, BOOL correctCredentials, NSError *error, NSString *callCode))callback;
+ (void)requestForNewPassword:(NSString *)email withCompletionHandler:(void (^)(BOOL succeeded, NSError *error, NSString *callCode))callback;

+ (void)setLocalLinkedInRequestToken:(NSString *)linkedInRequestToken;
+ (NSString *)localLinkedInRequestToken;

+ (NSData *)archiveAccount:(TVAccount *)accountObj;
+ (TVAccount *)unarchiveAccount:(NSData *)data;

@end