//
//  ViewController.h
//  Bike Party
//
//  Created by Jon on 11/11/14.
//  Copyright (c) 2014 Modeo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

#import "AddDestinationViewController.h"

@interface ViewController : UIViewController <MKMapViewDelegate, AddDestinationViewControllerDelegate>

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation;
- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay;
//- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view;
//- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control;

- (void)addDestinationView:(AddDestinationViewController *)addDestinationView userDidSelectDestination:(GooglePlace *)destination;

@end

