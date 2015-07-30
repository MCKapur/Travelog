//
//  TVMessageListViewController.h
//  Trvlogue
//
//  Created by Rohan Kapur on 18/8/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TVMessageListViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
{
}

@property (weak, nonatomic) IBOutlet UITableView *messageListTableView;

@end
