//
//  ORLocationPicker.m
//  Session
//
//  Created by Thomas Purnell-Fisher on 11/13/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import "ORLocationPicker.h"
#import "ORGooglePlace.h"
#import "ORFoursquareVenue.h"
#import "ORFoursquareVenueLocation.h"
#import "ORGooglePlacesAutoCompleteResult.h"
#import "ORGooglePlacesAutoCompleteItem.h"

#define LOCATION_UPDATE_TIMEOUT 10.0f

@interface ORLocationPicker () <UIScrollViewDelegate>

@property (strong, nonatomic) NSArray *places;
@property (nonatomic, strong) NSMutableArray *filteredPlaces;
@property (nonatomic, strong) CLLocation *currentLocation;
@property (strong, nonatomic) NSArray *googlePlacesSearchResults;
@property (nonatomic, strong) UIRefreshControl *refresh;
@property (nonatomic, assign) BOOL isWaitingForLocation;
@property (nonatomic, weak) MKNetworkOperation *googleOP;

@end

@implementation ORLocationPicker

static NSString *locationCell = @"locationCell";

- (void)dealloc
{
    self.tbMain.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithPlaces:(NSArray*)places selectedPlace:(ORFoursquareVenue *)place location:(CLLocation *)location
{
    self = [super initWithNibName:@"ORLocationPicker" bundle:nil];
    if (self) {
        // Custom initialization
		_places = places;
		_selectedPlace = place;
        _currentLocation = location;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORLocationUpdated:) name:@"ORLocationUpdated" object:nil];

	if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) [self setEdgesForExtendedLayout:UIRectEdgeNone];
    self.title = @"Location";
	self.screenName = @"LocationPicker";

    if (self.navigationController.viewControllers.count < 2) {
        UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAction:)];
        self.navigationItem.rightBarButtonItem = cancel;
    }

    [self txtSearch_EditingChanged:nil];

    UITableViewController *tableViewController = [[UITableViewController alloc] init];
    tableViewController.tableView = self.tbMain;
    
	self.refresh = [[UIRefreshControl alloc] init];
    [self.refresh addTarget:self action:@selector(refreshAction) forControlEvents:UIControlEventValueChanged];
	self.refresh.tintColor = [APP_COLOR_PRIMARY colorWithAlphaComponent:0.3f];
    tableViewController.refreshControl = self.refresh;
    
    if ((self.currentLocation.coordinate.latitude != 0 || self.currentLocation.coordinate.longitude != 0) && self.places.count == 0) {
        [self reloadPlaces];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    if (!AppDelegate.isAllowedToUseLocationManager) {
        self.isWaitingForLocation = YES;
        [RVC requestLocationPermissionFromUser];
    }
}

- (void)cancelAction:(id)sender
{
	[self close];
}

- (void)close
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(cancelLocationUpdate) object:nil];
    
    if (self.navigationController.viewControllers.count > 1) {
        [self.navigationController popViewControllerAnimated:YES];
    } else if (self.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [RVC showCamera];
    }
}

- (void)handleORLocationUpdated:(NSNotification *)n
{
    self.currentLocation = AppDelegate.lastKnownLocation;
    
    if (self.isWaitingForLocation) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(cancelLocationUpdate) object:nil];
        
        self.isWaitingForLocation = NO;
        [self reloadPlaces];
    }
}

#pragma mark - UI

- (void)txtSearch_EditingChanged:(id)sender
{
    NSString *query = self.txtSearch.text;
    
    if (!query || [query isEqualToString:@""]) {
        self.filteredPlaces = [self.places mutableCopy];
        if (!self.filteredPlaces) self.filteredPlaces = [NSMutableArray arrayWithCapacity:1];
        
        ORFoursquareVenue *venue = [[ORFoursquareVenue alloc] init];
        venue.name = @"Remove Location";
        venue.url = @"remove_location";
        
        [self.filteredPlaces insertObject:venue atIndex:0];
		[self.tbMain reloadData];

    } else {
        self.filteredPlaces = [NSMutableArray arrayWithCapacity:1];
        BOOL foundExact = NO;
        
        for (ORFoursquareVenue *place in self.places) {
            NSUInteger result = [place.name rangeOfString:query options:NSCaseInsensitiveSearch].location;
            
            if (result != NSNotFound) {
                if ([place.name caseInsensitiveCompare:query] == NSOrderedSame) foundExact = YES;
                [self.filteredPlaces addObject:place];
            }
        }
        
        if (!foundExact) {
            ORFoursquareVenueLocation *location = [[ORFoursquareVenueLocation alloc] init];
            location.lat = @(self.currentLocation.coordinate.latitude);
            location.lng = @(self.currentLocation.coordinate.longitude);
            
            ORFoursquareVenue *venue = [[ORFoursquareVenue alloc] init];
            venue.name = query;
            venue.location = location;
            venue.addedManually = YES;
            venue.custom = YES;
            
            [self.filteredPlaces insertObject:venue atIndex:0];
        }
		
        [self.tbMain reloadData];
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(performGooglePlaceSearch) object:nil];
        [self performSelector:@selector(performGooglePlaceSearch) withObject:nil afterDelay:0.25f];
    }
}

