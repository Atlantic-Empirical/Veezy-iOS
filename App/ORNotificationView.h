//
//  ORNotificationView.h
//  Cloudcam
//
//  Created by Rodrigo Sieiro on 26/11/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORNotificationView : GAITrackedViewController

@property (nonatomic, weak) IBOutlet UILabel *lblText;
@property (nonatomic, weak) IBOutlet UIButton *btnAction;

@property (nonatomic, strong) NSDictionary *notification;

- (id)initWithNotification:(NSDictionary *)notification;
- (IBAction)btnAction_TouchUpInside:(id)sender;

@end
