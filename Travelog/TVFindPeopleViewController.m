//
//  TrvlogueFindPeopleViewController.m
//  Trvlogue
//
//  Created by Rohan Kapur on 24/5/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import "TVFindPeopleViewController.h"

@interface NSMutableArray (Filter)

- (NSMutableArray *)filteredWith:(FindPeopleFilter *)filter;

@end

@implementation NSMutableArray (Filter)

- (NSMutableArray *)filteredWith:(FindPeopleFilter *)filter {

    NSMutableArray *retVal = [[NSMutableArray alloc] init];
    
    for (TVAccount *account in self) {
        
        if (filter == (FindPeopleFilter *)kFindPeopleFilterConnections) {
            
            if ([[TVDatabase confirmedUserConnections] containsObject:account.userId]) {
                
                [retVal addObject:account];
            }
        }
        else if (filter == (FindPeopleFilter *)kFindPeopleFilterPending) {

            if ([[TVDatabase pendingUserConnections] containsObject:account.userId]) {
                
                [retVal addObject:account];
            }
        }
        else if (filter == (FindPeopleFilter *)kFindPeopleFilterSuggestions) {
            
            if (![[TVDatabase allUserConnections] containsObject:account.userId]) {
                
                [retVal addObject:account];
            }
        }
    }
    
    return retVal;
}

@end

@implementation TVFindPeopleViewController
@synthesize table, accounts, searchedAccounts, filter, isSearching;

- (void)setIsSearching:(BOOL)_isSearching {
    
    isSearching = _isSearching;
    
    if (self.isSearching == NO) {
        
        self.filter = (FindPeopleFilter *)self.segmentedControl.selectedSegmentIndex;
    }
}

#pragma mark UIGestureRecognizerDelegate methods

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([touch.view.class isEqual:[UITableView class]]) {
        
        return NO;
    }
    
    return YES;
}

#pragma mark Handling Events

- (void)handleError:(NSError *)error andType:(NSString *)type {
    
    [TVErrorHandler handleError:[NSError errorWithDomain:[NSString stringWithFormat:@"Could not %@", type] code:200 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Could not %@", type]}]];
}

#pragma mark Search Bar

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {

    [searchBar resignFirstResponder];
    
    if (searchBar.text.length) {
        
        [self.searchedAccounts removeAllObjects];
        
        self.isSearching = YES;
        
        if ([searchBar.text rangeOfString:@"@"].location != NSNotFound) {
            
            [TVDatabase findUsersWithEmails:[[NSArray arrayWithObject:[searchBar.text stringByReplacingOccurrencesOfString:@" " withString:@""]] mutableCopy] withCompletionHandler:^(NSMutableArray *objects, NSError *error, NSString *callCode) {
                
                [self downloadedUsers:objects];

                if (!error && objects.count) {
                }
                else {
                    
                    [self handleError:error andType:callCode];
                }
            }];
        }
        else {

            [TVDatabase findUsersWithName:searchBar.text withCompletionHandler:^(NSMutableArray *objects, NSError *error, NSString *callCode) {

                [self downloadedUsers:objects];
            }];
        }
    }
    else {
        
        self.isSearching = NO;
        
        [searchBar resignFirstResponder];
    }
    
    [self reloadTableViews];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    
    if (self.isSearching) {
        
    }
    
    self.isSearching = NO;
    
    [searchBar resignFirstResponder];
    
    [self reloadTableViews];
}

#pragma mark Table View

- (void)reloadTableViews {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self.table reloadData];
        [self.table setNeedsDisplay];
    });
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return !isSearching ? [[self.accounts filteredWith:self.filter] count] : self.searchedAccounts.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return [TVFindPeopleCell heightForCell];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"PeopleCell";
    
    TVFindPeopleCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        
        cell.delegate = nil;
        cell.account = nil;
        
        NSArray *views = [[NSBundle mainBundle] loadNibNamed:@"TVFindPeopleCell" owner:self options:nil];
        
        for (UIView *view in views) {
            
            if ([view isKindOfClass:[UITableViewCell class]])
            {
                cell = (TVFindPeopleCell *)view;
            }
        }
    }
    
    [cell setDelegate:self];
    
    [cell setAccount:(!isSearching ? [self.accounts filteredWith:self.filter] : self.searchedAccounts)[indexPath.row]];
    
    cell.tag = indexPath.row;
    
    return cell;
}

