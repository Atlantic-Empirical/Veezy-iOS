//
//  ORPopDownView.m
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 08/08/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ORPopDownView.h"

@interface ORPopDownView ()

@property (nonatomic, strong) ORPopDownView *strongSelf;
@property (nonatomic, copy) NSString *titleText;
@property (nonatomic, copy) NSString *subtitleText;
@property (nonatomic, assign) BOOL didUndo;

@end

@implementation ORPopDownView

- (id)initWithTitle:(NSString *)title subtitle:(NSString *)subtitle
{
    self = [super init];
    if (!self) return nil;
    
    self.titleText = title;
    self.subtitleText = subtitle;
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.lblTitle.text = self.titleText;
    self.lblSubtitle.text = self.subtitleText;
//	self.btnUndo.layer.cornerRadius = 2.0f;
//	self.btnUndo.layer.borderColor = [UIColor whiteColor].CGColor;
//	self.btnUndo.layer.borderWidth = 1.0f;
	
	self.view.backgroundColor = APP_COLOR_PRIMARY_ALPHA(0.95f);
	
	NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
	
	if ([bundleIdentifier isEqualToString:@"net.maymudes.CloudCam"]) {
		self.lblSubtitle.textColor = [UIColor whiteColor];
		self.lblTitle.textColor = [UIColor whiteColor];
	} else if ([bundleIdentifier isEqualToString:@"com.orooso.Veezy"]) {
		self.lblSubtitle.textColor = [UIColor darkGrayColor];
		self.lblTitle.textColor = [UIColor darkGrayColor];
	} else if ([bundleIdentifier isEqualToString:@"com.orooso.Twidio"]) {
		self.lblSubtitle.textColor = [UIColor whiteColor];
		self.lblTitle.textColor = [UIColor whiteColor];
	} else if ([bundleIdentifier isEqualToString:@"com.orooso.Huck"]) {
		self.lblSubtitle.textColor = [UIColor whiteColor];
		self.lblTitle.textColor = [UIColor whiteColor];
	}

}

- (void)displayInView:(UIView *)view hideAfter:(NSTimeInterval)seconds
{
    [self displayInView:view margin:0 hideAfter:seconds];
}

- (void)displayInView:(UIView *)view margin:(CGFloat)margin hideAfter:(NSTimeInterval)seconds
{
    CGRect f = self.view.frame;
    f.origin.x = 0.0f;
    f.size.width = view.bounds.size.width;
    if (margin > 0) f.size.height += margin;
    f.origin.y = -f.size.height;
    self.view.frame = f;
    
    if (self.undoBlock) {
        self.btnUndo.hidden = NO;
    } else {
        self.btnUndo.hidden = YES;
    }

//    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:self.view.bounds byRoundingCorners:UIRectCornerBottomLeft | UIRectCornerBottomRight cornerRadii:CGSizeMake(7.0, 7.0)];
//    CAShapeLayer *maskLayer = [CAShapeLayer layer];
//    maskLayer.frame = self.view.bounds;
//    maskLayer.path = maskPath.CGPath;
//    self.view.layer.mask = maskLayer;
    
    f.origin.y = 0;
    self.strongSelf = self;
    
    [view addSubview:self.view];
    [UIView animateWithDuration:0.2f animations:^{
        self.view.frame = f;
    }];
    
    if (seconds > 0) {
        [self performSelector:@selector(close) withObject:nil afterDelay:seconds];
    }
}

- (void)close
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(close) object:nil];
    
    CGRect f = self.view.frame;
    f.origin.y = -f.size.height;
    
    [UIView animateWithDuration:0.2f animations:^{
        self.view.frame = f;
    } completion:^(BOOL finished) {
        if (self.completionBlock && !self.didUndo) self.completionBlock();
        self.completionBlock = nil;

        self.strongSelf = nil;
        [self.view removeFromSuperview];
    }];
}

- (void)btnClose_TouchUpInside:(id)sender
{
    [self close];
}

- (void)btnUndo_TouchUpInside:(id)sender
{
    if (self.undoBlock) self.undoBlock();
    self.undoBlock = nil;
    
    self.didUndo = YES;
    [self close];
}

@end
