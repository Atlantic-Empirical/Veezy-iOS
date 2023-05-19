//
//  ORFifaStadiumViewViewController.m
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 2/4/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "OREventVenueView.h"
#import "OREpicEventVenue.h"
#import "OREpicFeedItem.h"
#import "ORSimpleVideoListView.h"

@interface OREventVenueView ()

@property (strong, nonatomic) OREpicEventVenue *venue;
@property (strong, nonatomic) ORSimpleVideoListView *videoListView;

@end

@implementation OREventVenueView

- (id)initWithVenue:(OREpicEventVenue*)venue
{
    self = [super initWithNibName:@"OREventVenueView" bundle:nil];
    if (self) {
        _venue = venue;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.title = self.venue.name;
	
    if (self.navigationController.childViewControllers.count == 1) {
        // Camera as left bar button
        UIBarButtonItem *camera = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"camera-icon-black-40x"] style:UIBarButtonItemStylePlain target:RVC action:@selector(showCamera)];
        self.navigationItem.leftBarButtonItem = camera;
        
        // Right swipe to open camera
        UISwipeGestureRecognizer *rightSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:RVC action:@selector(showCamera)];
        rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
        [self.view addGestureRecognizer:rightSwipe];
    }
	
//	// Image
//	if (self.venue.imageUrlString) {
//		[[ORCachedEngine sharedInstance] imageAtURL:[NSURL URLWithString:self.venue.imageUrlString] size:self.imgStadium.frame.size completion:^(NSError *error, MKNetworkOperation *op, UIImage *image, BOOL cached) {
//			if (error) {
//				NSLog(@"Error: %@", error);
//			} else {
//				if (image) {
//					self.imgStadium.image = image;
//				}
//			}
//		}];
//	}
	
	// Video List
	[self loadVideoList];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Video List

- (void)loadVideoList
{
	self.videoListView = [[ORSimpleVideoListView alloc] initWithNibName:@"ORSimpleVideoListView" bundle:nil];
	self.videoListView.navigationController = self.navigationController;
	self.videoListView.view.frame = self.videoListParent.bounds;
	[self.videoListParent addSubview:self.videoListView.view];

    [ApiEngine videosForVenue:self.venue.venueId completion:^(NSError *error, NSArray *result) {
		if (!result || result.count == 0) {
			self.lblNoVideos.hidden = NO;
		} else {
            self.videoListView.videos = result;
			self.lblNoVideos.hidden = YES;
        }
    }];
}

@end
