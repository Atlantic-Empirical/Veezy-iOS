//
//  ORChopVideoView.h
//  Epic
//
//  Created by Thomas Purnell-Fisher on 11/11/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORChopVideoView : GAITrackedViewController

@property (weak, nonatomic) IBOutlet UIButton *btnCommit;

- (IBAction)btnCommit_TouchUpInside:(id)sender;
- (IBAction)view_TouchUpInside:(id)sender;

@end
