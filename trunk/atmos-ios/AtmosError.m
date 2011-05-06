//
//  AtmosError.m
//  AtmosCocoaBinding
//
//  Created by Aashish Patil on 8/26/10.
//  Copyright 2010 EMC. All rights reserved.
//

#import "AtmosError.h"


@implementation AtmosError

@synthesize errorCode,errorMessage;

- (id)initWithCode:(NSInteger)code message:(NSString *) errMsg {
    self = [super init];
    if (self) {
        self.errorCode = code;
		self.errorMessage = errMsg;
	}
    return self;
}


@end
