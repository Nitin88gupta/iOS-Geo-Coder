//
//  NGEnumAndConstants.h
//  GeoCoder
//
//  Created by Nitin Gupta on 30/01/14.
//  Copyright (c) 2014 Nitin Gupta. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kGeocoderTimeoutInterval 20

typedef enum {
    GeocoderStateReady = 0,
    GeocoderStateExecuting,
    GeocoderStateFinished
} GeocoderState;

typedef enum {
    GeoCoderZeroResultsError = 1,
	GeoCoderOverQueryLimitError,
	GeoCoderRequestDeniedError,
	GeoCoderInvalidRequestError,
    GeoCoderJSONParsingError
} GeoCoderError;
