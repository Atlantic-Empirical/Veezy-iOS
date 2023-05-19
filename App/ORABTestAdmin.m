//
//  ORABTestAdmin.m
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 2/2/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "ORABTestAdmin.h"

@interface ORABTestAdmin ()

@end

@implementation ORABTestAdmin

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.title = @"AB Tests";
    
    if (self.navigationController.childViewControllers.count == 1) {
        // Camera as left bar button
        UIBarButtonItem *camera = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"camera-icon-black-40x"] style:UIBarButtonItemStylePlain target:RVC action:@selector(showCamera)];
        self.navigationItem.leftBarButtonItem = camera;
    }
    
	[self loadCurrentValues];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UI

- (IBAction)swFIFA_ValueChanged:(UISwitch*)sender {
	[self setTest:1 on:sender.isOn];
}

#pragma mark - Persistence

- (void)loadCurrentValues
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *FIFA = [defaults objectForKey:@"abtest-1"];
	if (FIFA)
		[self.swFIFA setOn:YES];
}

- (void)setTest:(int)testId on:(BOOL)on
{
	NSString *testIdString = [NSString stringWithFormat:@"abtest-%d", testId];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if (on) {
		[CurrentUser.abTests addObject:testIdString];
		[defaults setObject:[NSString stringWithFormat:@"%d", testId] forKey:testIdString];
	} else {
		[CurrentUser.abTests removeObject:testIdString];
		[defaults removeObjectForKey:testIdString];
	}
	[defaults synchronize];
}

@end
