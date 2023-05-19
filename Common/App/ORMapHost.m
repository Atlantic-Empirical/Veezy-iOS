//
//  ORMapView.m
//  Epic
//
//  Created by Thomas Purnell-Fisher on 11/11/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import "ORMapHost.h"
#import "ORWatchView.h"
#import "OREpicVideoLocation.h"
#import "ORGooglePlaceDetailsGeometryViewport.h"
#import "ORGooglePlaceDetailsGeometryViewportNortheast.h"
#import "ORGooglePlaceDetailsGeometryViewportSouthwest.h"
#import "ORGooglePlaceDetailsGeometryLocation.h"

@interface ORMapHost () <GMSMapViewDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) GMSMarker *searchPlaceMarker;
@property (nonatomic, strong) UIAlertView *alertView;

@end

@implementation ORMapHost

- (void)dealloc
{
    self.alertView.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithMarkers:(NSMutableArray *)markers
{
    self = [super initWithNibName:nil bundle:nil];
    if (!self) return nil;
    
    self.markers = markers;
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self registerForNotifications];
	
	self.screenName = @"MapHost";
	
	GMSCameraPosition *camera;
    
    GMSMarker *marker = [self.markers firstObject];

	if (marker.position.latitude == 0 && marker.position.longitude == 0) {
		marker.position = CLLocationCoordinate2DMake(1.034377, -76.756088);
		camera = [GMSCameraPosition cameraWithLatitude:marker.position.latitude
											 longitude:marker.position.longitude
												  zoom:0];
	} else {
		camera = [GMSCameraPosition cameraWithLatitude:marker.position.latitude
											 longitude:marker.position.longitude
												  zoom:12];
	}
	

	self.mapView = [GMSMapView mapWithFrame:self.view.bounds camera:camera];
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.mapView.delegate = self;
	self.view = self.mapView;
    
	// Mapview settings
	self.mapView.settings.tiltGestures = NO;
	self.mapView.settings.rotateGestures = NO;
	self.mapView.settings.compassButton = NO;
	self.mapView.settings.myLocationButton = NO;
    
    if (self.markers.count > 1) {
        CLLocationCoordinate2D myLocation = ((GMSMarker *)self.markers.firstObject).position;
        GMSCoordinateBounds *bounds = [[GMSCoordinateBounds alloc] initWithCoordinate:myLocation coordinate:myLocation];

        for (GMSMarker *m in self.markers) {
            if (m.position.latitude != 0 && m.position.longitude != 0) {
                bounds = [bounds includingCoordinate:m.position];
                m.map = self.mapView;
            }
        }
        
        [self.mapView animateWithCameraUpdate:[GMSCameraUpdate fitBounds:bounds withPadding:15.0f]];
    } else {
        if (marker.position.latitude != 0 && marker.position.longitude != 0) {
            // Drop marker 0
            marker.map = self.mapView;
        }
    }
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(loadVideoPins) object:nil];
}

#pragma mark - Markers

- (void)addMarker:(GMSMarker *)marker scroll:(BOOL)scroll
{
    marker.map = self.mapView;
	[self.markers addObject:marker];
	
    //if (!self.mapView.myLocationEnabled) self.mapView.myLocationEnabled = YES;
    
    if (scroll) {
        [self.mapView animateToLocation:marker.position];
        [self.mapView animateToZoom:15];
    }
}

- (BOOL)markersVisible
{
	for (GMSMarker *m in self.markers)
		if ([self markerIsVisible:m])
			return YES;
	return NO;
}

- (BOOL)markerIsVisible:(GMSMarker*)marker
{
	return [self.mapView.projection containsCoordinate:marker.position];
}

- (void)clearAllMarkers
{
	[self.mapView clear];
	[self.markers removeAllObjects];
}

- (void)removeMarkerForVideoId:(NSString*)videoId
{
	for (GMSMarker *m in [self.markers copy]) {
		OREpicVideo *v = m.userData;
		if ([v.videoId isEqualToString:videoId]) {
//			DLog(@"removing marker for vid: %@", videoId);
			m.map = nil;
			[self.markers removeObject:m];
		}
	}
}

#pragma mark - GMSMapViewDelegate

- (void)mapView:(GMSMapView *)mapView willMove:(BOOL)gesture
{
	DLog(@"mapView willMove");
	//	self.isGestureMove = gesture;
	if (gesture) {
		self.mapView.selectedMarker = nil; // close any open info windows
	}
}

- (void)mapView:(GMSMapView *)mapView didChangeCameraPosition:(GMSCameraPosition *)position
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(loadVideoPins) object:nil];
}

- (void)mapView:(GMSMapView *)mapView idleAtCameraPosition:(GMSCameraPosition *)position
{
	DLog(@"%@", [NSString stringWithFormat:@"idleAtCameraPosition: %f - %f", position.target.latitude, position.target.longitude]);

	//	if (self.isGestureMove)
	if (self.inDiscoveryMode) {
		[self performSelector:@selector(loadVideoPins) withObject:nil afterDelay:1.0f];
	}
			
	//	self.isGestureMove = NO;
}

