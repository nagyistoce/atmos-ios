//
//  DeleteObjectOperation.m
//  AtmosCocoaBinding
//
//  Created by Aashish Patil on 9/20/10.
//  Copyright 2010 EMC. All rights reserved.
//

#import "DeleteObjectOperation.h"
#import "AtmosResult.h"

@implementation DeleteObjectOperation

@synthesize atmosObj, callback;


- (void) startAtmosOperation {
	if(self.atmosObj) {
		if(self.atmosObj.atmosId && self.atmosObj.atmosId.length == ATMOS_ID_LENGTH) {
			self.atmosResource = [NSString stringWithFormat:@"/rest/objects/%@",self.atmosObj.atmosId];
		} else if (self.atmosObj.objectPath) {
			self.atmosResource = [NSString stringWithFormat:@"/rest/namespace%@",self.atmosObj.objectPath];
		} else {
			return; //no atmos resource to delete
		}

		NSMutableURLRequest *req = [self setupBaseRequestForResource:self.atmosResource];
		[req setHTTPMethod:@"DELETE"];
		[self signRequest:req];
		
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
	//[connection release];
	
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
		
	} else {
        self.callback([AtmosResult successWithLabel:self.operationLabel]);
	}
	[self.atmosStore operationFinishedInternal:self];
}



@end
