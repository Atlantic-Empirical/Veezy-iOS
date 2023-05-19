//
//  ORFifaWc2014.m
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 2/2/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "OREventView.h"
#import "OREventVenueListView.h"
#import "OREventHomeView.h"
#import "ORMapView.h"
#import "OREpicEvent.h"
#import "OREventFeaturedStuffView.h"

@interface OREventView ()

@property (strong, nonatomic) OREpicEvent *event;
@property (strong, nonatomic) OREventVenueListView	*venueView;
@property (strong, nonatomic) ORMapView *mapView;
@property (strong, nonatomic) OREventHomeView *eventHomeView;
@property (strong, nonatomic) OREventFeaturedStuffView *featuredStuffView;

@end

@implementation OREventView

static NSString *cellIdentifier = @"cellIdentifier";

- (void)dealloc
{
    self.scrollerMain.delegate = nil;
}

- (id)initWithEvent:(OREpicEvent*)event
{
    self = [super initWithNibName:@"OREventView" bundle:nil];
    if (self) {
		_event = event;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self setupViews];
	
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) [self setEdgesForExtendedLayout:UIRectEdgeNone];
	self.title = self.event.name;
	
    if (self.navigationController.childViewControllers.count == 1) {
        // Camera as left bar button
        UIBarButtonItem *camera = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"camera-icon-black-40x"] style:UIBarButtonItemStylePlain target:RVC action:@selector(showCamera)];
        self.navigationItem.leftBarButtonItem = camera;
        
        // Right swipe to open camera
        UISwipeGestureRecognizer *rightSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:RVC action:@selector(showCamera)];
        rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
        [self.view addGestureRecognizer:rightSwipe];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UI

- (IBAction)btnHome_TouchUpInside:(UIButton*)sender {
	CGPoint p = CGPointMake(sender.tag * self.scrollerMain.frame.size.width, 0);
	[self.scrollerMain setContentOffset:p animated:YES];
	[self moveIndicatorToFrame:sender.frame];
}

- (IBAction)btnMap_TouchUpInside:(UIButton*)sender {
	CGPoint p = CGPointMake(sender.tag * self.scrollerMain.frame.size.width, 0);
	[self.scrollerMain setContentOffset:p animated:YES];
	[self moveIndicatorToFrame:sender.frame];
}

- (IBAction)btnVenues_TouchUpInside:(UIButton*)sender {
	CGPoint p = CGPointMake(sender.tag * self.scrollerMain.frame.size.width, 0);
	[self.scrollerMain setContentOffset:p animated:YES];
	[self moveIndicatorToFrame:sender.frame];
}

- (IBAction)btnList_TouchUpInside:(UIButton*)sender {
	CGPoint p = CGPointMake(sender.tag * self.scrollerMain.frame.size.width, 0);
	[self.scrollerMain setContentOffset:p animated:YES];
	[self moveIndicatorToFrame:sender.frame];
}

- (void)moveIndicatorToFrame:(CGRect)frame
{
	[UIView animateWithDuration:0.2f delay:0.0f
						options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut
					 animations:^{
						 self.viewActiveAreaIndicator.frame = frame;
					 } completion:^(BOOL finished) {
						 //
					 }];
}

#pragma mark - Views

- (void)setupViews
{
	
	// Banner
	if (self.event.bannerImageURL) {
		[[ORCachedEngine sharedInstance] imageAtURL:self.event.bannerImageURL maxAgeMinutes:CACHE_MAX_AGE_MIN completion:^(NSError *error, MKNetworkOperation *op, UIImage *image, BOOL cached) {
			if (error) {
				NSLog(@"Error: %@", error);
			} else {
				if (image) {
					self.imgBrandingBanner.image = image;
				}
			}
		}];
		self.lblEventName.text = @"";
	} else {
		self.imgBrandingBanner.image = nil;
		self.lblEventName.text = self.event.name;
	}
	
	// Scroller
	self.scrollerMain.contentSize = CGSizeMake(4 * self.scrollerMain.frame.size.width, self.scrollerMain.frame.size.height);
	
//	// Home
//	self.eventHomeView = [[OREventHomeView alloc] initWithEvent:self.event];
//	self.eventHomeView.view.frame = CGRectMake(0, 0, self.scrollerMain.frame.size.width, self.scrollerMain.frame.size.height);
//	[self.scrollerMain addSubview:self.eventHomeView.view];

	// Map
	self.mapView = [[ORMapView alloc] initForDiscovery];
	self.mapView.view.frame = CGRectMake(0 * self.scrollerMain.frame.size.width, 0, self.scrollerMain.frame.size.width, self.scrollerMain.frame.size.height);
	[self.mapView flyToCLLocation:CLLocationCoordinate2DMake([self.event.latitude doubleValue], [self.event.longitude doubleValue]) andName:self.event.name];
	[self.scrollerMain addSubview:self.mapView.view];

	// Venues
	self.venueView = [[OREventVenueListView alloc] initWithEvent:self.event];
	self.venueView.view.frame = CGRectMake(1 * self.scrollerMain.frame.size.width, 0, self.scrollerMain.frame.size.width, self.scrollerMain.frame.size.height);
	[self.scrollerMain addSubview:self.venueView.view];

	// Featured
	self.featuredStuffView = [[OREventFeaturedStuffView alloc] initWithEvent:self.event];
	self.featuredStuffView.view.frame = CGRectMake(2 * self.scrollerMain.frame.size.width, 0, self.scrollerMain.frame.size.width, self.scrollerMain.frame.size.height);
	[self.scrollerMain addSubview:self.featuredStuffView.view];
	
}

@end
