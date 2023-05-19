//
//  ORNavigationView.h
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 17/09/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORNavigationView : UIViewController

@property (nonatomic, weak) IBOutlet UIView *viewMainNav;
@property (nonatomic, weak) IBOutlet UIButton *btnMe;
@property (nonatomic, weak) IBOutlet UIButton *btnHome;
@property (nonatomic, weak) IBOutlet UIButton *btnActivity;
@property (nonatomic, weak) IBOutlet UIButton *btnCamera;
@property (nonatomic, weak) IBOutlet UIButton *btnAdd;
@property (nonatomic, weak) IBOutlet UILabel *lblBadge;
@property (nonatomic, weak) IBOutlet UILabel *lblActivityBadge;
@property (nonatomic, weak) IBOutlet UIButton *btnDiscover;
@property (weak, nonatomic) IBOutlet UIView *viewGoProHost;

- (IBAction)btnHome_TouchUpInside:(id)sender;
- (IBAction)btnMe_TouchUpInside:(id)sender;
- (IBAction)btnActivity_TouchUpInside:(id)sender;
- (IBAction)btnDiscover_TouchUpInside:(id)sender;
- (IBAction)btnCamera_TouchUpInside:(id)sender;
- (IBAction)btnAdd_TouchUpInside:(id)sender;
- (IBAction)btnGoProCaptureNow:(id)sender;

- (void)updateBadges;

@end
