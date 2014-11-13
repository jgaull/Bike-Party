//
//  GoogleDirectionsRoute.h
//  Bike Party
//
//  Created by Jon on 11/12/14.
//  Copyright (c) 2014 Modeo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@interface GoogleDirectionsRoute : NSObject

- (id)initWithDictionary:(NSDictionary *)dictionary;

@property (nonatomic, readonly) MKCoordinateRegion bounds;
@property (nonatomic, readonly) NSString *copyright;
@property (nonatomic, readonly) NSArray *legs;
@property (nonatomic, readonly) NSString *overviewPolyline;
@property (nonatomic, readonly) NSString *summary;
@property (nonatomic, readonly) NSArray *warnings;
@property (nonatomic, readonly) NSArray *waypointOrder;

@end
