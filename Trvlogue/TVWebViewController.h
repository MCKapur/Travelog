//
//  WebViewController.h
//
//  Created by Rohan Kapur on 17/12/11.
//  Copyright (c) 2011 UWCSEA. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TVRSSItem;

@interface TVWebViewController : UIViewController <UIWebViewDelegate> {

    UIActivityIndicatorView *act;
    
    NSString *link;
    NSString *title;
    
    IBOutlet UIWebView *wv;
}

- (IBAction)back;

- (id)initWithLink:(NSString *)_link andTitle: (NSString *)_title;

@end
