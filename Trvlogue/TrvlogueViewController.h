//
//  TrvlogueViewController.h
//  Trvlogue
//
//  Created by Rohan Kapur on 11/3/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "NotificationCell.h"

#import "MileTidbitsSwipeView.h"

#import "TrvlogueFlightDetailViewController.h"

@interface TrvlogueViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UINavigationControllerDelegate>
{
    TrvlogueFlightDetailViewController *detailView;
}

@property (strong, nonatomic) UITableView *notificationsTable;

@property (strong, nonatomic) IBOutlet UINavigationBar *navBar;

@property (strong, nonatomic) IBOutlet UITableView *flightsTable;

@property (strong, nonatomic) IBOutlet UIView *headerView;
@property (nonatomic, strong) MileTidbitsSwipeView *mileTidbitsSwipeView;

@end