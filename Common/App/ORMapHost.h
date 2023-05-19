//
//  ORMapView.h
//  Epic
//
//  Created by Thomas Purnell-Fisher on 11/11/13.
//  Copyright (c) 2013 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GoogleMaps/GoogleMaps.h>

@class ORGooglePlaceDetailsGeometryViewport, ORGooglePlaceDetailsGeometryLocation;

@interface ORMapHost : GAITrackedViewController

- (id)initWithMarkers:(NSMutableArray *)markers;

@property (nonatomic, strong) GMSMapView *mapView;
@property (nonatomic, strong) NSMutableArray *markers;
@property (nonatomic, assign) BOOL inDiscoveryMode;
@property (nonatomic, assign, readonly) BOOL markersVisible;

- (void)addMarker:(GMSMarker *)marker scroll:(BOOL)scroll;
- (BOOL)markerIsVisible:(GMSMarker*)marker;
- (void)flyToViewport:(ORGooglePlaceDetailsGeometryViewport*)viewport;
- (void)flyToLocation:(ORGooglePlaceDetailsGeometryLocation*)location andName:(NSString*)name;
- (void)flyToCLLocation:(CLLocationCoordinate2D)location andName:(NSString*)name;
- (void)flyToMyLocation;
- (void)clearAllMarkers;
- (void)removeMarkerForVideoId:(NSString*)videoId;

@end
