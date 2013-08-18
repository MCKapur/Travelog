//
//  PlacesQuerySuggestionsRetriever.m
//  Trvlogue
//
//  Created by Upi Kapur on 20/7/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import "TVPlacesQuerySuggestionsRetriever.h"

@implementation TVPlacesQuerySuggestionsRetriever

- (void)findPlacesBasedOnInput:(NSString *)input withCompletionHandler:(void (^)(NSError *error, NSMutableArray *places))callback {

    [self terminateRequests];
    
    NSString *request = [TVPlacesQuerySuggestionsRetriever SearchAPIRequest:input];

    NSURLRequest *URLRequest = [self getURLRequest:request];
    
    [NSURLConnection sendAsynchronousRequest:URLRequest queue:operationQueue completionHandler:^(NSURLResponse *URLResponse, NSData *responseData, NSError *responseError) {
        
        if (!responseError && responseData) {
            
            NSMutableArray *results = [[self deserialize:responseData][@"results"] mutableCopy];

            if (results.count) {
                
                for (NSMutableDictionary *result in results) {
                    
                    NSString *request = [TVPlacesQuerySuggestionsRetriever GetDetailsAPIRequest:result[@"reference"]];

                    NSURLRequest *URLRequest = [self getURLRequest:request];
                    
                    [NSURLConnection sendAsynchronousRequest:URLRequest queue:operationQueue completionHandler:^(NSURLResponse *URLResponse, NSData *responseData, NSError *responseError) {
                        
                        if (!responseError && URLResponse) {
                            
                            NSMutableDictionary *placeDetails = [self deserialize:responseData][@"result"];

                            TVGooglePlace *place = [[TVGooglePlace alloc] init];
                            [place setID:placeDetails[@"id"]];
                            [place setReference:placeDetails[@"reference"]];
                            [place setName:placeDetails[@"name"]];
                            [place setAddress:placeDetails[@"formatted_address"]];
                            [place setCoordinate:CLLocationCoordinate2DMake([placeDetails[@"geometry"][@"location"][@"lat"] doubleValue], [placeDetails[@"geometry"][@"location"][@"lng"] doubleValue])];
                            [place setPhoneNumber:placeDetails[@"formatted_phone_number"]];
                            [place setWebsite:placeDetails[@"website"]];
                            [place setRating:[placeDetails[@"rating"] doubleValue]];
                            
                            NSMutableArray *reviews = [[NSMutableArray alloc] init];
                            
                            for (NSMutableDictionary *placeReview in placeDetails[@"reviews"]) {
                                
                                TVGooglePlaceReview *review = [[TVGooglePlaceReview alloc] init];
                                
                                [review setAspects:placeReview[@"aspects"]];
                                [review setAuthorName:placeReview[@"author_name"]];
                                [review setAuthorURL:placeReview[@"author_url"]];
                                [review setBody:placeReview[@"text"]];
                                [review setTime:[placeReview[@"time"] intValue]];
                                
                                [reviews addObject:review];
                            }
                            
                            [place setReviews:reviews];
                            [place setPriceLevel:[placeDetails[@"price_level"] intValue]];
                            [place writeIconLocally:[UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:placeDetails[@"icon"]]]]];
                            
                            callback(nil, [NSArray arrayWithObject:place]);
                        }
                    }];
                }
            }
        }
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

+ (NSString *)GetDetailsAPIRequest:(NSString *)reference {
    
    return [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/details/json?reference=%@&key=%@&sensor=false", reference, GOOGLE_API_KEY];
}

- (NSURLRequest *)getURLRequest:(NSString *)request {
    
    NSURL *requestURL = [NSURL URLWithString:request];
    NSURLRequest *URLRequest = [NSURLRequest requestWithURL:requestURL];
    
    return URLRequest;
}

#pragma mark Data Handling

- (NSMutableDictionary *)deserialize:(NSData *)data {
    
    return [[NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil] mutableCopy];
}

@end