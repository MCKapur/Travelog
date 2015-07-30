//
//  TravelData.h
//  Trvlogue
//
//  Created by Rohan Kapur on 24/3/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#define GOOGLE_API_KEY @""

#import <Foundation/Foundation.h>

#import <CoreLocation/CoreLocation.h>

#import "TVRSSItem.h"
#import "TVRSSChannel.h"

#import "TVFlight.h"

#import "TVPlacesQuerySuggestionsRetriever.h"

#import "ForecastKit.h"

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

- (void)travelDataUpdated:(TravelDataTypes *)dataType;

@end

@class TVFlight;

@interface TVTravelDataDownloader : NSObject <NSCoding, NSURLConnectionDelegate, NSURLConnectionDataDelegate, NSXMLParserDelegate, CLLocationManagerDelegate>
{
    /** RSS **/
    
    TVRSSItem *entry;
    NSURLConnection *connection;
    NSMutableData *xmlData;
    TVRSSChannel *channel;
    
    NSDictionary *newImageLocated;
}

@property (nonatomic, strong) NSDate *lastUpdated;

@property (nonatomic, strong) NSMutableDictionary *downloadedData;

@property (nonatomic, strong) id<TravelDataDelegate> delegate;

@property (nonatomic, strong) NSString *FlightID;

@property (nonatomic, strong) TVFlight *flight;

@property (nonatomic, strong) NSOperationQueue *operationQueue;

- (void)updateDownloadedData: (NSMutableDictionary *)_downloadedData;

- (id)initWithDelegate: (id<TravelDataDelegate>)delegate andFlightID: (NSString *)_FlightID;

- (void)fireDataDownload;

@end
