//
//  PlacesQuerySuggestionsRetriever.h
//  Trvlogue
//
//  Created by Upi Kapur on 20/7/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TVPlacesQuerySuggestionsRetriever : NSObject
{
    NSOperationQueue *operationQueue;
}

- (void)findPlacesAutocompletionSuggestionsBasedOnInput:(NSString *)input withCompletionHandler:(void (^)(NSError *error, BOOL success, NSMutableArray *places))callback;

@end
