//
//  PlacesQuerySuggestionsRetriever.h
//  Trvlogue
//
//  Created by Upi Kapur on 20/7/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TVGooglePlace.h"

@interface TVPlacesQuerySuggestionsRetriever : NSObject
{
    NSOperationQueue *operationQueue;
}

- (void)findPlacesBasedOnInput:(NSString *)input withCompletionHandler:(void (^)(NSError *error, NSMutableArray *places))callback;

@end
