//
//  GooglePlacePhoto.h
//  Trvlogue
//
//  Created by Upi Kapur on 26/7/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TVGooglePlacePhoto : NSObject

@property (nonatomic, strong) NSString *appendingPath;

- (UIImage *)getPhoto;
- (void)writePhotoLocally:(UIImage *)photo atAppendingPath:(NSString *)path;

@end
