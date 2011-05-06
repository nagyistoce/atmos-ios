//
//  SetMetadataOperation.m
//  AtmosCocoaBinding
//
//  Created by Aashish Patil on 9/12/10.
//  Copyright 2010 EMC. All rights reserved.
//

#import "SetMetadataOperation.h"


@implementation SetMetadataOperation

@synthesize curObj;

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
	[self.progressListener finishedSettingMetadata:self.curObj forLabel:self.operationLabel withError:err];
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
		[self.progressListener finishedSettingMetadata:nil forLabel:self.operationLabel withError:aerr];
		
	} else {
		[self.progressListener finishedSettingMetadata:self.curObj forLabel:self.operationLabel withError:nil];
	}
	[self.atmosStore operationFinishedInternal:self];
}



@end
