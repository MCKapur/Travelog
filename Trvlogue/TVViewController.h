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

@interface TVViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UINavigationControllerDelegate>
{
    TVFlightDetailViewController *detailView;
}

@property (strong, nonatomic) UITableView *notificationsTable;

@property (strong, nonatomic) IBOutlet UINavigationBar *navBar;

@property (strong, nonatomic) IBOutlet UITableView *flightsTable;

@property (strong, nonatomic) IBOutlet UIView *headerView;
@property (nonatomic, strong) TVSwipeBanner *mileTidbitsSwipeView;

@end