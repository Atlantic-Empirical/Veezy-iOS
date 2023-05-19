//
//  ORTwitterConnectView.h
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 12/08/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORTwitterConnectView : GAITrackedViewController

@property (weak, nonatomic) IBOutlet UIView *viewContent;
@property (weak, nonatomic) IBOutlet UILabel *lblTitle;
@property (weak, nonatomic) IBOutlet UIButton *btnCancel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *aiLoading;

@property (nonatomic, assign) BOOL shouldFindFriends;
@property (nonatomic, copy) void (^completionBlock)(BOOL success);

- (IBAction)btnCancel_TouchUpInside:(id)sender;

@end
