//
//  ORFifaStadiumParentViewController.m
//  Cloudcam
//
//  Created by Thomas Purnell-Fisher on 2/4/14.
//  Copyright (c) 2014 Orooso, Inc. All rights reserved.
//

#import "OREventVenueListView.h"
#import "OREventVenueCell.h"
#import "OREpicEventVenue.h"
#import "OREventVenueView.h"
#import "OREpicEvent.h"

#define STADIUM_IMG_URL @"https://cloudcam-static.s3.amazonaws.com/%@-160x64.png"

@interface OREventVenueListView ()

@property (strong, nonatomic) OREpicEvent *event;

@end

@implementation OREventVenueListView

static NSString *cellIdentifier = @"cellIdentifier";

- (id)initWithEvent:(OREpicEvent*)event
{
    self = [super initWithNibName:@"OREventVenueListView" bundle:nil];
    if (self) {
        _event = event;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) [self setEdgesForExtendedLayout:UIRectEdgeNone];
	self.title = @"Venues";
	
    if (self.navigationController.childViewControllers.count == 1) {
        // Camera as left bar button
        UIBarButtonItem *camera = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"camera-icon-black-40x"] style:UIBarButtonItemStylePlain target:RVC action:@selector(showCamera)];
        self.navigationItem.leftBarButtonItem = camera;
        
        // Right swipe to open camera
        UISwipeGestureRecognizer *rightSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:RVC action:@selector(showCamera)];
        rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
        [self.view addGestureRecognizer:rightSwipe];
    }

	[self.tblMain registerNib:[UINib nibWithNibName:@"OREventVenueCell" bundle:nil] forCellReuseIdentifier:cellIdentifier];

	[self setupForEvent];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Setup

- (void)setupForEvent
{
//	self.venues = [NSMutableArray arrayWithCapacity:14];
//	
//	[self.venues addObject:[[OREpicEventVenue alloc] initWithName:@"Rio de Janeiro" andDescription:@"Estádio do Maracanã" andLocationLat:-22.912167 andLocationLng:-43.230164 andImageUrlString:[NSString stringWithFormat:STADIUM_IMG_URL, @"fifa-wc-stadium-rio"]]];
//
//	[self.venues addObject:[[OREpicEventVenue alloc] initWithName:@"Brasília" andDescription:@"Estádio Nacional Mané Garrincha" andLocationLat:-15.7835 andLocationLng:-47.899164 andImageUrlString:[NSString stringWithFormat:STADIUM_IMG_URL, @"fifa-wc-stadium-brasilia"]]];
//
//	[self.venues addObject:[[OREpicEventVenue alloc] initWithName:@"São Paulo" andDescription:@"Arena Corinthians" andLocationLat:-23.545531 andLocationLng:-46.473372 andImageUrlString:[NSString stringWithFormat:STADIUM_IMG_URL, @"fifa-wc-stadium-sp"]]];
//
//	[self.venues addObject:[[OREpicEventVenue alloc] initWithName:@"Fortaleza" andDescription:@"Estádio Castelão" andLocationLat:-3.807267 andLocationLng:-38.522481 andImageUrlString:[NSString stringWithFormat:STADIUM_IMG_URL, @"fifa-wc-stadium-fortaleza"]]];
//
//	[self.venues addObject:[[OREpicEventVenue alloc] initWithName:@"Belo Horizonte" andDescription:@"Estádio Mineirão" andLocationLat:-19.865833 andLocationLng:-43.970833 andImageUrlString:[NSString stringWithFormat:STADIUM_IMG_URL, @"fifa-wc-stadium-belo"]]];
//
//	[self.venues addObject:[[OREpicEventVenue alloc] initWithName:@"Porto Alegre" andDescription:@"Estádio Beira-Rio" andLocationLat:-30.065614 andLocationLng:-51.236086 andImageUrlString:[NSString stringWithFormat:STADIUM_IMG_URL, @"fifa-wc-stadium-portoalegre"]]];
//
//	[self.venues addObject:[[OREpicEventVenue alloc] initWithName:@"Salvador" andDescription:@"Arena Fonte Nova" andLocationLat:-12.978611 andLocationLng:-38.504167 andImageUrlString:[NSString stringWithFormat:STADIUM_IMG_URL, @"fifa-wc-stadium-salvadro"]]];
//
//	[self.venues addObject:[[OREpicEventVenue alloc] initWithName:@"Recife" andDescription:@"Arena Pernambuco" andLocationLat:-8.04 andLocationLng:-35.008056 andImageUrlString:[NSString stringWithFormat:STADIUM_IMG_URL, @"fifa-wc-stadium-recife"]]];
//
//	[self.venues addObject:[[OREpicEventVenue alloc] initWithName:@"Cuiabá" andDescription:@"Arena Pantanal" andLocationLat:-15.603056 andLocationLng:-56.120556 andImageUrlString:[NSString stringWithFormat:STADIUM_IMG_URL, @"fifa-wc-stadium-cuiaba"]]];
//
//	[self.venues addObject:[[OREpicEventVenue alloc] initWithName:@"Manaus" andDescription:@"Arena Amazônia" andLocationLat:-3.083056 andLocationLng:-60.028056 andImageUrlString:[NSString stringWithFormat:STADIUM_IMG_URL, @"fifa-wc-stadium-manaus"]]];
//
//	[self.venues addObject:[[OREpicEventVenue alloc] initWithName:@"Natal" andDescription:@"Arena das Dunas" andLocationLat:-5.828939 andLocationLng:-35.213864 andImageUrlString:[NSString stringWithFormat:STADIUM_IMG_URL, @"fifa-wc-stadium-natal"]]];
//
//	[self.venues addObject:[[OREpicEventVenue alloc] initWithName:@"Curitiba" andDescription:@"Arena da Baixada" andLocationLat:-25.448333 andLocationLng:-49.276944 andImageUrlString:[NSString stringWithFormat:STADIUM_IMG_URL, @"fifa-wc-stadium-curitiba"]]];

}

#pragma mark - UITableViewDelegate

- (int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return self.event.venues.count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	OREventVenueCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
	
	cell.backgroundColor = [UIColor whiteColor];
	cell.textLabel.textColor = APP_COLOR_FOREGROUND;
	cell.detailTextLabel.textColor = APP_COLOR_FOREGROUND;
	cell.navigationController = self.navigationController;
	
	cell.venue = self.event.venues[indexPath.row];
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
	OREventVenueView *vc = [[OREventVenueView alloc] initWithVenue:self.event.venues[indexPath.row]];
	[RVC pushToMainViewController:vc completion:nil];
}

@end
