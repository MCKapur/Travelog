//
//  TVReviewCell.h
//  Trvlogue
//
//  Created by Rohan Kapur on 17/8/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "TVPlaceDetailViewController.h"

@protocol TVReviewCellDelegate <NSObject>

- (void)clickedAuthorButtonWithName:(NSString *)authorName andURL:(NSString *)authorURL;

@end

@interface TVReviewCell : UITableViewCell

@property (weak, nonatomic) id<TVReviewCellDelegate> delegate;

@property (weak, nonatomic) IBOutlet UILabel *authorName;
@property (weak, nonatomic) IBOutlet UITextView *reviewBodyTextView;

@property (strong, nonatomic) NSString *authorURL;

- (IBAction)clickedAuthor;

- (void)setStars:(float)rating;

@end