#pragma mark Cell Delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (![[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Cancel"]) {
        
        if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Accept"]) {
            
            TVConnection *connectionToAccept = nil;
            
            for (TVConnection *connection in [[[TVDatabase currentAccount] person] connections]) {

                if ([connection.senderId isEqualToString:[self.accounts[actionSheet.tag] userId]]) {
                    
                    connectionToAccept = connection;
                }
            }
            
            if (connectionToAccept) {
                
                ((TVFindPeopleCell *)[table cellForRowAtIndexPath:[NSIndexPath indexPathForRow:actionSheet.tag inSection:0]]).followButton.userInteractionEnabled = NO;
                
                [TVLoadingSignifier signifyLoading:@"Accepting connection" duration:-1];
                
                [TVDatabase acceptConnection:connectionToAccept withCompletionHandler:^(NSError *error, NSString *callCode, BOOL success) {
                    
                    [TVLoadingSignifier hideLoadingSignifier];
                    
                    ((TVFindPeopleCell *)[table cellForRowAtIndexPath:[NSIndexPath indexPathForRow:actionSheet.tag inSection:0]]).followButton.userInteractionEnabled = YES;
                    
                    if (!error && success) {
                    }
                    else {
                        
                        [self handleError:error andType:callCode];
                    }
                    
                    [self reloadTableViews];
                }];
            }
        }
        else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Decline"]) {
            
            TVConnection *connectionToDisconnect = nil;
            
            for (TVConnection *connection in [[[TVDatabase currentAccount] person] connections]) {
                
                if ([connection.senderId isEqualToString:[self.accounts[actionSheet.tag] userId]]) {
                    
                    connectionToDisconnect = connection;
                }
            }
            
            ((TVFindPeopleCell *)[table cellForRowAtIndexPath:[NSIndexPath indexPathForRow:actionSheet.tag inSection:0]]).followButton.userInteractionEnabled = NO;
            
            [TVLoadingSignifier signifyLoading:@"Declining connection" duration:-1];
            
            [TVDatabase declineConnection:connectionToDisconnect withCompletionHandler:^(NSError *error, NSString *callCode, BOOL success) {
                
                [TVLoadingSignifier hideLoadingSignifier];
                
                ((TVFindPeopleCell *)[table cellForRowAtIndexPath:[NSIndexPath indexPathForRow:actionSheet.tag inSection:0]]).followButton.userInteractionEnabled = YES;
                
                if (!error && success) {
                    
                    [self.accounts removeObject:self.accounts[actionSheet.tag]];
                }
                else {
                    
                    [self handleError:error andType:callCode];
                }
                
                [self reloadTableViews];
            }];
        }
    }
}

- (void)cell:(TVFindPeopleCell *)cell didTapFollowButton:(TVAccount *)account {

    NSInteger decision = 0;

    BOOL shouldDisconnect = NO;
    
    if (cell.hasConnection) {
        
        for (TVConnection *connection in [[[TVDatabase currentAccount] person] connections]) {
            
            if ([connection.senderId isEqualToString:account.userId]) {
                
                if (connection.status == kConnectRequestPending) {
                    
                    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Accept", @"Decline", nil];
                    [actionSheet setTag:[self.accounts indexOfAccount:account]];
                    [actionSheet showInView:self.view];
                }
                else if (connection.status == (ConnectRequestStatus *)kConnectRequestAccepted) {
                    
                    if ([cell.followButton.accessibilityIdentifier isEqualToString:@"Connect"]) {
                        
                        shouldDisconnect = YES;
                    }
                }
            }
            else if ([connection.receiverId isEqualToString:account.userId]) {
                
                if (connection.status == (ConnectRequestStatus *)kConnectRequestAccepted) {
                    
                    if ([cell.followButton.accessibilityIdentifier isEqualToString:@"Connect"]) {
                        
                        cell.hasConnection = NO;
                        cell.followButton.selected = YES;
                        
                        [cell setAccessibilityIdentifier:nil];
                        
                        shouldDisconnect = YES;
                    }
                }
            }
        }
    }
    else {

        if ([cell.followButton isSelected]) {

            cell.followButton.selected = NO;
            
            cell.followButton.userInteractionEnabled = NO;
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, (unsigned)NULL), ^{
                
                dispatch_async(dispatch_get_main_queue(), ^{

                    [TVLoadingSignifier signifyLoading:@"Disconnecting with user" duration:-1];
                });
                
                [TVDatabase disconnectWithUserId:account.userId withCompletionHandler:^(NSError *error, NSString *callCode, BOOL success) {
                
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        [self refreshSegments];
                        
                        [self reloadTableViews];
                        
                        [TVLoadingSignifier hideLoadingSignifier];
                        
                        cell.followButton.userInteractionEnabled = YES;
                        
                        if (success && !error) {
                        }
                        else {
                            
                            cell.followButton.selected = YES;
                            
                            [self handleError:error andType:callCode];
                        }
                    });
                }];
            });
        }
        else {

            cell.followButton.selected = YES;
            
            cell.userInteractionEnabled = NO;
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, (unsigned)NULL), ^{
                
                dispatch_async(dispatch_get_main_queue(), ^{

                    [TVLoadingSignifier signifyLoading:@"Connecting with user" duration:-1];
                });
                
                [TVDatabase connectWithUserId:account.userId withCompletionHandler:^(NSString *callCode, BOOL success) {
                    
                    dispatch_async(dispatch_get_main_queue(), ^{

                        [self refreshSegments];

                        [self reloadTableViews];
                        
                        [TVLoadingSignifier hideLoadingSignifier];
                    
                        cell.userInteractionEnabled = YES;
                    
                        if (success) {
                        }
                        else {
                        
                            cell.followButton.selected = NO;
                        
                            [self handleError:nil andType:callCode];
                        }
                    });
                }];
            });
        }
    }

    if (shouldDisconnect) {
        
        [TVLoadingSignifier signifyLoading:@"Disconnecting with user" duration:-1];
        
        [TVDatabase disconnectWithUserId:account.userId withCompletionHandler:^(NSError *error, NSString *callCode, BOOL success) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [TVLoadingSignifier hideLoadingSignifier];
                
                [self refreshSegments];
                
                [self reloadTableViews];
            });
        }];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self reloadTableViews];
        
        [self refreshSegments];
    });
}

