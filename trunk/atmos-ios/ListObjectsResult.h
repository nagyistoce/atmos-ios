//
//  ListObjectsResult.h
//  atmos-ios
//
//  Created by Jason Cwik on 5/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AtmosResult.h"

@interface ListObjectsResult : AtmosResult {
    NSMutableDictionary *objects;
}

@property (nonatomic,retain) NSMutableDictionary* objects;

@end
