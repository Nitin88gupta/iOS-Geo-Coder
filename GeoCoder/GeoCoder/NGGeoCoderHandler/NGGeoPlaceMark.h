//
//  NGGeoPlaceMark.h
//  GeoCoder
//
//  Created by Nitin Gupta on 30/01/14.
//  Copyright (c) 2014 Nitin Gupta. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface NGGeoPlaceMark : NSObject {
    
}

@property (nonatomic,readonly) NSString *name;
@property (nonatomic,readonly) NSString *formattedAddress;
@property (nonatomic,readonly) NSString *subThoroughfare;
@property (nonatomic,readonly) NSString *thoroughfare;
@property (nonatomic,readonly) NSString *subLocality;
@property (nonatomic,readonly) NSString *locality;
@property (nonatomic,readonly) NSString *subAdministrativeArea;
@property (nonatomic,readonly) NSString *administrativeArea;
@property (nonatomic,readonly) NSString *administrativeAreaCode;
@property (nonatomic,readonly) NSString *postalCode;
@property (nonatomic,readonly) NSString *country;
@property (nonatomic,readonly) NSString *ISOcountryCode;
@property (nonatomic,readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic,readonly) MKCoordinateRegion region;
@property (nonatomic,readonly) CLLocation *location;
@property (nonatomic,assign) NSString *anIDKey;

- (id)initWithDictionary:(NSDictionary*)dictionary;

@end
