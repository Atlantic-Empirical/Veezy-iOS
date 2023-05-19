//
//  vcSFWebView.h
//  Orooso
//
//  Created by Thomas Purnell-Fisher on 7/19/12.
//  Copyright (c) 2012 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ORWebViewDelegate;
@class ORSyncFlowCard, ORWebsite;

@interface ORWebView : GAITrackedViewController <UIWebViewDelegate, UIGestureRecognizerDelegate>

- (id)initWithURLString:(NSString*)urlString;
- (id)initWithURL:(NSURL *)url;

@property (weak, nonatomic) IBOutlet UIView *viewSpinnerHost;
@property (strong, nonatomic) IBOutlet UIWebView *wvMain;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *aiPageLoading;
@property (strong, nonatomic) NSURL *targetURL;
@property (nonatomic, strong) NSString *callbackURL;
@property (weak) id <ORWebViewDelegate> delegate;

@end

@protocol ORWebViewDelegate <NSObject>

- (void)webView:(ORWebView *)webView didHitCallbackURL:(NSURL *)url;
- (void)webView:(ORWebView *)webView didCancelWithError:(NSError *)error;

@end
