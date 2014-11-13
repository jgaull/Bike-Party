//
//  MFLocationManager.m
//  ModeoFramework
//
//  Created by Jon on 10/28/14.
//  Copyright (c) 2014 Modeo Vehicles LLC. All rights reserved.
//

#import "MFLocationManager.h"

@interface MFLocationManager ()

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) MFLocationManagerCallback callback;

@end

@implementation MFLocationManager

- (void)findUserWithAccuracy:(CLLocationAccuracy)accuracy andCallback:(MFLocationManagerCallback)callback {
    
    if (!self.locationManager) {
        
        self.callback = callback;
        
        self.locationManager = [CLLocationManager new];
        self.locationManager.desiredAccuracy = accuracy;
        self.locationManager.delegate = self;
        
        [self.locationManager requestWhenInUseAuthorization];
        [self.locationManager startUpdatingLocation];
    }
}

- (void)endSearchWithLocation:(CLLocation *)location andError:(NSError *)error {
    
    [self.locationManager stopUpdatingLocation];
    self.locationManager.delegate = nil;
    self.locationManager = nil;
    
    self.callback(location, error);
    //self.callback = nil;
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    //NSLog(@"Authorization status changed. %d", status);
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    [self endSearchWithLocation:nil andError:error];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *location = locations.firstObject;
    //NSLog(@"horizontalAccuracy: %f, desiredAccuracy: %f", location.horizontalAccuracy, manager.desiredAccuracy);
    if (location.horizontalAccuracy <= manager.desiredAccuracy) {
        [self endSearchWithLocation:location andError:nil];
    }
}

@end
