//
//  GoogleDirectionsRoute.m
//  Bike Party
//
//  Created by Jon on 11/12/14.
//  Copyright (c) 2014 Modeo. All rights reserved.
//

#import "GoogleDirectionsRoute.h"
#import "GoogleDirectionsLeg.h"
#import "MKPolyline+GoogleDirections.h"

@implementation GoogleDirectionsRoute

- (id)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        
        NSDictionary *boundsDictionary = dictionary[@"bounds"];
        
        NSDictionary *northeastDictionary = boundsDictionary[@"northeast"];
        CLLocationCoordinate2D northeast = CLLocationCoordinate2DMake([northeastDictionary[@"lat"] floatValue], [northeastDictionary[@"lng"] floatValue]);
        
        NSDictionary *southwestDictionary = boundsDictionary[@"southwest"];
        CLLocationCoordinate2D southwest = CLLocationCoordinate2DMake([southwestDictionary[@"lat"] floatValue], [southwestDictionary[@"lng"] floatValue]);
        
        CLLocationDistance lattitudeDelta = northeast.latitude - southwest.latitude;
        CLLocationDistance longitudeDelta = northeast.longitude - southwest.longitude;
        MKCoordinateSpan span = MKCoordinateSpanMake(lattitudeDelta, longitudeDelta);
        
        CLLocationCoordinate2D center = CLLocationCoordinate2DMake(southwest.latitude + lattitudeDelta / 2, southwest.longitude + longitudeDelta / 2);
        
        _bounds = MKCoordinateRegionMake(center, span);
        
        
        NSArray *legDictionaries = dictionary[@"legs"];
        NSMutableArray *legs = [NSMutableArray new];
        for (NSDictionary *legDictionary in legDictionaries) {
            
            GoogleDirectionsLeg *leg = [[GoogleDirectionsLeg alloc] initWithDictionary:legDictionary];
            [legs addObject:leg];
            
        }
        
        _legs = [[NSArray alloc] initWithArray:legs];
        
        _overviewPolyline = [MKPolyline polylineWithEncodedString:dictionary[@"overview_polyline"][@"points"]];
        _copyright = dictionary[@"copyrights"];
        _summary = dictionary[@"summary"];
        _warnings = dictionary[@"warnings"];
        _waypointOrder = dictionary[@"waypoint_order"];
    }
    return self;
}

@end
