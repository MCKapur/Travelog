//
//  WebViewController.m
//  Nerdfeed
//
//  Created by Rohan Kapur on 17/12/11.
//  Copyright (c) 2011 UWCSEA. All rights reserved.
//

#import "TVWebViewController.h"

@implementation TVWebViewController

- (void)webViewDidStartLoad:(UIWebView *)webView {
 
    if ([self webView].loading == YES) {
        
        if (act == nil) {
            
            act = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
            act.color = [UIColor blackColor];
            act.center = self.view.center;
            [self.view addSubview:act];
            
        } else {
            
            act.hidden = NO;
        }
        
        act.center = self.view.center;
        [act startAnimating];        
    }
}

- (void)viewDidLoad {
    
    UIBarButtonItem *rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(share)];
    [self.navigationItem setRightBarButtonItem:rightBarButtonItem];
    
    self.navigationItem.title = self.title;
    
    [wv loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:link]]];
    [wv setSuppressesIncrementalRendering:YES];
    [wv setDelegate:self];
}

- (IBAction)share {
    
    NSArray *activityItems = @[title, link];
    
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    activityViewController.excludedActivityTypes = @[UIActivityTypePostToWeibo, UIActivityTypeAssignToContact];
    
    [self presentViewController:activityViewController animated:YES completion:NULL];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    
    [act stopAnimating];
    [act setHidden:YES];
    act = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:YES];
        
    // Create UIWebView as large as the screen
}                        

- (id)initWithLink:(NSString *)_link andTitle: (NSString *)specifiedTitle {
    
    self = [super init];
    
    if (self) {
        
        link = _link;
        title = specifiedTitle;
    }
    
    return self;
}
 
- (IBAction)back {
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)io
{
    return (io == UIInterfaceOrientationPortrait);
}

- (UIWebView *)webView {
    
    return wv;
}

@end
