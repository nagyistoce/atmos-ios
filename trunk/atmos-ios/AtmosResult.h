//
//  AtmosResult.h
//  atmos-ios
//
//  Created by Jason Cwik on 5/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AtmosError.h"

@interface AtmosResult : NSObject {
    NSString *requestLabel;
    BOOL    wasSuccessful;
    AtmosError *error;
}

+ (id)successWithLabel:(NSString*)label;
+ (id)failureWithError:(AtmosError*)err withLabel:(NSString*)label;

- (id)initWithResult:(BOOL)success 
           withError:(AtmosError*)err 
           withLabel:(NSString*)label;

@property (assign,readwrite) NSString *requestLabel;
@property (assign,readwrite) BOOL wasSuccessful;
@property (assign,readwrite) AtmosError *error;


@end
