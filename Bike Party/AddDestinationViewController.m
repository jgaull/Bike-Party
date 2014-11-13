//
//  AddDestinationViewController.m
//  Bike Party
//
//  Created by Jon on 11/12/14.
//  Copyright (c) 2014 Modeo. All rights reserved.
//

#import "AddDestinationViewController.h"

@interface AddDestinationViewController ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneButton;
@property (weak, nonatomic) IBOutlet UITextField *searchTextField;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@property (strong, nonatomic) NSArray *places;

@end

@implementation AddDestinationViewController

- (void)performSearchForPlaceWithName:(NSString *)name {
    
    __weak typeof(self) weakSelf = self;
    GooglePlacesSearch *googlePlacesSearch = [[GooglePlacesSearch alloc] initWithAPIKey:@"AIzaSyBHeXy9Im_mAQyCqugF8_kBdKnerpQ0kjE"];
    [googlePlacesSearch findplaceByName:name nearLocation:self.userLocation withinRadius:10000 WithCallback:^(NSArray *places, NSError *error) {
        if (error) {
            NSLog(@"Error: %@", error.localizedDescription);
        }
        else {
            NSLog(@"%lu places found.", (unsigned long)places.count);
            
            weakSelf.places = [NSArray arrayWithArray:places];
            
            NSMutableArray *annotations = [NSMutableArray new];
            for (GooglePlace *place in places) {
                MKPointAnnotation *annotation = [MKPointAnnotation new];
                annotation.coordinate = place.location.coordinate;
                annotation.title = place.name;
                annotation.subtitle = place.address;
                
                [annotations addObject:annotation];
            }
            
            [weakSelf.mapView addAnnotations:annotations];
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
    //NSLog(@"Did select view: %@", view.annotation.title);
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
    NSLog(@"Callout accessory view tapped: %@", view.annotation.title);
    
    for (GooglePlace *place in self.places) {
        if ([place.name isEqualToString:view.annotation.title] && [place.address isEqualToString:view.annotation.subtitle]) {
            NSLog(@"Found the place...");
            [self completeSelectionWithPlace:place];
            break;
        }
    }
}

- (IBAction)userDidTapCancelButton:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
    
    if ([self.delegate respondsToSelector:@selector(addDestinationViewUserDidCancel:)]) {
        [self.delegate addDestinationViewUserDidCancel:self];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    [self performSearchForPlaceWithName:textField.text];
    
    return NO;
}

- (void)completeSelectionWithPlace:(GooglePlace *)place {
    [self dismissViewControllerAnimated:YES completion:nil];
    
    if ([self.delegate respondsToSelector:@selector(addDestinationView:userDidSelectDestination:)]) {
        [self.delegate addDestinationView:self userDidSelectDestination:place];
    }
}

@end
