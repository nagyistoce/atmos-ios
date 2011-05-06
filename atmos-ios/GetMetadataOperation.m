//
//  GetMetadataOperation.m
//  AtmosCocoaBinding
//
//  Created by Aashish Patil on 9/11/10.
//  Copyright 2010 EMC. All rights reserved.
//

#import "GetMetadataOperation.h"

@interface GetMetadataOperation (Private)

- (void) setMetadata:(NSString *) metaStr onDictionary:(NSMutableDictionary *)dict;

@end

@implementation GetMetadataOperation

@synthesize atmosId, objectPath, sysMetaConn, userMetaConn,atmosObj, loadUserMeta, loadSysMeta;

- (void) startAtmosOperation {
	
	maxConnections = 0;
	numConnections = 0;
	AtmosObject *aobj = [[AtmosObject alloc] init];
	self.atmosObj = aobj;
	[aobj release];
	//first user meta
	if(self.loadUserMeta) {
		if(self.atmosId) {
			self.atmosResource = [NSString stringWithFormat:@"/rest/objects/%@?metadata/user",self.atmosId];
		} else if(self.objectPath) {
			self.atmosResource = [NSString stringWithFormat:@"/rest/namespace%@?metadata/user",self.objectPath];
		}
		
		NSMutableURLRequest *req = [self setupBaseRequestForResource:self.atmosResource];
		[self setFilterTagsOnRequest:req];
		[self signRequest:req];
		NSLog(@"setup request %@",req);
		self.userMetaConn = [NSURLConnection connectionWithRequest:req delegate:self];
		maxConnections++;
	}
	
	if(self.loadSysMeta) {
		if(self.atmosId) {
			self.atmosResource = [NSString stringWithFormat:@"/rest/objects/%@?metadata/system",self.atmosId];
		} else if(self.objectPath) {
			self.atmosResource = [NSString stringWithFormat:@"/rest/namespace%@?metadata/system",self.objectPath];
		}
		
		NSMutableURLRequest *req = [self setupBaseRequestForResource:self.atmosResource];
		[self setFilterTagsOnRequest:req];
		[self signRequest:req];
		NSLog(@"setup request %@",req);
		self.sysMetaConn = [NSURLConnection connectionWithRequest:req delegate:self];
		maxConnections++;
	}
	
	
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
		[self.progressListener finishedLoadingMetadata:nil forLabel:self.operationLabel withError:aerr];
		
	} else {
		
		if(self.objectPath) {
			self.atmosObj.objectPath = self.objectPath;
		} else if(self.atmosId) {
			self.atmosObj.atmosId = self.atmosId;
		}
			
		NSLog(@"response header fields %@",[self.httpResponse allHeaderFields]);
		NSString *sysMetaStr = [[self.httpResponse allHeaderFields] objectForKey:@"x-emc-meta"];
		if(sysMetaStr == nil || sysMetaStr.length == 0)
			sysMetaStr = [[self.httpResponse allHeaderFields] objectForKey:@"X-Emc-Meta"];
		if(sysMetaStr == nil || sysMetaStr.length == 0)
			sysMetaStr = [[self.httpResponse allHeaderFields] objectForKey:@"X-EMC-META"];
		
		if(sysMetaStr && sysMetaStr.length > 0) {
			if(con == self.sysMetaConn) 
				[self setMetadata:sysMetaStr onDictionary:self.atmosObj.systemMeta];
			else if(con == self.userMetaConn) 
				[self setMetadata:sysMetaStr onDictionary:self.atmosObj.userRegularMeta];
				
		}
		
		if(con == self.userMetaConn) {
			NSString *listableMetaStr = [[self.httpResponse allHeaderFields] objectForKey:@"x-emc-listable-meta"];
			if(listableMetaStr == nil || listableMetaStr.length == 0)
				listableMetaStr = [[self.httpResponse allHeaderFields] objectForKey:@"X-Emc-Listable-Meta"];
			if(listableMetaStr == nil || listableMetaStr.length == 0)
				listableMetaStr = [[self.httpResponse allHeaderFields] objectForKey:@"X-EMC-LISTABLE-META"];
			
			if(listableMetaStr && listableMetaStr.length > 0) {
				[self setMetadata:listableMetaStr onDictionary:self.atmosObj.userListableMeta];
			}
		}
		
	}
	
	numConnections++;
	if(numConnections == maxConnections) {
		[self.progressListener finishedLoadingMetadata:self.atmosObj forLabel:self.operationLabel withError:nil];
		[self.atmosStore operationFinishedInternal:self];
	}
		
}




@end