- (void)mapView:(GMSMapView *)mapView didTapInfoWindowOfMarker:(GMSMarker *)marker
{
	ORWatchView *watch;
    if ([marker.userData isKindOfClass:[OREpicVideo class]]) {
		watch = [[ORWatchView alloc] initWithVideo:marker.userData];
    } else {
		watch = [[ORWatchView alloc] initWithVideoId:((OREpicVideoLocation*)marker.userData).videoId];
	}
    
	if (self.parentViewController.navigationController) {
		[self.parentViewController.navigationController pushViewController:watch animated:YES];
	} else {
        [RVC pushToMainViewController:watch completion:nil];
	}
}

- (BOOL)didTapMyLocationButtonForMapView:(GMSMapView *)mapView
{
	return YES;
}

#pragma mark - Custom

- (void)loadVideoPins
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ORDiscoveryMapDidMove" object:self.mapView.projection];
}

- (void)flyToViewport:(ORGooglePlaceDetailsGeometryViewport*)viewport
{
	CLLocationCoordinate2D ne = CLLocationCoordinate2DMake(viewport.northeast.lat.doubleValue, viewport.northeast.lng.doubleValue);
	CLLocationCoordinate2D sw = CLLocationCoordinate2DMake(viewport.southwest.lat.doubleValue, viewport.southwest.lng.doubleValue);
	GMSCoordinateBounds *bounds = [[GMSCoordinateBounds alloc] initWithCoordinate:ne coordinate:sw];
	GMSCameraUpdate *fly = [GMSCameraUpdate fitBounds:bounds];
	[self.mapView animateWithCameraUpdate:fly];
	if (self.searchPlaceMarker)
		self.searchPlaceMarker.map = nil;
}

- (void)flyToLocation:(ORGooglePlaceDetailsGeometryLocation*)location andName:(NSString*)name
{
	CLLocationCoordinate2D ll = CLLocationCoordinate2DMake(location.lat.doubleValue, location.lng.doubleValue);
	[self flyToCLLocation:ll andName:name];
}

- (void)flyToCLLocation:(CLLocationCoordinate2D)location andName:(NSString*)name
{
	GMSCameraPosition *cam = [[GMSCameraPosition alloc] initWithTarget:location zoom:16 bearing:0 viewingAngle:0];
	GMSCameraUpdate *fly = [GMSCameraUpdate setCamera:cam];
	[self.mapView animateWithCameraUpdate:fly];
	if (self.searchPlaceMarker)
		self.searchPlaceMarker.map = nil;
	self.searchPlaceMarker = [GMSMarker markerWithPosition:location];
	self.searchPlaceMarker.icon = [GMSMarker markerImageWithColor:APP_COLOR_PRIMARY];
	self.searchPlaceMarker.tappable = YES;
	self.searchPlaceMarker.appearAnimation = YES;
	self.searchPlaceMarker.map = self.mapView;
	self.searchPlaceMarker.title = name;
}

- (void)flyToMyLocation
{
	if (AppDelegate.isAllowedToUseLocationManager) {
		[self flyToCLLocation:CLLocationCoordinate2DMake(AppDelegate.lastKnownLocation.coordinate.latitude, AppDelegate.lastKnownLocation.coordinate.longitude) andName:@""];
	} else {
		[self presentLocationPermissionAlert];
	}
}

#pragma mark - Location Permission

- (void)presentLocationPermissionAlert
{
	self.alertView = [[UIAlertView alloc] initWithTitle:@"LOCATION PERMISSION"
													message:@"Focus the map on your location?"
												   delegate:self
										  cancelButtonTitle:@"No"
										  otherButtonTitles:@"Yes", nil];
	self.alertView.tag = 1;
	[self.alertView show];
}

- (void)requestLocationPermission
{
	AppDelegate.isAllowedToUseLocationManager = YES;
    [AppDelegate updateLocation];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    alertView.delegate = nil;
	
	switch (alertView.tag) {
			
		case 1: // user responded to location rationale alert
			if (buttonIndex == 1)
			{
				[self requestLocationPermission];
			} else {
				// user doesn't want to grant location permission right now
				// don't say anything more for right now
			}
			break;
			
		default:
			break;
	}
}

#pragma mark - NSNotifications

- (void)registerForNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleORLocationUpdated:) name:@"ORLocationUpdated" object:nil];
}

- (void)handleORLocationUpdated:(NSNotification *)n
{
//	CLLocation *l = (CLLocation*)n.object;
//	self.marker0.position = CLLocationCoordinate2DMake(l.coordinate.latitude, l.coordinate.longitude);
//	self.marker0.map = self.mapView;
	[self flyToMyLocation];
}

@end
