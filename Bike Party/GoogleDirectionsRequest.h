//
//  GoogleDirectionsRequest.h
//  Bike Party
//
//  Created by Jon on 11/12/14.
//  Copyright (c) 2014 Modeo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#import "GooglePlace.h"

@interface GoogleDirectionsRequest : NSObject

- (id)initWithAPIKey:(NSString *)apiKey;
- (void)loadDirectionsFromPlace:(GooglePlace *)origin toPlace:(GooglePlace *)destination WithCallback:(void (^)(NSArray *places, NSError *error))callback;
- (void)loadDirectionsForPath:(NSArray *)path WithCallback:(void (^)(NSArray *places, NSError *error))callback;

@end
