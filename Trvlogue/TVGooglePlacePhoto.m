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
    
    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/%@", self.appendingPath]];
    
    return [UIImage imageWithContentsOfFile:path];
}

- (void)writePhotoLocally:(UIImage *)photo atAppendingPath:(NSString *)path {

    NSString *imgPath = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/%@", path]];
    
    self.appendingPath = path;
    
    [UIImageJPEGRepresentation(photo, 1.0) writeToFile:imgPath atomically:NO];
}

@end
