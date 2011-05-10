//
//  GetServerOffsetResult.h
//  atmos-ios
//
//  Created by Jason Cwik on 5/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AtmosResult.h"

@interface GetServerOffsetResult : AtmosResult {
    NSTimeInterval offset;
}

@property NSTimeInterval offset;

@end
