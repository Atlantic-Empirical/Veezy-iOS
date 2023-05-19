//
//  ORTimebombPickerView.h
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 1/3/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORTimebombPickerView : GAITrackedViewController <UIPickerViewDataSource, UIPickerViewDelegate>

- (id)initWithVideo:(OREpicVideo *)video;

@property (weak, nonatomic) IBOutlet UIPickerView *pickerView;
@property (strong, nonatomic) NSNumber *selectedIntervalValue;
@property (weak, nonatomic) IBOutlet UIButton *btnInfo;

- (IBAction)btnInfo_TouchUpInside:(id)sender;
- (IBAction)doneAction:(id)sender;

+ (NSString *)titleForValue:(NSUInteger)value;

@end
