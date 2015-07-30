//
//  Flight.m
//  Trvlogue
//
//  Created by Rohan Kapur on 19/1/13.
//  Copyright (c) 2013 UWCSEA. All rights reserved.
//

#import "TVFlight.h"

#import "Reachability.h"

@interface NSArray (Indexing)

- (NSInteger)indexOfFlight:(TVFlight *)flight;

@end

@implementation NSArray (Indexing)

- (NSInteger)indexOfFlight:(TVFlight *)flight {
    
    NSInteger retVal = NSNotFound;
    
    for (NSInteger i = 0; i <= self.count - 1; i++) {
        
        if ([((TVFlight *)self[i]).ID isEqualToString:flight.ID]) {
            
            retVal = i;
        }
    }
    
    return retVal;
}

@end

@implementation TVFlight

@synthesize date, miles, originCity, destinationCity, originCountry, destinationCountry, originCoordinate, destinationCoordinate, ID;

- (void)instantiateTravelData {
    
    Reachability *reach = [Reachability reachabilityWithHostname:@"google.com"];

    if ([reach isReachable] && ([reach isReachableViaWiFi] || [reach isReachableViaWWAN])) {

        if ([TVDatabase travelDataPacketWithID:self.ID]) {
            
            TVTravelDataDownloader *travelData = [[TVTravelDataDownloader alloc] initWithDelegate:self andFlightID:self.ID];
            [travelData setDownloadedData:[TVDatabase travelDataPacketWithID:self.ID]];
            [travelData fireDataDownload];
        }
        else {
            
            TVTravelDataDownloader *travelData = [[TVTravelDataDownloader alloc] initWithDelegate:self andFlightID:self.ID];
            [travelData fireDataDownload];
        }
    }
}

- (id)initWithCoder:(NSCoder *)aDecoder { 
    
    self = [super init];
    
    if (self) {
        
        self.miles = [aDecoder decodeDoubleForKey:@"miles"];
        
        self.originCity = [aDecoder decodeObjectForKey:@"originCity"];
        self.destinationCity = [aDecoder decodeObjectForKey:@"destinationCity"];
        
        self.originCountry = [aDecoder decodeObjectForKey:@"originCountry"];
        self.destinationCountry = [aDecoder decodeObjectForKey:@"destinationCountry"];
        
        self.date = [aDecoder decodeObjectForKey:@"date"];
        
        double originLatitude = [aDecoder decodeDoubleForKey:@"originLatitude"];
        double originLongitude = [aDecoder decodeDoubleForKey:@"originLongitude"];

        double destinationLatitude = [aDecoder decodeDoubleForKey:@"destinationLatitude"];
        double destinationLongitude = [aDecoder decodeDoubleForKey:@"destinationLongitude"];
        
        self.originCoordinate = CLLocationCoordinate2DMake(originLatitude, originLongitude);
        self.destinationCoordinate = CLLocationCoordinate2DMake(destinationLatitude,  destinationLongitude);
        
        self.ID = [aDecoder decodeObjectForKey:@"ID"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    
    [aCoder encodeDouble:self.miles forKey:@"miles"];
    [aCoder encodeObject:self.originCity forKey:@"originCity"];
    [aCoder encodeObject:self.destinationCity forKey:@"destinationCity"];
    [aCoder encodeObject:self.originCountry forKey:@"originCountry"];
    [aCoder encodeObject:self.destinationCountry forKey:@"destinationCountry"];
    [aCoder encodeObject:self.date forKey:@"date"];
    [aCoder encodeDouble:self.originCoordinate.latitude forKey:@"originLatitude"];
    [aCoder encodeDouble:self.originCoordinate.longitude forKey:@"originLongitude"];
    [aCoder encodeDouble:self.destinationCoordinate.latitude forKey:@"destinationLatitude"];
    [aCoder encodeDouble:self.destinationCoordinate.longitude forKey:@"destinationLongitude"];
    [aCoder encodeObject:self.ID forKey:@"ID"];
}

- (id)initWithParameters:(NSDictionary *)dictionary {
    
    self = [super init];
    
    if (self) {
        
        self.miles = [dictionary[@"miles"] doubleValue];
        self.originCity = dictionary[@"originCity"];
        self.destinationCity = dictionary[@"destinationCity"];
        self.originCountry = dictionary[@"originCountry"];
        self.destinationCountry = dictionary[@"destinationCountry"];
        self.date = dictionary[@"date"];
        
        if (dictionary[@"originLatitude"]) {
            
            double originLatitude = [dictionary[@"originLatitude"] doubleValue];
            double originLongitude = [dictionary[@"originLongitude"] doubleValue];
            
            double destinationLatitude = [dictionary[@"destinationLatitude"] doubleValue];
            double destinationLongitude = [dictionary[@"destinationLongitude"] doubleValue];
            
            self.originCoordinate = CLLocationCoordinate2DMake(originLatitude, originLongitude);
            self.destinationCoordinate = CLLocationCoordinate2DMake(destinationLatitude,  destinationLongitude);
        }
                
        self.ID = [self generateRandomID];
    }
    
    return self;
}

- (NSString *)description {
    
    return [NSString stringWithFormat:@"\r%@\r\rMiles:%g\r\rName:%@ to %@\r\rDate:%@\r", self.ID, self.miles, self.originCity, self.destinationCity, [TVConversions convertDateToString:self.date withFormat:DAY_MONTH_YEAR]];
}

- (NSString *)generateRandomID {
    
    return [NSString stringWithFormat:@"%@-%@-%@", self.originCity, self.destinationCity, self.date];
}

#pragma mark TravelData Delegate

- (void)travelDataUpdated:(TravelDataTypes *)dataType {

    dispatch_async(dispatch_get_main_queue(), ^{

        [[NSNotificationCenter defaultCenter] postNotificationName:[NSString stringWithFormat:@"%@_%@", NSNotificationTravelDataPacketUpdated, self.ID] object:nil userInfo:@{@"dataType":@((NSInteger)dataType)}];
    });
}

@end
