//
//  TravelData.m
//  Trvlogue
//
//  Created by Rohan Kapur on 24/3/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import "TVTravelDataDownloader.h"

#import "NSString+Soundex.h"

#import "DDCurrencyUnitConverter.h"

@implementation TVTravelDataDownloader

@synthesize downloadedData, delegate, operationQueue, FlightID, lastUpdated;

- (void)updateDownloadedData:(NSMutableDictionary *)_downloadedData {
    
    self.downloadedData = _downloadedData;
}

#pragma mark Error Handling

- (void)handleError:(NSError *)error andType:(NSString *)type {
    
    [TVErrorHandler handleError:[NSError errorWithDomain:[NSString stringWithFormat:@"Could not %@", type] code:200 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Could not %@", type]}]];
}

#pragma mark NSCoding

- (void)encodeWithCoder:(NSCoder *)aCoder {
    
    [aCoder encodeObject:self.downloadedData forKey:@"downloadedData"];
    [aCoder encodeObject:self.FlightID forKey:@"FlightID"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    
    self = [self init];
    
    if (self) {
        
        self.FlightID = [aDecoder decodeObjectForKey:@"FlightID"];
        self.downloadedData = [aDecoder decodeObjectForKey:@"downloadedData"];
    }
    
    return self;
}

#pragma mark Init

- (id)init {
    
    self = [super init];
    
    if (self) {
                
        self.downloadedData = [[NSMutableDictionary alloc] init];
        
        dispatch_queue_t downloadQueue = dispatch_queue_create("OperationQueue", NULL);
        
        dispatch_async(downloadQueue, ^{
            
            self.operationQueue = [[NSOperationQueue alloc] init];
        });
    }
    
    return self;
}

- (id)initWithDelegate:(id<TravelDataDelegate>)_delegate andFlightID:(NSString *)_FlightID {
    
    self = [self init];
    
    if (self) {
        
        self.delegate = _delegate;
        
        self.FlightID = _FlightID;
        
        self.flight = [TVDatabase flightFromID:self.FlightID];
    }
    
    return self;
}

- (void)fireDataDownload {
    
    self.lastUpdated = [NSDate date];
    self.downloadedData[@"lastUpdated"] = self.lastUpdated;
    
    if (![TVDatabase travelDataPacketWithID:self.FlightID]) {
        
        [TVDatabase addTravelDataPacketWithID:self.FlightID andTravelDataObject:self];
    }
    
    [self chainDataDownloads];
}

#pragma mark Data Download

- (void)chainDataDownloads {
    
    [self downloadNews];

    dispatch_queue_t downloadQueue = dispatch_queue_create("Download data", NULL);
    
    dispatch_async(downloadQueue, ^{

        [self downloadPeople];
        [self downloadLanguages];
        [self downloadPlugs];
        [self downloadCurrencies:1];
        [self downloadTimezone];
        [self downloadFacts];
        [self downloadWeather];
        [self downloadPlaces];
    });
}

#pragma mark Places

- (void)downloadPlaces {
}

#pragma mark People

- (void)downloadPeople {

    self.downloadedData[@"people"] = [[NSMutableArray alloc] init];

    [TVDatabase downloadConnectionsInTheSameCity:self.FlightID withCompletionHandler:^(NSMutableArray *objects, NSError *error, NSString *callCode) {
        
        if (!error) {

            if (![self.downloadedData[@"people"] containsObject:objects[0]]) {
                
                [self.downloadedData[@"people"] addObject:objects[0]];
                
                [TVDatabase refreshTravelDataPacketWithID:self.FlightID andTravelDataObject:self];
                
                [self.delegate travelDataUpdated:(TravelDataTypes *)kTravelDataPeople];
            }
        }
        else {
            
        }
    }];
}

#pragma mark Facts

- (void)downloadFacts {
    
    
}

#pragma mark (SUBMARK) Timezone

- (void)downloadTimezone {
    
    NSString *URLFormattedDestinationCity = [self.flight.destinationCity stringByReplacingOccurrencesOfString:@" " withString:@"+"];
    NSString *URLFormattedOriginCity = [self.flight.originCity stringByReplacingOccurrencesOfString:@" " withString:@"+"];
    
    NSString *destinationTimezoneURLString = @"http://www.worldweatheronline.com/feed/tz.ashx";
    NSString *originTimezoneURLString = @"http://www.worldweatheronline.com/feed/tz.ashx";
    
    destinationTimezoneURLString = [destinationTimezoneURLString stringByAppendingFormat:@"?key=%@&q=%@&format=json", WORLD_WEATHER_API_KEY, URLFormattedDestinationCity];
    
    originTimezoneURLString = [originTimezoneURLString stringByAppendingFormat:@"?key=%@&q=%@&format=json", WORLD_WEATHER_API_KEY, URLFormattedOriginCity];
    
    NSURL *destinationTimezoneRequestURL = [NSURL URLWithString:destinationTimezoneURLString];
    NSURLRequest *destinationTimezoneRequest = [NSURLRequest requestWithURL:destinationTimezoneRequestURL];
    
    NSURL *originTimezoneRequestURL = [NSURL URLWithString:originTimezoneURLString];
    NSURLRequest *originTimezoneRequest = [NSURLRequest requestWithURL:originTimezoneRequestURL];
    
    __block NSDictionary *destinationTimezone = [[NSDictionary alloc] init];
    __block NSDictionary *originTimezone = [[NSDictionary alloc] init];
    
    [NSURLConnection sendAsynchronousRequest:originTimezoneRequest queue:self.operationQueue completionHandler:^(NSURLResponse *responseURL, NSData *responseData, NSError *error) {
        
        [NSURLConnection sendAsynchronousRequest:destinationTimezoneRequest queue:self.operationQueue completionHandler:^(NSURLResponse *responseURL2, NSData *responseData2, NSError *error2) {

            if (!error && !error2) {
                
                destinationTimezone = [self deserialize:responseData2];
                originTimezone = [self deserialize:responseData];
                
                if ([originTimezone[@"data"][@"time_zone"] lastObject][@"utcOffset"]) {
                    
                    NSString *utcOffsetString = [NSString stringWithFormat:@"%+.1f", [[destinationTimezone[@"data"][@"time_zone"] lastObject][@"utcOffset"] doubleValue]];
                    
                    if ([originTimezone[@"data"][@"time_zone"]  lastObject][@"utcOffset"]) {
                        
                        NSNumber *offsetFromCurrentTZ = @([[destinationTimezone[@"data"][@"time_zone"] lastObject][@"utcOffset"] floatValue]-[[originTimezone[@"data"][@"time_zone"] lastObject][@"utcOffset"] floatValue]);
                        
                        NSString *currentOffsetString = [NSString stringWithFormat:@"%+.1f", [offsetFromCurrentTZ doubleValue]];
                        
                        NSMutableDictionary *timezone = [[NSMutableDictionary alloc] init];
                        
                        timezone[@"utfOffset"] = utcOffsetString;
                        timezone[@"currentOffsetString"] = currentOffsetString;
                        
                        self.downloadedData[@"timezone"] = timezone;
                        
                        [TVDatabase refreshTravelDataPacketWithID:self.FlightID andTravelDataObject:self];
                        
                        [self.delegate travelDataUpdated:(TravelDataTypes *)kTravelDataTimezone];
                    }
                }
            }
        }];
    }];
}

#pragma mark (SUBMARK) Currencies

- (void)downloadCurrencies:(int)amountToConvert {
    
    NSMutableDictionary *currency = [[NSMutableDictionary alloc] init];
    
    NSString *URLFormattedCountry = [self.flight.originCountry stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    URLFormattedCountry = [URLFormattedCountry lowercaseString];
    
    NSString *requestURL = [NSString stringWithFormat:@"https://www.googleapis.com/freebase/v1/mqlread?query=%%7B%%22type%%22:%%22/location/country%%22,%%22id%%22:%%22/en/%@%%22,%%22currency_used%%22:%%5B%%5D%%7D", URLFormattedCountry];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:requestURL]];
    
    __block NSString *originCurrency;
    __block NSString *destinationCurrency;

    [NSURLConnection sendAsynchronousRequest:request queue:self.operationQueue completionHandler:^(NSURLResponse *urlResponse, NSData *responseData, NSError *error) {

        if (!error) {
            
            NSDictionary *result = [self deserialize:responseData][@"result"];

            if (result && ![result isEqual:[NSNull null]]) {
                
                originCurrency = (result[@"currency_used"])[0];
                
                if (originCurrency) {
                    
                    NSString *URLFormattedCountry = [self.flight.destinationCountry stringByReplacingOccurrencesOfString:@" " withString:@"_"];
                    URLFormattedCountry = [URLFormattedCountry lowercaseString];
                    
                    NSString *requestString = [NSString stringWithFormat:@"https://www.googleapis.com/freebase/v1/mqlread?query=%%7B%%22type%%22:%%22/location/country%%22,%%22id%%22:%%22/en/%@%%22,%%22currency_used%%22:%%5B%%5D%%7D", URLFormattedCountry];
                    
                    NSString *requestURL = requestString;
                    
                    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:requestURL]];

                    [NSURLConnection sendAsynchronousRequest:request queue:self.operationQueue completionHandler:^(NSURLResponse *urlResponse, NSData *responseData, NSError *error) {
                        
                        if (!error) {
                            
                            NSDictionary *result = [self deserialize:responseData][@"result"];
                            
                            if (result && ![result isEqual:[NSNull null]]) {
                                
                                destinationCurrency = (result[@"currency_used"])[0];
                                
                                if (destinationCurrency) {
                                    
                                    (currency)[@"destinationCurrency"] = destinationCurrency;
                                    
                                    if (originCurrency) {

                                        if (![originCurrency isEqualToString:destinationCurrency]) {
                                            
                                            (currency)[@"originCurrency"] = originCurrency;
                                            
                                            self.downloadedData[@"currency"] = currency;

                                            if ([self hasDDUnit:originCurrency] && [self hasDDUnit:destinationCurrency]) {
                                                
                                                (currency)[@"o->d"] = @([self currencyConversionWithKey:@"o->d" withAmount:amountToConvert]);
                                                (currency)[@"d->o"] = @([self currencyConversionWithKey:@"d->o" withAmount:amountToConvert]);

                                                self.downloadedData[@"currency"] = currency;
                                                                                                
                                                [TVDatabase refreshTravelDataPacketWithID:self.FlightID andTravelDataObject:self];
                                                
                                                [self.delegate travelDataUpdated:(TravelDataTypes *)kTravelDataCurrency];
                                            }
                                            else if (![self hasDDUnit:originCurrency] && ![self hasDDUnit:destinationCurrency]) {
                                                
                                                self.downloadedData[@"currency"] = currency;
                                                                                                
                                                [TVDatabase refreshTravelDataPacketWithID:self.FlightID andTravelDataObject:self];
                                                
                                                [self.delegate travelDataUpdated:(TravelDataTypes *)kTravelDataCurrency];
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }];
                }
            }
        }
    }];
}

- (BOOL)hasDDUnit:(NSString *)currencyName {
    
    BOOL retVal = NO;
    
    for (NSString *DDUnitName in [self DDUnitNames]) {
        
        if ([[self DDUnitCurrencyVersion:currencyName] soundsLikeString:DDUnitName]) {
            
            retVal = YES;
            
            break;
        }
    }
    
    return retVal;
}

- (int)DDUnitVersion:(NSString *)currencyName {
    
    int retVal = -1;
    
    for (NSString *DDUnitName in [self DDUnitNames]) {
        
        if ([[self DDUnitCurrencyVersion:currencyName] soundsLikeString:DDUnitName]) {
            
            retVal = [[self DDUnitNames] indexOfObject:DDUnitName];
            
            break;
        }
    }
    
    return retVal;
}

- (NSString *)DDUnitCurrencyVersion:(NSString *)currencyName {
    
    if ([currencyName rangeOfString:@"UK" options:NSCaseInsensitiveSearch].location != NSNotFound) {
        
        currencyName = @"U.K. Pound Sterling";
    }
    
    if ([currencyName rangeOfString:@"Polish" options:NSCaseInsensitiveSearch].location != NSNotFound) {
        
        currencyName = @"Polish Zloty";
    }
    
    if ([currencyName rangeOfString:@"United States" options:NSCaseInsensitiveSearch].location != NSNotFound) {
        
        currencyName = @"U.S. Dollar";
    }
    
    if ([currencyName rangeOfString:@"Bahraini" options:NSCaseInsensitiveSearch].location != NSNotFound) {
        
        currencyName = @"Bahrain Dinar";
    }
    
    if ([currencyName rangeOfString:@"Renminbi" options:NSCaseInsensitiveSearch].location != NSNotFound) {
        
        currencyName = @"Chinese Yuan";
    }
    
    if ([currencyName rangeOfString:@"Korean Won" options:NSCaseInsensitiveSearch].location != NSNotFound) {
        
        currencyName = @"Korean Won";
    }
    
    if ([currencyName rangeOfString:@"Oman Real" options:NSCaseInsensitiveSearch].location != NSNotFound) {
        
        currencyName = @"Rial Omani";
    }
    
    if ([currencyName rangeOfString:@"Peruvian Nuevo Sol" options:NSCaseInsensitiveSearch].location != NSNotFound) {
        
        currencyName = @"Nuevo Sol";
    }
    
    if ([currencyName rangeOfString:@"Saudi Riyal" options:NSCaseInsensitiveSearch].location != NSNotFound) {
        
        currencyName = @"Saudi Arabian Riyal";
    }
    
    if ([currencyName rangeOfString:@"United Arab Emirates dirham" options:NSCaseInsensitiveSearch].location != NSNotFound) {
        
        currencyName = @"U.A.E. Dirham";
    }
    
    if ([currencyName rangeOfString:@"Uruguayan peso" options:NSCaseInsensitiveSearch].location != NSNotFound) {
        
        currencyName = @"Peso Uruguayo";
    }
    
    if ([currencyName rangeOfString:@"Venezuelan" options:NSCaseInsensitiveSearch].location != NSNotFound) {
        
        currencyName = @"Bolivar Fuerte";
    }
    
    return currencyName;
}

- (double)currencyConversionWithKey:(NSString *)key withAmount:(int)amount {
    
    NSMutableDictionary *currency = self.downloadedData[@"currency"];
    
    double retVal = 0;
    
    DDCurrencyUnit originUnit = [self DDUnitVersion:(currency)[@"originCurrency"]];
    DDCurrencyUnit destinationUnit = [self DDUnitVersion:(currency)[@"destinationCurrency"]];
    
    DDUnitConverter *converter = [DDUnitConverter currencyUnitConverter];
    
    if ([key isEqual:@"o->d"]) {
        
        retVal = [[converter convertNumber:[NSNumber numberWithDouble:amount] fromUnit:originUnit toUnit:destinationUnit] doubleValue];
    }
    else {
        
        retVal = [[converter convertNumber:[NSNumber numberWithDouble:amount] fromUnit:destinationUnit toUnit:originUnit] doubleValue];
    }
    
    return retVal;
}

- (NSArray *)DDUnitNames {
    
    return @[@"Euro",
             @"Japanese Yen",
             @"U.K. Pound Sterling",
             @"U.S. Dollar",
             @"Algerian Dinar",
             @"Argentine Peso",
             @"Australian Dollar",
             @"Bahrain Dinar",
             @"Botswana Pula",
             @"Brazilian Real",
             @"Brunei Dollar",
             @"Canadian Dollar",
             @"Chilean Peso",
             @"Chinese Yuan",
             @"Colombian Peso",
             @"Czech Koruna",
             @"Danish Krone",
             @"Hungarian Forint",
             @"Icelandic Krona",
             @"Indian Rupee",
             @"Indonesian Rupiah",
             @"Iranian Rial",
             @"Israeli New Sheqel",
             @"Kazakhstani Tenge",
             @"Korean Won",
             @"Kuwaiti Dinar",
             @"Libyan Dinar",
             @"Malaysian Ringgit",
             @"Mauritian Rupee",
             @"Mexican Peso",
             @"Nepalese Rupee",
             @"New Zealand Dollar",
             @"Norwegian Krone",
             @"Rial Omani",
             @"Pakistani Rupee",
             @"Nuevo Sol",
             @"Philippine Peso",
             @"Polish Zloty",
             @"Qatar Riyal",
             @"Russian Ruble",
             @"Saudi Arabian Riyal",
             @"Singapore Dollar",
             @"South African Rand",
             @"Sri Lanka Rupee",
             @"Swedish Krona",
             @"Swiss Franc",
             @"Thai Baht",
             @"Trinidad And Tobago Dollar",
             @"Tunisian Dinar",
             @"U.A.E. Dirham",
             @"Peso Uruguayo",
             @"Bolivar Fuerte",
             @"SDR"];
}

#pragma mark (SUBMARK) Plugs

- (void)downloadPlugs {
    
    NSMutableDictionary *plugs = [[NSMutableDictionary alloc] init];
    
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"PlugList" ofType:@"plist"];
    NSArray *plugArray = [[NSArray alloc] initWithContentsOfFile:plistPath];
    
    for (NSDictionary *plug in plugArray) {
        
        NSString *comments = plug[@"Comments"];
        
        NSString *freq = plug[@"Frequency"];
        freq = [freq stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        freq = [freq stringByReplacingOccurrencesOfString:@"\t" withString:@""];
        
        NSString *plugTypes = plug[@"Plugs"];
        plugTypes = [plugTypes stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        plugTypes = [plugTypes stringByReplacingOccurrencesOfString:@"\t" withString:@""];
        
        NSString *voltage = plug[@"Voltage"];
        voltage = [voltage stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        voltage = [voltage stringByReplacingOccurrencesOfString:@"\t" withString:@""];
        
        NSString *plistCountry = plug[@"Country"];
        
        if ([plistCountry isEqualToString:@"United States of America"]) {
            
            plistCountry = @"United States";
        }
        
        plistCountry = [plistCountry stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        plistCountry = [plistCountry stringByReplacingOccurrencesOfString:@"\t" withString:@""];
        
        if ([plistCountry soundsLikeString:self.flight.destinationCountry]) {
            
            if (!([self.flight.destinationCountry isEqualToString:@"Romania"] && [plistCountry isEqualToString:@"Reunion"])) {
                
                if ([plistCountry length]) {
                    
                    (plugs)[@"country"] = plistCountry;
                }
                
                if ([freq length]) {
                    
                    (plugs)[@"frequency"] = freq;
                }
                
                if ([voltage length]) {
                    
                    (plugs)[@"voltage"] = voltage;
                }
                
                if ([plugTypes length]) {
                    
                    NSString *chars = [plugTypes stringByReplacingOccurrencesOfString:@", " withString:@""];
                    
                    chars = [chars stringByReplacingOccurrencesOfString:@" " withString:@""];
                    
                    NSArray *plugImageArray = [self analyzingTextAndRetrievingImageSetsWithChars:chars andComments:comments];
                    NSArray *images = [self crackDownOnImagesArray:plugImageArray];
                    
                    NSNumber *number = @(images.count);
                    
                    (plugs)[@"numberOfPlugs"] = number;
                    
                    plugTypes = [plugTypes stringByReplacingOccurrencesOfString:@"+" withString:@" "];
                    
                    (plugs)[@"plugs"] = plugTypes;
                    
                    (plugs)[@"images"] = images;
                }
            }
        }
    }
    
    if ([plugs count]) {
        
        self.downloadedData[@"plugs"] = plugs;
                
        [TVDatabase refreshTravelDataPacketWithID:self.FlightID andTravelDataObject:self];
        
        [self.delegate travelDataUpdated:(TravelDataTypes *)kTravelDataPlug];
    }
}

- (NSArray *)crackDownOnImagesArray:(NSArray *)plugsAlgorithmed {
    
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    
    for (NSDictionary *d in plugsAlgorithmed) {
        
        NSMutableDictionary *bigD = [[NSMutableDictionary alloc] init];
        
        NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"ImagesList" ofType:@"plist"];
        
        NSArray *imageStringArray = [[NSArray alloc] initWithContentsOfFile:plistPath];
        
        NSString *retrievedImage;
        NSString *commentsImage;
        NSString *countryImage;
        
        NSMutableArray *obviousImage = [[NSMutableArray alloc] init];
        
        for (NSString *imageString in imageStringArray) {
            
            if (d[@"possibleImageContainersFromRetrieval"]) {
                
                if ([imageString rangeOfString:d[@"possibleImageContainersFromRetrieval"]].location != NSNotFound) {
                    
                    retrievedImage = imageString;
                }
            }
            
            if (d[@"possibleImageContainersFromComments"]) {
                
                if ([imageString rangeOfString:d[@"possibleImageContainersFromComments"]].location != NSNotFound) {
                    
                    commentsImage = imageString;
                }
            }
            
            if (d[@"possibleImageStringFromCountry"]) {
                
                if ([imageString rangeOfString:d[@"possibleImageStringFromCountry"]].location != NSNotFound) {
                    
                    countryImage = imageString;
                }
            }
            
            if (d[@"possibleImageStringsObvious"]) {
                
                for (NSString *string in d[@"possibleImageStringsObvious"]) {
                    
                    if ([imageString rangeOfString:string].location != NSNotFound) {
                        
                        [obviousImage addObject:imageString];
                    }
                }
            }
        }
        
        NSString *masterImage;
        
        if (retrievedImage) {
            
            masterImage = retrievedImage;
        }
        
        if (countryImage) {
            
            masterImage = countryImage;
        }
        
        if (commentsImage) {
            
            masterImage = commentsImage;
        }
        
        if (!masterImage) {
            
            if (obviousImage.count) {
                
                NSSortDescriptor *sortOrder = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
                
                NSArray *sortedArray = [obviousImage sortedArrayUsingDescriptors:@[sortOrder]];
                
                masterImage = sortedArray[0];
            }
        }
        
        bigD[d[@"letter"]] = masterImage;
        
        [arr addObject:bigD];
    }
    
    if (newImageLocated) {
        
        [arr addObject:newImageLocated];
    }
    
    return arr;
}

- (NSMutableArray *)analyzingTextAndRetrievingImageSetsWithChars:(NSString *)chars andComments:(NSString *)comments {
    
    NSMutableArray *newpa;
    
    NSString *characters = [self flatten:chars];
    
    NSMutableArray *pairedLetterDicts = [[NSMutableArray alloc] init];
    
    if ([characters rangeOfString:@"IEC+60906-1"].location != NSNotFound) {
        
        NSRange range = [chars rangeOfString:@"IEC+60906-1" options:NSBackwardsSearch range:NSMakeRange(0, characters.length)];
        
        if ([characters length] >= range.location) {
            
            characters = [characters substringToIndex:range.location];
        }
    }
    
    for (int i = 0; i <= characters.length - 1; i++) {
        
        NSString *singleLetter = [NSString stringWithFormat:@"%c",[characters characterAtIndex:i]];
        
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        
        dict[@"letter"] = singleLetter;
        
        [pairedLetterDicts addObject:dict];
    }
    
    newpa = [pairedLetterDicts mutableCopy];
    
    for (NSMutableDictionary *d in pairedLetterDicts) {
        
        NSString *letter = d[@"letter"];
        
        [newpa removeObjectIdenticalTo:d];
        
        if ([chars rangeOfString:@"(IEC+60906-2)"].location != NSNotFound) {
            
            NSRange range = [chars rangeOfString:@"(IEC+60906-2)" options:NSBackwardsSearch range:NSMakeRange(0, chars.length)];
            
            NSString *pairedLetter = [NSString stringWithFormat:@"%c", [chars characterAtIndex:range.location - 1]];
            
            if ([pairedLetter isEqualToString:letter]) {
                
                NSString *parenthesisCantDefeatMe = [self getpars:chars];
                
                d[@"possibleImageContainersFromRetrieval"] = parenthesisCantDefeatMe;
            }
        }
        
        if (comments.length) {
            
            if ([comments rangeOfString:@"CEE 7/17"].location != NSNotFound) {
                
                NSString *extractingFromComments = @"C--CEE+7:17";
                
                if ([letter isEqualToString:@"C"]) {
                    
                    d[@"possibleImageContainersFromComments"] = extractingFromComments;
                }
            }
            
            if ([comments rangeOfString:@"CEE 7/16"].location != NSNotFound) {
                
                NSString *extractingFromComments = @"C--CEE+7:16";
                
                if ([letter isEqualToString:@"C"]) {
                    
                    d[@"possibleImageContainersFromComments"] = extractingFromComments;
                }
            }
            
            if ([comments rangeOfString:@"Type E sockets are standard, earthed appliances ship with an E+F plug"].location != NSNotFound) {
                
                NSString *extractingFromComments = @"E+F";
                
                if ([letter isEqualToString:@"E"]) {
                    
                    d[@"possibleImageContainersFromComments"] = extractingFromComments;
                }
            }
            
            if ([comments rangeOfString:@"all devices since early 1990's sold with E+F plug"].location != NSNotFound) {
                
                NSString *extractingFromComments = @"E+F";
                
                if ([letter isEqualToString:@"E"] || [letter isEqualToString:@"F"]) {
                    
                    d[@"possibleImageContainersFromComments"] = extractingFromComments;
                }
            }
        }
        
        if ([chars rangeOfString:@"IEC+60906-1"].location != NSNotFound) {
            
            newImageLocated = @{@"IEC+60906-1":@"IEC+60906-1.jpg"};
        }
        
        NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"ImagesList" ofType:@"plist"];
        
        NSArray *imageStringArray = [[NSArray alloc] initWithContentsOfFile:plistPath];
        
        NSMutableArray *obviousImageArray = [[NSMutableArray alloc] init];
        
        for (NSString *imageString in imageStringArray) {
            
            if ([imageString rangeOfString:self.flight.destinationCountry].location != NSNotFound) {
                
                NSString *containingCountryImage = imageString;
                
                NSString *charr = [NSString stringWithFormat:@"%c", [imageString characterAtIndex:0]];
                
                if ([letter isEqualToString:charr]) {
                    
                    d[@"possibleImageStringFromCountry"] = containingCountryImage;
                }
            }
            
            NSString *charr = [NSString stringWithFormat:@"%c", [imageString characterAtIndex:0]];
            
            if ([charr isEqualToString:letter]) {
                
                [obviousImageArray addObject:imageString];
                
                
                d[@"possibleImageStringsObvious"] = obviousImageArray;
                
                if (comments.length && [letter isEqualToString:@"C"]) {
                    
                    if ([comments rangeOfString:@"Type C (round)"].location != NSNotFound) {
                        
                        [obviousImageArray removeAllObjects];
                        
                        [obviousImageArray addObject:@"C--CEE+7:17.jpg"];
                        
                        d[@"possibleImageStringsObvious"] = obviousImageArray;
                    }
                }
            }
        }
        
        [newpa addObject:d];
    }
    
    pairedLetterDicts = newpa;
    
    return pairedLetterDicts;
}

- (NSString *)getpars:(NSString *)stringToFlatten {
    
    NSScanner *theScanner;
    NSString *text = nil;
    theScanner = [NSScanner scannerWithString:stringToFlatten];
    
    while ([theScanner isAtEnd] == NO) {
        
        [theScanner scanUpToString:@"(" intoString:NULL] ;
        
        [theScanner scanUpToString:@")" intoString:&text] ;
        
    }
    
    if (text) {
        
        text = [text stringByReplacingOccurrencesOfString:@" " withString:@"+"];
    }
    
    text = [text stringByReplacingOccurrencesOfString:@"(" withString:@""];
    text = [text stringByReplacingOccurrencesOfString:@")" withString:@""];
    
    return text;
}


- (NSString *)flatten:(NSString *)instruction {
    
    NSScanner *theScanner;
    NSString *text = nil;
    theScanner = [NSScanner scannerWithString:instruction];
    
    while ([theScanner isAtEnd] == NO) {
        
        [theScanner scanUpToString:@"(" intoString:NULL] ;
        
        [theScanner scanUpToString:@")" intoString:&text] ;
        
        instruction = [instruction stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@)", text] withString:@""];
    }
    //
    instruction = [instruction stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    return instruction;
}

#pragma mark (SUBMARK) Language / Translations

- (void)downloadLanguages {
    
    NSMutableArray *languages = [[NSMutableArray alloc] init];
    
    NSString *URLFormattedCity = [self.flight.destinationCountry stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    
    URLFormattedCity = [URLFormattedCity lowercaseString];
    
    NSString *string = [NSString stringWithFormat:@"https://www.googleapis.com/freebase/v1/mqlread?query=%%7B%%22type%%22:%%22/location/country%%22,%%22id%%22:%%22/en/%@%%22,%%22official_language%%22:%%5B%%5D%%7D", URLFormattedCity];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:string]];
    
    __block NSMutableArray *languagesTemporaryArray;
    
    [NSURLConnection sendAsynchronousRequest:request queue:self.operationQueue completionHandler:^(NSURLResponse *urlResponse, NSData *responseData, NSError *responseError) {
        
        if ((responseError == nil && [responseError code] == noErr)) {
            
            if (responseData) {
                
                NSDictionary *result = [self deserialize:responseData][@"result"];
                
                if (![result isEqual:[NSNull null]] && result) {
                    
                    languagesTemporaryArray = [[self deserialize:responseData][@"result"][@"official_language"] mutableCopy];
                    
                    if (languagesTemporaryArray.count && ![languagesTemporaryArray containsObject:@"English Language"]) {
                        
                        for (NSString *languageName in languagesTemporaryArray) {
                            
                            [languages addObject:[NSMutableDictionary dictionaryWithObject:languageName forKey:@"name"]];
                        }
                        
                        self.downloadedData[@"languages"] = languages;
                        
                        [self downloadTranslations];
                    }
                }
            }
        }
    }];
}

- (void)downloadTranslations {
    
    NSMutableArray *languages = [self.downloadedData[@"languages"] mutableCopy];
    
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"PreTranslation" ofType:@"plist"];
    
    NSDictionary *phrases = [[NSDictionary alloc] initWithContentsOfFile:plistPath];
    
    if ([languages count]) {
        
        for (int i = 0; i <= languages.count - 1; i++) {
            
            NSMutableDictionary *language = languages[i];
            
            NSString *name = language[@"name"];
            name = [name stringByReplacingOccurrencesOfString:@" language" withString:@""];
            name = [name stringByReplacingOccurrencesOfString:@" Language" withString:@""];
            
            NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"TranslatingLanguageCodes" ofType:@"plist"];
            
            NSDictionary *codesArray = [[NSDictionary alloc] initWithContentsOfFile:plistPath];
            
            for (NSString *code_lang in [codesArray allKeys]) {
                
                NSString *code = codesArray[code_lang];
                
                for (NSString *component in [name componentsSeparatedByString:@" "]) {
                    
                    if ([component soundsLikeString:code_lang]) {
                        
                        languages[i][@"name"] = component;
                        
                        NSMutableArray *allPhrases = [[NSMutableArray alloc] init];
                        
                        for (NSString *key in [phrases allKeys]) {
                            
                            [allPhrases addObjectsFromArray:phrases[key]];
                        }
                        
                        NSMutableArray *translations = [[NSMutableArray alloc] init];
                        
                        int phraseNumber = 0;
                        
                        for (__strong NSString *phrase in allPhrases) {
                            
                            phraseNumber++;
                            
                            phrase = [phrase stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
                            
                            NSString *URLFormattedString = [NSString stringWithFormat:@"https://www.googleapis.com/language/translate/v2?key=%@&q=%@&source=en&target=%@&format=text&prettyprint=true", GOOGLE_API_KEY, phrase, code];
                            
                            NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:URLFormattedString]];
                            
                            [NSURLConnection sendAsynchronousRequest:request queue:self.operationQueue completionHandler:^(NSURLResponse *urlResponse, NSData *responseData, NSError *responseError) {
                                
                                if (!responseError) {
                                    
                                    NSDictionary *json = [self deserialize:responseData];
                                    
                                    if (json) {
                                        
                                        NSString *translatedText = json[@"data"][@"translations"][0][@"translatedText"];
                                        
                                        if (translatedText.length) {
                                            
                                            [translations addObject:@{@"phrase":phrase, @"translation":translatedText}];
                                        }
                                    }
                                }
                                
                                if (phraseNumber == allPhrases.count && i == languages.count - 1) {
                                    
                                    if (translations.count) {
                                        
                                        (languages[i])[@"translations"] = translations;
                                    }
                                    
                                    self.downloadedData[@"languages"] = languages;
                                                                        
                                    [TVDatabase refreshTravelDataPacketWithID:self.FlightID andTravelDataObject:self];
                                    
                                    [self.delegate travelDataUpdated:(TravelDataTypes *)kTravelDataLanguagesSpoken];
                                }
                            }];
                        }
                        
                        break;
                    }
                    else {
                        
                    }
                }
            }
        }
    }
}

#pragma mark (SUBMARK) News

- (void)downloadNews {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self fetchEntries:[self.flight.destinationCity stringByReplacingOccurrencesOfString:@" " withString:@"+"]];
    });
}

- (void)fetchEntries:(NSString *)URLFormattedCity {
    
    // Create a new data container for the stuff that comes back from the service
    xmlData = [[NSMutableData alloc] init];
    
    NSString *linkFormatted = [NSString stringWithFormat:@"https://news.google.com/news/section?pz=1&cf=all&geo=%@&output=rss", URLFormattedCity];

    // Construct a URL that will ask the service for what you want -
    // note we can concatenate literal strings together on multiple
    // lines in this way - this results in a single NSString instance
    NSURL *url = [NSURL URLWithString:linkFormatted];
    
    // Put that URL into an NSURLRequest
    NSURLRequest *req = [NSURLRequest requestWithURL:url];
        
    // Create a connection that will exchange this request for data from the URL
    connection = [[NSURLConnection alloc] initWithRequest:req delegate:self startImmediately:YES];
}

#pragma mark (SUBMARK) RSS Parser

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {

    channel = [[TVRSSChannel alloc] init];
    
    [channel setParentParserDelegate:self];
    
    [parser setDelegate:channel];
}

#pragma mark (SUBMARK) NSURLConnection

- (void)connection:(NSURLConnection *)conn didReceiveData:(NSData *)data {

    [xmlData appendData:data];
}

- (void)connection:(NSURLConnection *)conn didFailWithError:(NSError *)error {

    connection = nil;
    xmlData = nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)conn {

    NSMutableArray *news = nil;
    
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:xmlData];
    [parser setDelegate:self];
    
    [parser parse];
    
    xmlData = nil;
    connection = nil;
    
    news = [channel items];

    if ([news count]) {
        
        self.downloadedData[@"news"] = news;
                
        [TVDatabase refreshTravelDataPacketWithID:self.FlightID andTravelDataObject:self];
        
        [self.delegate travelDataUpdated:(TravelDataTypes *)kTravelDataCurrentNews];
    }
}

