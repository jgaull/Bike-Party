//
//  GooglePlace.h
//  Bike Party
//
//  Created by Jon on 11/12/14.
//  Copyright (c) 2014 Modeo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface GooglePlace : NSObject

@property (strong, readonly) CLLocation *location;
@property (strong, readonly) NSString *name;
@property (strong, readonly) NSDictionary *openingHours;
@property (strong, readonly) NSArray *photos;
@property (strong, readonly) NSString *placeId;
@property (strong, readonly) NSString *reference;
@property (strong, readonly) NSString *scope;
@property (strong, readonly) NSArray *types;
@property (strong, readonly) NSString *address;
@property (readonly) float rating;

- (id)initWithDictionary:(NSDictionary *)dictionary;

@end
