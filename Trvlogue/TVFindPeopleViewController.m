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
        
        [self.table reloadData];
        [self.table setNeedsDisplay];
    }
    
    [self.table reloadData];
    [self.table setNeedsDisplay];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    
    if (self.isSearching) {
        
    }
    
    self.isSearching = NO;
    
    [searchBar resignFirstResponder];
    
    [self.table reloadData];
    [self.table setNeedsDisplay];
}

#pragma mark Table View

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
                        
            for (TVConnection *connection in [[[TVDatabase currentAccount] person] connections]) {

                if ([connection.senderId isEqualToString:[self.accounts[actionSheet.tag] userId]]) {

                    ((TVFindPeopleCell *)[table cellForRowAtIndexPath:[NSIndexPath indexPathForRow:actionSheet.tag inSection:0]]).followButton.userInteractionEnabled = NO;
                    
                    [TVLoadingSignifier signifyLoading:@"Accepting connection" duration:-1];
                    
                    [TVDatabase acceptConnection:connection withCompletionHandler:^(NSError *error, NSString *callCode, BOOL success) {
                        
                        [TVLoadingSignifier hideLoadingSignifier];
                        
                        ((TVFindPeopleCell *)[table cellForRowAtIndexPath:[NSIndexPath indexPathForRow:actionSheet.tag inSection:0]]).followButton.userInteractionEnabled = YES;

                        if (!error && success) {
                        }
                        else {
                            
                            [self handleError:error andType:callCode];
                        }

                        [self.table reloadData];
                        [self.table setNeedsDisplay];
                    }];
                }
            }
        }
        else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Decline"]) {
                        
            for (TVConnection *connection in [[[TVDatabase currentAccount] person] connections]) {
                
                if ([connection.senderId isEqualToString:[self.accounts[actionSheet.tag] userId]]) {
                    
                    ((TVFindPeopleCell *)[table cellForRowAtIndexPath:[NSIndexPath indexPathForRow:actionSheet.tag inSection:0]]).followButton.userInteractionEnabled = NO;
                    
                    [TVLoadingSignifier signifyLoading:@"Declining connection" duration:-1];
                    
                    [TVDatabase declineConnection:connection withCompletionHandler:^(NSError *error, NSString *callCode, BOOL success) {

                        [TVLoadingSignifier hideLoadingSignifier];
                        
                        ((TVFindPeopleCell *)[table cellForRowAtIndexPath:[NSIndexPath indexPathForRow:actionSheet.tag inSection:0]]).followButton.userInteractionEnabled = YES;

                        if (!error && success) {
                            
                            [self.accounts removeObject:self.accounts[actionSheet.tag]];
                        }
                        else {
                            
                            [self handleError:error andType:callCode];
                        }
                        
                        [self.table reloadData];
                        [self.table setNeedsDisplay];
                    }];
                }
            }
        }
    }
}

- (void)cell:(TVFindPeopleCell *)cell didTapFollowButton:(TVAccount *)account {
    
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
                        
                        [TVLoadingSignifier signifyLoading:@"Disconnecting with user" duration:-1];

                        [TVDatabase disconnectWithUserId:account.userId withCompletionHandler:^(NSError *error, NSString *callCode, BOOL success) {
                            
                            [self refreshSegments];
                            
                            [TVLoadingSignifier hideLoadingSignifier];

                            dispatch_async(dispatch_get_main_queue(), ^{
                                
                                for (int i = 0; i <= self.accounts.count - 1; i++) {
                                    
                                    if ([self.accounts[i] isEqual:cell.account]) {

                                        [self.table reloadData];
                                        [self.table setNeedsDisplay];
                                    }
                                }
                            });
                        }];
                    }
                }
            }
            else if ([connection.receiverId isEqualToString:account.userId]) {

                if (connection.status == (ConnectRequestStatus *)kConnectRequestAccepted) {

                    if ([cell.followButton.accessibilityIdentifier isEqualToString:@"Connect"]) {

                        cell.hasConnection = NO;
                        cell.followButton.selected = YES;
                        
                        [cell setAccessibilityIdentifier:nil];
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
                
                [TVLoadingSignifier signifyLoading:@"Disconnecting with user" duration:-1];
                
                [TVDatabase disconnectWithUserId:account.userId withCompletionHandler:^(NSError *error, NSString *callCode, BOOL success) {
                    
                    [self refreshSegments];

                    [TVLoadingSignifier hideLoadingSignifier];
                    
                    cell.followButton.userInteractionEnabled = YES;
                    
                    if (success && !error) {
                    }
                    else {
                        
                        cell.followButton.selected = YES;
                        
                        [self handleError:error andType:callCode];
                    }
                }];
            });
        }
        else {

            cell.followButton.selected = YES;
            
            cell.userInteractionEnabled = NO;
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, (unsigned)NULL), ^{
                
                [TVLoadingSignifier signifyLoading:@"Connecting with user" duration:-1];
                
                [TVDatabase connectWithUserId:account.userId withCompletionHandler:^(NSString *callCode, BOOL success) {
                    
                    [self refreshSegments];

                    [TVLoadingSignifier hideLoadingSignifier];
                    
                    cell.userInteractionEnabled = YES;
                    
                    if (success) {
                    }
                    else {
                        
                        cell.followButton.selected = NO;
                        
                        [self handleError:nil andType:callCode];
                    }
                }];
            });
        }
    }
    
    [self refreshSegments];
}

#pragma mark Finding Friends

