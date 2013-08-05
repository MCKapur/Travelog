//
//  AutocompleteSuggestionsRetriever.h
//  Trvlogue
//
//  Created by Rohan Kapur on 17/3/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CoreLocation/CoreLocation.h>

@interface AutocompleteSuggestionsRetriever : NSObject
{
    NSOperationQueue *opQue;
}

- (void)findLocationAutocompletionSuggestionsBasedOnInput:(NSString *)input withCompletionHandler:(void (^)(NSError *error, BOOL success, NSDictionary *location))callback;

@end
