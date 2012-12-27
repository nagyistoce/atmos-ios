/*
 
 Copyright (c) 2012, EMC Corporation
 
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 
 * Neither the name of the EMC Corporation nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
 
 INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 
 WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 */
#import "CreateAccessTokenResult.h"
#import "AtmosConstants.h"

@implementation CreateAccessTokenResult

@synthesize accessTokenId, credentials;

#pragma mark Memory Management
- (void) dealloc {
    self.accessTokenId = nil;
    self.credentials = nil;
    
    [super dealloc];
}

-(id) init {
    self = [super init];

    return self;
}

- (id)initWithResult:(BOOL)success
           withError:(AtmosError *)err
           withLabel:(NSString *)label {
    self = [super initWithResult:success withError:err withLabel:label];
        
    return self;
}

- (NSURL*) getURLForToken {
    NSString *baseUrl = [NSString stringWithFormat:@"%@://%@:%d",
                         self.credentials.httpProtocol,
                         self.credentials.accessPoint,
                         self.credentials.portNumber];
    NSURL *base = [NSURL URLWithString:baseUrl];
    NSString *tokenPath = [NSString stringWithFormat:@"%@%@", ATMOS_ACCESS_TOKEN_LOCATION_PREFIX, self.accessTokenId];
    NSURL *url = [NSURL URLWithString:tokenPath relativeToURL:base];
    
    return url;
}


#pragma mark convienience constructors
+ (id)successWithLabel:(NSString *)label
{
    CreateAccessTokenResult *res = [[CreateAccessTokenResult alloc]initWithResult:YES withError:nil withLabel:label];
    [res autorelease];
    return res;
}

+ (id)failureWithError:(AtmosError *)err withLabel:(NSString *)label
{
    CreateAccessTokenResult *res = [[CreateAccessTokenResult alloc]initWithResult:NO withError:err withLabel:label];
    [res autorelease];
    return res;
}


@end
