//
//  RSSItem.m
//  Nerdfeed
//
//  Created by Rohan Kapur on 17/12/11.
//  Copyright (c) 2011 UWCSEA. All rights reserved.
//

#import "RSSItem.h"

NSString *type;
@implementation RSSItem
@synthesize title, link, parentParserDelegate, source, date;

- (void)encodeWithCoder:(NSCoder *)aCoder {
    
    [aCoder encodeObject:self.title forKey: @"title"];
    [aCoder encodeObject:self.link forKey: @"link"];
    [aCoder encodeObject:self.source forKey: @"source"];
    [aCoder encodeObject:self.date forKey: @"date"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    
    self = [super init];
    
    if (self) {
        
        self.title = [aDecoder decodeObjectForKey: @"title"];
        self.link = [aDecoder decodeObjectForKey: @"link"];
        self.source = [aDecoder decodeObjectForKey: @"source"];
        self.date = [aDecoder decodeObjectForKey: @"date"];
    }
    
    return self;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {

    if ([elementName isEqual: @"title"]) {
        
        currentString = [[NSMutableString alloc] init];
        [self setTitle: currentString];
        
        
    }
    else if ([elementName isEqual:@"link"]) {
        
        currentString = [[NSMutableString alloc] init];
        [self setLink: currentString];
    }
}

- (id)init {
    
    self = [super init];
    return self;
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    
    if (currentString) {
        
        [currentString appendString:string];
    }
}


- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    
    currentString = nil;
    if ([elementName isEqual:@"item"]) {
        [parser setDelegate:parentParserDelegate];
    }
}

@end
