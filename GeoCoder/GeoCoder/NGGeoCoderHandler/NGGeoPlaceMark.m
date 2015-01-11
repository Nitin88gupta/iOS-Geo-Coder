//
//  NGGeoPlaceMark.m
//  GeoCoder
//
//  Created by Nitin Gupta on 30/01/14.
//  Copyright (c) 2014 Nitin Gupta. All rights reserved.
//

#import "NGGeoPlaceMark.h"
#import <CoreLocation/CoreLocation.h>

@implementation NGGeoPlaceMark
@synthesize name = _name;
@synthesize formattedAddress = _formattedAddress;
@synthesize subThoroughfare = _subThoroughfare;
@synthesize thoroughfare = _thoroughfare;
@synthesize subLocality = _subLocality;
@synthesize locality = _locality;
@synthesize subAdministrativeArea = _subAdministrativeArea;
@synthesize administrativeArea = _administrativeArea;
@synthesize administrativeAreaCode = _administrativeAreaCode;
@synthesize postalCode = _postalCode;
@synthesize country = _country;
@synthesize ISOcountryCode = _ISOcountryCode;
@synthesize coordinate = _coordinate;
@synthesize region = _region;
@synthesize location = _location;
@synthesize anIDKey = _anIDKey;

- (id)initWithDictionary:(NSDictionary *)result {
    
    if(self = [super init]) {
        _formattedAddress = [result objectForKey:@"formatted_address"];
        
        NSArray *addressComponents = [result objectForKey:@"address_components"];
        
        [addressComponents enumerateObjectsUsingBlock:^(NSDictionary *component, NSUInteger idx, BOOL *stopAddress) {
            NSArray *types = [component objectForKey:@"types"];
            
            if([types containsObject:@"street_number"])
                _subThoroughfare = [component objectForKey:@"long_name"];
            
            if([types containsObject:@"route"])
                _thoroughfare = [component objectForKey:@"long_name"];
            
            if([types containsObject:@"administrative_area_level_3"] || [types containsObject:@"sublocality"] || [types containsObject:@"neighborhood"])
                _subLocality = [component objectForKey:@"long_name"];
            
            if([types containsObject:@"locality"])
                _locality = [component objectForKey:@"long_name"];
            
            if([types containsObject:@"administrative_area_level_2"])
                _subAdministrativeArea = [component objectForKey:@"long_name"];
            
            if([types containsObject:@"administrative_area_level_1"]) {
                _administrativeArea = [component objectForKey:@"long_name"];
                _administrativeAreaCode = [component objectForKey:@"short_name"];
            }
            
            if([types containsObject:@"country"]) {
                _country = [component objectForKey:@"long_name"];
                _ISOcountryCode = [component objectForKey:@"short_name"];
            }
            
            if([types containsObject:@"postal_code"])
                _postalCode = [component objectForKey:@"long_name"];
            
        }];
        
        NSDictionary *locationDict = [[result objectForKey:@"geometry"] objectForKey:@"location"];
        NSDictionary *boundsDict = [[result objectForKey:@"geometry"] objectForKey:@"bounds"];
        
        CLLocationDegrees lat = [[locationDict objectForKey:@"lat"] doubleValue];
        CLLocationDegrees lng = [[locationDict objectForKey:@"lng"] doubleValue];
        _coordinate = CLLocationCoordinate2DMake(lat, lng);
        _location = [[CLLocation alloc] initWithLatitude:lat longitude:lng];
        
        NSDictionary *northEastDict = [boundsDict objectForKey:@"northeast"];
        NSDictionary *southWestDict = [boundsDict objectForKey:@"southwest"];
        CLLocationDegrees northEastLatitude = [[northEastDict objectForKey:@"lat"] doubleValue];
        CLLocationDegrees southWestLatitude = [[southWestDict objectForKey:@"lat"] doubleValue];
        CLLocationDegrees latitudeDelta = fabs(northEastLatitude - southWestLatitude);
        CLLocationDegrees northEastLongitude = [[northEastDict objectForKey:@"lng"] doubleValue];
        CLLocationDegrees southWestLongitude = [[southWestDict objectForKey:@"lng"] doubleValue];
        CLLocationDegrees longitudeDelta = fabs(northEastLongitude - southWestLongitude);
        MKCoordinateSpan span = MKCoordinateSpanMake(latitudeDelta, longitudeDelta);
        _region = MKCoordinateRegionMake( _location.coordinate, span);
    }
    
    return self;
}

- (NSString *)name {
    if( _subThoroughfare && _thoroughfare)
        return [NSString stringWithFormat:@"%@ %@",  _subThoroughfare,  _thoroughfare];
    else if( _thoroughfare)
        return  _thoroughfare;
    else if( _subLocality)
        return  _subLocality;
    else if( _locality)
        return [NSString stringWithFormat:@"%@, %@",  _locality,  _administrativeAreaCode];
    else if( _administrativeArea)
        return  _administrativeArea;
    else if( _country)
        return  _country;
    return nil;
}

- (NSString*)description {
	return [[self getPlacemarkInfo] description];
}

- (NSDictionary *) getPlacemarkInfo {
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          _formattedAddress, @"formattedAddress",
                          _subThoroughfare?_subThoroughfare:[NSNull null], @"subThoroughfare",
                          _thoroughfare?_thoroughfare:[NSNull null], @"thoroughfare",
                          _subLocality?_subLocality:[NSNull null], @"subLocality",
                          _locality?_locality:[NSNull null], @"locality",
                          _subAdministrativeArea?_subAdministrativeArea:[NSNull null], @"subAdministrativeArea",
                          _administrativeArea?_administrativeArea:[NSNull null], @"administrativeArea",
                          _postalCode?_postalCode:[NSNull null], @"postalCode",
                          _country?_country:[NSNull null], @"country",
                          _ISOcountryCode?_ISOcountryCode:[NSNull null], @"ISOcountryCode",
                          [NSString stringWithFormat:@"%f, %f",  _coordinate.latitude,  _coordinate.longitude], @"coordinate",
                          nil];
    return dict;
}


@end
