//
//  RSSChannel.m
//  Nerdfeed
//
//  Created by Rohan Kapur on 16/12/11.
//  Copyright (c) 2011 UWCSEA. All rights reserved.
//

#import "TVRSSChannel.h"
#import "TVRSSItem.h"

@implementation TVRSSChannel
@synthesize items, title, shortDescription, parentParserDelegate;

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    
    
    if ([elementName isEqual:@"title"]) {
        
        currentString = [[NSMutableString alloc] init];
        [self setTitle: currentString];
        
    } else if ([elementName isEqual:@"description"]) {
        
        currentString = [[NSMutableString alloc] init];
        [self setShortDescription:currentString];
        
    } else if ([elementName isEqual:@"item"]) {
        
        TVRSSItem *entry = [[TVRSSItem alloc] init];
        [entry setParentParserDelegate:self];
        
        [parser setDelegate:entry];
        
        [items addObject:entry];
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    
    [currentString appendString:string];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    
    currentString = nil;

    if ([elementName isEqual:@"channel"]) {
        
        [parser setDelegate:self.parentParserDelegate];
    }
}

- (id)init {
    
    self = [super init];
    
    if (self) {
        
        items = [[NSMutableArray alloc] init];
    }
    
    return self;
}

@end
