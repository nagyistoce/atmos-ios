//
//  ListAccessTokensResult.m
//  atmos-ios
//
//  Created by Jason Cwik on 12/20/12.
//
//

#import "ListAccessTokensResult.h"

@implementation ListAccessTokensResult

@synthesize results;
@synthesize token;

- (void) dealloc {
    self.results = nil;
    self.token = nil;
    
    [super dealloc];
}

@end
