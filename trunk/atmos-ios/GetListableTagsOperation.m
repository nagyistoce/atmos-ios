//
//  GetListableTagsOperation.m
//  AtmosCocoaBinding
//
//  Created by Aashish Patil on 7/9/10.
//  Copyright 2010 EMC. All rights reserved.
//

#import "GetListableTagsOperation.h"


@implementation GetListableTagsOperation

@synthesize callback;

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
	}
	[self.atmosStore operationFinishedInternal:self];
	
}





@end
