//
//  GetServerOffsetOperation.h
//  atmos-ios
//
//  Created by Jason Cwik on 5/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AtmosBaseOperation.h"
#import "GetServerOffsetResult.h"

@interface GetServerOffsetOperation : AtmosBaseOperation {
    void (^callback)(GetServerOffsetResult *result);
}

@property (nonatomic,copy) void (^callback)(GetServerOffsetResult *result);

@end
