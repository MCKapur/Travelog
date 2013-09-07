//
//  Database.h
//  Trvlogue
//
//  Created by Rohan Kapur on 6/2/13.
//  Copyright (c) 2013 UWCSEA. All rights reserved.
//

extern NSString *const WRONG_LOGIN;
extern NSString *const EMAIL_TAKEN;

#define WORLD_WEATHER_API_KEY @"8f1faddf20134841120710"

#define DAY_MONTH_YEAR @"dd - MM - yyyy"
#define DAY_MONTH @"dd/MM"
#define YEAR_MONTH_DAY @"yyyy-MM-dd"

#define GOOGLE_API_KEY @"AIzaSyCMCS9TGb5Xr06cW611vnaZea_Rzcxxnqc"

#define TRVLOGUE_NAVIGATION_BAR @"TrvlogueNavigationBar.png"

#define VERIFIED_EMAIL_TEST @"me@rohankapur.com"
#define VERIFIED_EMAIL @"support@trvlogue.com"

// Operation tags - used for error handling too! :) :) :) :)

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
#define FINDING_PEOPLE @"find people"
#define GET_LINKEDIN @"retrieve LinkedIn info"
#define GET_LINKEDIN @"retrieve LinkedIn info"
#define REQUEST_FORGOT_PASSWORD @"request a new password"
#define SEND_MESSAGE @"send the message"
#define DOWNLOAD_MESSAGE @"download messages"

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

@interface NSMutableArray (ContainsPerson)

- (BOOL)containsUser:(PFUser *)user;
- (int)indexOfUser:(PFUser *)user;

- (BOOL)containsAccount:(TVAccount *)account;
- (int)indexOfAccount:(TVAccount *)account;

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

- (int)indexOfAccount:(TVAccount *)account {

    int retVal = NSNotFound;
    
    if (self.count) {
        
        for (int i = 0; i <= self.count - 1; i++) {

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

- (int)indexOfUser:(PFUser *)user {
    
    int retVal = NSNotFound;
    
    if (self.count) {
        
        for (int i = 0; i <= self.count - 1; i++) {
            
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
+ (void)updateFlights:(NSArray *)flights withObjectId:(NSString *)objectId; // Doesn't really need a callback/completion handler but I guess I should add it...

+ (void)findUsersWithEmails:(NSMutableArray *)emails withCompletionHandler:(void (^)(NSMutableArray *objects, NSError *error, NSString *callCode))callback;
+ (void)findUsersWithName:(NSString *)name withCompletionHandler:(void (^)(NSMutableArray *objects, NSError *error, NSString *callCode))callback;
+ (void)findUsersWithLinkedInIds:(NSMutableArray *)linkedInIds withCompletionHandler:(void (^)(NSMutableArray *objects, NSError *error, NSString *callCode))callback;
+ (void)downloadMyConnectionsWithCompletionHandler:(void (^)(NSMutableArray *objects, NSError *error, NSString *callCode))callback;
+ (void)connectWithUserId:(NSString *)userId withCompletionHandler:(void (^)(NSString *callCode, BOOL success))callback;
+ (void)disconnectWithUserId:(NSString *)userId withCompletionHandler:(void (^)(NSError *error, NSString *callCode, BOOL success))callback;
+ (void)findConnectionsFromId:(NSString *)userId withCompletionHandler:(void (^)(NSMutableArray *objects, NSError *error, NSString *callCode))callback;
+ (void)downloadConnectionsInTheSameCity:(NSString *)FlightID withCompletionHandler:(void (^)(NSMutableArray *objects, NSError *error, NSString *callCode))callback;
+ (void)acceptConnection:(TVConnection *)connection withCompletionHandler:(void (^)(NSError *error, NSString *callCode, BOOL success))callback;
+ (void)declineConnection:(TVConnection *)connection withCompletionHandler:(void (^)(NSError *error, NSString *callCode, BOOL success))callback;
+ (NSMutableArray *)pendingUserConnections;
+ (NSMutableArray *)confirmedUserConnections;
+ (NSMutableArray *)allUserConnections;

+ (NSMutableArray *)cachedPeople;
+ (void)cachePerson:(TVAccount *)account;
+ (TVAccount *)cachedPersonWithId:(NSString *)userId;
+ (void)refreshCachedPeople;

+ (void)removeTravelDataPacketWithID:(NSString *)_FlightID;
+ (void)addTravelDataPacketWithID:(NSString *)_FlightID andTravelDataObject:(TVTravelDataDownloader *)travelData;
+ (void)refreshTravelDataPacketWithID:(NSString *)_FlightID andTravelDataObject:(TVTravelDataDownloader *)travelData;
+ (NSMutableDictionary *)travelDataPacketWithID:(NSString *)_FlightID;

+ (TVFlight *)flightFromID:(NSString *)_FlightID;

+ (NSString *)generateRandomKeyWithLength:(int)len;

+ (void)logout;

+ (void)sendEmail:(NSMutableDictionary *)dictionary withCompletionHandler:(void (^)(BOOL success, NSError *error, NSString *callCode))callback;

+ (void)trackAnalytics:(NSDictionary *)launchOptions;

+ (void)receivedLocalNotification:(NSDictionary *)userInfo;
+ (void)updatePushNotificationsSetup;
+ (void)pushNotificationToObjectId:(NSString *)objectId withData:(NSDictionary *)data;
+ (void)removePushNotificationsSetup;

+ (TVAccount *)nativeAccount;
+ (TVAccount *)currentAccount;

+ (void)downloadUsersFromUserIds:(NSArray *)userIds withCompletionHandler:(void (^)(NSMutableArray *users, NSError *error, NSString *callCode))callback;
+ (void)getAccountFromUser:(PFUser *)object isPerformingCacheRefresh:(BOOL)isPerformingCacheRefresh withCompletionHandler:(void (^)(TVAccount *account, BOOL downloadedFlights, BOOL downloadedProfilePicture, BOOL downloadedConnections, BOOL downloadedMessages))callback;
+ (void)refreshAccountWithCompletionHandler:(void (^)(BOOL completed))callback;

+ (void)uploadAccount:(TVAccount *)trvlogueAccount withProfilePicture:(UIImage *)profilePicture andCompletionHandler:(void (^)(BOOL success, NSError *error, NSString *callCode))callback;
+ (void)updateMyAccount:(TVAccount *)accountObj withCompletionHandler:(void (^)(BOOL succeeded, NSError *error, NSString *callCode))callback;
+ (void)updateMyCache:(TVAccount *)accountObj;

+ (void)loginToAccountWithEmail:(NSString *)email andPassword:(NSString *)password withCompletionHandler:(void (^)(BOOL success, BOOL correctCredentials, NSError *error, NSString *callCode))callback;
+ (void)requestForNewPassword:(NSString *)email withCompletionHandler:(void (^)(BOOL succeeded, NSError *error, NSString *callCode))callback;

+ (NSData *)archiveAccount:(TVAccount *)accountObj;
+ (TVAccount *)unarchiveAccount:(NSData *)data;

@end