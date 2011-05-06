//
//  DeleteMetadataOperation.m
//  AtmosCocoaBinding
//
//  Created by Aashish Patil on 9/24/10.
//  Copyright 2010 EMC. All rights reserved.
//

#import "DeleteMetadataOperation.h"


@implementation DeleteMetadataOperation

@synthesize atmosObj;

- (void) startAtmosOperation {
	
	if(self.atmosObj) {
		if(self.atmosObj.atmosId) {
			self.atmosResource = [NSString stringWithFormat:@"/rest/objects/%@",self.atmosObj.atmosId];
		} else if(self.atmosObj.objectPath) {
			self.atmosResource = [NSString stringWithFormat:@"/rest/namespace%@",self.atmosObj.objectPath];
		} else {
			return;
		}
	}
	
	NSMutableURLRequest *req = [self setupBaseRequestForResource:self.atmosResource];
	[req setHTTPMethod:@"DELETE"];
	//self.requestTags = [self.atmosObj.requestTags allObjects];
    self.requestTags = [NSMutableArray arrayWithArray:[self.atmosObj.requestTags allObjects]];
	[self setFilterTagsOnRequest:req];
	[self signRequest:req];
	
	[NSURLConnection connectionWithRequest:req delegate:self];
	
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
	[self.progressListener finishedDeletingMetadata:self.atmosObj status:NO forLabel:self.operationLabel withError:err];
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
		[self.progressListener finishedDeletingMetadata:self.atmosObj status:NO forLabel:self.operationLabel withError:aerr];
		
	} else {
		[self.progressListener finishedDeletingMetadata:self.atmosObj status:YES forLabel:self.operationLabel withError:nil];
	}
	[self.atmosStore operationFinishedInternal:self];
}



@end
