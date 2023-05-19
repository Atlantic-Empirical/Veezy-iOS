//
//  ORVUMeterView.m
//  Veezy
//
//  Created by Thomas Purnell-Fisher on 11/19/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "ORVUMeterView.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/CoreAudioTypes.h>

@interface ORVUMeterView () <AVAudioRecorderDelegate>

@property (strong, nonatomic) AVAudioRecorder *recorder;
@property (strong, nonatomic) NSTimer *audioLevelTimer;

@end

@implementation ORVUMeterView

float meterHeight_1 = 0;
float meterHeight_2 = 0;
float meterHeight_3 = 0;
float meterHeight_4 = 0;
float meterHeight_5 = 0;
float meterHeight_6 = 0;

- (void)dealloc
{
    [self stopMetering];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self startMetering];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
	[self stopMetering];
}

- (void)startMetering
{

  	NSError *error;

	// SETUP AUDIO SESSION
	[AppDelegate AudioSession_AudioMonitor];

	// doesn't seem to be needed
//	[[AVAudioSession sharedInstance] setActive:YES error:&error];
//	if (error) NSLog(@"Error description: %@", [error description]);
	
	// SETUP RECORDER
  	NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithFloat: 44100.0],                 AVSampleRateKey,
                              [NSNumber numberWithInt: kAudioFormatLinearPCM],     AVFormatIDKey,
                              [NSNumber numberWithInt: 1],                         AVNumberOfChannelsKey,
                              [NSNumber numberWithInt: AVAudioQualityMax],         AVEncoderAudioQualityKey,
                              nil];

	// 	NSURL *url = [NSURL fileURLWithPath:@"/dev/null"]; // causes -160 values
	NSURL *url = [NSURL URLWithString:[NSTemporaryDirectory() stringByAppendingPathComponent:@"tmp.caf"]];

	self.recorder = [[AVAudioRecorder alloc] initWithURL:url settings:settings error:&error];
	if (error) NSLog(@"Error description: %@", [error description]);

  	if (self.recorder) {
  		[self.recorder prepareToRecord];
  		self.recorder.meteringEnabled = YES;
		self.recorder.delegate = self;
        self.audioLevelTimer = [NSTimer scheduledTimerWithTimeInterval:0.03f target:self selector:@selector(audioLevelTimerCallback:) userInfo:nil repeats:YES];
        [self.recorder record];
	}
}

- (void)stopMetering
{
    [self.audioLevelTimer invalidate];
	self.audioLevelTimer = nil;
    
	[self.recorder stop];
    self.recorder.delegate = nil;
    self.recorder = nil;
    
	[AppDelegate AudioSession_Default];
}

- (void)audioLevelTimerCallback:(NSTimer *)timer
{
    [self.recorder updateMeters];
	double avg = [self.recorder averagePowerForChannel:0]; // on a -160 to 0 scale
//	NSLog(@"avg: %f", avg);
	double lowerLimit = -70; //adjust this higher to make the quiet state larger/fatter
    if (avg < lowerLimit) avg = lowerLimit;
    double volumePercentage = ((avg + (lowerLimit*-1)) * (100/(lowerLimit * -1))) / 100;
	
//	// Simulate a bit of noise
//	if (volumePercentage == 0) {
//		int r = arc4random() % 10;
//		volumePercentage = (float)r / 100.0f;
//	}
	
    meterHeight_1 = meterHeight_2;
    meterHeight_2 = meterHeight_3;
    meterHeight_3 = meterHeight_4;
    meterHeight_4 = meterHeight_5;
    meterHeight_5 = meterHeight_6;

	float maxHeight = self.view.frame.size.height;
	float newVal = maxHeight * volumePercentage;
//	NSLog(@"volPer: %f  -  maxHeight: %f  -  newHeight: %f", volumePercentage, maxHeight, newVal);
	meterHeight_6 = newVal;
	
    self.vwVUMeter_1.frame = CGRectMake(self.vwVUMeter_1.frame.origin.x, maxHeight-meterHeight_1, self.vwVUMeter_1.frame.size.width, meterHeight_1);
    self.vwVUMeter_2.frame = CGRectMake(self.vwVUMeter_2.frame.origin.x, maxHeight-meterHeight_2, self.vwVUMeter_2.frame.size.width, meterHeight_2);
    self.vwVUMeter_3.frame = CGRectMake(self.vwVUMeter_3.frame.origin.x, maxHeight-meterHeight_3, self.vwVUMeter_3.frame.size.width, meterHeight_3);
    self.vwVUMeter_4.frame = CGRectMake(self.vwVUMeter_4.frame.origin.x, maxHeight-meterHeight_4, self.vwVUMeter_4.frame.size.width, meterHeight_4);
    self.vwVUMeter_5.frame = CGRectMake(self.vwVUMeter_5.frame.origin.x, maxHeight-meterHeight_5, self.vwVUMeter_5.frame.size.width, meterHeight_5);
	self.vwVUMeter_6.frame = CGRectMake(self.vwVUMeter_6.frame.origin.x, maxHeight-meterHeight_6, self.vwVUMeter_6.frame.size.width, meterHeight_6);

//	NSLog(@"1: %@", NSStringFromCGRect(self.vwVUMeter_1.frame));
//	NSLog(@"2: %@", NSStringFromCGRect(self.vwVUMeter_2.frame));
//	NSLog(@"3: %@", NSStringFromCGRect(self.vwVUMeter_3.frame));
//	NSLog(@"4: %@", NSStringFromCGRect(self.vwVUMeter_4.frame));
//	NSLog(@"5: %@", NSStringFromCGRect(self.vwVUMeter_5.frame));
//	NSLog(@"6: %@", NSStringFromCGRect(self.vwVUMeter_6.frame));
}

@end
