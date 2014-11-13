//
//  MFLocationManager.h
//  ModeoFramework
//
//  Created by Jon on 10/28/14.
//  Copyright (c) 2014 Modeo Vehicles LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

typedef void (^MFLocationManagerCallback)(CLLocation *location, NSError *error);

@interface MFLocationManager : NSObject <CLLocationManagerDelegate>

- (void)findUserWithAccuracy:(CLLocationAccuracy)accuracy andCallback:(MFLocationManagerCallback)callback;

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status;
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error;
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations;

@end
