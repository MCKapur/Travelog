//
//  TrvlogueFindPeopleViewController.h
//  Trvlogue
//
//  Created by Rohan Kapur on 12/1/13.
//  Copyright (c) 2013 UWCSEA. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "TVCustomUINavigationBar.h"

#import "TVCreateAccountViewController.h"

#import <AddressBookUI/AddressBookUI.h>

#import <MessageUI/MessageUI.h>

#import "LinkedInDataRetriever.h"

#import "TVFindPeopleCell.h"

#import "TVDatabase.h"

typedef enum {
    
    kFindPeopleFilterSuggestions = 0,
    kFindPeopleFilterConnections,
    kFindPeopleFilterPending
    
} FindPeopleFilter;

@interface TVFindPeopleViewController : UIViewController <TrvlogueFindPeopleCellDelegate, UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate, UISearchBarDelegate>
{
}

@property (nonatomic) BOOL isSearching;
@property (nonatomic) FindPeopleFilter *filter;

@property (nonatomic, strong) NSMutableArray *accounts;
@property (nonatomic, strong) NSMutableArray *searchedAccounts;

@property (nonatomic, weak) IBOutlet UITableView *table;

@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

- (IBAction)changedSegment:(UISegmentedControl *)sender;

- (void)findPeople;

@end
