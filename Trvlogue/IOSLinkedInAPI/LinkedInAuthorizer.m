//
//  LinkedInAuthorizer.m
//  Trvlogue
//
//  Created by Rohan Kapur on 27/5/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import "LinkedInAuthorizer.h"

@implementation LinkedInAuthorizer

+ (void)authorizeWithCompletionHandler:(void (^)(BOOL succeeded, BOOL cancelled, NSError *error, NSString *accessToken))callback {
    
    NSArray *grantedAccess = @[@"r_fullprofile", @"r_network", @"r_emailaddress"];
    
    LIALinkedInApplication *application = [LIALinkedInApplication applicationWithRedirectURL:@"http://www.trvlogue.com" clientId:LINKEDIN_API_KEY clientSecret:LINKEDIN_SECRET_KEY state:LINKEDIN_UNIQUE_STATE grantedAccess:grantedAccess];
    
    LIALinkedInHttpClient *client = [LIALinkedInHttpClient clientForApplication:application];
    
    __block NSString *accessToken;
    __block BOOL success;
    __block BOOL cancelled = NO;
    __block NSError *error;
    
    [client getAuthorizationCode:^(NSString *authorizationCode) {
        
        [client getAccessToken:authorizationCode success:^(NSDictionary *accessTokenData) {
            
            accessToken = accessTokenData[@"access_token"];
            
            if (accessToken.length) {

                error = nil;
                accessToken = accessToken;
                success = YES;
                cancelled = NO;
            }
            else {
                
                error = nil;
                accessToken = nil;
                success = NO;
                cancelled = NO;
            }
            
            callback(success, cancelled, error, accessToken);
            
        } failure:^(NSError *_error) {

            error = _error;
            accessToken = nil;
            success = NO;
            cancelled = NO;
            
            callback(success, cancelled, error, accessToken);
        }];

    } cancel:^{
        
        error = nil;
        accessToken = nil;
        success = NO;
        cancelled = YES;
        
        callback(success, cancelled, error, accessToken);
        
    } failure:^(NSError *_error) {

        error = _error;
        accessToken = nil;
        success = NO;
        cancelled = NO;
        
        callback(success, cancelled, error, accessToken);
    }];
}

@end