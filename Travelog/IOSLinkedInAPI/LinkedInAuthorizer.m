//
//  LinkedInAuthorizer.m
//  Trvlogue
//
//  Created by Rohan Kapur on 27/5/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import "LinkedInAuthorizer.h"

@implementation LinkedInAuthorizer

+ (void)getAuthorizationToken:(void (^)(BOOL success, BOOL cancelled, NSError *error, NSString *callCode))callback {
    
    NSArray *grantedAccess = @[@"r_fullprofile", @"r_network", @"r_emailaddress"];
    
    LIALinkedInApplication *application = [LIALinkedInApplication applicationWithRedirectURL:@"http://www.travelogapp.com" clientId:LINKEDIN_API_KEY clientSecret:LINKEDIN_SECRET_KEY state:LINKEDIN_UNIQUE_STATE grantedAccess:grantedAccess];
    
    LIALinkedInHttpClient *client = [LIALinkedInHttpClient clientForApplication:application];
    
    __block NSString *authorizationCode;
    __block BOOL success;
    __block BOOL cancelled = NO;
    __block NSError *error;
    
    [client getAuthorizationCode:^(NSString *_authorizationCode) {
            
        if (_authorizationCode.length) {
            
            error = nil;
            authorizationCode = _authorizationCode;
            success = YES;
            cancelled = NO;
        }
        else {
            
            error = nil;
            authorizationCode = nil;
            success = NO;
            cancelled = NO;
        }
        
        callback(success, cancelled, error, authorizationCode);
        
    } cancel:^{
        
        error = nil;
        authorizationCode = nil;
        success = NO;
        cancelled = YES;
        
        callback(success, cancelled, error, authorizationCode);

    } failure:^(NSError *_error) {
        
        error = _error;
        authorizationCode = nil;
        success = NO;
        cancelled = NO;
        
        callback(success, cancelled, error, authorizationCode);
    }];
}

+ (void)requestAccessTokenFromAuthorizationCode:(NSString *)authorizationCode withCompletionHandler:(void (^)(BOOL succeeded, NSError *error, NSString *accessToken))callback {

    NSArray *grantedAccess = @[@"r_fullprofile", @"r_network", @"r_emailaddress"];
    
    LIALinkedInApplication *application = [LIALinkedInApplication applicationWithRedirectURL:@"http://www.travelogapp.com" clientId:LINKEDIN_API_KEY clientSecret:LINKEDIN_SECRET_KEY state:LINKEDIN_UNIQUE_STATE grantedAccess:grantedAccess];
    
    LIALinkedInHttpClient *client = [LIALinkedInHttpClient clientForApplication:application];
    
    __block NSString *accessToken;
    __block BOOL success;
    __block NSError *error;
    
    [client getAccessToken:authorizationCode success:^(NSDictionary *accessTokenResults) {
        
        if (accessTokenResults[@"access_token"]) {
            
            accessToken = accessTokenResults[@"access_token"];
            success = accessToken.length ? YES : NO;
            error = nil;
        }
        
        callback(success, error, accessToken);
        
    } failure:^(NSError *_error) {
        
        accessToken = nil;
        success = NO;
        error = _error;
        
        callback(success, error, accessToken);
    }];
}

@end