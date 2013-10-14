//
//  TVGoogleGeocoder.m
//  Trvlogue
//
//  Created by Rohan Kapur on 30/9/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import "TVGoogleGeocoder.h"

@implementation TVGoogleGeocoder

- (void)geocodeCityWithName:(NSString *)city withCompletionHandler:(void (^)(NSError *error, BOOL success, NSDictionary *result))callback {
    
    __block NSMutableDictionary *location = nil;
    __block BOOL success;
    
    NSString *request = [TVGoogleGeocoder APIRequest:city];
    
    NSURLRequest *URLRequest = [self getURLRequest:request];
    
    [NSURLConnection sendAsynchronousRequest:URLRequest queue:opQueue completionHandler:^(NSURLResponse *URLResponse, NSData *responseData, NSError *responseError) {
        
        if (!responseError && responseData) {
            
            success = NO;
            
            if ([self handleData:responseData].count) {
                
                location = [[self handleData:responseData] mutableCopy];
                
                if (location.count)
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

#pragma mark Dirty, Funky, Native :S

- (id)init {
    
    self = [super init];
    
    if (self) {
        
        opQueue = [[NSOperationQueue alloc] init];
    }
    
    return self;
}

#pragma mark API Request Generating

+ (NSString *)APIRequest:(NSString *)input {
    
    return [NSString stringWithFormat:@"http://maps.googleapis.com/maps/api/geocode/json?address=%@&sensor=true", [input stringByReplacingOccurrencesOfString:@" " withString:@"+"]];
}

- (NSURLRequest *)getURLRequest:(NSString *)request {
    
    NSURL *requestURL = [NSURL URLWithString:request];
    NSURLRequest *URLRequest = [NSURLRequest requestWithURL:requestURL];
    
    return URLRequest;
}

#pragma mark Data Handling

- (NSDictionary *)handleData:(NSData *)responseData {
    
    NSMutableDictionary *responseDictionary = [self deserialize:responseData];

    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    
    if (responseDictionary) {
        
        if ([responseDictionary[@"status"] isEqualToString:@"OK"]) {

            NSString *city = nil;
            NSString *country = nil;
            
            for (NSDictionary *component in responseDictionary[@"results"][0][@"address_components"]) {
                
                if ([component[@"types"] containsObject:@"locality"]) {
                    
                    city = component[@"long_name"];
                }
                else if ([component[@"types"] containsObject:@"country"]) {
                    
                    country = component[@"long_name"];
                }
            }
            
            if (!city) {
                
                for (NSDictionary *component in responseDictionary[@"results"][0][@"address_components"]) {
                    
                    if ([component[@"types"] containsObject:@"administrative_area_level_1"]) {
                        
                        city = component[@"long_name"];
                    }
                }

                if (!city) {
                    
                    city = [responseDictionary[@"results"][0][@"formatted_address"] componentsSeparatedByString:@","][0];
                }
            }
            
            if (country) {
                
                result[@"city"] = city;
                result[@"coordinate_latitude"] = [NSNumber numberWithDouble:[responseDictionary[@"results"][0][@"geometry"][@"location"][@"lat"] doubleValue]];
                result[@"coordinate_longitude"] =  [NSNumber numberWithDouble:[responseDictionary[@"results"][0][@"geometry"][@"location"][@"lng"] doubleValue]];
                
                result[@"country"] = country;
            }
        }
    }
    
    return result;
}

- (NSMutableDictionary *)deserialize:(NSData *)data {
    
    return [[NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil] mutableCopy];
}

@end
