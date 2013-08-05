//
//  TravelData.h
//  Trvlogue
//
//  Created by Rohan Kapur on 24/3/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CoreLocation/CoreLocation.h>

#import "RSSItem.h"
#import "RSSChannel.h"

#import "PeopleFeed.h"

#import "TrvlogueFlight.h"
#import "PlacesQuerySuggestionsRetriever.h"

typedef enum {
    
    kTravelDataWeather = 0,
    kTravelDataPeople,
    kTravelDataCurrentNews,
    kTravelDataLanguagesSpoken,
    kTravelDataPlug,
    kTravelDataCurrency,
    kTravelDataTimezone,
    kTravelDataFacts
    
} TravelDataTypes;

@protocol TravelDataDelegate <NSObject>

- (void)travelDataUpdated: (TravelDataTypes *)dataType;

@end

@class TrvlogueFlight;

@interface TravelDataDownloader : NSObject <NSCoding, NSURLConnectionDelegate, NSURLConnectionDataDelegate, NSXMLParserDelegate, CLLocationManagerDelegate>
{
    /** RSS **/
    
    RSSItem *entry;
    NSURLConnection *connection;
    NSMutableData *xmlData;
    RSSChannel *channel;
    
    /**     **/
    
    NSDictionary *newImageLocated;
}

@property (nonatomic, strong) NSDate *lastUpdated;

@property (nonatomic, strong) NSMutableDictionary *downloadedData;

@property (nonatomic, strong) id<TravelDataDelegate> delegate;

@property (nonatomic, strong) NSString *FlightID;

@property (nonatomic, strong) TrvlogueFlight *flight;

@property (nonatomic, strong) NSOperationQueue *operationQueue;

- (void)updateDownloadedData: (NSMutableDictionary *)_downloadedData;

- (id)initWithDelegate: (id<TravelDataDelegate>)delegate andFlightID: (NSString *)_FlightID;

- (void)fireDataDownload;

@end
