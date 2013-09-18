//
//  PAPFindFriendsCell.m
//  Anypic
//
//  Created by Mattieu Gamache-Asselin on 5/31/12.
//

#import "TVFindPeopleCell.h"

@implementation TVFindPeopleCell
@synthesize delegate;
@synthesize account;
@synthesize avatarImageView;
@synthesize avatarImageButton;
@synthesize nameLabel;
@synthesize jobLabel;
@synthesize followButton;
@synthesize hasConnection;

#pragma mark - NSObject

- (id)initWithCoder:(NSCoder *)aDecoder {
    
    self = [super initWithCoder:aDecoder];
    
    if (self) {
    
        [self setSelectionStyle:UITableViewCellSelectionStyleNone];

        self.hasConnection = NO;
    }
    
    return self;
}

#pragma mark - TrvlogueFindFriendsCell

- (void)setAccount:(TVAccount *)_account {
    
    [self.followButton addTarget:self action:@selector(didTapFollowButtonAction:) forControlEvents:UIControlEventTouchUpInside];

    account = _account;
    
    TVPerson *person = [self.account person];

    // Configure the cell
    [self.avatarImageView setImage:[TVDatabase locateProfilePictureOnDiskWithUserId:self.account.userId]];
    
    self.avatarImageView.layer.cornerRadius = 7.0f;
    self.avatarImageView.layer.masksToBounds = YES;
    
    // Set name
    [nameLabel setText:person.name];
    
    // Set miles number label
    [self.jobLabel setText:person.position];
    
    // Set follow button
    [followButton setFrame:CGRectMake(208.0f, 20.0f, 103.0f, 32.0f)];

    for (TVConnection *connection in [TVDatabase currentAccount].person.connections) {
        
        if ([connection.senderId isEqualToString:self.account.userId]) {
            
            self.hasConnection = YES;
            
            if (connection.status == kConnectRequestPending) {
                
                self.followButton.titleLabel.textColor = [UIColor brownColor];
                [self.followButton setTitle:@"Respond" forState:UIControlStateNormal]; // space added for centering
                
                [self.followButton setAccessibilityIdentifier:@"Respond"];
            }
            else if (connection.status == (ConnectRequestStatus *)kConnectRequestAccepted) {

                self.followButton.titleLabel.textColor = [UIColor colorWithRed:58.0f/255.0f green:191.0f/255.0f blue:79.0f/255.0f alpha:1.0f];
                [self.followButton setTitle:@"Connected" forState:UIControlStateNormal];
                
                [self.followButton setAccessibilityIdentifier:@"Connect"];
            }
        }
        else if ([connection.receiverId isEqualToString:self.account.userId]) {

            if (connection.status == (ConnectRequestStatus *)kConnectRequestPending) {

                self.hasConnection = NO;

                [self.followButton setSelected:YES];
            }
            else if (connection.status == (ConnectRequestStatus *)kConnectRequestAccepted) {
                
                self.hasConnection = YES;

                self.followButton.titleLabel.textColor = [UIColor colorWithRed:58.0f/255.0f green:191.0f/255.0f blue:79.0f/255.0f alpha:1.0f];
                [self.followButton setTitle:@"Connected" forState:UIControlStateNormal];

                [self.followButton setAccessibilityIdentifier:@"Connect"];
            }
        }
    }
    
    if (!self.hasConnection) {

        [self.followButton setTitle:@"Connect" forState:UIControlStateNormal]; // space added for centering
        [self.followButton setTitle:@"Sent" forState:UIControlStateSelected];
    }
}

#pragma mark - ()

+ (CGFloat)heightForCell {
    return 77.0f;
}

/* Inform delegate that the follow button was tapped */
- (void)didTapFollowButtonAction:(id)sender {

    if (self.delegate && [self.delegate respondsToSelector:@selector(cell:didTapFollowButton:)]) {

        [self.delegate cell:self didTapFollowButton:self.account];
    }        
}

@end
