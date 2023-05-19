//
//  ORNudgeView.h
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 29/04/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORNudgeView : UIViewController

@property (nonatomic, weak) IBOutlet UILabel *lblTitle;
@property (nonatomic, weak) IBOutlet UILabel *lblSubtitle;
@property (nonatomic, weak) IBOutlet UIButton *btnClose;

- (IBAction)cellTapped:(id)sender;
- (IBAction)btnClose_TouchUpInside:(id)sender;

@end
