//
//  CreateRouteViewController.h
//  Bike Party
//
//  Created by Jon on 11/20/14.
//  Copyright (c) 2014 Modeo. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "EditRouteMapViewController.h"

@interface CreateRouteViewController : UIViewController <EditRouteMapViewControllerDelegate>

- (void)editRouteMap:(EditRouteMapViewController *)editRouteMap didBeginEditingWaypoint:(Waypoint *)waypoint;
- (void)editRouteMap:(EditRouteMapViewController *)editRouteMap didUpdateEditingWaypoint:(Waypoint *)waypoint;

- (void)editRouteMap:(EditRouteMapViewController *)editRouteMap didSelectCoordinate:(CLLocationCoordinate2D)coordinate;
- (void)editRouteMap:(EditRouteMapViewController *)editRouteMap didSelectWaypoint:(Waypoint *)waypoint;
- (void)editRouteMap:(EditRouteMapViewController *)editRouteMap didDeselectWaypoint:(Waypoint *)waypoint;
//- (void)editRouteMap:(EditRouteMapViewController *)editRouteMap didSelectPolyline:(id<NSCopying>)polylineIdentifier atCoordinate:(CLLocationCoordinate2D)coordinate;

@end
