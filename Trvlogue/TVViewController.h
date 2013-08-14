//
//  TrvlogueViewController.h
//  Trvlogue
//
//  Created by Rohan Kapur on 11/3/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "TVNotificationCell.h"

#import "TVSwipeBanner.h"

#import "TVFlightDetailViewController.h"

#import "Reachability.h"

#import "TVFlightCell.h"

#import "TVFlightRecorderViewController.h"

#import "TVLoginViewController.h"

#import "TVFindPeopleViewController.h"

#import "CustomBadge.h"

@interface TVViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UINavigationControllerDelegate, MCSwipeTableViewCellDelegate>
{
    TVFlightDetailViewController *detailView;
    
    BOOL loading;
}

@property (strong, nonatomic) UITableView *notificationsTable;

@property (weak, nonatomic) IBOutlet UITableView *flightsTable;

@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (nonatomic, strong) TVSwipeBanner *mileTidbitsSwipeView;

@end