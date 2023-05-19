//
//  vcSFWebView.m
//  Orooso
//
//  Created by Thomas Purnell-Fisher on 7/19/12.
//  Copyright (c) 2012 Orooso, Inc. All rights reserved.
//

#import "ORWebView.h"
#import <QuartzCore/QuartzCore.h>

@interface ORWebView ()

@property (strong, nonatomic, readonly) NSString *pageTitle;
@property (strong, nonatomic) NSURL *currentUrl;
@property (strong, nonatomic) UIBarButtonItem *btnBack;
@property (strong, nonatomic) UIBarButtonItem *btnReload;
@property (strong, nonatomic) UIBarButtonItem *btnForward;

@end

@implementation ORWebView

- (void)dealloc
{
    self.wvMain.delegate = nil;
    [self.wvMain stopLoading];
	[self setWvMain:nil];
}

- (id)initWithURL:(NSURL *)url
{
    self = [super initWithNibName:nil bundle:nil];
    if (!self) return nil;
    
    self.targetURL = url;
    
    return self;
}

- (id)initWithURLString:(NSString*)urlString
{
    NSURL *url = [NSURL URLWithString:urlString];
    return [self initWithURL:url];
}

- (void)setTargetURL:(NSURL *)targetURL
{
    _targetURL = targetURL;
    [self navigateWebView:_targetURL];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) [self setEdgesForExtendedLayout:UIRectEdgeNone];
	
	self.screenName = @"WebView";
	
    if (self.navigationController.childViewControllers.count == 1) {
        // Cancel
        UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(close)];
        self.navigationItem.leftBarButtonItem = cancel;
    }

	// Bottom (tool) Bar
	self.btnBack = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRewind target:self action:@selector(backAction)];
	self.btnReload = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reloadAction)];
	self.btnForward = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFastForward target:self action:@selector(forwardAction)];
		
	UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
	UIBarButtonItem *flex1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
	UIBarButtonItem *flex2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
	UIBarButtonItem *flex3 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
	
	self.toolbarItems = [NSArray arrayWithObjects:flex, self.btnBack, flex1, self.btnReload, flex2, self.btnForward, flex3, nil];
	[[UIToolbar appearance] setBackgroundColor:[UIColor whiteColor]];
	
	self.viewSpinnerHost.layer.cornerRadius = 6.0f;
    [self navigateWebView:self.targetURL];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self configureForOrientation:toInterfaceOrientation duration:duration];
}

- (void)configureForOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
}

- (void)viewWillAppear:(BOOL)animated
{
	self.navigationController.toolbarHidden = YES;
//    self.navigationController.toolbarHidden = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.navigationController.toolbarHidden = YES;
}

- (void)close
{
    [self.delegate webView:self didCancelWithError:nil];
}

- (NSString*)pageTitle
{
	NSString *str = [self.wvMain stringByEvaluatingJavaScriptFromString:@"document.title"];
	return str;
}

#pragma mark - Navigation

- (void)backAction
{
	if (self.wvMain.canGoBack) [self.wvMain goBack];
}

- (void)forwardAction
{
	if (self.wvMain.canGoForward) [self.wvMain goForward];
}

- (void)reloadAction
{
	[self.wvMain reload];
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)theWebView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if (self.callbackURL) {
        NSString *url = [NSString stringWithFormat:@"%@://%@%@", request.URL.scheme, request.URL.host, request.URL.path];
        if ([url isEqualToString:self.callbackURL]) {
            [self.delegate webView:self didHitCallbackURL:request.URL];
            return NO;
        }
    }
    
    return YES;
}

- (void)navigateWebView:(NSURL *)url
{
    if (!url) {
        [self.wvMain loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]]];
        return;
    }
    
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
    [self.wvMain loadRequest:requestObj];
	
	[UIView animateWithDuration:0.2f animations:^{
		self.viewSpinnerHost.alpha = 1.0f;
	}];
}

- (void)loadHtmlString:(NSString*)string
{
	if (!string) return;
	[self.wvMain loadHTMLString:string baseURL:nil];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	self.currentUrl = webView.request.mainDocumentURL;
	
	[UIView animateWithDuration:0.2f animations:^{
		self.viewSpinnerHost.alpha = 0.0f;
	}];
    
    self.btnBack.enabled = (webView.canGoBack);
    self.btnForward.enabled = (webView.canGoForward);
//	self.title = [STTweetLabel htmlToText:self.pageTitle];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    // Blank page error, should be ignored
    if (error.code == -999) return;
    
    DLog(@"Error (UIWebView): %@", [error localizedDescription]);
}

@end
