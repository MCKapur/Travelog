//
//  PAPFindFriendsCell.h
//  Anypic
//
//  Created by Mattieu Gamache-Asselin on 5/31/12.
//

#import "TVAccount.h"

@protocol TravelogFindPeopleCellDelegate;

@interface TVFindPeopleCell : UITableViewCell {
    id _delegate;
}

@property (nonatomic, strong) id<TravelogFindPeopleCellDelegate> delegate;

/*! The user represented in the cell */
@property (nonatomic, strong) TVAccount *account;

/*! Presenting user data */
@property (nonatomic, strong) IBOutlet UILabel *jobLabel;
@property (nonatomic, strong) IBOutlet UIButton *followButton;
@property (nonatomic, strong) IBOutlet UILabel *nameLabel;

@property (nonatomic, strong) IBOutlet UIButton *avatarImageButton;
@property (nonatomic, strong) IBOutlet UIImageView *avatarImageView;

@property (nonatomic) BOOL hasConnection;

/*! Setters for the cell's content */
- (void)setAccount:(TVAccount *)account;

- (void)didTapFollowButtonAction:(id)sender;

/*! Static Helper methods */
+ (CGFloat)heightForCell;

@end

/*!
 The protocol defines methods a delegate of a PAPBaseTextCell should implement.
 */
@protocol TravelogFindPeopleCellDelegate <NSObject>
@optional

/*!
 Sent to the delegate when a user button is tapped
 @param aUser the PFUser of the user that was tapped
 */
- (void)cell:(TVFindPeopleCell *)cellView didTapFollowButton:(TVAccount *)account;

@end
