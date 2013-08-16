//
//  TVTranslationsViewController.h
//  Trvlogue
//
//  Created by Rohan Kapur on 16/8/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TVTranslationsViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITableView *translationsTableView;

@property (nonatomic, strong) NSMutableArray *translations;

- (id)initWithTranslations:(NSMutableArray *)_translations;

@end
