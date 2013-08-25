//
//  TrvlogueFindPeopleViewController.m
//  Trvlogue
//
//  Created by Rohan Kapur on 24/5/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import "TVFindPeopleViewController.h"

static int expectedOperations;

@implementation TVFindPeopleViewController
@synthesize table, people, filter;

#pragma mark Handling Events

- (void)handleError:(NSError *)error andType:(NSString *)type {
    
    [TVErrorHandler handleError:[NSError errorWithDomain:[NSString stringWithFormat:@"Could not %@", type] code:200 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Could not %@", type]}]];
}

#pragma mark Table View

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return [self.people count];
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
    
    [cell setPerson:self.people[indexPath.row]];
    [cell setUser:self.users[indexPath.row]];
    
    cell.tag = indexPath.row;
    
    return cell;
}

#pragma mark Cell Delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (![[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Cancel"]) {
        
        if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Accept"]) {
                        
            for (TVConnection *connection in [[[TVDatabase currentAccount] person] connections]) {

                if ([connection.senderId isEqualToString:[self.users[actionSheet.tag] objectId]]) {

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
                
                if ([connection.senderId isEqualToString:[self.users[actionSheet.tag] objectId]]) {
                    
                    ((TVFindPeopleCell *)[table cellForRowAtIndexPath:[NSIndexPath indexPathForRow:actionSheet.tag inSection:0]]).followButton.userInteractionEnabled = NO;
                    
                    [TVLoadingSignifier signifyLoading:@"Declining connection" duration:-1];
                    
                    [TVDatabase declineConnection:connection withCompletionHandler:^(NSError *error, NSString *callCode, BOOL success) {

                        [TVLoadingSignifier hideLoadingSignifier];
                        
                        ((TVFindPeopleCell *)[table cellForRowAtIndexPath:[NSIndexPath indexPathForRow:actionSheet.tag inSection:0]]).followButton.userInteractionEnabled = YES;

                        if (!error && success) {
                            
                            [self.people removeObject:self.people[actionSheet.tag]];
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

- (void)cell:(TVFindPeopleCell *)cell didTapFollowButton:(PFUser *)aUser {
    
    if (cell.hasConnection) {
        
        for (TVConnection *connection in [[[TVDatabase currentAccount] person] connections]) {
            
            if ([connection.senderId isEqualToString:aUser.objectId]) {
                
                if (connection.status == kConnectRequestPending) {
                    
                    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Accept", @"Decline", nil];
                    [actionSheet setTag:[self.users indexOfUser:aUser]];
                    [actionSheet showInView:self.view];
                }
                else if (connection.status == (ConnectRequestStatus *)kConnectRequestAccepted) {
                    
                    if ([cell.followButton.accessibilityIdentifier isEqualToString:@"Connect"]) {
                        
                        [TVLoadingSignifier signifyLoading:@"Disconnecting with user" duration:-1];

                        [TVDatabase disconnectWithUserId:aUser.objectId withCompletionHandler:^(NSError *error, NSString *callCode, BOOL success) {
                            
                            [TVLoadingSignifier hideLoadingSignifier];

                            dispatch_async(dispatch_get_main_queue(), ^{
                                
                                for (int i = 0; i <= self.users.count - 1; i++) {
                                    
                                    if ([self.users[i] isEqual:cell.user]) {

                                        [self.table reloadData];
                                        [self.table setNeedsDisplay];
                                    }
                                }
                            });
                        }];
                    }
                }
            }
            else if ([connection.receiverId isEqualToString:aUser.objectId]) {

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
            
            dispatch_queue_t downloadQueue = dispatch_queue_create("Disconnect people", NULL);
            
            dispatch_async(downloadQueue, ^{
                
                [TVLoadingSignifier signifyLoading:@"Disconnecting with user" duration:-1];
                
                [TVDatabase disconnectWithUserId:aUser.objectId withCompletionHandler:^(NSError *error, NSString *callCode, BOOL success) {
                    
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
            
            dispatch_queue_t downloadQueue = dispatch_queue_create("Connect people", NULL);
            
            dispatch_async(downloadQueue, ^{
                
                [TVLoadingSignifier signifyLoading:@"Connecting with user" duration:-1];
                
                [TVDatabase connectWithUser:aUser withCompletionHandler:^(NSString *callCode, BOOL success) {
                    
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
}

#pragma mark Finding Friends

- (void)finishedOperation:(int)operationNumber withObjects:(NSMutableArray *)objects {
    
    if (objects.count) {
                
        for (int i = 0; i <= objects.count - 1; i++) {
            
            if (![((PFUser *)objects[i]).objectId isEqualToString:[[TVDatabase currentAccount] userId]]) {
                
                [TVDatabase getAccountFromUser:objects[i] withCompletionHandler:^(TVAccount *account, BOOL allOperationsComplete, BOOL downloadedFlights, BOOL downloadedProfilePicture, BOOL downloadedConnections, BOOL downloadedMessages) {
                    
                    if (downloadedProfilePicture) {
                        NSLog(@"FPS STUFF");
                        if (![self.users containsUser:objects[i]]) {
                            
                            [self.people addObject:account.person];
                            [self.users addObject:objects[i]];
                        }
                        else {
                            
                            int index = [self.users indexOfUser:objects[i]];
                            
                            if (index != NSNotFound) {
                                
                                [self.users replaceObjectAtIndex:index withObject:objects[i]];
                                [self.people replaceObjectAtIndex:index withObject:account.person];
                            }
                        }
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            
                            [self.table reloadData];
                            [self.table setNeedsDisplay];
                        });
                        
                        if (operationNumber == expectedOperations) {
                            
                            [TVLoadingSignifier hideLoadingSignifier];
                        }
                    }
                } isPerformingCacheRefresh:YES];
            }
        }
    }
}

- (void)findPeople {
    
    __block int operationNumber = 0;

    [TVLoadingSignifier signifyLoading:@"Finding people" duration:-1];
    
    dispatch_queue_t downloadQueue = dispatch_queue_create("Find people", NULL);
    
    dispatch_async(downloadQueue, ^{
        
        if (self.filter == (FindPeopleFilter *)kFindPeopleOnlyConnectRequests) {
            
            NSMutableArray *IDs = [[NSMutableArray alloc] init];
            
            for (TVConnection *connection in [[[TVDatabase currentAccount] person] connections]) {
                
                if ([connection.receiverId isEqualToString:[[TVDatabase currentAccount] userId]] && connection.status == kConnectRequestPending) {
                    
                    [IDs addObject:connection.senderId];
                }
            }
            
            expectedOperations = IDs.count;
            
            [TVDatabase downloadUsersFromUserIds:IDs withCompletionHandler:^(NSMutableArray *users, NSError *error, NSString *callCode) {
                
                if (!error && users.count) {
                    
                    operationNumber++;
                    [self finishedOperation:operationNumber withObjects:users];
                }
                else {
                    
                    [self handleError:error andType:callCode];
                }
            }];
        }
        else if (self.filter == kFindPeopleFilterAllPeople) {
            
            expectedOperations = 3;

            [TVDatabase findUsersWithEmails:[self peopleEmails] withCompletionHandler:^(NSMutableArray *objects, NSError *error, NSString *callCode) {
                
                operationNumber++;
                [self finishedOperation:operationNumber withObjects:objects];
            }];
            
            if ([[TVDatabase currentAccount] isUsingLinkedIn]) {
                
                [LinkedInDataRetriever downloadConnectionsWithAccessToken:[[TVDatabase currentAccount] linkedInAccessKey] andCompletionHandler:^(NSArray *connections, BOOL success, NSError *error) {
                    
                    if (!error && success && connections.count) {
                        
                        NSMutableArray *linkedInIds = [[NSMutableArray alloc] init];
                        
                        for (NSDictionary *connection in connections) {
                            
                            [linkedInIds addObject:connection[@"id"]];
                        }
                        
                        [TVDatabase findUsersWithLinkedInIds:linkedInIds withCompletionHandler:^(NSMutableArray *objects, NSError *error, NSString *callCode) {
                            
                            operationNumber++;
                            [self finishedOperation:operationNumber withObjects:objects];
                        }];
                    }
                    else {
                        
                        operationNumber++;
                        [self finishedOperation:operationNumber withObjects:nil];
                    }
                }];
            }
            else {
                
                operationNumber++;
                [self finishedOperation:operationNumber withObjects:nil];
            }
            
            [TVDatabase downloadMyConnectionsWithCompletionHandler:^(NSMutableArray *objects, NSError *error, NSString *callCode) {
                
                operationNumber++;
                [self finishedOperation:operationNumber withObjects:objects];
            }];
        }
    });
}

- (NSMutableArray *)peopleEmails {
    
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    
    __block NSMutableArray *peopleEmails = [[NSMutableArray alloc] init];
    
    __block BOOL accessGranted = NO;
    
    if (ABAddressBookRequestAccessWithCompletion != NULL) { // we're on iOS 6
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
            accessGranted = granted;
            dispatch_semaphore_signal(sema);
        });
        
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    }
    else { // we're on iOS 5 or older
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
                TFLog_async(@"%@", email);
                if (![email isEqualToString:[[TVDatabase currentAccount] email]]) {
                    
                    [peopleEmails addObject:email];
                }
            }
        }
    }
    TFLog_async(@"%@", peopleEmails);
    
    return peopleEmails;
}

#pragma mark Dirty, Funky, Native ^_^

- (id)init {
    
    self = [super init];
    
    if (self) {
        
        self.people = [[NSMutableArray alloc] init];
        self.users = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    [self findPeople];
}

- (void)viewDidLoad {
        
    [super viewDidLoad];
}

- (IBAction)changedSegment:(UISegmentedControl *)sender {
}

@end