#pragma mark Finding Friends

- (void)downloadedUsers:(NSMutableArray *)objects {

    if (objects.count) {
                
        for (NSInteger i = 0; i <= objects.count - 1; i++) {
            
            if (![((PFUser *)objects[i]).objectId isEqualToString:[[TVDatabase currentAccount] userId]]) {

                [TVDatabase getAccountFromUser:objects[i] isPerformingCacheRefresh:NO withCompletionHandler:^(TVAccount *account, NSMutableArray *downloadedTypes) {

                    dispatch_async(dispatch_get_main_queue(), ^{

                        if (self.isSearching) {

                            if (self.searchedAccounts.count) {
                                                                    
                                NSInteger index = [self.searchedAccounts indexOfAccount:account];
                                
                                if (index != NSNotFound) {
                                    
                                    (self.searchedAccounts)[index] = account;
                                }
                                else {
                                    
                                    [self.searchedAccounts addObject:account];
                                }
                            }
                            else {
                                
                                [self.searchedAccounts addObject:account];
                            }
                        }
                        else {

                            if (self.accounts.count) {
                                
                                NSInteger index = [self.accounts indexOfAccount:account];
                                
                                if (index != NSNotFound) {
                                    
                                    (self.accounts)[index] = account;
                                }
                                else {
                                    
                                    [self.accounts addObject:account];
                                }
                            }
                            else {
                                
                                [self.accounts addObject:account];
                            }
                        }
                        
                        [self reloadTableViews];
                    });
                }];
            }
        }
    }
}

- (void)findPeople {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        if (((TVAppDelegate *)[UIApplication sharedApplication].delegate).emails) {

            [TVDatabase findUsersWithEmails:((TVAppDelegate *)[UIApplication sharedApplication].delegate).emails withCompletionHandler:^(NSMutableArray *objects, NSError *error, NSString *callCode) {
                
                [self downloadedUsers:objects];
            }];
        }
        else {

        }

        [TVDatabase downloadUsersFromUserIds:[TVDatabase allUserConnections] withCompletionHandler:^(NSMutableArray *users, NSError *error, NSString *callCode) {

            [self downloadedUsers:users];
        }];
        
        if ([[TVDatabase currentAccount] isUsingLinkedIn] && [TVDatabase localLinkedInRequestToken]) {
            
            [LinkedInDataRetriever downloadConnectionsWithAccessToken:[TVDatabase localLinkedInRequestToken] andCompletionHandler:^(NSArray *connections, BOOL success, NSError *error) {
                
                if (!error && success && connections.count) {
                    
                    NSMutableArray *linkedInIds = [[NSMutableArray alloc] init];
                    
                    for (NSDictionary *connection in connections) {
                        
                        [linkedInIds addObject:connection[@"id"]];
                    } 
                    
                    [TVDatabase findUsersWithLinkedInIds:linkedInIds withCompletionHandler:^(NSMutableArray *objects, NSError *error, NSString *callCode) {
                        
                        [self downloadedUsers:objects];
                    }];
                }
            }];
        }
    });
    
    [self refreshSegments];
}

