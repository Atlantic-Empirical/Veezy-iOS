//
//  OREventFeaturedStuffView.m
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 2/28/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "OREventFeaturedStuffView.h"
#import "ORSimpleVideoListView.h"
#import "OREpicEvent.h"
#import "ORFeaturedCell_person.h"
#import "ORUserView.h"

@interface OREventFeaturedStuffView () <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) OREpicEvent *event;
@property (strong, nonatomic) ORSimpleVideoListView *videoListView;
@property (strong, nonatomic) NSArray *featuredPeople;

@end

@implementation OREventFeaturedStuffView

static NSString *cellId = @"CellId";

- (id)initWithEvent:(OREpicEvent*)event
{
    self = [super initWithNibName:@"OREventFeaturedStuffView" bundle:nil];
    if (self) {
        _event = event;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self.tblMain registerNib:[UINib nibWithNibName:@"ORFeaturedCell_person" bundle:nil] forCellReuseIdentifier:cellId];
	[self setup];
	[self refreshFeaturedPeopleList];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UI

- (IBAction)btnVideos_TouchUpInside:(id)sender {
	[self.viewHost bringSubviewToFront:self.videoListView.view];
	self.btnPeople.alpha = 0.8;
	self.btnVideos.alpha = 1.0;
}

- (IBAction)btnPeople_TouchUpInside:(id)sender {
	[self.viewHost bringSubviewToFront:self.tblMain];
	self.btnPeople.alpha = 1.0;
	self.btnVideos.alpha = 0.8;
}

#pragma mark - Custom

- (void)setup
{
	self.videoListView = [[ORSimpleVideoListView alloc] initWithNibName:@"ORSimpleVideoListView" bundle:nil];
	self.videoListView.view.frame = self.viewHost.bounds;
	[self.viewHost addSubview:self.videoListView.view];
	[self refreshFeaturedVideoList];
}

- (void)refreshFeaturedVideoList
{
	[ApiEngine featuredVideosForEvent:self.event.eventId completion:^(NSError *error, NSArray *result) {
		if (error) {
			DLog(@"Error refreshFeaturedVideoList() %@", error.localizedDescription);
		} else {
			self.videoListView.videos = result;
		}
	}];
}

- (void)refreshFeaturedPeopleList
{
	[ApiEngine featuredUsersForEvent:self.event.eventId completion:^(NSError *error, NSArray *result) {
		if (error) {
			DLog(@"Error refreshFeaturedVideoList() %@", error.localizedDescription);
		} else {
			self.featuredPeople = result;
			[self.tblMain reloadData];
		}
	}];
}

#pragma mark - UITableViewDatasource / UITableViewDelegate

- (int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return self.featuredPeople.count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
	id item = self.featuredPeople[indexPath.row];
	
	if ([item isKindOfClass:[OREpicFriend class]]) {
		ORFeaturedCell_person *cell = [tableView dequeueReusableCellWithIdentifier:cellId forIndexPath:indexPath];
		cell.featuredUser = item;
		cell.parentNavigationController = self.navigationController;
		return cell;
	}
	
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
	id item = self.featuredPeople[indexPath.row];
	
	if ([item isKindOfClass:[OREpicFriend class]]) {
		ORUserView *profile = [[ORUserView alloc] initWithFriend:item];
		if (self.navigationController)
			[self.navigationController pushViewController:profile animated:YES];
		else
			[RVC pushToMainViewController:profile completion:nil];
	}
}

@end
