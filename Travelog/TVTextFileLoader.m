//
//  TextFileLoader.m
//  Trvlogue
//
//  Created by Rohan Kapur on 3/4/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import "TVTextFileLoader.h"

@implementation TVTextFileLoader

+ (NSString *)loadTextFile:(NSString *)dir {
    
    NSString *path = [[NSBundle mainBundle] pathForResource:dir ofType: @"txt"];
    
    NSString *content = [NSString stringWithContentsOfFile:path
                                                  encoding:                         NSUTF8StringEncoding
                                                     error:
                         NULL];
    return content;
}

@end
