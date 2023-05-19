//
//  ORVUMeterView.h
//  Veezy
//
//  Created by Thomas Purnell-Fisher on 11/19/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORVUMeterView : UIViewController

@property (weak, nonatomic) IBOutlet UIView *vwVUMeter_1;
@property (weak, nonatomic) IBOutlet UIView *vwVUMeter_2;
@property (weak, nonatomic) IBOutlet UIView *vwVUMeter_3;
@property (weak, nonatomic) IBOutlet UIView *vwVUMeter_4;
@property (weak, nonatomic) IBOutlet UIView *vwVUMeter_5;
@property (weak, nonatomic) IBOutlet UIView *vwVUMeter_6;

- (void)startMetering;
- (void)stopMetering;

@end
