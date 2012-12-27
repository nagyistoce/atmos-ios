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


#import "GetListableTagsOperation.h"


@implementation GetListableTagsOperation

@synthesize callback;

- (void) dealloc {
    self.callback = nil;
    [super dealloc];
}

- (void) startAtmosOperation {
	
	NSString *strResource = [NSString stringWithFormat:@"/rest/objects?listableTags"];
	self.atmosResource = strResource;
	
	NSMutableURLRequest *req = [super setupBaseRequestForResource:strResource];
	[super setFilterTagsOnRequest:req];
	[super signRequest:req];
	
	NSLog(@"header fields %@",[req allHTTPHeaderFields]);
	
	NSLog(@"about to make the request %@",req);
	
	self.connection = [NSURLConnection connectionWithRequest:req delegate:self];
	
	NSLog(@"Connection %@", self.connection);
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
    GetListableTagsResult *result = [[GetListableTagsResult alloc]init];
	result.wasSuccessful = NO;
    result.error = err;
    
    self->callback(result);
    
    [result release];
    [err release];
    
	[self.atmosStore operationFinishedInternal:self];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)con
{
	NSLog(@"connectionDidFinishLoading %@",con);
	if([self.httpResponse statusCode] >= 400) {
		NSString *errStr = [[NSString alloc] initWithData:self.webData encoding:NSASCIIStringEncoding];
		AtmosError *aerr = [self extractAtmosError:errStr];
        GetListableTagsResult *result = [[GetListableTagsResult alloc]init];
        result.wasSuccessful = NO;
        result.error = aerr;
        
        self->callback(result);
        
        [result release];
        [errStr release];
	} else {
		NSLog(@"response header fields %@",[self.httpResponse allHeaderFields]);
		NSString *tagsStr = [[self.httpResponse allHeaderFields] objectForKey:@"x-emc-listable-tags"];
		if(tagsStr == nil || tagsStr.length == 0)
			tagsStr = [[self.httpResponse allHeaderFields] objectForKey:@"X-Emc-Listable-Tags"];
		if(tagsStr == nil || tagsStr.length == 0)
			tagsStr = [[self.httpResponse allHeaderFields] objectForKey:@"X-EMC-LISTABLE-TAGS"];
		
		NSArray *tags = [tagsStr componentsSeparatedByString:@", "];
        GetListableTagsResult *result = [[GetListableTagsResult alloc]init];
        result.wasSuccessful = YES;
        result.tags = tags;
        
        self->callback(result);
        
        [result release];
        
	}
	[self.atmosStore operationFinishedInternal:self];
	
}





@end
