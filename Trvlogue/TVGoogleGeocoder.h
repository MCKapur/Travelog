//
//  TVGoogleGeocoder.h
//  Trvlogue
//
//  Created by Rohan Kapur on 30/9/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TVGoogleGeocoder : NSObject
{
    NSOperationQueue *opQueue;
}

- (void)geocodeCityWithName:(NSString *)city withCompletionHandler:(void (^)(NSError *error, BOOL success, NSDictionary *result))callback;

@end
