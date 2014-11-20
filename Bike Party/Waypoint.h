//
//  Waypoint.h
//  Bike Party
//
//  Created by Jon on 11/20/14.
//  Copyright (c) 2014 Modeo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface Waypoint : NSObject

@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (strong, nonatomic) NSString *name;

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate;
- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate andName:(NSString *)name;

@end
