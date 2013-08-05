//
//  LinkedInDataRetriever.m
//  Trvlogue
//
//  Created by Rohan Kapur on 27/5/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import "LinkedInDataRetriever.h"

@implementation LinkedInDataRetriever

+ (void)downloadConnectionsWithAccessToken:(NSString *)accessToken andCompletionHandler:(void (^)(NSArray *connections, BOOL success, NSError *error))callback {
    
    NSArray *grantedAccess = @[@"r_fullprofile", @"r_network", @"r_emailaddress"];

    LIALinkedInApplication *application = [LIALinkedInApplication applicationWithRedirectURL:@"http://www.trvlogue.com" clientId:LINKEDIN_API_KEY clientSecret:LINKEDIN_SECRET_KEY state:LINKEDIN_UNIQUE_STATE grantedAccess:grantedAccess];
    
    LIALinkedInHttpClient *client = [LIALinkedInHttpClient clientForApplication:application];
    
    [client getPath:[NSString stringWithFormat:@"https://api.linkedin.com/v1/people/~/connections:(id)?oauth2_access_token=%@&format=json", accessToken] parameters:nil success:^(AFHTTPRequestOperation *operation, NSDictionary *result) {
        
        NSArray *connections = nil;
        BOOL success = NO;
        
        if ([result[@"_total"] intValue] >= 0) {
            
            connections = result[@"values"];
            success = YES;
        }
        
        callback(connections, success, nil);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        callback(nil, NO, error);
    }];
}

+ (void)downloadProfileWithAccessToken:(NSString *)accessToken andCompletionHandler:(void (^)(NSDictionary *profile, BOOL success, NSError *error))callback {
    
    NSArray *grantedAccess = @[@"r_fullprofile", @"r_network", @"r_emailaddress"];
    
    LIALinkedInApplication *application = [LIALinkedInApplication applicationWithRedirectURL:@"http://www.trvlogue.com" clientId:LINKEDIN_API_KEY clientSecret:LINKEDIN_SECRET_KEY state:LINKEDIN_UNIQUE_STATE grantedAccess:grantedAccess];
    
    LIALinkedInHttpClient *client = [LIALinkedInHttpClient clientForApplication:application];
    
    [client getPath:[NSString stringWithFormat:@"https://api.linkedin.com/v1/people/~:(id,formatted-name,location:(name),headline,picture-url,email-address)?oauth2_access_token=%@&format=json", accessToken] parameters:nil success:^(AFHTTPRequestOperation * operation, NSDictionary *result) {
                
        NSDictionary *profile = nil;
        BOOL success = NO;
        
        if ([result count]) {

            profile = result;
            success = YES;
        }
        
        callback(profile, success, nil);
        
    } failure:^(AFHTTPRequestOperation * operation, NSError *error) {
        
        callback(nil, NO, error);
    }];
}

@end
