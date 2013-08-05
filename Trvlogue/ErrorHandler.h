//
//  ErrorHandler.h
//  Trvlogue
//
//  Created by Rohan Kapur on 20/3/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ErrorHandler : NSObject

+ (void)handleError: (NSError *)error;
+ (void)generalError;

@end
