//
//  ORMapView.m
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 11/20/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import "ORMapView.h"
#import "ORMapHost.h"
#import "OREpicEvent.h"
#import "ORMapSearchView.h"
#import "ORGooglePlaceDetails.h"
#import "ORGooglePlaceDetailsGeometry.h"
#import "ORMapDateRangeSelectorView.h"
#import <QuartzCore/QuartzCore.h>
#import "OREpicApiEngine.h"
#import "ORGooglePlaceDetailsGeometryLocation.h"

@interface ORMapView ()

@property (strong, nonatomic) ORMapHost *mh;
@property (nonatomic, assign) BOOL inDiscoveryMode;
@property (nonatomic, strong) OREpicEvent *event;
@property (nonatomic, strong) ORMapSearchView *searchView;
@property (nonatomic, strong) ORMapDateRangeSelectorView *dateSelectorView;
@property (nonatomic, strong) NSMutableOrderedSet *markerVideoIds;
@property (nonatomic, strong) NSString *currentDateRange;
@property (nonatomic, assign) CLLocationDegrees latitude;
@property (nonatomic, assign) CLLocationDegrees longitude;
@property (nonatomic, strong) NSArray *videos;

@end

@implementation ORMapView

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initForDiscovery
{
    self = [super initWithNibName:@"ORMapView" bundle:nil];
    if (self) {
		_inDiscoveryMode = YES;
    }
    return self;
}

- (id)initWithEvent:(OREpicEvent*)event
{
    self = [super initWithNibName:@"ORMapView" bundle:nil];
    if (self) {
		_event = event;
    }
    return self;
}

- (id)initWithVideos:(NSArray *)videos
{
    self = [super initWithNibName:nil bundle:nil];
    if (!self) return nil;
    
    self.videos = videos;
    
    return self;
}

- (id)initWithLatitude:(CLLocationDegrees)latitude longitude:(CLLocationDegrees)longitude
{
    self = [super initWithNibName:@"ORMapView" bundle:nil];
    if (self) {
		_latitude = latitude;
        _longitude = longitude;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) [self setEdgesForExtendedLayout:UIRectEdgeNone];
	if (self.title == nil) {
		self.title = @"MapView";
	}

//    if (self.navigationController.childViewControllers.count == 1) {
//		UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:RVC action:@selector(showCamera)];
//        self.navigationItem.leftBarButtonItem = done;
//    }

	self.aiTimeRange.color = APP_COLOR_PRIMARY;

	[self registerForNotifications];

    NSMutableArray *markers = [NSMutableArray arrayWithCapacity:self.videos.count];
	
	if (self.inDiscoveryMode) {
		// Pin for my-location
		GMSMarker *m = [GMSMarker markerWithPosition:CLLocationCoordinate2DMake(AppDelegate.lastKnownLocation.coordinate.latitude, AppDelegate.lastKnownLocation.coordinate.longitude)];
		m.icon = [GMSMarker markerImageWithColor:APP_COLOR_PRIMARY];
		m.tappable = NO;
		m.appearAnimation = YES;
        [markers addObject:m];
	} else if (self.videos) {
		// Pin for videos
        for (OREpicVideo *video in self.videos) {
            GMSMarker *m = [self markerForVideo:video];
            [markers addObject:m];
        }
	} else if (self.event) {
		// Pin for event
		GMSMarker *m = [self markerForEvent:self.event];
        [markers addObject:m];
	} else {
		// Pin for other-location
		GMSMarker *m = [GMSMarker markerWithPosition:CLLocationCoordinate2DMake(self.latitude, self.longitude)];
		m.icon = [GMSMarker markerImageWithColor:APP_COLOR_PRIMARY];
		m.tappable = NO;
		m.appearAnimation = YES;
        [markers addObject:m];
	}

	self.btnMyLocation.hidden = !self.inDiscoveryMode;
	self.viewRangeParent.hidden = !self.inDiscoveryMode;
	
	self.mh = [[ORMapHost alloc] initWithMarkers:markers];
	self.mh.inDiscoveryMode = self.inDiscoveryMode;
    [self addChildViewController:self.mh];

	self.mh.view.frame = self.viewMapParent.bounds;
	[self.viewMapParent addSubview:self.mh.view];
	
	[AppDelegate styleView:self.btnMap];
	[AppDelegate styleView:self.btnSat];
	[AppDelegate styleView:self.btnTerrain];
	
	self.btnOpenRangeSelector.layer.cornerRadius = 4.0f;
//	self.btnMyLocation.layer.cornerRadius = 4.0f;
//	self.btnOpenRangeSelector.layer.shadowColor = [UIColor darkGrayColor].CGColor;
//	self.btnOpenRangeSelector.layer.shadowOffset = CGSizeMake(1.0f, 1.0f);
//	self.btnOpenRangeSelector.layer.shadowRadius = 4.0f;
//	self.btnOpenRangeSelector.layer.shadowOpacity = 0.92f;
//	self.viewRangeParent.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.view.bounds].CGPath;
	
	[self setupSearch];
	[self setupRangeSelector];
	[self.view bringSubviewToFront:self.btnMyLocation];
	
	self.lblNoDiscoveryVidsFound.text = [NSString stringWithFormat:@"No videos found in this area.\nZoom out to see more."];
}

