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

#import "GetMetadataOperation.h"

@interface GetMetadataOperation (Private)

- (void) setMetadata:(NSString *) metaStr onDictionary:(NSMutableDictionary *)dict;

@end

@implementation GetMetadataOperation

@synthesize atmosId, objectPath, atmosObj, metaLoadType, callback;

- (void) startAtmosOperation {
	
	AtmosObject *aobj = [[AtmosObject alloc] init];
	self.atmosObj = aobj;
	[aobj release];
    
    NSMutableURLRequest *req;
    
    switch (metaLoadType) {
        case kMetaLoadAll:
            // All metadata is fetched via a HEAD call to the object
            if(self.atmosId) {
                self.atmosResource = [NSString stringWithFormat:@"/rest/objects/%@",self.atmosId];
            } else if(self.objectPath) {
                self.atmosResource = [NSString stringWithFormat:@"/rest/namespace%@",self.objectPath];
            }
            req = [self setupBaseRequestForResource:self.atmosResource];
            [req setHTTPMethod:@"HEAD"];
            break;
            
        case kMetaLoadUser:
            if(self.atmosId) {
                self.atmosResource = [NSString stringWithFormat:@"/rest/objects/%@?metadata/user",self.atmosId];
            } else if(self.objectPath) {
                self.atmosResource = [NSString stringWithFormat:@"/rest/namespace%@?metadata/user",self.objectPath];
            }
            
            req = [self setupBaseRequestForResource:self.atmosResource];
            break;
        case kMetaLoadSystem:
            if(self.atmosId) {
                self.atmosResource = [NSString stringWithFormat:@"/rest/objects/%@?metadata/system",self.atmosId];
            } else if(self.objectPath) {
                self.atmosResource = [NSString stringWithFormat:@"/rest/namespace%@?metadata/system",self.objectPath];
            }
            
            req = [self setupBaseRequestForResource:self.atmosResource];
            break;
    }
    
    [self setFilterTagsOnRequest:req];
    [self signRequest:req];
    NSLog(@"setup request %@",req);
    self.connection = [NSURLConnection connectionWithRequest:req delegate:self];

}

- (void) setMetadata:(NSString *) metaStr onDictionary:(NSMutableDictionary *)dict {
	NSArray *arr = [metaStr componentsSeparatedByString:@", "];
	for(int i=0;i < arr.count;i++) {
		NSString *str = [arr objectAtIndex:i];
		NSArray *comps = [str componentsSeparatedByString:@"="];
		[dict setObject:[comps objectAtIndex:1] forKey:[comps objectAtIndex:0]];
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


- (void)connectionDidFinishLoading:(NSURLConnection *)con
{
	NSLog(@"connectionDidFinishLoading %@",con);
	if([self.httpResponse statusCode] >= 400) {
		//some atmos error
		NSString *errStr = [[NSString alloc] initWithData:self.webData encoding:NSASCIIStringEncoding];
		AtmosError *aerr = [self extractAtmosError:errStr];
        
        self.callback([AtmosObjectResult failureWithError:aerr withLabel:self.operationLabel]);
        
        [aerr release];
        [errStr release];
        		
	} else {
		
		if(self.objectPath) {
			self.atmosObj.objectPath = self.objectPath;
		} else if(self.atmosId) {
			self.atmosObj.atmosId = self.atmosId;
		}
			
		NSLog(@"response header fields %@",[self.httpResponse allHeaderFields]);
        
        switch(metaLoadType) {
            case kMetaLoadAll:
                [self extractEMCMetaFromResponse:self.httpResponse
                                        toObject:self.atmosObj];
                
                [self setMetadata:[[self.httpResponse allHeaderFields] objectForKey:@"X-Emc-Meta"] onDictionary:self.atmosObj.userRegularMeta];
                
                break;
            case kMetaLoadSystem:
                [self setMetadata:[[self.httpResponse allHeaderFields] objectForKey:@"X-Emc-Meta"] onDictionary:self.atmosObj.systemMeta];
                break;
            case kMetaLoadUser:
                [self setMetadata:[[self.httpResponse allHeaderFields] objectForKey:@"X-Emc-Meta"] onDictionary:self.atmosObj.userRegularMeta];
                [self setMetadata:[[self.httpResponse allHeaderFields] objectForKey:@"X-Emc-Listable-Meta"] onDictionary:self.atmosObj.userListableMeta];
                break;
                
        }
        
        AtmosObjectResult *result = [[AtmosObjectResult alloc] initWithResult:YES withError:nil withLabel:self.operationLabel withObject:self.atmosObj];
        self.callback(result);
        [result release];
		
			
		[self.atmosStore operationFinishedInternal:self];
	}
		
}




@end