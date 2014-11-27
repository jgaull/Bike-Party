//
//  RouteLoader.h
//  Bike Party
//
//  Created by Jon on 11/27/14.
//  Copyright (c) 2014 Modeo. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^Callback)(NSArray *routes, NSError *error);

@interface RouteLoader : NSObject

- (void)loadDirectionsForWaypoints:(NSArray *)waypoints withCallback:(Callback)callback;

@end