- (void)viewWillAppear:(BOOL)animated
{
	self.mh.view.frame = self.viewMapParent.bounds; // needed when this view is opened from the map button on watch view, without this the tabbar space is not utilized by mh.view
	
	if (self.inDiscoveryMode) {
		[self refreshPinsForNewBounds:self.mh.mapView.projection.visibleRegion cb:nil];
    }
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

#pragma mark - Markers

- (void)addVideoMarkers:(NSArray *)videos
{
    for (OREpicVideo *video in videos) {
		[self.mh addMarker:[self markerForVideo:video] scroll:(video == videos[videos.count-1])];
    }
}

- (GMSMarker*)markerForVideo:(OREpicVideo*)video
{
	if (!video) return nil;
	GMSMarker *m = [[GMSMarker alloc] init];
	m.position = CLLocationCoordinate2DMake(video.latitude, video.longitude);
    m.title = (video.user.name) ?: video.autoTitle;
    m.snippet = [NSString stringWithFormat:@"%@ - %@", video.locationFriendlyName, video.friendlyDateString];
	m.userData = video;
	m.appearAnimation = YES;
    
	return m;
}

- (GMSMarker*)markerForEvent:(OREpicEvent*)event
{
	if (!event) return nil;
	GMSMarker *m = [[GMSMarker alloc] init];
	m.position = CLLocationCoordinate2DMake([event.latitude doubleValue], [event.longitude doubleValue]);
	m.title = [NSString stringWithFormat:@"%@", event.name];
	m.userData = event;
	m.appearAnimation = YES;
	return m;
}

#pragma mark - UI

- (IBAction)btnMap_TouchUpInside:(id)sender {
	self.mh.mapView.mapType = kGMSTypeNormal;
}

- (IBAction)btnSat_TouchUpInside:(id)sender {
	self.mh.mapView.mapType = kGMSTypeSatellite;
}

- (IBAction)btnTerrain_TouchUpInside:(id)sender {
	self.mh.mapView.mapType = kGMSTypeTerrain;
}

- (IBAction)btnOpenRangeSelector_TouchUpInside:(id)sender {
	if ([self rangeSelectorIsOpen])
		[self collapseRangeSelector];
	else
		[self expandRangeSelector];
}

- (IBAction)view_TimeRangeTouchCatcher_TouchUpInside:(id)sender {
	[self collapseRangeSelector];
}

- (IBAction)btnMyLocation_TouchUpInside:(id)sender {
	[self.mh flyToMyLocation];
}

#pragma mark - Custom

- (void)refreshPinsForNewBounds:(GMSVisibleRegion)vr cb:(ORBoolCompletion)completion
{
	DLog(@"refreshPinsForNewBounds");
	self.lblNoDiscoveryVidsFound.hidden = YES;
	
	__weak ORMapView *weakSelf = self;
    
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        ORMapView *strongSelf = weakSelf;
        if (!strongSelf) return;
        
		NSString *sw = [NSString stringWithFormat:@"%f,%f", vr.nearLeft.latitude, vr.nearLeft.longitude];
		NSString *ne = [NSString stringWithFormat:@"%f,%f", vr.farRight.latitude, vr.farRight.longitude];
		NSString *bounds = [NSString stringWithFormat:@"%@,%@", sw, ne];
		
        __weak ORMapView *weakSelf = strongSelf;
        
		[ApiEngine geoVids:bounds andStartTime:[strongSelf rangeStartDate] andEndTime:[strongSelf rangeEndDate] completion:^(NSError *error, NSArray *result) {
            ORMapView *strongSelf = weakSelf;
            if (!strongSelf) return;

			if (error) {
				if (completion) completion(error, NO);
			} else {
				DLog(@"%d videos found for map", result.count);

				if ((!result || result.count == 0) && !strongSelf.mh.markersVisible) {
					dispatch_async(dispatch_get_main_queue(), ^{
						strongSelf.lblNoDiscoveryVidsFound.hidden = NO;
					});
				}
					
				// REMOVE MARKERS THAT NO LONGER ARE INCLUDED IN THE RESULT
				NSMutableOrderedSet *keepers = [NSMutableOrderedSet orderedSetWithCapacity:result.count];
				for (NSString *vid in [strongSelf.markerVideoIds copy]) {
					for (OREpicVideo *v in result) {
						if ([vid isEqualToString:v.videoId]) {
							[keepers addObject:vid];
							[strongSelf.markerVideoIds removeObject:vid];
						}
					}
				}
				for (NSString *vid in strongSelf.markerVideoIds) {
					[strongSelf.mh removeMarkerForVideoId:vid];
                }
                
				strongSelf.markerVideoIds = keepers;
				
				// WE'RE DONE IF NO RESULTS
				if (result.count == 0) {
					strongSelf.lblNoDiscoveryVidsFound.hidden = NO;
					if (completion) completion(nil, YES);
					return;
				}

				// REMOVE VIDEOS FROM RESULT THAT ARE ALREADY ON THE MAP
				if (!strongSelf.markerVideoIds) {
					strongSelf.markerVideoIds = [NSMutableOrderedSet orderedSetWithCapacity:result.count];
                }
				
				NSMutableArray *itemsToRemove = [NSMutableArray array];
				for (NSString *videoId in strongSelf.markerVideoIds) {
					for (OREpicVideo *v in result) {
						if ([videoId isEqualToString:v.videoId]) {
							[itemsToRemove addObject:v];
                        }
					}
				}
                
				NSMutableArray *mutableResult = [result mutableCopy];
				[mutableResult removeObjectsInArray:itemsToRemove];
                
                __weak ORMapView *weakSelf = strongSelf;
				
				// GET FRIEND FOR EACH OF THE VIDEOS
				for (OREpicVideo *v in mutableResult) {
					[ApiEngine friendWithId:v.userId completion:^(NSError *error, OREpicFriend *user) {
						if (error) {
                            NSLog(@"Error: %@", error);
						} else {
							dispatch_async(dispatch_get_main_queue(), ^{
								
								// WE'VE GOT VIDEOS
								weakSelf.lblNoDiscoveryVidsFound.hidden = YES;
								
								// ADD MARKER
								GMSMarker *m = [GMSMarker markerWithPosition:CLLocationCoordinate2DMake(v.latitude, v.longitude)];
								m.title = user.name;
								m.snippet = [NSString stringWithFormat:@"%@ - %@", v.locationFriendlyName, v.friendlyDateString];
								m.userData = v;
								[weakSelf.mh addMarker:m scroll:NO];
							});
							[weakSelf.markerVideoIds addObject:v.videoId];
						}
					}];
					if (completion) completion(nil, YES); // do completion here, ok for now
				}
			}
		}];
	});
}

