//
//  TestMapViewController.h
//  Bike Party
//
//  Created by Jon on 11/15/14.
//  Copyright (c) 2014 Modeo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

#import "Waypoint.h"

typedef enum {
    EditRouteMapViewControllerStateIdle,
    EditRouteMapViewControllerStateEditing
}EditRouteMapViewControllerState;

@class EditRouteMapViewController;
@protocol EditRouteMapViewControllerDelegate <NSObject>
@optional

- (void)editRouteMap:(EditRouteMapViewController *)editRouteMap didBeginEditingWaypoint:(Waypoint *)waypoint;
- (void)editRouteMap:(EditRouteMapViewController *)editRouteMap didEndEditingWaypoint:(Waypoint *)waypoint;

@end

@interface EditRouteMapViewController : UIViewController <MKMapViewDelegate, UIGestureRecognizerDelegate>

@property (weak, nonatomic) NSObject <EditRouteMapViewControllerDelegate> *delegate;
@property (readonly, nonatomic) EditRouteMapViewControllerState state;
@property (readonly, nonatomic) NSArray *waypoints;

- (void)confirmEdits;
- (void)cancelEdits;

- (void)addPolyline:(MKPolyline *)polyline withIdentifier:(NSString *)identifier;
- (void)removePolylineWithIdentifier:(NSString *)identifier;
- (void)showPolylineWithIdentifier:(NSString *)identifier edgePadding:(CGFloat)edgeInsets animated:(BOOL)animated;

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation;
- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated;
//- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated;
- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay;

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer;

@end
