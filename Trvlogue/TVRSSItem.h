//
//  RSSItem.h
//  Nerdfeed
//
//  Created by Rohan Kapur on 17/12/11.
//  Copyright (c) 2011 UWCSEA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TVRSSItem : NSObject <NSXMLParserDelegate, NSCoding> {
    
    BOOL processingInfo;
    NSMutableString *currentString;
    BOOL isTitle;
    BOOL isLink;
}

@property (nonatomic, weak) id parentParserDelegate;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *link;
@property (nonatomic, strong) NSString *source;
@property (nonatomic, strong) NSString *date;

@end