- (void)btnCancelSearch_TouchUpInside:(id)sender
{
    self.selectedPlace = nil;
	[self close];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	[self.view endEditing:YES];
}

#pragma mark - Refresh

- (void)refreshAction
{
    [self.refresh beginRefreshing];
    
    if (AppDelegate.isAllowedToUseLocationManager && !AppDelegate.isUpdatingLocation) {
        [self performSelector:@selector(cancelLocationUpdate) withObject:nil afterDelay:LOCATION_UPDATE_TIMEOUT];
        
        self.isWaitingForLocation = YES;
        [AppDelegate updateLocation];
    } else {
        [self reloadPlaces];
    }
    
}

- (void)cancelLocationUpdate
{
    self.isWaitingForLocation = NO;
    [self reloadPlaces];
}

- (void)reloadPlaces
{
	[AppDelegate.places getPlacesForLocation:self.currentLocation andRadiusMeters:PLACE_SEARCH_RADIUS completion:^(NSError *error, NSArray *venues) {
		if (error) DLog(@"problem getting places: %@", error.localizedDescription);
		
        if (venues && venues.count > 0) {
            self.places = venues;
			[self txtSearch_EditingChanged:nil];
        } else {
            self.places = nil;
        }
        
        [self.refresh endRefreshing];
	}];
}

#pragma mark - UITableViewDatasource / UITableViewDelegate

- (int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return self.filteredPlaces.count + 1;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:locationCell];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:locationCell];
    cell.imageView.image = nil;
	
	if (indexPath.row < self.filteredPlaces.count) {
		// Normal place cell
		ORFoursquareVenue *pl = (ORFoursquareVenue*)self.filteredPlaces[indexPath.row];
		cell.textLabel.text = (!pl.addedManually) ? pl.name : [NSString stringWithFormat:@"Add \"%@\"", pl.name];
		cell.backgroundColor = [UIColor clearColor];
		
		if ([pl.url isEqualToString:@"remove_location"]) {
			cell.textLabel.textColor = [UIColor redColor];
		} else {
			cell.textLabel.textColor = [UIColor blackColor];
		}
	} else {
		// Attribution cell
		if ([self.txtSearch.text isEqualToString:@""]) {
			// Foursquare
			cell.imageView.image = [UIImage imageNamed:@"foursquare-logo-44x12"];
			cell.textLabel.text = @"Powered by Foursquare";
		} else {
			// Google Places
			cell.imageView.image = [UIImage imageNamed:@"powered-by-google-on-white-78x12"];
			cell.textLabel.text = @"Google Places";
		}
	}
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (indexPath.row >= self.filteredPlaces.count) return;
    
    ORFoursquareVenue *pl = self.filteredPlaces[indexPath.row];
    self.selectedPlace = pl;
	
    if ([pl.url isEqualToString:@"remove_location"]) {
        self.selectedPlace = nil;
    } else if (pl.addedManually || pl.custom) {
        [AppDelegate.places addCustomPlace:pl];
    }
    
    [self.txtSearch resignFirstResponder];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORLocationSelected" object:self.selectedPlace];
	[self close];
}

#pragma mark - Places Search

- (void)performGooglePlaceSearch
{
	if (!GoogleEngine) GoogleEngine = [[ORGoogleEngine alloc] initWithDelegate:nil];
    if (self.googleOP) [self.googleOP cancel];
    
    NSLog(@"Google Autocomplete for %@", self.txtSearch.text);

	self.googleOP = [GoogleEngine placesAutoComplete:self.txtSearch.text completion:^(NSError *error, ORGooglePlacesAutoCompleteResult *result) {
		if (error) {
			NSLog(@"Error: %@", error);
		} else {
            if (!self.filteredPlaces) self.filteredPlaces = [NSMutableArray arrayWithCapacity:1];
            
			for (ORGooglePlacesAutoCompleteItem *p in result.predictions) {
				[self.filteredPlaces addObject:[[ORFoursquareVenue alloc] initWithGooglePlaceAutoCompleteItem:p]];
            }
        }
        
        [self.tbMain reloadData];
	}];
}

@end
