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

#define AWS_ACCESS_KEY_ID                @"AKIAIYCWHUXQQVXGTGLA"
#define AWS_SECRET_KEY                   @"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"

#define GOOGLE_API_KEY @"AIzaSyCMCS9TGb5Xr06cW611vnaZea_Rzcxxnqc"

#define TRVLOGUE_NAVIGATION_BAR @"TrvlogueNavigationBar.png"

#define VERIFIED_EMAIL_TEST @"me@rohankapur.com"
#define VERIFIED_EMAIL @"us@trvlogue.com"

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

typedef enum {
    
    kEmailCouldNotSend = 0,
    kEmailSent = 1
    
} EmailSendRequestResult;

typedef enum {
    
    kPushNotificationWantsToConnect = 0,
    kPushNotificationAcceptedConnection

} PushNotificationType;

#import <Foundation/Foundation.h>

#import "TVAccount.h"

#import <Parse/Parse.h>

#import <AWSiOSSDK/SES/AmazonSESClient.h>

#import "TVMessageHistory.h"

#import "TVNotification.h"

#import "TVConnection.h"

#import "TVFindPeopleViewController.h"
 
@class TVCreateAccountViewController;

@interface TVDatabase : NSObject

+ (void)setCurrentAccount:(TVAccount *)account;

+ (void)createMessageHistory:(TVMessageHistory *)messageHistory withUserId:(NSString *)userId withCompletionHandler:(void (^)(BOOL success, NSError *error, NSString *callCode))callback;
+ (void)queueMessages:(NSMutableArray *)messageHistory withUserId:(NSString *)userId withCompletionHandler:(void (^)(BOOL success, NSError *error, NSString *callCode))callback;
+ (void)userHasReadAllMessagesInMessageHistory:(TVMessageHistory *)messageHistory withUserId:(NSString *)userId withCompletionHandler:(void (^)(BOOL success, NSError *error, NSString *callCode))callback;
+ (void)downloadMessageHistoriesWithUserId:(NSString *)userId withCompletionHandler:(void (^)(BOOL success, NSError *error, NSString *callCode, TVMessageHistory *messageHistories))callback;

+ (void)downloadProfilePicturesWithObjectIds:(NSArray *)objectIds withCompletionHandler:(void (^)(NSError *error, UIImage *profilePic))callback;
+ (void)uploadProfilePicture:(UIImage *)profilePicture withObjectId:(NSString *)objectId; // Doesn't really need a callback/completion handler but I guess I should add it...
+ (void)updateProfilePicture:(UIImage *)profilePicture withObjectId:(NSString *)objectId withCompletionHandler:(void (^)(BOOL succeeded, NSError *error, NSString *callCode))callback; // Doesn't really need a callback/completion handler but I guess I should add it...

+ (void)downloadFlightsWithObjectIds:(NSArray *)objectIds withCompletionHandler:(void (^)(NSError *error, NSMutableArray *flights))callback;
+ (void)uploadFlights:(NSArray *)flights withObjectId:(NSString *)objectId; // Doesn't really need a callback/completion handler but I guess I should add it...
+ (void)updateFlights:(NSArray *)flights withObjectId:(NSString *)objectId; // Doesn't really need a callback/completion handler but I guess I should add it...

+ (void)findUsersWithEmails:(NSMutableArray *)emails withCompletionHandler:(void (^)(NSMutableArray *objects, NSError *error, NSString *callCode))callback;
+ (void)findUsersWithLinkedInIds:(NSMutableArray *)linkedInIds withCompletionHandler:(void (^)(NSMutableArray *objects, NSError *error, NSString *callCode))callback;
+ (void)downloadMyConnectionsWithCompletionHandler:(void (^)(NSMutableArray *objects, NSError *error, NSString *callCode))callback;
+ (void)connectWithUser:(PFUser *)user withCompletionHandler:(void (^)(NSString *callCode, BOOL success))callback;
+ (void)disconnectWithUserId:(NSString *)userId withCompletionHandler:(void (^)(NSError *error, NSString *callCode, BOOL success))callback;
+ (void)findMyConnections:(void (^)(NSMutableArray *objects, NSError *error, NSString *callCode))callback;
+ (void)downloadConnectionsInTheSameCity:(NSString *)FlightID withCompletionHandler:(void (^)(NSMutableArray *objects, NSError *error, NSString *callCode))callback;
+ (void)acceptConnection:(TVConnection *)connection withCompletionHandler:(void (^)(NSError *error, NSString *callCode, BOOL success))callback;
+ (void)declineConnection:(TVConnection *)connection withCompletionHandler:(void (^)(NSError *error, NSString *callCode, BOOL success))callback;

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
+ (void)setupPushNotifications:(NSData *)deviceToken;
+ (void)pushNotificationToObjectId:(NSString *)objectId withData:(NSDictionary *)data;
+ (void)removePushNotificationsSetup;

+ (BOOL)staysLoggedIn;

+ (TVAccount *)nativeAccount;
+ (TVAccount *)currentAccount;

+ (void)downloadUsersFromUserIds:(NSArray *)userIds withCompletionHandler:(void (^)(NSMutableArray *users, NSError *error, NSString *callCode))callback;
+ (void)getAccountFromUser:(PFUser *)object withCompletionHandler:(void (^)(TVAccount *account, BOOL allOperationsComplete, BOOL hasWrittenProfilePicture))callback;
+ (void)refreshAccountWithCompletionHandler:(void (^)(BOOL completed))callback;

+ (void)uploadAccount:(TVAccount *)trvlogueAccount withCompletionHandler:(void (^)(BOOL success, NSError *error, NSString *callCode))callback;
+ (void)updateMyAccount:(TVAccount *)accountObj withCompletionHandler:(void (^)(BOOL succeeded, NSError *error, NSString *callCode))callback;
+ (void)updateMyCache:(TVAccount *)accountObj;

+ (void)loginToAccountWithEmail:(NSString *)email andPassword:(NSString *)password withCompletionHandler:(void (^)(BOOL success, BOOL correctCredentials, NSError *error, NSString *callCode))callback;
+ (void)requestForNewPassword:(NSString *)email withCompletionHandler:(void (^)(BOOL succeeded, NSError *error, NSString *callCode))callback;

+ (NSData *)archiveAccount:(TVAccount *)accountObj;
+ (TVAccount *)unarchiveAccount:(NSData *)data;

@end