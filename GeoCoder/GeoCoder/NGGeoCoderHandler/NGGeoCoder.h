//
//  NGGeoCoder.h
//  GeoCoder
//
//  Created by Nitin Gupta on 30/01/14.
//  Copyright (c) 2014 Nitin Gupta. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "NGEnumAndConstants.h"

typedef void (^GeocoderCompletionHandler)(NSArray *placemarks, NSHTTPURLResponse *urlResponse, NSError *error);

@interface NGGeoCoder : NSOperation {
    @private
    NSMutableURLRequest *operationRequest;
    NSMutableData *operationData;
    NSURLConnection *operationConnection;
    NSHTTPURLResponse *operationURLResponse;
    GeocoderCompletionHandler operationCompletionBlock;
    GeocoderState state;
    NSString *requestPath;
    NSTimer *timeoutTimer;
    NSString *parentID;
}

//Address To Code without Region
+ (NGGeoCoder*)geocode:(NSString *)address ID:(NSString *)_anID completion:(GeocoderCompletionHandler)block;
//Address To Code with Region
+ (NGGeoCoder*)geocode:(NSString *)address region:(CLCircularRegion *)region ID:(NSString *)_anID completion:(GeocoderCompletionHandler)block;

//Reverse Code to Address
+ (NGGeoCoder*)reverseGeocode:(CLLocationCoordinate2D)coordinate ID:(NSString *)_anID completion:(GeocoderCompletionHandler)block;

@end
