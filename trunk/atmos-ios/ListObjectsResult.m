//
//  ListObjectsResult.m
//  atmos-ios
//
//  Created by Jason Cwik on 5/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ListObjectsResult.h"


@implementation ListObjectsResult

@synthesize objects;

- (id)init
{
    self = [super init];
    
    if(self) {
        self.objects = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

@end
