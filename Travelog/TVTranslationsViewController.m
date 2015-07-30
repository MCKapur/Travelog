//
//  TVTranslationsViewController.m
//  Trvlogue
//
//  Created by Rohan Kapur on 16/8/13.
//  Copyright (c) 2013 Rohan Kapur. All rights reserved.
//

#import "TVTranslationsViewController.h"

@interface NSMutableArray (FilterTranslations)

- (NSMutableArray *)translationsWithLanguage:(NSString *)language;

@end

@implementation NSMutableArray (FilterTranslations)

- (NSMutableArray *)translationsWithLanguage:(NSString *)language {
    
    NSMutableArray *retVal = nil;
    
    for (NSDictionary *languageDictionary in self) {

        if ([languageDictionary[@"name"] isEqualToString:language]) {
            
            retVal = [languageDictionary[@"translations"] mutableCopy];
        }
    }
    
    return retVal;
}

@end

@interface TVTranslationsViewController ()

@end

@implementation TVTranslationsViewController
@synthesize translations;

- (void)setTranslations:(NSMutableArray *)_translations {
    
    translations = _translations;
    
    [self.translationsTableView reloadData];
    [self.translationsTableView setNeedsDisplay];
}

- (IBAction)languagesSegmentedControlChanged:(UISegmentedControl *)sender {

    [self.translationsTableView reloadData];
    [self.translationsTableView setNeedsDisplay];
}

#pragma mark UITableView Methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (![self.translations translationsWithLanguage:[self.languagesSegmentedControl titleForSegmentAtIndex:self.languagesSegmentedControl.selectedSegmentIndex]]) return 0;
    return [self.translations translationsWithLanguage:[self.languagesSegmentedControl titleForSegmentAtIndex:self.languagesSegmentedControl.selectedSegmentIndex]].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    NSString *CellIdentifier = [NSString stringWithFormat:@"CELL_%@", [self.translations translationsWithLanguage:[self.languagesSegmentedControl titleForSegmentAtIndex:self.languagesSegmentedControl.selectedSegmentIndex]][indexPath.row][@"translation"]];
    
    tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {

        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        
        cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:20.0f];
        cell.textLabel.text = [self.translations translationsWithLanguage:[self.languagesSegmentedControl titleForSegmentAtIndex:self.languagesSegmentedControl.selectedSegmentIndex]][indexPath.row][@"translation"];
        cell.textLabel.numberOfLines = 3;
        
        cell.detailTextLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16.0f];
        cell.detailTextLabel.text = [[[self.translations translationsWithLanguage:[self.languagesSegmentedControl titleForSegmentAtIndex:self.languagesSegmentedControl.selectedSegmentIndex]][indexPath.row][@"phrase"] stringByReplacingOccurrencesOfString:@"%20" withString:@" "] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
        cell.detailTextLabel.numberOfLines = 2;
        cell.detailTextLabel.textColor = [UIColor grayColor];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return 90.0f;
}

#pragma mark Init

- (id)initWithTranslations:(NSMutableArray *)_translations {
    
    if (self = [self init]) {
        
        self.translations = _translations;
    }
    
    return self;
}

- (id)init {
    
    if (self = [super init]) {
        
    }
    
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark View Lifecycle

- (void)viewDidLoad
{
    self.navigationItem.title = @"Translations";
    
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewWillAppear:(BOOL)animated {

    [self.languagesSegmentedControl removeAllSegments];
    
    if (self.translations.count) {

        for (NSInteger i = 0; i <= self.translations.count - 1; i++) {

            NSDictionary *languageDictionary = self.translations[i];

            if ([languageDictionary[@"translations"] count]) {
                
                [self.languagesSegmentedControl insertSegmentWithTitle:languageDictionary[@"name"] atIndex:i animated:YES];
            }
        }
        
        if (self.languagesSegmentedControl.numberOfSegments) {
            
            [self.languagesSegmentedControl setSelectedSegmentIndex:0];
        }
    }
    
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
