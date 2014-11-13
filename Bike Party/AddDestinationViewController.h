//
//  AddDestinationViewController.h
//  Bike Party
//
//  Created by Jon on 11/12/14.
//  Copyright (c) 2014 Modeo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

#import "GooglePlacesSearch.h"

@class AddDestinationViewController;
@protocol AddDestinationViewControllerDelegate <NSObject>

@optional
- (void)addDestinationViewUserDidCancel:(AddDestinationViewController *)addDestinationView;
- (void)addDestinationView:(AddDestinationViewController *)addDestinationView userDidSelectDestination:(GooglePlace *)destination;

@end

@interface AddDestinationViewController : UIViewController <MKMapViewDelegate, UITextFieldDelegate>

@property (weak, nonatomic) NSObject <AddDestinationViewControllerDelegate> *delegate;
@property (strong, nonatomic) CLLocation *userLocation;

- (BOOL)textFieldShouldReturn:(UITextField *)textField;

@end
