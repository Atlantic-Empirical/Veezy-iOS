//
//  ORColdStartView.m
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 1/26/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "ORColdStartView.h"
#import "ORNavigationController.h"
#import "ORColdStartOne.h"
#import "ORColdStartTwo.h"
#import "ORColdStartThree.h"

@interface ORColdStartView () <UIScrollViewDelegate>

@property (assign, nonatomic) int pageIndex;
@property (strong, nonatomic) NSMutableArray *pages;

@end

@implementation ORColdStartView

- (void)dealloc
{
    self.scroller.delegate = nil;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.screenName = @"ColdStart";
	self.pageIndex = 0;
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
}

- (void)viewDidAppear:(BOOL)animated
{
	[self setupViews];
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)close
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setBool:YES forKey:@"coldStart"];
	[defaults synchronize];
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
    
    BOOL first = self.firstTime;
	[UIView transitionFromView:self.view
						toView:self.parentView.view
					  duration:1
					   options:UIViewAnimationOptionTransitionFlipFromBottom
					completion:^(BOOL finished) {
                        if (first) {
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"ORPresentSignIn" object:nil];
                        }
                    }];
}

- (void)setupViews
{
	self.pages = [NSMutableArray array];
	
	[self.pages addObject:[ORColdStartOne new]];
	[self.pages addObject:[ORColdStartTwo new]];
	[self.pages addObject:[ORColdStartThree new]];
	
	UIViewController *l;
	for (int i = 0; i < self.pages.count; i++)
	{
		l = self.pages[i];
		l.view.frame = CGRectMake(i * self.scroller.frame.size.width, 0, self.scroller.frame.size.width, self.scroller.frame.size.height);
		[self.scroller addSubview:l.view];
	}
	
	self.scroller.contentSize = CGSizeMake(self.pages.count * self.scroller.frame.size.width, self.scroller.frame.size.height);
	
	[self scrollToPage];
	self.scroller.hidden = NO;
	
	self.pager.numberOfPages = self.pages.count;
}

#pragma mark - UI

- (IBAction)btnGotIt_TouchUpInside:(id)sender {
	[self nextAction];
}

#pragma mark - Direction Actions

- (void)nextAction
{
	if (self.pageIndex >= (int)self.pages.count-1)
		[self close];
	else
		[self scrollNext];
}

#pragma mark - Scroller

- (void)scrollNext
{
	DLog(@"%d", self.pageIndex);
	self.pageIndex++;
	DLog(@"%d", self.pageIndex);
	[self scrollToPage];
}

- (void)scrollPrevious
{
	self.pageIndex--;
	[self scrollToPage];
}

- (void)scrollToPage
{
	[self.scroller setContentOffset:CGPointMake(self.pageIndex*self.scroller.frame.size.width, 0) animated:YES];
	[self updateButtonStates];
}

- (void)updateButtonStates
{
	// Change text of next button for last page
	if (self.pageIndex == self.pages.count-1) {
		[self.btnGotIt setTitle:@"Go For It" forState:UIControlStateNormal];
	} else {
		[self.btnGotIt setTitle:@"Next" forState:UIControlStateNormal];
	}
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	CGPoint p = self.scroller.contentOffset;
	
	if (p.x >= 0 && (p.x < (0.5 * self.scroller.frame.size.width)))
		self.pageIndex = 0;
	
	else if ((p.x >= (0.5 * self.scroller.frame.size.width)) && p.x < (1.5 * self.scroller.frame.size.width))
		self.pageIndex = 1;
	
	else if ((p.x >= (1.5 * self.scroller.frame.size.width)) && p.x < (2.5 * self.scroller.frame.size.width))
		self.pageIndex = 2;
	
	else if ((p.x >= (2.5 * self.scroller.frame.size.width)) && p.x < (3.5 * self.scroller.frame.size.width))
		self.pageIndex = 3;

	else if ((p.x >= (3.5 * self.scroller.frame.size.width)) && p.x < (4.5 * self.scroller.frame.size.width))
		self.pageIndex = 4;

	else if ((p.x >= (4.5 * self.scroller.frame.size.width)) && p.x < (5.5 * self.scroller.frame.size.width))
		self.pageIndex = 5;
	
	else if ((p.x >= (5.5 * self.scroller.frame.size.width)) && p.x < (6.5 * self.scroller.frame.size.width))
		self.pageIndex = 6;
	
	else if ((p.x >= (6.5 * self.scroller.frame.size.width)) && p.x < (7.5 * self.scroller.frame.size.width))
		self.pageIndex = 7;

	[self updateButtonStates];
	self.pager.currentPage = self.pageIndex;
}

@end
