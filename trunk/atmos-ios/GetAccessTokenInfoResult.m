//
//  GetAccessTokenInfoResult.m
//  atmos-ios
//
//  Created by Jason Cwik on 12/20/12.
//
//

#import "GetAccessTokenInfoResult.h"

@implementation GetAccessTokenInfoResult

@synthesize tokenInfo;

- (void) dealloc {
    self.tokenInfo = nil;
    
    [super dealloc];
}

@end
