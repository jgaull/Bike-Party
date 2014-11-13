//
//  ViewController.m
//  Bike Party
//
//  Created by Jon on 11/11/14.
//  Copyright (c) 2014 Modeo. All rights reserved.
//

#define EDGE_PAD 0.01

#import "ViewController.h"
#import "MFLocationManager.h"
#import "GoogleDirectionsRequest.h"
#import "GoogleDirectionsRoute.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *addWaypointButton;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@property (strong, nonatomic) MFLocationManager *locationManager;
@property (strong, nonatomic) CLLocation *userLocation;

@property (strong, nonatomic) MKPolyline *routePolyline;

@property (strong, nonatomic) NSMutableArray *destinations;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.locationManager = [MFLocationManager new];
    self.addWaypointButton.enabled = NO;
    
    __weak typeof(self) weakSelf = self;
    [self.locationManager findUserWithAccuracy:kCLLocationAccuracyHundredMeters andCallback:^(CLLocation *location, NSError *error) {
        weakSelf.userLocation = location;
        weakSelf.addWaypointButton.enabled = YES;
        NSLog(@"Found user");
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[AddDestinationViewController class]]) {
        AddDestinationViewController *viewController = (AddDestinationViewController *)segue.destinationViewController;
        viewController.userLocation = self.userLocation;
        viewController.delegate = self;
    }
}

- (NSMutableArray *)destinations {
    if (!_destinations) {
        _destinations = [NSMutableArray new];
    }
    return _destinations;
}

- (void)addDestinationView:(AddDestinationViewController *)addDestinationView userDidSelectDestination:(GooglePlace *)destination {
    [self.destinations addObject:destination];
    
    MKPointAnnotation *annotation = [MKPointAnnotation new];
    annotation.coordinate = destination.location.coordinate;
    annotation.title = destination.name;
    annotation.subtitle = destination.address;
    [self.mapView addAnnotation:annotation];
    
    NSInteger numberOfSteps = self.destinations.count;
    
    CLLocationCoordinate2D coordinates[numberOfSteps];
    for (NSInteger index = 0; index < numberOfSteps; index++) {
        GooglePlace *place = [self.destinations objectAtIndex:index];
        CLLocation *location = place.location;
        CLLocationCoordinate2D coordinate = location.coordinate;
        
        coordinates[index] = coordinate;
    }
    
    MKPolyline *polyLine = [MKPolyline polylineWithCoordinates:coordinates count:numberOfSteps];
    [self.mapView removeOverlay:self.routePolyline];
    self.routePolyline = polyLine;
    [self.mapView addOverlay:polyLine];
    
    if (self.destinations.count > 1) {
        [self refreshDirections];
    }
}

- (void)refreshDirections {
    GooglePlace *origin = self.destinations.firstObject;
    GooglePlace *destination = self.destinations.lastObject;
    GoogleDirectionsRequest *directionsRequest = [[GoogleDirectionsRequest alloc] initWithAPIKey:@"AIzaSyBHeXy9Im_mAQyCqugF8_kBdKnerpQ0kjE"];
    [directionsRequest loadDirectionsFromPlace:origin toPlace:destination WithCallback:^(NSArray *routes, NSError *error) {
        if (!error) {
            GoogleDirectionsRoute *route = routes.firstObject;
            MKCoordinateSpan span = route.bounds.span;
            MKCoordinateSpan paddedSpan = MKCoordinateSpanMake(span.latitudeDelta + EDGE_PAD, span.longitudeDelta + EDGE_PAD);
            MKCoordinateRegion paddedRegion = MKCoordinateRegionMake(route.bounds.center, paddedSpan);
            
            [self.mapView setRegion:paddedRegion animated:YES];
        }
        else {
            NSLog(@"Flail: %@", error.localizedDescription);
        }
    }];
}

/*
- (IBAction)userDidTapAddWaypoint:(UIBarButtonItem *)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Add Destination" message:@"What destination would you like to add to your route?" preferredStyle:UIAlertControllerStyleAlert];
    
    __block UITextField *alertTextField;
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        alertTextField = textField;
    }];
    
    UIAlertAction *searchAction = [UIAlertAction actionWithTitle:@"Search" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSLog(@"Search button pushed.");
        [self performSearchForPlaceWithName:alertTextField.text];
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    
    [alert addAction:searchAction];
    [alert addAction:cancelAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}
 */

/*
- (void)performSearchForPlaceWithName:(NSString *)name {
    GooglePlacesSearch *googlePlacesSearch = [[GooglePlacesSearch alloc] initWithAPIKey:@"AIzaSyBHeXy9Im_mAQyCqugF8_kBdKnerpQ0kjE"];
    [googlePlacesSearch findplaceByName:name nearLocation:self.userLocation withinRadius:10000 WithCallback:^(NSArray *places, NSError *error) {
        if (error) {
            NSLog(@"Error: %@", error.localizedDescription);
        }
        else {
            NSLog(@"%lu places found.", (unsigned long)places.count);
            
            NSMutableArray *annotations = [NSMutableArray new];
            for (GooglePlace *place in places) {
                MKPointAnnotation *annotation = [MKPointAnnotation new];
                annotation.coordinate = place.location.coordinate;
                annotation.title = place.name;
                annotation.subtitle = place.address;
                
                [annotations addObject:annotation];
            }
            
            [self.mapView addAnnotations:annotations];
        }
    }];
}
 */

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    MKPinAnnotationView *pin = (MKPinAnnotationView *) [self.mapView dequeueReusableAnnotationViewWithIdentifier: @"destinationPin"];
    if (pin == nil) {
        pin = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier: @"destinationPin"];
        UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeContactAdd];
        
        pin.animatesDrop = YES;
        pin.canShowCallout = YES;
        pin.rightCalloutAccessoryView = rightButton;
        
    } else {
        pin.annotation = annotation;
    }
    
    return pin;
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    
    MKPolylineRenderer *polylineRenderer = [[MKPolylineRenderer alloc] initWithPolyline:overlay];
    polylineRenderer.strokeColor = [UIColor redColor];
    polylineRenderer.lineWidth = 5.0;
    
    return polylineRenderer;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    NSLog(@"Did select view: %@", view.annotation.title);
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
    NSLog(@"Callout accessory view tapped: %@", view.annotation.title);
}

@end
