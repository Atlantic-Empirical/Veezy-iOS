//
//  ORUserStatsView.h
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 2/17/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORUserStatsView : GAITrackedViewController

@property (strong, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UILabel *lblUploadWifi;
@property (weak, nonatomic) IBOutlet UILabel *lblUploadWwan;
@property (weak, nonatomic) IBOutlet UILabel *lblVideoMin;
@property (weak, nonatomic) IBOutlet UILabel *lblVideoCount;
@property (weak, nonatomic) IBOutlet UILabel *lblBufferCapacityInBytes;
@property (weak, nonatomic) IBOutlet UILabel *lblBufferCapacityInMinutes;
@property (weak, nonatomic) IBOutlet UILabel *lblBufferUsedInBytes;
@property (weak, nonatomic) IBOutlet UILabel *lblBufferUsedInMinutes;
@property (weak, nonatomic) IBOutlet UILabel *lblTransferRateInKbps;
@property (weak, nonatomic) IBOutlet UILabel *lblViewCount;
@property (weak, nonatomic) IBOutlet UILabel *lblLikeCount;
@property (weak, nonatomic) IBOutlet UILabel *lblBufferedVideoCount;
@property (weak, nonatomic) IBOutlet UIButton *btnInfo_UploadData;
@property (weak, nonatomic) IBOutlet UIButton *btnInfo_TotalStored;
@property (weak, nonatomic) IBOutlet UIButton *btnInfo_Viewership;
@property (weak, nonatomic) IBOutlet UIButton *btnInfo_BufferFree;
@property (weak, nonatomic) IBOutlet UIButton *btnInfo_BufferUsed;
@property (weak, nonatomic) IBOutlet UIButton *btnInfo_CurrentTransfer;


- (IBAction)btnResetWifi_TouchUpInside:(id)sender;
- (IBAction)btnResetWwan_TouchUpInside:(id)sender;
- (IBAction)btnInfo_UploadData_TouchUpInside:(id)sender;
- (IBAction)btnInfo_TotalStored_TouchUpInside:(id)sender;
- (IBAction)btnInfo_Viewership_TouchUpInside:(id)sender;
- (IBAction)btnInfo_BufferFree_TouchUpInside:(id)sender;
- (IBAction)btnInfo_BufferUsed_TouchUpInside:(id)sender;
- (IBAction)btnInfo_CurrentTransfer_TouchUpInside:(id)sender;

@end
