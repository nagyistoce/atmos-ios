/*
 
 Copyright (c) 2009, EMC Corporation
 
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



#import "ListObjectsOperation.h"

@interface ListObjectsOperation (Private)
-(void) parseXMLData;
@end


@implementation ListObjectsOperation

@synthesize currentId,currentElement,currentAtmosProp,currentValue,currentPropValue,listable, result;
@synthesize loadMetadata, systemMetadata, userMetadata, callback;
@synthesize token, limit;

- (id)init
{
    self = [super init];
    if( self ) {
        result = [[ListObjectsResult alloc] init];
    }
    
    return self;
}

- (void) startAtmosOperation {
    self.result.requestLabel = self.operationLabel;
	self.atmosResource = @"/rest/objects";	

	NSMutableURLRequest *req = [super setupBaseRequestForResource:self.atmosResource];
	if(self.loadMetadata) {
		[req addValue:[NSString stringWithFormat:@"%d",self.loadMetadata] forHTTPHeaderField:@"x-emc-include-meta"];
	}  
	
	if(self.systemMetadata && self.systemMetadata.count > 0) {
		NSString *sysTagsStr = [self.systemMetadata componentsJoinedByString:@","];
		NSLog(@"system tags as string %@",sysTagsStr);
		[req addValue:sysTagsStr forHTTPHeaderField:@"x-emc-system-tags"];
	}
	
	if(self.userMetadata && self.userMetadata.count > 0) {
		NSString *userTagsStr = [self.userMetadata componentsJoinedByString:@","];
		[req addValue:userTagsStr forHTTPHeaderField:@"x-emc-user-tags"];
	}
    
    if(self.token != nil) {
        [req addValue:self.token forHTTPHeaderField:@"x-emc-token"];
    }
    
    if(self.limit != 0) {
        NSString *limitValue = [NSString stringWithFormat:@"%d", self.limit];
        [req addValue:limitValue forHTTPHeaderField:@"x-emc-limit"];
    }
	
	[self setFilterTagsOnRequest:req];
	[super signRequest:req];
	
	self.connection = [[NSURLConnection alloc] initWithRequest:req delegate:self startImmediately:YES];
}

- (void) parseXMLData {
	xmlParser = [[NSXMLParser alloc] initWithData:self.webData];
	[xmlParser setDelegate:self];
    [xmlParser setShouldProcessNamespaces:NO];
    [xmlParser setShouldReportNamespacePrefixes:NO];
    [xmlParser setShouldResolveExternalEntities:NO];
    
    [xmlParser parse];
	[xmlParser release];
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
	//NSLog(@"didReceiveData %d",data.length);
	[self.webData appendData:data];
}

- (void)connection:(NSURLConnection *)con
  didFailWithError:(NSError *)error
{
	NSLog(@"didFailWithError %@",[error localizedDescription]);
	AtmosError *err = [[AtmosError alloc] initWithCode:-1 message:[error localizedDescription]];

    result.wasSuccessful = NO;
    result.error = err;
    self->callback(result);
    
	[err release];
	[self.atmosStore operationFinishedInternal:self];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)con
{
	if([self.httpResponse statusCode] >= 400) {
		NSString *errStr = [[NSString alloc] initWithData:self.webData encoding:NSASCIIStringEncoding];
		AtmosError *aerr = [self extractAtmosError:errStr];
        ListObjectsResult *res = [[ListObjectsResult alloc]init];
        res.wasSuccessful = NO;
        res.error = aerr;
        
        self->callback(res);
        
        [res release];
        [errStr release];
	} else {
        // Check for token
        NSDictionary *headers = self.httpResponse.allHeaderFields;
        
        NSLog(@"Response headers: %@", headers);
        
        self.result.token = [headers valueForKey:@"X-Emc-Token"];
        NSString *str = [[NSString alloc] initWithData:self.webData encoding:NSASCIIStringEncoding];
        NSLog(@"connectionFinishedLoading %@",str);
        [str release];
        [self parseXMLData];
    }
}
	
#pragma mark NSXMLParser delegate
- (void)parserDidStartDocument:(NSXMLParser *)parser
{
	NSLog(@"didstart doc");
    if(result.objects != nil) {
		[result.objects removeAllObjects];
	}
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
	
    if (qName) {
        elementName = qName;
    }
	
	//NSLog(@"didstartelement %@",elementName);
	//begin processing new atmos object
	if([elementName isEqualToString:@"Object"]) { 
		currentObject = [[AtmosObject alloc] init];
		NSLog(@"started new object");
	} else if([elementName isEqualToString:@"SystemMetadataList"]) {
		isSystemMetadata = YES;
		isUserMetadata = NO;
	} else if([elementName isEqualToString:@"UserMetadataList"]) {
		isUserMetadata = YES;
		isSystemMetadata = NO;
	}
	
	self.currentElement = elementName;
	self.currentValue = [NSMutableString string];
	
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{     
    if (qName) {
        elementName = qName;
    }
	
	if([elementName isEqualToString:@"Object"]) {
		if(currentObject != nil) {
			[result.objects 
             addObject:currentObject];
			//NSLog(@"Just added items %@",self.currentObject);
            
            [currentObject release];
            currentObject = nil;
		}
	}
	else if([elementName isEqualToString:@"ObjectID"]) {
		//NSLog(@"Got object id %@",self.currentValue);
		currentObject.atmosId = [self.currentValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	}
	else if([elementName isEqualToString:@"SystemMetadataList"]) {
		isSystemMetadata = NO;
	}
	else if([elementName isEqualToString:@"UserMetadataList"]) {
		isUserMetadata = NO;
	}
	else if([elementName isEqualToString:@"Name"]) {
		//NSLog(@"Got prop name %@",self.currentValue);
		self.currentAtmosProp = [self.currentValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		
	} else if([elementName isEqualToString:@"Value"]) {
		//NSLog(@"Found value %@ = %@",self.currentAtmosProp,self.currentValue);
		self.currentPropValue = [self.currentValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		
	} else if([elementName isEqualToString:@"Listable"]) {
		self.listable = [[self.currentValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] boolValue];
	} else if([elementName isEqualToString:@"Metadata"]) {
		if(self.listable && isUserMetadata) {
			[currentObject.userListableMeta setObject:self.currentPropValue forKey:self.currentAtmosProp];
		} else if(!self.listable && isUserMetadata) {
			[currentObject.userRegularMeta setObject:self.currentPropValue forKey:self.currentAtmosProp];
		} else if(isSystemMetadata) {
			[currentObject.systemMeta setObject:self.currentPropValue forKey:self.currentAtmosProp];
		}
	}
	
	//NSLog(@"currentData %@",self.currentData);
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
	//NSLog(@"foundChars %@",string);
	[self.currentValue appendString:string];
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {

    result.wasSuccessful = YES;
    
    [result retain];
    self.callback(self.result);
    [result release];
	[self.atmosStore operationFinishedInternal:self];
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
	if(parseError) {
		NSLog(@"Parse Error %@",parseError);
		AtmosError *aerr = [[AtmosError alloc] initWithCode:parseError.code message:[parseError localizedDescription]] ;

        result.wasSuccessful = NO;
        result.error = aerr;
        self->callback(result);
        
		[self.atmosStore operationFinishedInternal:self];
		[aerr release];
	}
}

- (void) dealloc {
    NSLog(@"ListObjectsOperation dealloc");
	self.currentId = nil;
    self.currentElement = nil;
    self.currentAtmosProp = nil;
    self.currentPropValue = nil;
    self.currentValue = nil;
    self.result = nil;
    self.systemMetadata = nil;
    self.userMetadata = nil;
    self.token = nil;
    
	[super dealloc];
}


@end
