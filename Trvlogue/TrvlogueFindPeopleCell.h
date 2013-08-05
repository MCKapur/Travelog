//
//  PAPFindFriendsCell.h
//  Anypic
//
//  Created by Mattieu Gamache-Asselin on 5/31/12.
//

#import "TrvlogueAccount.h"

@protocol TrvlogueFindPeopleCellDelegate;

@interface TrvlogueFindPeopleCell : UITableViewCell {
    id _delegate;
}

@property (nonatomic, strong) id<TrvlogueFindPeopleCellDelegate> delegate;

/*! The user represented in the cell */
@property (nonatomic, strong) PFUser *user;
@property (nonatomic, strong) UILabel *milesLabel;
@property (nonatomic, strong) UIButton *followButton;

@property (nonatomic) BOOL hasConnection;

@property (nonatomic, strong) Person *person;

/*! Setters for the cell's content */
- (void)setUser:(PFUser *)user;

- (void)didTapUserButtonAction:(id)sender;
- (void)didTapFollowButtonAction:(id)sender;

/*! Static Helper methods */
+ (CGFloat)heightForCell;

@end

/*!
 The protocol defines methods a delegate of a PAPBaseTextCell should implement.
 */
@protocol TrvlogueFindPeopleCellDelegate <NSObject>
@optional

/*!
 Sent to the delegate when a user button is tapped
 @param aUser the PFUser of the user that was tapped
 */
- (void)cell:(TrvlogueFindPeopleCell *)cellView didTapUserButton:(PFUser *)aUser;
- (void)cell:(TrvlogueFindPeopleCell *)cellView didTapFollowButton:(PFUser *)aUser;

@end
