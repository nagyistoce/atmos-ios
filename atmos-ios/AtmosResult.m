//
//  AtmosResult.m
//  atmos-ios
//
//  Created by Jason Cwik on 5/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AtmosResult.h"


@implementation AtmosResult

@synthesize requestLabel, wasSuccessful, error;

- (id)initWithResult:(BOOL)success 
           withError:(AtmosError *)err 
           withLabel:(NSString *)label {
    self = [super init];
    
    if( self ) {
        self.wasSuccessful = success;
        self.error = err;
        self.requestLabel = label;
    }
    
    return self;
}

+ (id)successWithLabel:(NSString *)label
{
    AtmosResult *res = [AtmosResult alloc];
    [res initWithResult:YES withError:nil withLabel:label];
    return res;
}

+ (id)failureWithError:(AtmosError *)err withLabel:(NSString *)label
{
    AtmosResult *res = [AtmosResult alloc];
    [res initWithResult:NO withError:err withLabel:label];
    return res;
}

@end
