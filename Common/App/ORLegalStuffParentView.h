//
//  ORLegalStuffParentView.h
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 12/26/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORLegalStuffParentView : GAITrackedViewController

@property (weak, nonatomic) IBOutlet UIButton *btnToS;
@property (weak, nonatomic) IBOutlet UIButton *btnPrivacy;
@property (weak, nonatomic) IBOutlet UIButton *btnAcknowledgements;
@property (weak, nonatomic) IBOutlet UIButton *btnOpenSource;

- (IBAction)btnToS_TouchUpInside:(id)sender;
- (IBAction)btnPrivacy_TouchUpInside:(id)sender;
- (IBAction)btnAcknowledgements_TouchUpInside:(id)sender;
- (IBAction)btnOpenSource_TouchUpInside:(id)sender;

@end
