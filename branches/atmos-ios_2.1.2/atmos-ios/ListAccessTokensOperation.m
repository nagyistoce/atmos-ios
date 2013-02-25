/*
 Copyright (c) 2012, EMC Corporation
 
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 * Neither the name of the EMC Corporation nor the names of its contributors
 may be used to endorse or promote products derived from this software
 without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 */

#import "ListAccessTokensOperation.h"
#import "AtmosConstants.h"

@implementation ListAccessTokensOperation

@synthesize token, limit, callback;

#pragma mark memory management

- (id) init {
    self = [super init];
    if(self) {
        token = nil;
        limit = 0;
    }
    
    return self;
}

- (void) dealloc {
    self.token = nil;
    self.callback = nil;
    
    [super dealloc];
}

#pragma mark implementation
- (void) startAtmosOperation {
    self.atmosResource = ATMOS_ACCESS_TOKEN_LOCATION_PREFIX;
    
    NSMutableURLRequest *req = [self setupBaseRequestForResource:self.atmosResource];
    [req setHTTPMethod:@"GET"];
    
    if(self.token) {
        [req addValue:self.token forHTTPHeaderField:ATMOS_HEADER_TOKEN];
    }
    if(self.limit > 0) {
        [req addValue:[NSString stringWithFormat:@"%d", self.limit] forHTTPHeaderField:ATMOS_HEADER_LIMIT];
    }
    
    [self signRequest:req];
    
    self.connection = [NSURLConnection connectionWithRequest:req delegate:self];
}

#pragma mark NSURLRequest delegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	//NSLog(@"didReceiveResponse %@",response);
	self.httpResponse = (NSHTTPURLResponse *) response;
	[self.webData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[self.webData appendData:data];
}

- (void)connection:(NSURLConnection *)con
  didFailWithError:(NSError *)error
{
	NSLog(@"didFailWithError %@",[error localizedDescription]);
	AtmosError *err = [[AtmosError alloc] initWithCode:-1 message:[error localizedDescription]];
    
    ListAccessTokensResult *result = [[ListAccessTokensResult alloc] init];
    result.error = err;
    result.wasSuccessful = NO;
    
    self.callback(result);
    
	[err release];
    [result release];
	[self.atmosStore operationFinishedInternal:self];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)con
{
	if([self.httpResponse statusCode] >= 400) {
		NSString *errStr = [[NSString alloc] initWithData:self.webData encoding:NSASCIIStringEncoding];
		AtmosError *aerr = [self extractAtmosError:errStr];
        ListAccessTokensResult *result = [[ListAccessTokensResult alloc]init];
        result.wasSuccessful = NO;
        result.error = aerr;
        
        self.callback(result);
        
        [result release];
        [errStr release];
	} else {
        NSString *str = [[NSString alloc] initWithData:self.webData encoding:NSASCIIStringEncoding];
        NSLog(@"connectionFinishedLoading %@",str);
        [str release];
        ListAccessTokensResult *result = [[ListAccessTokensResult alloc]init];
        result.wasSuccessful = YES;
        result.results = [TNSListAccessTokenResultType fromListAccessTokensResult:self.webData];
        if(!result.results) {
            result.wasSuccessful = NO;
            AtmosError *aerr = [[AtmosError alloc] initWithCode:0 message:@"Failed to parse response XML"];
            result.error = aerr;
            [aerr release];
        }
        self.responseHeaders = [self.httpResponse allHeaderFields];
        result.token = [self.responseHeaders valueForKey:ATMOS_HEADER_TOKEN];
        
        self.callback(result);
        
        [result release];
    }
    [self.atmosStore operationFinishedInternal:self];
}


@end