- (void)downloadedUsers:(NSMutableArray *)objects {

    if (objects.count) {
                
        for (int i = 0; i <= objects.count - 1; i++) {
            
            if (![((PFUser *)objects[i]).objectId isEqualToString:[[TVDatabase currentAccount] userId]]) {

                [TVDatabase getAccountFromUser:objects[i] isPerformingCacheRefresh:NO withCompletionHandler:^(TVAccount *account, NSMutableArray *downloadedTypes) {

                    dispatch_async(dispatch_get_main_queue(), ^{

                        if (self.isSearching) {

                            if (self.searchedAccounts.count) {
                                                                    
                                int index = [self.searchedAccounts indexOfAccount:account];
                                
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
                                
                                int index = [self.accounts indexOfAccount:account];
                                
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
                        
                        [self refreshSegments];
                        
                        [self.table reloadData];
                        [self.table setNeedsDisplay];
                    });
                }];
            }
        }
    }
}

- (void)findPeople {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        [TVDatabase findUsersWithEmails:[self peopleEmails] withCompletionHandler:^(NSMutableArray *objects, NSError *error, NSString *callCode) {

            [self downloadedUsers:objects];
        }];

        [TVDatabase downloadUsersFromUserIds:[TVDatabase allUserConnections] withCompletionHandler:^(NSMutableArray *users, NSError *error, NSString *callCode) {

            [self downloadedUsers:users];
        }];
        
        if ([[TVDatabase currentAccount] isUsingLinkedIn]) {
            
            [LinkedInDataRetriever downloadConnectionsWithAccessToken:[[TVDatabase currentAccount] linkedInAccessKey] andCompletionHandler:^(NSArray *connections, BOOL success, NSError *error) {
                
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
}

- (NSMutableArray *)peopleEmails {
    
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    
    __block NSMutableArray *peopleEmails = [[NSMutableArray alloc] init];
    
    __block BOOL accessGranted = NO;
    
    if (ABAddressBookRequestAccessWithCompletion != NULL) {
        
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
            accessGranted = granted;
            dispatch_semaphore_signal(sema);
        });
        
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    }
    else {
        
        accessGranted = YES;
    }
    
    if (accessGranted) {
        
        CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeople(addressBook);
        CFIndex numberOfPeople = ABAddressBookGetPersonCount(addressBook);
        
        for (int i = 0; i < numberOfPeople; i++){
           
            ABRecordRef person = CFArrayGetValueAtIndex(allPeople, i);
            
            ABMultiValueRef emails = ABRecordCopyValue(person, kABPersonEmailProperty);

            for (CFIndex j = 0; j < ABMultiValueGetCount(emails); j++) {
                
                NSString *email = (__bridge NSString *)ABMultiValueCopyValueAtIndex(emails, j);

                if (![email isEqualToString:[[TVDatabase currentAccount] email]]) {
                    
                    [peopleEmails addObject:email];
                }
            }
        }
    }
    
    return peopleEmails;
}

#pragma mark Dirty, Funky, Native ^_^

- (id)init {
    
    self = [super init];
    
    if (self) {
        
        self.tabBarItem.title = @"People";
        self.tabBarItem.image = [UIImage imageNamed:@"people.png"];
        self.navigationItem.title = @"People";

        self.isSearching = NO;
        
        self.accounts = [[NSMutableArray alloc] init];
        
        self.filter = (FindPeopleFilter *)self.segmentedControl.selectedSegmentIndex;
        self.searchedAccounts = [[NSMutableArray alloc] init];

        [self findPeople];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(findPeople) name:NSNotificationReloadPeople object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(findPeople) name:NSNotificationDownloadedConnections object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(findPeople) name:NSNotificationReceivedConnectionRequest object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(findPeople) name:NSNotificationWroteProfilePicture object:nil];
    }
    
    return self;
}

- (void)refreshSegments {

    [self.segmentedControl setTitle:[[[NSString stringWithFormat:@"%i suggestions", [self.accounts filteredWith:kFindPeopleFilterSuggestions].count] stringByReplacingOccurrencesOfString:@"(0)" withString:@""] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]] forSegmentAtIndex:0];
    [self.segmentedControl setTitle:[[[NSString stringWithFormat:@"%i connections", [TVDatabase confirmedUserConnections].count]  stringByReplacingOccurrencesOfString:@"(0)" withString:@""] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]] forSegmentAtIndex:1];
    [self.segmentedControl setTitle:[[[NSString stringWithFormat:@"%i pending", [TVDatabase pendingUserConnections].count]  stringByReplacingOccurrencesOfString:@"(0)" withString:@""] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]] forSegmentAtIndex:2];
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
    
    [super viewDidLoad];
}

- (IBAction)changedSegment:(UISegmentedControl *)sender {
    
    self.filter = (FindPeopleFilter *)sender.selectedSegmentIndex;
    
    [self.table reloadData];
    [self.table setNeedsDisplay];
}

- (void)refreshConnections:(UIRefreshControl *)refreshControl {
    
    [refreshControl beginRefreshing];
    
    [TVDatabase findConnectionsFromId:[[TVDatabase currentAccount] userId] withCompletionHandler:^(NSMutableArray *objects, NSError *error, NSString *callCode) {
        
        [refreshControl endRefreshing];
        
        if (!error) {
            
            TVAccount *account = [TVDatabase currentAccount];
            
            [account.person.notifications clearNotificationOfType:kNotificationTypeConnectionRequest];
            
            for (TVConnection *connection in objects) {
                
                if (connection.status == kConnectRequestPending && [connection.receiverId isEqualToString:[[TVDatabase currentAccount] userId]]) {
                    
                    TVNotification *connectNotification = [[TVNotification alloc] initWithType:kNotificationTypeConnectionRequest withUserId:connection.senderId];
                    
                    [account.person.notifications addNotification:connectNotification];
                }
            }
            
            [account.person setConnections:objects];
            
            [TVDatabase updateMyCache:account];
            
            [self.table reloadData];
            [self.table setNeedsDisplay];
        }
    }];
}

@end