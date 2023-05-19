//
//  ORExipiringVideoView.h
//  Veezy
//
//  Created by Thomas Purnell-Fisher on 10/27/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORExpiringVideoView : GAITrackedViewController

- (id)initWithVideoId:(NSString *)videoId;

@property (weak, nonatomic) IBOutlet UIView *viewLoading;
@property (weak, nonatomic) IBOutlet UIButton *btnSubscribe;
@property (weak, nonatomic) IBOutlet UIButton *btnDelete;
@property (weak, nonatomic) IBOutlet UIImageView *imgThumb;
@property (weak, nonatomic) IBOutlet UILabel *lblTitle;
@property (weak, nonatomic) IBOutlet UILabel *lblViewCount;
@property (weak, nonatomic) IBOutlet UIButton *btnOpenVideo;
@property (weak, nonatomic) IBOutlet UILabel *lblExpirationInfo;

- (IBAction)btnSubscribe_TouchUpInside:(id)sender;
- (IBAction)btnOpenVideo_TouchUpInside:(id)sender;
- (IBAction)btnIgnore_TouchUpInside:(id)sender;
- (IBAction)btnDelete_TouchUpInside:(id)sender;

@end
