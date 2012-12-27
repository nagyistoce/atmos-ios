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

#import "CreateAccessTokenOperation.h"
#import "AtmosConstants.h"

@implementation CreateAccessTokenOperation

@synthesize object,callback,policy;

- (void) dealloc {
    self.object = nil;
    self.callback = nil;
    self.policy = nil;
    [super dealloc];
}

- (void) startAtmosOperation {
    self.atmosResource = ATMOS_ACCESS_TOKEN_LOCATION_PREFIX;
    NSMutableURLRequest *req = [self setupBaseRequestForResource:self.atmosResource];
    
    [req setHTTPMethod:@"POST"];
    
    if(self.object) {
        // Extract create object settings from the object.
        self.regularMeta = self.object.userRegularMeta;
		self.listableMeta = self.object.userListableMeta;
		[self setMetadataOnRequest:req];
        
        if(self.object.atmosId) {
            [req addValue:self.object.atmosId forHTTPHeaderField:ATMOS_HEADER_OBJECTID];
        } else if(self.object.objectPath) {
            [req addValue:self.object.objectPath forHTTPHeaderField:ATMOS_HEADER_PATH];
        }
    }
    
    if(self.policy) {
        NSData *policyXml = [self.policy toPolicy];
        [req setHTTPBody:policyXml];
        // Append a null terminator to make it a CString
        char *xmlCStr = malloc([policyXml length] +1);
        [policyXml getBytes:xmlCStr];
        xmlCStr[[policyXml length]] = 0;
        
        // Back to a string so we can compare it.
        NSString *policyStr = [NSString stringWithCString:xmlCStr encoding:NSUTF8StringEncoding];
        NSLog(@"Create Policy: %@", policyStr);
        
        free(xmlCStr);
    }
    
    [self signRequest:req];
    
    NSLog(@"req %@",req);
    NSLog(@"all headers %@",[req allHTTPHeaderFields]);
    
    self.connection = [NSURLConnection connectionWithRequest:req delegate:self];
}

#pragma mark NSURLConnection delegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	NSLog(@"didReceiveResponse %@",response);
	self.httpResponse = (NSHTTPURLResponse *) response;
	[self.webData setLength:0];
	
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	NSLog(@"didReceiveData %d",data.length);
	[self.webData appendData:data];
}

- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error
{
	NSLog(@"didFailWithError %@",[error localizedDescription]);
	AtmosError *err = [[AtmosError alloc] initWithCode:-1 message:[error localizedDescription]];
    self.callback([CreateAccessTokenResult failureWithError:err withLabel:self.operationLabel]);
    
    [err release];
	
	[self.atmosStore operationFinishedInternal:self];
	
}

- (void)connectionDidFinishLoading:(NSURLConnection *)con
{
	NSLog(@"connectionDidFinishLoading %@",con);
	if([self.httpResponse statusCode] >= 400) {
		//some atmos error
		NSString *errStr = [[NSString alloc] initWithData:self.webData encoding:NSASCIIStringEncoding];
		AtmosError *aerr = [self extractAtmosError:errStr];
        
        self.callback([CreateAccessTokenResult failureWithError:aerr withLabel:self.operationLabel]);
        
		[errStr release];
	} else {
        // Extract new access token ID
        NSString *location = [self extractLocation:self.httpResponse];
        NSString *tokenId = [location substringFromIndex:[ATMOS_ACCESS_TOKEN_LOCATION_PREFIX length]];
        CreateAccessTokenResult *result = [CreateAccessTokenResult successWithLabel:self.operationLabel];
        result.accessTokenId = tokenId;
        
        // Copy over the credentials object so the result can generate an
        // absolute URL to the token object.
        result.credentials = self.atmosCredentials;
        
        self.callback(result);
	}
    
	[self.atmosStore operationFinishedInternal:self];
}


@end
