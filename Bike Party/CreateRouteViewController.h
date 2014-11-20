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

- (void)editRouteMap:(EditRouteMapViewController *)editRouteMap didBeginEditingWaypoint:(CLLocation *)waypoint;

@end
