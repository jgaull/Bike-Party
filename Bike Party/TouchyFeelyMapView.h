//
//  TouchyFeelyMapView.h
//  Bike Party
//
//  Created by Jon on 11/15/14.
//  Copyright (c) 2014 Modeo. All rights reserved.
//

#import <MapKit/MapKit.h>

@class TouchyFeelyMapView;
@protocol TouchyFeelyMapViewDelegate <MKMapViewDelegate>

- (void)mapView:(MKMapView *)mapView didDragToCoordinate:(CLLocationCoordinate2D)coordinate;

@optional

@end

@interface TouchyFeelyMapView : MKMapView

@end
