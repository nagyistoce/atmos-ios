//
//  GetListableTagsResult.h
//  atmos-ios
//
//  Created by Jason Cwik on 5/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AtmosResult.h"


@interface GetListableTagsResult : AtmosResult {
    NSArray *tags;
}

@property (assign,readwrite) NSArray *tags;

@end
