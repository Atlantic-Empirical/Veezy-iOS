//
//  ORYouView.h
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 12/30/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORYouView : GAITrackedViewController

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIButton *btnVideos;
@property (weak, nonatomic) IBOutlet UIButton *btnLikes;
@property (weak, nonatomic) IBOutlet UIView *viewIndicator;

- (IBAction)btnVideos_TouchUpInside:(id)sender;
- (IBAction)btnLikes_TouchUpInside:(id)sender;

@end