#pragma mark Dirty, Funky, Native ^_^

- (void)updateNotifications {
    
    NSInteger numberOfConnectRequestNotifications = 0;
    
    for (TVNotification *notification in [[[TVDatabase currentAccount] person] notifications]) {
        
        if (notification.type == (NotificationType *)kNotificationTypeConnectionRequest) {
            
            numberOfConnectRequestNotifications++;
        }
    }
  
    if (numberOfConnectRequestNotifications) {
        
        [self.tabBarItem setBadgeValue:[NSString stringWithFormat:@"%i", numberOfConnectRequestNotifications]];

    }
    else {
        
        [self.tabBarItem setBadgeValue:0];
    }
}

- (id)init {
    
    self = [super init];
    
    if (self) {
        
        self.tabBarItem.title = @"Connections";
        self.tabBarItem.image = [UIImage imageNamed:@"people.png"];
        self.navigationItem.title = @"Connections";
        
        [self updateNotifications];

        self.isSearching = NO;
        
        self.accounts = [[NSMutableArray alloc] init];
        
        self.filter = (FindPeopleFilter *)self.segmentedControl.selectedSegmentIndex;
        self.searchedAccounts = [[NSMutableArray alloc] init];

        [self findPeople];
        
        dispatch_async(dispatch_get_main_queue(), ^{

            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateNotifications) name:NSNotificationUpdateNotifications object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(findPeople) name:NSNotificationDownloadedConnections object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(findPeople) name:NSNotificationReceivedConnectionRequest object:nil];
        });
    }
    
    return self;
}

- (void)refreshSegments {
    
    dispatch_async(dispatch_get_main_queue(), ^{

        [self.segmentedControl setTitle:[[[NSString stringWithFormat:@"%i suggestions", [self.accounts filteredWith:kFindPeopleFilterSuggestions].count] stringByReplacingOccurrencesOfString:@"(0)" withString:@""] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]] forSegmentAtIndex:1];
        [self.segmentedControl setTitle:[[[NSString stringWithFormat:@"%i connections", [TVDatabase confirmedUserConnections].count]  stringByReplacingOccurrencesOfString:@"(0)" withString:@""] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]] forSegmentAtIndex:0];
        [self.segmentedControl setTitle:[[[NSString stringWithFormat:@"%i pending", [TVDatabase pendingUserConnections].count]  stringByReplacingOccurrencesOfString:@"(0)" withString:@""] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]] forSegmentAtIndex:2];
    });
}

- (void)viewWillAppear:(BOOL)animated {
    
    [self refreshSegments];
    
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    
    [self.searchBar resignFirstResponder];
}

- (void)viewDidLoad {
    
    for (UIView *v in [[[self.segmentedControl subviews] objectAtIndex:0] subviews]) {
        
        if ([v isKindOfClass:[UILabel class]]) {
            
            UILabel *label = (UILabel *)v;
            
            label.textColor = [UIColor blackColor];
        }
    }

    for (UIView *subview in self.searchBar.subviews)
    {
        if ([subview isKindOfClass:NSClassFromString(@"UISearchBarBackground")])
            subview.alpha = 0.0;
    }
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refreshConnections:) forControlEvents:UIControlEventValueChanged];
    [self.table addSubview:refreshControl];
    
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(touchedView)];
    [self.view addGestureRecognizer:gestureRecognizer];
    
    [super viewDidLoad];
}

- (void)touchedView {
    
    for (UIView *view in self.view.subviews){
        
        if ([view isKindOfClass:[UITextField class]] && [view isFirstResponder]) {
            
            [view resignFirstResponder];
        }
    }
}

- (IBAction)changedSegment:(UISegmentedControl *)sender {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        self.filter = (FindPeopleFilter *)sender.selectedSegmentIndex;
        
        [self reloadTableViews];
    });
}

- (void)refreshConnections:(UIRefreshControl *)refreshControl {
    
    [refreshControl beginRefreshing];
    [refreshControl endRefreshing];
    
    [self findPeople];
}

@end