//
//  AutocompleteSuggestionsRetriever.m
//  Trvlogue
//
//  Created by Rohan Kapur on 17/3/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import "TVAutocompleteSuggestionsRetriever.h"

@implementation TVAutocompleteSuggestionsRetriever

- (void)findLocationAutocompletionSuggestionsBasedOnInput:(NSString *)input withCompletionHandler:(void (^)(NSError *error, BOOL success, NSDictionary *location))callback {
    
    [self terminateRequests];
    
    __block NSMutableDictionary *location = nil;
    __block BOOL success;
    
    NSString *request = [TVAutocompleteSuggestionsRetriever APIRequest:input];

    NSURLRequest *URLRequest = [self getURLRequest:request];
        
    [NSURLConnection sendAsynchronousRequest:URLRequest queue:opQue completionHandler:^(NSURLResponse *URLResponse, NSData *responseData, NSError *responseError) {
        
        if (!responseError && responseData) {
            
            success = NO;
            
            if ([self handleData:responseData].count) {
                
                location = [[self handleData:responseData] mutableCopy];
                                
                success = YES;
            }
            else {
                
                success = NO;
            }
        }
        else {
            
            success = NO;
        }
        
        callback(responseError, success, location);
    }];
}

- (void)terminateRequests {
    
    opQue = [[NSOperationQueue alloc] init];
}

#pragma mark Dirty, Funky, Native :S

- (id)init {
    
    self = [super init];
    
    if (self) {
                
        opQue = [[NSOperationQueue alloc] init];
    }
    
    return self;
}

#pragma mark API Request Generating

+ (NSString *)APIRequest:(NSString *)input {
    
    return [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/autocomplete/json?input=%@&types=(regions)&sensor=true&key=%@", [input stringByReplacingOccurrencesOfString:@" " withString:@"%20"], GOOGLE_API_KEY];
}

- (NSURLRequest *)getURLRequest:(NSString *)request {

    NSURL *requestURL = [NSURL URLWithString:request];
    NSURLRequest *URLRequest = [NSURLRequest requestWithURL:requestURL];
    
    return URLRequest;
}

#pragma mark Data Handling

- (NSDictionary *)handleData:(NSData *)responseData {
    
    #define key objectForKey:
    #define index objectAtIndex:
    
    NSMutableDictionary *responseDictionary = [self deserialize:responseData];
    
    NSMutableDictionary *filteredPrediction = nil;

    if (responseDictionary) {
        
        if ([responseDictionary[@"status"] isEqualToString:@"OK"]) {
                                                                
            filteredPrediction = [[NSMutableDictionary alloc] init];
            
            NSDictionary *prediction = responseDictionary[@"predictions"][0];
            
            NSMutableString *city_name = [[NSMutableString alloc] init];

            for (NSDictionary *term in prediction[@"terms"]) {
                
                if (!city_name.length) {
                        
                    [city_name appendString:term[@"value"]];
                }
                else {
                    
                    [city_name appendFormat:@", %@", term[@"value"]];
                }
            }
            
            filteredPrediction[@"city_name"] = city_name;
            
            filteredPrediction[@"short_city_name"] = [city_name componentsSeparatedByString:@","][0];
            
            filteredPrediction[@"country"] = [city_name componentsSeparatedByString:@","][[city_name componentsSeparatedByString:@","].count - 1];
        }
    }
    
    return filteredPrediction;
}

- (NSMutableDictionary *)deserialize:(NSData *)data {
    
    return [[NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil] mutableCopy];
}

@end
