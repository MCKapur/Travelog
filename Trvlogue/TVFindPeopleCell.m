//
//  PAPFindFriendsCell.m
//  Anypic
//
//  Created by Mattieu Gamache-Asselin on 5/31/12.
//

#import "TVFindPeopleCell.h"

@interface TVFindPeopleCell ()
/*! The cell's views. These shouldn't be modified but need to be exposed for the subclass */
@property (nonatomic, strong) UIButton *nameButton;
@property (nonatomic, strong) UIButton *avatarImageButton;
@property (nonatomic, strong) UIImageView *avatarImageView;

@end


@implementation TVFindPeopleCell
@synthesize delegate;
@synthesize user;
@synthesize avatarImageView;
@synthesize avatarImageButton;
@synthesize nameButton;
@synthesize milesLabel;
@synthesize followButton;
@synthesize person;
@synthesize hasConnection;

#pragma mark - NSObject

- (id)initWithCoder:(NSCoder *)aDecoder {
    
    self = [super initWithCoder:aDecoder];
    
    if (self) {
    
        [self setSelectionStyle:UITableViewCellSelectionStyleNone];
                
        self.contentView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"backgroundFindFriendsCell.png"]];
        
        self.avatarImageView = [[UIImageView alloc] init];
        [self.avatarImageView setFrame:CGRectMake(10.0f, 7.0f, 53.0f, 53.0f)];
        [self.contentView addSubview:self.avatarImageView];
        
        self.avatarImageButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.avatarImageButton setBackgroundColor:[UIColor clearColor]];
        [self.avatarImageButton setFrame:CGRectMake(10.0f, 7.0f, 53.0f, 53.0f)];
        [self.avatarImageButton addTarget:self action:@selector(didTapUserButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:self.avatarImageButton];
        
        self.nameButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.nameButton setBackgroundColor:[UIColor clearColor]];
        [self.nameButton.titleLabel setFont:[UIFont boldSystemFontOfSize:16.0f]];
        [self.nameButton.titleLabel setLineBreakMode:NSLineBreakByTruncatingTail];
        [self.nameButton setTitleColor:[UIColor colorWithRed:87.0f/255.0f green:72.0f/255.0f blue:49.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
        [self.nameButton setTitleColor:[UIColor colorWithRed:134.0f/255.0f green:100.0f/255.0f blue:65.0f/255.0f alpha:1.0f] forState:UIControlStateHighlighted];
        [self.nameButton setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.nameButton setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateSelected];
        [self.nameButton.titleLabel setShadowOffset:CGSizeMake(0.0f, 1.0f)];
        [self.nameButton addTarget:self action:@selector(didTapUserButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:self.nameButton];
        
        self.milesLabel = [[UILabel alloc] init];
        [self.milesLabel setFont:[UIFont systemFontOfSize:13.0f]];
        [self.milesLabel setTextColor:[UIColor grayColor]];
        [self.milesLabel setBackgroundColor:[UIColor clearColor]];
        [self.milesLabel setShadowColor:[UIColor colorWithWhite:1.0f alpha:0.700f]];
        [self.milesLabel setShadowOffset:CGSizeMake(0.0f, 1.0f)];
        [self.contentView addSubview:self.milesLabel];
        
        self.followButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.followButton.titleLabel setFont:[UIFont boldSystemFontOfSize:15.0f]];
        [self.followButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0f, 10.0f, 0.0f, 0.0f)];
        [self.followButton.titleLabel setShadowOffset:CGSizeMake(0.0f, -1.0f)];
        [self.contentView addSubview:self.followButton];
        [self.followButton addTarget:self action:@selector(didTapFollowButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        
        self.hasConnection = NO;
    }
    
    return self;
}

#pragma mark - TrvlogueFindFriendsCell

- (void)setUser:(PFUser *)aUser {
    
    user = aUser;

    NSNumberFormatter *milesFormatter = [[NSNumberFormatter alloc] init];
    [milesFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    milesFormatter.maximumFractionDigits = 0;
    
    NSString *formattedMiles = [milesFormatter stringFromNumber:@(person.miles)];
    formattedMiles = [formattedMiles stringByReplacingOccurrencesOfString:@"," withString:@", "];

    // Configure the cell
    [avatarImageView setImage:[person getProfilePic]];
    
    self.avatarImageView.layer.cornerRadius = 7.0f;
    self.avatarImageView.layer.masksToBounds = YES;
    
    // Set name
    NSString *nameString = [person name];
    CGSize nameSize = [nameString sizeWithFont:[UIFont boldSystemFontOfSize:16.0f] forWidth:144.0f lineBreakMode:NSLineBreakByTruncatingTail];
    [nameButton setTitle:nameString forState:UIControlStateNormal];
    [nameButton setTitle:nameString forState:UIControlStateHighlighted];
    [nameButton setFrame:CGRectMake(70.0f, 17.0f, nameSize.width, nameSize.height)];
    
    // Set miles number label
    CGSize photoLabelSize = [@"miles" sizeWithFont:[UIFont systemFontOfSize:11.0f] forWidth:144.0f lineBreakMode:NSLineBreakByTruncatingTail];
    [milesLabel setFrame:CGRectMake(70.0f, 17.0f + nameSize.height, 140.0f, photoLabelSize.height)];
    [milesLabel setText:[NSString stringWithFormat:@"%@ miles", formattedMiles]];
    
    // Set follow button
    [followButton setFrame:CGRectMake(208.0f, 20.0f, 103.0f, 32.0f)];

    for (TVConnection *connection in [TVDatabase currentAccount].person.connections) {
        
        if ([connection.senderId isEqualToString:user.objectId]) {
            
            self.hasConnection = YES;
            
            if (connection.status == kConnectRequestPending) {
                
                [self.followButton setTitle:@"Respond  " forState:UIControlStateNormal]; // space added for centering
                [self.followButton setBackgroundImage:[UIImage imageNamed:@"buttonFollow.png"] forState:UIControlStateNormal];
                
                [self.followButton setAccessibilityIdentifier:@"Respond"];
            }
            else if (connection.status == (ConnectRequestStatus *)kConnectRequestAccepted) {

                [self.followButton setTitle:@"Connect  " forState:UIControlStateNormal];
                [self.followButton setBackgroundImage:[UIImage imageNamed:@"buttonFollowing.png"] forState:UIControlStateNormal];
                [self.followButton setImage:[UIImage imageNamed:@"iconTick.png"] forState:UIControlStateNormal];
                
                [self.followButton setAccessibilityIdentifier:@"Connect"];
            }
        }
        else if ([connection.receiverId isEqualToString:user.objectId]) {

            if (connection.status == (ConnectRequestStatus *)kConnectRequestPending) {

                self.hasConnection = NO;

                [self.followButton setSelected:YES];
            }
            else if (connection.status == (ConnectRequestStatus *)kConnectRequestAccepted) {
                
                self.hasConnection = YES;

                [self.followButton setTitle:@"Connect  " forState:UIControlStateNormal];

                [self.followButton setBackgroundImage:[UIImage imageNamed:@"buttonFollowing.png"] forState:UIControlStateNormal];
                [self.followButton setImage:[UIImage imageNamed:@"iconTick.png"] forState:UIControlStateNormal];
                [self.followButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                [self.followButton setTitleShadowColor:[UIColor blackColor] forState:UIControlStateSelected];

                [self.followButton setAccessibilityIdentifier:@"Connect"];
            }
        }
    }
    
    if (!self.hasConnection) {

        [self.followButton setBackgroundImage:[UIImage imageNamed:@"buttonFollow.png"] forState:UIControlStateNormal];
        [self.followButton setBackgroundImage:[UIImage imageNamed:@"buttonFollowing.png"] forState:UIControlStateSelected];
        [self.followButton setImage:[UIImage imageNamed:@"iconTick.png"] forState:UIControlStateSelected];
        [self.followButton setTitle:@"Connect  " forState:UIControlStateNormal]; // space added for centering
        [self.followButton setTitle:@"Sent  " forState:UIControlStateSelected];
        [self.followButton setTitleColor:[UIColor colorWithRed:84.0f/255.0f green:57.0f/255.0f blue:45.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
        [self.followButton setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        [self.followButton setTitleShadowColor:[UIColor colorWithRed:232.0f/255.0f green:203.0f/255.0f blue:168.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
        [self.followButton setTitleShadowColor:[UIColor blackColor] forState:UIControlStateSelected];
    }
}

#pragma mark - ()

+ (CGFloat)heightForCell {
    return 77.0f;
}

/* Inform delegate that a user image or name was tapped */
- (void)didTapUserButtonAction:(id)sender {
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(cell:didTapUserButton:)]) {
    
        [self.delegate cell:self didTapUserButton:self.user];
    }    
}

/* Inform delegate that the follow button was tapped */
- (void)didTapFollowButtonAction:(id)sender {
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(cell:didTapFollowButton:)]) {
        
        [self.delegate cell:self didTapFollowButton:self.user];
    }        
}

@end
