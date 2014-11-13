//
//  ViewController.m
//  Bike Party
//
//  Created by Jon on 11/11/14.
//  Copyright (c) 2014 Modeo. All rights reserved.
//

#import "ViewController.h"
#import "MFLocationManager.h"
#import "GooglePlacesSearch.h"
#import "GooglePlace.h"
#import "DestinationAnnotation.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *addWaypointButton;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@property (strong, nonatomic) MFLocationManager *locationManager;
@property (strong, nonatomic) CLLocation *userLocation;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.locationManager = [MFLocationManager new];
    
    __weak typeof(self) weakSelf = self;
    [self.locationManager findUserWithAccuracy:kCLLocationAccuracyHundredMeters andCallback:^(CLLocation *location, NSError *error) {
        weakSelf.userLocation = location;
        NSLog(@"Found user");
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

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

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    NSLog(@"Did select view: %@", view.annotation.title);
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
    NSLog(@"Callout accessory view tapped: %@", view.annotation.title);
}

@end
