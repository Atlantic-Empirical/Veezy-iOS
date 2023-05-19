//
//  OREventsView.m
//  OneCent
//
//  Created by Thomas Purnell-Fisher on 12/15/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import "OREventsView.h"
#import "OREpicEvent.h"
#import "OREventListView.h"
#import "OREventCell.h"
#import "ORLeadEventPanel.h"

@interface OREventsView () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSArray *events;
@property (nonatomic, strong) OREpicEvent *selectedEvent;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) ORLeadEventPanel *leadEventPanel;

@end

@implementation OREventsView

static NSString *eventCell = @"eventCell";

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
	
	// NAV BAR
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) [self setEdgesForExtendedLayout:UIRectEdgeNone];
    self.title = @"Events";
	self.screenName = @"EventsParent";
	
    if (self.navigationController.childViewControllers.count == 1) {
        // Camera as left bar button
        UIBarButtonItem *camera = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"camera-icon-black-40x"] style:UIBarButtonItemStylePlain target:RVC action:@selector(showCamera)];
        self.navigationItem.leftBarButtonItem = camera;
        
        // Right swipe to open camera
        UISwipeGestureRecognizer *rightSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:RVC action:@selector(showCamera)];
        rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
        [self.view addGestureRecognizer:rightSwipe];
    }

	// TABLE
	[self.tblEvents registerNib:[UINib nibWithNibName:@"OREventCell" bundle:nil] forCellReuseIdentifier:eventCell];
	[self refreshEvents];
	
	// REFRESH CONTROL
    UITableViewController *tableViewController = [[UITableViewController alloc] init];
    tableViewController.tableView = self.tblEvents;
    
	self.refreshControl = [[UIRefreshControl alloc] init];
	[self.refreshControl addTarget:self action:@selector(refreshEvents) forControlEvents:UIControlEventValueChanged];
	self.refreshControl.tintColor = [APP_COLOR_FOREGROUND colorWithAlphaComponent:0.3f];
    tableViewController.refreshControl = self.refreshControl;
	
	[self setupLeadEvent];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Lead Event

- (void)setupLeadEvent
{
	self.viewLeadEvent.hidden = YES;
	
	if ([CurrentUser userIsInTest:@"1"] || AppDelegate.leadEvent)
	{
		CGRect f = self.viewTableParent.frame;
		f.origin.y = self.viewLeadEvent.frame.origin.y + self.viewLeadEvent.frame.size.height;
		f.size.height = self.view.frame.size.height - self.viewLeadEvent.frame.size.height;
		self.viewTableParent.frame = f;
		DLog(@"%@", NSStringFromCGRect(f));
		
		self.leadEventPanel = [[ORLeadEventPanel alloc] initWithNibName:@"ORLeadEventPanel" bundle:nil];
		[self.viewSponsorViewHost addSubview:self.leadEventPanel.view];
		
		self.viewLeadEvent.hidden = NO;
	}
}

#pragma mark - Refresh Events

- (void)refreshEvents
{
	self.tblEvents.hidden = YES;
	
//	[ApiEngine eventsForLatitude:LocMgr.location.coordinate.latitude andLongitude:LocMgr.location.coordinate.longitude completion:^(NSError *error, NSArray *result) {
//		if (error) {
//			
//		} else {
//			self.events = result;
//			[self.tblEvents reloadData];
//			[self.refreshControl endRefreshing];
//		}
//	}];
}

#pragma mark - UITableViewDatasource / UITableViewDelegate

- (int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return self.events.count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	OREventCell	*cell = [tableView dequeueReusableCellWithIdentifier:eventCell forIndexPath:indexPath];
    if (!cell) cell = [[OREventCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:eventCell];
    
    OREpicEvent *event = self.events[indexPath.row];
	cell.event = event;
	cell.parentNavigationController = self.navigationController;
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    self.selectedEvent = self.events[indexPath.row];
    
    OREventListView *mv = [[OREventListView alloc] initWithEvent:self.selectedEvent];
    [self.navigationController pushViewController:mv animated:YES];
}

@end
