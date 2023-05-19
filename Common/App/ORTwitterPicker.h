//
//  ORTwitterPicker.h
//  Veezy
//
//  Created by Rodrigo Sieiro on 29/10/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORTwitterPicker : UIViewController

@property (nonatomic, weak) IBOutlet UIButton *btnMain;
@property (nonatomic, weak) IBOutlet UIButton *btnConnect;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *aiLoading;

@property (nonatomic, assign) BOOL forceSelected;
@property (nonatomic, assign, getter=isSelected) BOOL selected;

- (IBAction)btnMain_TouchUpInside:(id)sender;
- (IBAction)btnConnect_TouchUpInside:(id)sender;

@end
