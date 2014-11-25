//
//  CreateRouteViewController.h
//  Bike Party
//
//  Created by Jon on 11/20/14.
//  Copyright (c) 2014 Modeo. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CenterLockingMapView.h"

@interface CreateRouteViewController : UIViewController <MKMapViewDelegate, UIGestureRecognizerDelegate>

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay;
- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated;
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation;
- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view;
- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view;

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch;

@end