#pragma mark Weather

- (void)downloadWeather {

    __block NSMutableArray *filteredWeather = [[NSMutableArray alloc] init];

    NSString *urlFormattedDestination = [self.flight.destinationCity stringByReplacingOccurrencesOfString:@" " withString:@"+"];
    
    NSString *weatherRequestString = @"http://free.worldweatheronline.com/feed/weather.ashx";
    
    weatherRequestString = [weatherRequestString stringByAppendingFormat:@"?key=%@&q=%@&num_of_days=%i&format=json", WORLD_WEATHER_API_KEY, urlFormattedDestination, 5];

    NSURL *weatherRequestURL = [NSURL URLWithString:weatherRequestString];
    NSURLRequest *weatherRequest = [NSURLRequest requestWithURL:weatherRequestURL];
    
    __block NSMutableDictionary *weatherForecast = [[NSMutableDictionary alloc] init];
    
    [NSURLConnection sendAsynchronousRequest:weatherRequest queue:self.operationQueue completionHandler:^(NSURLResponse *urlResponse, NSData *responseData, NSError *responseError) {
        
        if ((responseError == nil && [responseError code] == noErr)) {
            
            if (responseData != nil) {
                
                NSError *error = nil;

                weatherForecast = [self deserialize:responseData];
                
                if (!error && !weatherForecast[@"data"][@"error"] && weatherForecast[@"data"][@"weather"]) {
                    
                    for (int i = 0; i <= [weatherForecast[@"data"][@"weather"] count] - 1; i++) {

                        NSMutableDictionary *day = [weatherForecast[@"data"][@"weather"][i] mutableCopy];

                        UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[day[@"weatherIconUrl"] lastObject][@"value"]]]];
                        
                        if (image) {
                            
                            NSString *pngPath = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/WeatherIcon_%i.png", i]];
                            [UIImagePNGRepresentation(image) writeToFile:pngPath atomically:YES];
                            
                            day[@"imageFilePath"] = pngPath;
                        }

                        [filteredWeather addObject:day];
                    }
                }
            }
        }
        else {
        }
        
        if ([filteredWeather count]) {

            self.downloadedData[@"weather"] = filteredWeather;
                        
            [TVDatabase refreshTravelDataPacketWithID:self.FlightID andTravelDataObject:self];
            
            [self.delegate travelDataUpdated:(TravelDataTypes *)kTravelDataWeather];
        }
    }];
}

#pragma mark Operational Methods

- (NSMutableDictionary *)deserialize:(NSData *)data {
    
    return [[NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil] mutableCopy];
}

@end