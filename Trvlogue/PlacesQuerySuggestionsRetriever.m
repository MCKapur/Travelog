//
//  PlacesQuerySuggestionsRetriever.m
//  Trvlogue
//
//  Created by Upi Kapur on 20/7/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import "PlacesQuerySuggestionsRetriever.h"

@implementation PlacesQuerySuggestionsRetriever

- (void)findPlacesAutocompletionSuggestionsBasedOnInput:(NSString *)input withCompletionHandler:(void (^)(NSError *error, BOOL success, NSMutableArray *places))callback {
    
    [self terminateRequests];
    
    __block NSMutableArray *places = nil;
    __block BOOL success;

    NSString *request = [PlacesQuerySuggestionsRetriever SearchAPIRequest:input];
    NSURLRequest *URLRequest = [self getURLRequest:request];
    
    [NSURLConnection sendAsynchronousRequest:URLRequest queue:operationQueue completionHandler:^(NSURLResponse *URLResponse, NSData *responseData, NSError *responseError) {
        
        if (!responseError && responseData) {
            
            success = NO;
            
//            if ([self handleData:responseData].count) {
                
                NSLog(@"%@", [self deserialize:responseData]);
                
//                success = YES;
//            }
//            else {
//                
//                success = NO;
//            }
        }
        else {
            
            success = NO;
        }
        
//        callback(responseError, success, location);
    }];
}

- (void)terminateRequests {
        
    operationQueue = [[NSOperationQueue alloc] init];
}

#pragma mark Dirty, Funky, Native :S

- (id)init {
    
    self = [super init];
    
    if (self) {
        
        operationQueue = [[NSOperationQueue alloc] init];
    }
    
    return self;
}

#pragma mark API Request Generating

+ (NSString *)SearchAPIRequest:(NSString *)input {

    return [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/textsearch/json?&sensor=false&query=%@&key=%@", [input stringByReplacingOccurrencesOfString:@" " withString:@"%20"], GOOGLE_API_KEY];
}

- (NSURLRequest *)getURLRequest:(NSString *)request {
    
    NSURL *requestURL = [NSURL URLWithString:request];
    NSURLRequest *URLRequest = [NSURLRequest requestWithURL:requestURL];
    
    return URLRequest;
}

#pragma mark Data Handling

- (NSMutableArray *)handleData:(NSData *)responseData {
    
    #define key objectForKey:
    #define index objectAtIndex:
}

- (NSMutableDictionary *)deserialize:(NSData *)data {
    
    return [[NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil] mutableCopy];
}

@end
