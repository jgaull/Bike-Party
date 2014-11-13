//
//  GooglePlacesSearch.m
//  Bike Party
//
//  Created by Jon on 11/12/14.
//  Copyright (c) 2014 Modeo. All rights reserved.
//

#import "GooglePlacesSearch.h"
#import "GooglePlace.h"

@interface GooglePlacesSearch ()

@property (strong, nonatomic) NSURLSession *urlSession;
@property (strong, nonatomic) NSString *apiKey;

@end

@implementation GooglePlacesSearch

- (id)initWithAPIKey:(NSString *)apiKey {
    self = [super init];
    if (self) {
        self.apiKey = apiKey;
    }
    return self;
}

- (void)findplaceByName:(NSString *)name nearLocation:(CLLocation *)location withinRadius:(CLLocationDistance)radius WithCallback:(void (^)(NSArray *places, NSError *error))callback {
    
    if (self.apiKey && ![name isEqualToString:@""] && radius > 0 && location) {
        
        NSString *urlFormat = @"https://maps.googleapis.com/maps/api/place/nearbysearch/json?language=en&key=%@&location=%f,%f&radius=%f&name=%@";
        
        NSString *urlString = [NSString stringWithFormat:urlFormat, self.apiKey, location.coordinate.latitude, location.coordinate.longitude, radius, name];
        
        NSMutableURLRequest *urlRequest = [self urlRequestForHTTPMethod:@"GET" withURLString:urlString];
        
        NSURLSessionDataTask *dataTask = [self.urlSession dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (!error) {
                NSError *error;
                NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
                
                if ([responseDictionary[@"status"] isEqualToString:@"OK"]) {
                    //NSLog(@"Success: %@", responseDictionary);
                    
                    NSArray *results = responseDictionary[@"results"];
                    NSMutableArray *places = [NSMutableArray new];
                    
                    for (NSDictionary *placeDictionary in results) {
                        GooglePlace *place = [[GooglePlace alloc] initWithDictionary:placeDictionary];
                        [places addObject:place];
                    }
                    callback(places, nil);
                }
                else {
                    //NSLog(@"Error JSON decoding: %@", error.localizedDescription);
                    callback(nil, error);
                }
            }
            else {
                //NSLog(@"Error loading request: %@", error.localizedDescription);
                callback(nil, error);
            }
        }];
        
        [dataTask resume];
    }
    else {
        NSLog(@"Not enough params...");
    }
}

- (NSMutableURLRequest *)urlRequestForHTTPMethod:(NSString *)method withURLString:(NSString *)urlString {
    
    NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    
    [urlRequest setHTTPMethod:method];
    return urlRequest;
}

- (NSURLSession *)urlSession {
    if (!_urlSession) {
        _urlSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    }
    
    return _urlSession;
}

@end
