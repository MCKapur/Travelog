//
//  RSSChannel.h
//  Nerdfeed
//
//  Created by Rohan Kapur on 16/12/11.
//  Copyright (c) 2011 UWCSEA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TVRSSChannel : NSObject <NSXMLParserDelegate>
{    
    NSMutableString *currentString;
    NSString *title;
    NSString *shortDescription;
    NSMutableArray *items;
}

@property (nonatomic, weak) id parentParserDelegate;
@property (nonatomic, strong) NSString *shortDescription;
@property (nonatomic, readonly) NSMutableArray *items;
@property (nonatomic, strong) NSString *title;

@end
