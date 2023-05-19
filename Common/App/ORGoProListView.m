//
//  ORGoProListView.m
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 5/18/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "ORGoProListView.h"
#import "ORGoProStaticVideo.h"
#import "ORGoProEngine.h"

@interface ORGoProListView () <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) NSArray *videos;

@property (strong, nonatomic) ORGoProEngine *gpe;

@end

@implementation ORGoProListView

static NSString *CellIdentifier = @"CellIdentifier";

- (id)initWithGoProEngine:(ORGoProEngine*)gpe
{
    self = [super initWithNibName:@"ORGoProListView" bundle:nil];
    if (self) {
        // Custom initialization
		_gpe = gpe;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
	[self updateVideoListFromGoPro];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Setup

- (void)updateVideoListFromGoPro
{
    [self.gpe fetchRecordedVideosWithCompletion:^(NSError *error, NSArray *result) {
        if (error) {
            NSLog(@"Error: %@", error);
        } else {
			self.videos = result;
			[self.tblMain reloadData];
        }
    }];
}

#pragma mark - UI

- (IBAction)btnClose_TouchUpInside:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableViewDelegate

- (int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return self.videos.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return @"Videos on your GoPro™";
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
	}
	
	cell.textLabel.text = self.videos[indexPath.row];
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];

}

@end
