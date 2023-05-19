//
//  ORProfessionalSettingsView.h
//  OneCent
//
//  Created by Thomas Purnell-Fisher on 12/18/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORProSettingsView : GAITrackedViewController

@property (nonatomic, weak) IBOutlet UISwitch *switchKeepVideos;
@property (weak, nonatomic) IBOutlet UISlider *sldVideoBitrate;
@property (weak, nonatomic) IBOutlet UISlider *sldAudioBitrate;
@property (weak, nonatomic) IBOutlet UILabel *lblVideoBitrate;
@property (weak, nonatomic) IBOutlet UILabel *lblAudioBitrate;

- (IBAction)switchKeepVideos_ValueChanged:(id)sender;
- (IBAction)sldVideoBitrate_ValueChanged:(id)sender;
- (IBAction)sldAudioBitrate_ValueChanged:(id)sender;

@end
