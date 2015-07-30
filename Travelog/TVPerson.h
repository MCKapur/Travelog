//
//  TVPerson.h
//  Trvlogue
//
//  Created by Rohan Kapur on 2/6/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TVMileTidbits.h"

#import "TVMessageHistory.h"

#import "TVNotification.h"

#import "TVAppDelegate.h"

@interface NSMutableArray (FlightSorting)

- (NSMutableArray *)sortedByDate;

@end

@implementation NSMutableArray (FlightSorting)

- (NSMutableArray *)sortedByDate {
    
    NSSortDescriptor *sortByDate = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO];
    
    NSMutableArray *sortedByDate = [self mutableCopy];
    [sortedByDate sortUsingDescriptors:@[sortByDate]];
    
    return sortedByDate;
}

@end

@interface NSMutableArray (Notifications)

- (NSInteger)indexOfNotification:(TVNotification *)_notification;
- (void)clearNotificationOfType:(NSInteger)notificationType;

- (void)addNotification:(TVNotification *)notification;
- (void)removeNotification:(TVNotification *)notification;

@end

@implementation NSMutableArray (Notifications)

- (void)addNotification:(TVNotification *)notification {
        
    if ([self indexOfNotification:notification] == NSNotFound) {

        [self addObject:notification];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateNotifications" object:nil userInfo:nil];
}

- (void)removeNotification:(TVNotification *)notification {
        
    if ([self indexOfNotification:notification] != NSNotFound) {
        
        [self removeObjectAtIndex:[self indexOfNotification:notification]];
    }
    else {
        
        NSLog(@"Cannot find %@. %@", notification.ID, self);
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateNotifications" object:nil userInfo:nil];
}

- (NSInteger)indexOfNotification:(TVNotification *)notification {
    
    NSInteger retVal = NSNotFound;
    
    if (self.count) {
        
        for (NSInteger i = 0; i <= self.count - 1; i++) {
            
            TVNotification *_notification = self[i];

            if ([notification.ID isEqualToString:_notification.ID]) {
                
                retVal = i;
            }
        }
    }
    
    return retVal;
}

- (void)clearNotificationOfType:(NSInteger)notificationType {

    NSMutableIndexSet *indexSet = [[NSMutableIndexSet alloc] init];
    
    for (TVNotification *notification in self) {

        if ((NSInteger)notification.type == notificationType) {
            
            [indexSet addIndex:[self indexOfNotification:notification]];
        }
    }
    
    [self removeObjectsAtIndexes:indexSet];
}

@end

@interface TVPerson : NSObject <NSCoding>

@property (nonatomic, strong) NSMutableArray *notifications;

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *email;

@property (nonatomic, strong) NSString *position;

@property (nonatomic) CGFloat miles;

@property (nonatomic, strong) NSString *originCity;

@property (nonatomic, strong) NSMutableArray *connections;

@property (nonatomic, strong) NSMutableDictionary *knownDestinationPreferences;

@property (nonatomic, strong) NSMutableArray *flights;

@property (nonatomic, strong) NSMutableArray *messageHistories;

- (void)addFlight: (TVFlight *)flight;
- (void)deleteFlight: (TVFlight *)flight;

- (NSMutableArray *)sortedMessageHistories;
- (NSMutableArray *)mileTidbits;

@end