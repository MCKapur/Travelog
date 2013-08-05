//
//  RSSChannel.m
//  Nerdfeed
//
//  Created by Rohan Kapur on 16/12/11.
//  Copyright (c) 2011 UWCSEA. All rights reserved.
//

#import "RSSChannel.h"
#import "RSSItem.h"

@implementation RSSChannel
@synthesize items, title, shortDescription, parentParserDelegate;

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    
    
    if ([elementName isEqual:@"title"]) {
        
        currentString = [[NSMutableString alloc] init];
        [self setTitle: currentString];
        
    } else if ([elementName isEqual:@"description"]) {
        
        currentString = [[NSMutableString alloc] init];
        [self setShortDescription:currentString];
        
    } else if ([elementName isEqual:@"item"]) {
        
        // When we find an item, create an instance of RSSItem
        RSSItem *entry = [[RSSItem alloc] init];
        
        // Set up its parent as ourselves so we regain control of the parser
        [entry setParentParserDelegate:self];
        
        // Turn the parser to the RSSItem
        [parser setDelegate:entry];
        
        // Add the item to our array and release our hold on it
        [items addObject:entry];
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    
    [currentString appendString:string];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    
    // If we were in an element that we were collecting the string for,
    // this appropriately releases our hold on it and the permanent ivar keeps
    // ownership of it. If we weren't parsing such an element, currentString
    // is nil and this message does nothing
    currentString = nil;
    
    // If the element that ended was the channel, give up control to
    // who gave us control in the first place
    if ([elementName isEqual:@"channel"]) {
        [parser setDelegate:self.parentParserDelegate];
    }
}

- (id)init {
    
    self = [super init];
    
    if (self) {
        
        // Create the container for the RSSItems this channel has; we'll create the RSSItem class shortly.
        items = [[NSMutableArray alloc] init];
    }
    
    return self;
}

@end
