//
//  ORTimebombPickerView.m
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 1/3/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "ORTimebombPickerView.h"
#import "SORelativeDateTransformer.h"

@interface ORTimebombPickerView ()

@property (strong, nonatomic) OREpicVideo *video;
@property (strong, nonatomic) NSArray *intervalValues;
@property (assign, nonatomic) BOOL isDirty;

@end

@implementation ORTimebombPickerView

+(NSString *)titleForValue:(NSUInteger)value
{
    switch (value) {
        case 5:
            return @"in 5 minutes";
        case 30:
            return @"in 30 minutes";
        case 60:
            return @"in 1 hour";
        case 360:
            return @"in 6 hours";
        case 720:
            return @"in 12 hours";
        case 1440:
            return @"in 1 day";
        case 10080:
            return @"in 1 week";
        case 20160:
            return @"in 2 weeks";
        case 43200:
            return @"in 1 month";
        case 129600:
            return @"in 3 months";
        case 259200:
            return @"in 6 months";
        case 518400:
            return @"in 1 year";
		default:
            return @"never";
    }
}

- (id)initWithVideo:(OREpicVideo *)video
{
    self = [super initWithNibName:nil bundle:nil];
    if (!self) return nil;
    
    self.video = video;
    
    return self;
}

- (void)prepareIntervals
{
    self.intervalValues = @[@(0), @(5), @(30), @(60), @(360), @(720), @(1440), @(10080), @(20160), @(43200), @(129600), @(259200), @(518400)];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) [self setEdgesForExtendedLayout:UIRectEdgeNone];
    self.title = @"Timebomb";
	self.screenName = @"TimebombPicker";

	[self prepareIntervals];
}

- (void)viewDidAppear:(BOOL)animated
{
	[self.pickerView selectRow:0 inComponent:0 animated:NO];
}

- (void)doneAction:(id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ORTimebombPickerValueSelected" object:self.selectedIntervalValue];
}

- (IBAction)btnInfo_TouchUpInside:(id)sender {
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"What is 'timebomb'?"
													message:[NSString stringWithFormat:@"Set a countdown time and the video will be deleted from the %@ system in the time specified.\n\nYou can return later and cancel the countdown.\n\nOnce the video is deleted, it cannot be retrieved.", APP_NAME]
											   delegate:nil
									  cancelButtonTitle:nil
									  otherButtonTitles:@"Ok", nil];
    [alert show];
}

#pragma mark - UIPickerView

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)thePickerView
{
	return 1;
}

- (float)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
	return 50;
}

- (NSInteger)pickerView:(UIPickerView *)thePickerView numberOfRowsInComponent:(NSInteger)component
{
	if (self.video.timebombMinutes > 0) {
        return self.intervalValues.count + 1;
    } else {
        return self.intervalValues.count;
    }
}

- (NSString *)pickerView:(UIPickerView *)thePickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if (self.video.timebombMinutes) {
        if (row == 0) {
            SORelativeDateTransformer *rdt = [[SORelativeDateTransformer alloc] init];
            NSDate *dt = [NSDate dateWithTimeInterval:(self.video.timebombMinutes * 60) sinceDate:self.video.startTime];
            return [rdt transformedValue:dt];
        } else {
            return [ORTimebombPickerView titleForValue:[self.intervalValues[row - 1] integerValue]];
        }
    } else {
        return [ORTimebombPickerView titleForValue:[self.intervalValues[row] integerValue]];
    }
}

- (void)pickerView:(UIPickerView *)thePickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if (self.video.timebombMinutes > 0 && row == 0) {
        self.selectedIntervalValue = nil;
    } else {
        if (self.video.timebombMinutes > 0) {
            self.selectedIntervalValue = self.intervalValues[row - 1];
        } else {
            self.selectedIntervalValue = self.intervalValues[row];
        }
    }
}

- (UIView*)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
	UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, pickerView.frame.size.width, self.view.frame.size.height)];
    label.backgroundColor = [UIColor clearColor];
    label.textColor = APP_COLOR_PRIMARY;
	label.textAlignment = NSTextAlignmentLeft;
    label.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:30];
	label.text = [self pickerView:pickerView titleForRow:row forComponent:component];
    return label;
}

@end
