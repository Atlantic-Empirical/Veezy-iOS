//
//  ORYouView.m
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 12/30/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import "ORYouView.h"
#import "ORVideosView.h"
#import "ORLikedVideosView.h"

@interface ORYouView () <UIScrollViewDelegate>

@property (nonatomic, strong) ORVideosView *videos;
@property (nonatomic, strong) ORLikedVideosView *liked;

@end

@implementation ORYouView

- (void)dealloc
{
    self.scrollView.delegate = nil;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (!self) return nil;

    self.title = @"Your Videos";
	self.tabBarItem.image = [UIImage imageNamed:@"people-icon-white-40x"];

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) [self setEdgesForExtendedLayout:UIRectEdgeNone];
	self.screenName = @"Your Videos";

    if (self.navigationController.childViewControllers.count == 1) {
		UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction:)];
        self.navigationItem.leftBarButtonItem = done;
    }

    self.videos = [ORVideosView new];
    [self addChildViewController:self.videos];
    [self.scrollView addSubview:self.videos.view];
    [self.videos didMoveToParentViewController:self];

    self.liked = [ORLikedVideosView new];
    [self addChildViewController:self.liked];
    [self.scrollView addSubview:self.liked.view];
    [self.liked didMoveToParentViewController:self];
}

- (void)viewDidLayoutSubviews
{
    self.scrollView.contentSize = CGSizeMake(self.scrollView.subviews.count * self.scrollView.frame.size.width, self.scrollView.frame.size.height);
    
    CGRect f = self.scrollView.bounds;
    
    f.origin.x = 0 * f.size.width;
    self.videos.view.frame = f;

//    f.origin.x = 1 * f.size.width;
//    self.activity.view.frame = f;
    
    f.origin.x = 1 * f.size.width;
    self.liked.view.frame = f;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)doneAction:(id)sender
{
	[self.view endEditing:YES];
    
    if (self.navigationController.viewControllers.count > 1) {
        [self.navigationController popViewControllerAnimated:YES];
    } else if (self.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [RVC showCamera];
    }
}

#pragma mark - UI

- (void)btnVideos_TouchUpInside:(id)sender
{
	[self.scrollView setContentOffset:CGPointMake(0*self.scrollView.frame.size.width, 0) animated:YES];
}

- (void)btnLikes_TouchUpInside:(id)sender
{
	[self.scrollView setContentOffset:CGPointMake(1*self.scrollView.frame.size.width, 0) animated:YES];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	[self updatePageIndicator];
}

#pragma mark - Custom

- (void)updatePageIndicator
{
	CGPoint p = self.scrollView.contentOffset;
	CGRect f = self.viewIndicator.frame;
	
	if (p.x >= 0 && (p.x < (.5 * self.scrollView.frame.size.width))) {
		f.origin.x = self.btnVideos.frame.origin.x;
		f.size.width = self.btnVideos.frame.size.width;
		[self.view endEditing:YES];
	}
	
	else if ((p.x > (.5 * self.scrollView.frame.size.width)) && p.x < (1.5 * self.scrollView.frame.size.width)) {
		f.origin.x = self.btnLikes.frame.origin.x;
		f.size.width = self.btnLikes.frame.size.width;

//		f.origin.x = self.btnActivity.frame.origin.x;
//		f.size.width = self.btnActivity.frame.size.width;
//		[self.view endEditing:YES];
	}
	
	else {
//		f.origin.x = self.btnLikes.frame.origin.x;
//		f.size.width = self.btnLikes.frame.size.width;
//		isInSearch = (p.x == 3 * self.scrollView.frame.size.width);
	}

	[UIView animateWithDuration:0.2f delay:0.0f
						options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseInOut
					 animations:^{
						 self.viewIndicator.frame = f;
					 } completion:^(BOOL finished) {
                         //
					 }];
}

@end
