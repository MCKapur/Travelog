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
        
        [self.followButton setTitle:@"" forState:UIControlStateNormal];
    }
    
    return self;
}

#pragma mark - TrvlogueFindFriendsCell

- (void)setAccount:(TVAccount *)_account {
    
    [self.followButton setTitle:@"" forState:UIControlStateNormal];
   
    [self.followButton addTarget:self action:@selector(didTapFollowButtonAction:) forControlEvents:UIControlEventTouchUpInside];

    account = _account;
    
    TVPerson *person = [self.account person];

    // Configure the cell
    [self.avatarImageView setImage:[TVDatabase locateProfilePictureOnDiskWithUserId:self.account.userId]];
    
    self.avatarImageView.layer.cornerRadius = 7.0f;
    self.avatarImageView.layer.masksToBounds = YES;
    
    // Set name
    [self.nameLabel setText:person.name];
    
    // Set miles number label
    [self.jobLabel setText:person.position];
    
    // Set follow button
    [self.followButton setFrame:CGRectMake(208.0f, 20.0f, 103.0f, 32.0f)];

    UIColor *textColor = self.followButton.titleLabel.textColor;
    NSString *text = self.followButton.titleLabel.text;
    NSString *accessibilityIdentifier = self.followButton.accessibilityIdentifier;
    BOOL selected = self.followButton.selected;

    for (TVConnection *connection in [TVDatabase currentAccount].person.connections) {
        
        if ([connection.senderId isEqualToString:self.account.userId]) {
            
            self.hasConnection = YES;
            
            if (connection.status == kConnectRequestPending) {

                textColor = [UIColor brownColor];
                text = @"Respond";
                
                accessibilityIdentifier = @"Respond";
            }
            else if (connection.status == (ConnectRequestStatus *)kConnectRequestAccepted) {

                textColor = [UIColor colorWithRed:58.0f/255.0f green:191.0f/255.0f blue:79.0f/255.0f alpha:1.0f];
                text = @"Connected";
                
                accessibilityIdentifier = @"Connect";
            }
        }
        else if ([connection.receiverId isEqualToString:self.account.userId]) {

            if (connection.status == (ConnectRequestStatus *)kConnectRequestPending) {
                
                self.hasConnection = NO;

                selected = YES;
            }
            else if (connection.status == (ConnectRequestStatus *)kConnectRequestAccepted) {
                
                self.hasConnection = YES;

                textColor = [UIColor colorWithRed:58.0f/255.0f green:191.0f/255.0f blue:79.0f/255.0f alpha:1.0f];
                text = @"Connected";

                accessibilityIdentifier = @"Connect";
            }
        }
    }
    
    if (!self.hasConnection) {

        [self.followButton setSelected:selected];
        text = @"Connect";
        [self.followButton setTitle:text forState:UIControlStateNormal];
        [self.followButton setTitle:@"Sent" forState:UIControlStateSelected];
        [self.followButton.titleLabel setTextColor:textColor];
        [self.followButton setAccessibilityIdentifier:accessibilityIdentifier];
    }
    else {

        [self.followButton setSelected:selected];
        [self.followButton setTitle:text forState:UIControlStateNormal];
        [self.followButton.titleLabel setTextColor:textColor];
        [self.followButton setAccessibilityIdentifier:accessibilityIdentifier];
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
