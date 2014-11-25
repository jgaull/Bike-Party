//
//  Waypoint.h
//  Bike Party
//
//  Created by Jon on 11/20/14.
//  Copyright (c) 2014 Modeo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

typedef enum {
    WaypointTypeDestination,
    WaypointTypeTurn,
    WaypointTypeViaPoint
} WaypointType;

@interface Waypoint : NSObject <MKAnnotation>

@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, readonly, copy) NSString *subtitle;

@property (nonatomic, readonly) WaypointType type;
@property (nonatomic, readonly) NSInteger leg;

- (id)initWithWaypoint:(Waypoint *)waypoint;
- (id)initWithType:(WaypointType)type coordinate:(CLLocationCoordinate2D)coordinate;
- (id)initWithType:(WaypointType)type coordinate:(CLLocationCoordinate2D)coordinate title:(NSString *)name;
- (id)initWithType:(WaypointType)type coordinate:(CLLocationCoordinate2D)coordinate leg:(NSInteger)leg;

@end
