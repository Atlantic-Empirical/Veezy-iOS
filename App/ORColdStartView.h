//
//  ORColdStartView.h
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 1/26/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ORNavigationController;

@interface ORColdStartView : GAITrackedViewController

@property (weak, nonatomic) IBOutlet UIScrollView *scroller;
@property (weak, nonatomic) IBOutlet UIButton *btnGotIt;
@property (weak, nonatomic) IBOutlet UIPageControl *pager;

- (IBAction)btnGotIt_TouchUpInside:(id)sender;

@property (assign, nonatomic) BOOL firstTime;
@property (weak, nonatomic) UIViewController *parentView;

@end
