/*
 
 Copyright (c) 2011, EMC Corporation
 
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


#import "SetMetadataOperation.h"


@implementation SetMetadataOperation

@synthesize curObj,callback;

-(void) dealloc
{
    self.curObj = nil;
    self.callback = nil;
    [super dealloc];
}

- (void) startAtmosOperation {
	
	if(self.curObj) {
		if(self.curObj.atmosId) {
			self.atmosResource = [NSString stringWithFormat:@"/rest/objects/%@?metadata/user",self.curObj.atmosId];
		} else if(self.curObj.objectPath) {
			self.atmosResource = [NSString stringWithFormat:@"/rest/namespace%@?metadata/user",self.curObj.objectPath];
		} else {
			return;
		}
		
		NSMutableURLRequest *req = [self setupBaseRequestForResource:self.atmosResource];
		
		[req setHTTPMethod:@"POST"];
		self.regularMeta = self.curObj.userRegularMeta;
		self.listableMeta = self.curObj.userListableMeta;
		[self setMetadataOnRequest:req];
		[self signRequest:req];
		
		NSLog(@"req %@",req);
		NSLog(@"all headers %@",[req allHTTPHeaderFields]);
		
		[NSURLConnection connectionWithRequest:req delegate:self];
	}
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
    self.callback([AtmosResult failureWithError:err withLabel:self.operationLabel]);
    
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
        
        self.callback([AtmosResult failureWithError:aerr withLabel:self.operationLabel]);
        
		[errStr release];
	} else {
        self.callback([AtmosResult successWithLabel:self.operationLabel]);
	}
    
	[self.atmosStore operationFinishedInternal:self];
}



@end
