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

typedef enum {
    
    kFindPeopleFilterAllPeople = 0,
    kFindPeopleOnlyConnectRequests
    
} FindPeopleFilter;

@interface TVFindPeopleViewController : UIViewController <TrvlogueFindPeopleCellDelegate, UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate>
{
}

@property (nonatomic) FindPeopleFilter *filter;

@property (nonatomic, strong) NSMutableArray *people;
@property (nonatomic, strong) NSMutableArray *users;

@property (nonatomic, strong) IBOutlet UITableView *table;

@end
