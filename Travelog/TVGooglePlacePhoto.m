//
//  GooglePlacePhoto.m
//  Trvlogue
//
//  Created by Upi Kapur on 26/7/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import "TVGooglePlacePhoto.h"

@implementation TVGooglePlacePhoto
@synthesize appendingPath;

- (UIImage *)getPhoto {
    
    return [[EGOCache globalCache] imageForKey:self.appendingPath];
}

- (void)writePhotoLocally:(UIImage *)photo atAppendingPath:(NSString *)path {
    
    self.appendingPath = path;
    
    [[EGOCache globalCache] setImage:photo forKey:self.appendingPath];
}

@end