- (void)flyToCLLocation:(CLLocationCoordinate2D)location andName:(NSString*)name
{
	[self.mh flyToCLLocation:location andName:name];
}

#pragma mark - Search

- (void)setupSearch
{
	if (self.inDiscoveryMode) {
		self.searchView = [ORMapSearchView new];
		self.searchView.view.frame = self.viewSearch.bounds;
		[self.viewSearch addSubview:self.searchView.view];
		[self collapseSearch];
		self.viewSearch.hidden = NO;
	} else {
		self.viewSearch.hidden = YES;
	}
}

- (void)collapseSearch {
	CGRect f = self.viewSearch.frame;
	f.size.height = 30;
	f.size.width = 280;
	f.origin.x = 20;
	f.origin.y = 8;
	[UIView animateWithDuration:0.2f animations:^{
		self.viewSearch.frame = f;
	}];
}

- (void)expandSearch {
	CGRect f = self.viewSearch.frame;
	f.size.height = self.view.frame.size.height - f.origin.y;
	f.size.width = self.view.frame.size.width;
	f.origin.x = 0;
	f.origin.y = 0;
	[UIView animateWithDuration:0.2f animations:^{
		self.viewSearch.frame = f;
	}];
}

#pragma mark - NSNotifications

- (void)registerForNotifications
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORDiscoveryMapDidMove:) name:@"ORDiscoveryMapDidMove" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORGooglePlaceSelected:) name:@"ORGooglePlaceSelected" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORStartedPlaceSearch:) name:@"ORStartedPlaceSearch" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleOREndedPlaceSearch:) name:@"ORFinishedPlaceSearch" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORMapDateRangeSelected:) name:@"ORMapDateRangeSelected" object:nil];
}

- (void)handleORMapDateRangeSelected:(NSNotification*)n
{
	self.currentDateRange = n.object;
	[self collapseRangeSelector];
	self.aiTimeRange.hidden = NO;
    
    __weak ORMapView *weakSelf = self;
    
	[self refreshPinsForNewBounds:self.mh.mapView.projection.visibleRegion cb:^(NSError *error, BOOL result) {
        if (error) NSLog(@"Error: %@", error);
		weakSelf.aiTimeRange.hidden = YES;
	}];
}

