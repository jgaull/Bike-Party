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
    EditRouteMapViewControllerStateEditingWaypoint
}EditRouteMapViewControllerState;

@class EditRouteMapViewController;
@protocol EditRouteMapViewControllerDelegate <NSObject>
@optional

- (void)editRouteMap:(EditRouteMapViewController *)editRouteMap didBeginEditingWaypoint:(Waypoint *)waypoint;
- (void)editRouteMap:(EditRouteMapViewController *)editRouteMap didUpdateEditingWaypoint:(Waypoint *)waypoint;
- (void)editRouteMap:(EditRouteMapViewController *)editRouteMap didEndEditingWaypoint:(Waypoint *)waypoint;
- (void)editRouteMap:(EditRouteMapViewController *)editRouteMap didSelectPolyline:(id <NSCopying>)polylineIdentifier atCoordinate:(CLLocationCoordinate2D)coordinate;
- (void)editRouteMap:(EditRouteMapViewController *)editRouteMap didSelectCoordinate:(CLLocationCoordinate2D)coordinate;
- (void)editRouteMap:(EditRouteMapViewController *)editRouteMap didSelectWaypoint:(Waypoint *)waypoint;
- (void)editRouteMap:(EditRouteMapViewController *)editRouteMap didDeselectWaypoint:(Waypoint *)waypoint;

@end

@interface EditRouteMapViewController : UIViewController <MKMapViewDelegate, UIGestureRecognizerDelegate>

@property (weak, nonatomic) NSObject <EditRouteMapViewControllerDelegate> *delegate;
@property (readonly, nonatomic) EditRouteMapViewControllerState state;
@property (readonly, nonatomic) NSArray *waypoints;
@property (readonly, nonatomic) Waypoint *editingWaypoint;
@property (readonly, nonatomic) Waypoint *selectedWaypoint;

- (void)confirmEdits;
- (void)cancelEdits;

- (void)addPolyline:(MKPolyline *)polyline withIdentifier:(id <NSCopying>)identifier;
- (void)removePolylineWithIdentifier:(id <NSCopying>)identifier;
- (void)removeAllPolylines;
- (void)showPolylineWithIdentifier:(id <NSCopying>)identifier edgePadding:(CGFloat)edgeInsets animated:(BOOL)animated;
- (void)showPolylinesWithIdentifiers:(NSArray *)identifiers edgePadding:(CGFloat)edgeInsets animated:(BOOL)animated;

- (void)addWaypoint:(Waypoint *)waypoint;
- (void)addWaypoints:(NSArray *)waypoints;
- (void)insertWaypoint:(Waypoint *)waypoint atIndex:(NSUInteger)index;
- (void)removeWaypoint:(Waypoint *)waypoint;
- (void)removeWaypoints:(NSArray *)waypoints;
- (void)removeAllWaypoints;
- (void)beginEditingWaypoint:(Waypoint *)waypoint;

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation;
- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated;
- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay;
//- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view;
//- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view;

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer;

@end
