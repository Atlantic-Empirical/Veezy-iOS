//
//  ORTrimVideoView.h
//  Epic
//
//  Created by Thomas Purnell-Fisher on 11/11/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORTrimVideoView : GAITrackedViewController

@property (weak, nonatomic) IBOutlet UIButton *btnCommitTrim;

- (IBAction)btnCommitTrim_TouchUpInside:(id)sender;
- (IBAction)view_TouchUpInside:(id)sender;


@end