- (void)handleORDiscoveryMapDidMove:(NSNotification*)n
{
	[self refreshPinsForNewBounds:((GMSProjection*)n.object).visibleRegion cb:nil];
}

- (void)handleORStartedPlaceSearch:(NSNotification*)n
{
	[self expandSearch];
}

- (void)handleOREndedPlaceSearch:(NSNotification*)n
{
	[self collapseSearch];
}

- (void)handleORGooglePlaceSelected:(NSNotification*)n
{
	ORGooglePlaceDetails *d = n.object;
	[self collapseSearch];
	if (d.geometry.viewport)
		[self.mh flyToViewport:d.geometry.viewport];
	else
		[self.mh flyToLocation:d.geometry.location andName:d.name];
}

#pragma mark - Range Selection

- (void)setupRangeSelector
{
	self.currentDateRange = @"2 weeks";
	[self.btnOpenRangeSelector setTitle:self.currentDateRange forState:UIControlStateNormal];
	self.dateSelectorView = [ORMapDateRangeSelectorView new];
	self.dateSelectorView.view.frame = self.viewRangeParent.bounds;
	self.dateSelectorView.view.alpha = 0.0f;
	[self.viewRangeParent insertSubview:self.dateSelectorView.view belowSubview:self.btnOpenRangeSelector];
}

- (BOOL)rangeSelectorIsOpen
{
	return self.viewRangeParent.frame.size.height > 30;
}

- (void)expandRangeSelector
{
	CGRect f = self.viewRangeParent.frame;
	f.size.height = 230;
	f.origin.y -= 200;
	[self animateRangeSelectorViewToFrame:f];
	self.view_TimeRangeTouchCatcher.hidden = NO;
}

- (void)collapseRangeSelector
{
	[self.btnOpenRangeSelector setTitle:self.currentDateRange forState:UIControlStateNormal];
	CGRect f = self.viewRangeParent.frame;
	f.size.height = 30;
	f.origin.y += 200;
	[self animateRangeSelectorViewToFrame:f];
	self.view_TimeRangeTouchCatcher.hidden = YES;
}

- (void)animateRangeSelectorViewToFrame:(CGRect)f
{
	[UIView animateWithDuration:0.3f delay:0.0f
						options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseInOut
					 animations:^{
						 self.viewRangeParent.frame = f;
						 self.dateSelectorView.view.alpha = (f.size.height>30) ? 1.0f : 0.0f;
						 self.btnOpenRangeSelector.alpha = (f.size.height>30) ? 0.0f : 1.0f;
					 } completion:^(BOOL finished) {
						 //
					 }];
}

- (NSDate*)rangeStartDate
{
	NSDateComponents *components = [[NSDateComponents alloc] init];
	
	if ([self.currentDateRange isEqualToString:@"10 min"]) {
		[components setMinute:(-1*10)];
	} else if ([self.currentDateRange isEqualToString:@"30 min"]) {
		[components setMinute:(-1*30)];
	} else if ([self.currentDateRange isEqualToString:@"1 hour"]) {
		[components setHour:(-1*1)];
	} else if ([self.currentDateRange isEqualToString:@"6 hours"]) {
		[components setHour:(-1*6)];
	} else if ([self.currentDateRange isEqualToString:@"12 hours"]) {
		[components setHour:(-1*12)];
	} else if ([self.currentDateRange isEqualToString:@"24 hours"]) {
		[components setHour:(-1*24)];
	} else if ([self.currentDateRange isEqualToString:@"2 days"]) {
		[components setHour:(-1*48)];
	} else if ([self.currentDateRange isEqualToString:@"1 week"]) {
		[components setHour:(-1*168)];
	} else if ([self.currentDateRange isEqualToString:@"2 weeks"]) {
		[components setHour:(-1*168*2)];
	} else if ([self.currentDateRange isEqualToString:@"1 month"]) {
		[components setHour:(-1*728)];
	} else if ([self.currentDateRange isEqualToString:@"6 months"]) {
		[components setHour:(-1*728*6)];
	} else if ([self.currentDateRange isEqualToString:@"1 year"]) {
		[components setHour:(-1*8736)];
	}
	
	NSDate *now = [NSDate date];
	NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSDate *startDate = [gregorian dateByAddingComponents:components toDate:now options:0];
	NSLog(@"startDate: %@", startDate);
	return startDate;
}

- (NSDate*)rangeEndDate
{
	NSDate *endTime = [NSDate date];
	return endTime;
}

@end
