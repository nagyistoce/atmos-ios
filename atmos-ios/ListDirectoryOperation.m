//
//  ListDirectoryOperation.m
//  AtmosCocoaBinding
//
//  Created by Aashish Patil on 9/21/10.
//  Copyright 2010 EMC. All rights reserved.
//

#import "ListDirectoryOperation.h"


@interface ListDirectoryOperation (Private)
-(void) parseXMLData;
@end


@implementation ListDirectoryOperation

@synthesize atmosObj,currentValue, emcToken, emcLimit, atmosObjects, currentElement, currentObject;

- (void) startAtmosOperation {
	if(self.atmosObj) {
		if(self.atmosObj.atmosId) {
			self.atmosResource = [NSString stringWithFormat:@"/rest/objects/%@",self.atmosObj.atmosId];
		} else if (self.atmosObj.objectPath) {
			self.atmosResource = [NSString stringWithFormat:@"/rest/namespace%@",self.atmosObj.objectPath];
		}
		
		NSMutableURLRequest *req = [self setupBaseRequestForResource:self.atmosResource];
		[req setHTTPMethod:@"GET"];
		if(self.emcToken) {
			[req setValue:self.emcToken forHTTPHeaderField:@"x-emc-token"];
		}
		if(self.emcLimit > 0) {
			[req setValue:[NSString stringWithFormat:@"%d",self.emcLimit] forHTTPHeaderField:@"x-emc-limit"];
		}
		[self signRequest:req];
		
		[NSURLConnection connectionWithRequest:req delegate:self];
	} else {
		return;
	}
	
}

- (void) parseXMLData {
	if(xmlParser != nil) {
		[xmlParser release];
	} 
	
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
	[self.progressListener finishedLoadingDirectory:self.atmosObj contents:nil token:self.emcToken forLabel:self.operationLabel withError:err];
	
	[err release];
	[self.atmosStore operationFinishedInternal:self];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)con
{
	NSString *str = [[NSString alloc] initWithData:self.webData encoding:NSASCIIStringEncoding];
	NSLog(@"connectionFinishedLoading %@",str);
	[self parseXMLData];
}

#pragma mark NSXMLParser delegate
- (void)parserDidStartDocument:(NSXMLParser *)parser
{
	NSLog(@"didstart doc");
    if(atmosObjects != nil) {
		[atmosObjects removeAllObjects];
		[atmosObjects release];
	}
	
	self.atmosObjects = [[NSMutableArray alloc] init];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
	
    if (qName) {
        elementName = qName;
    }
	
	//NSLog(@"didstartelement %@",elementName);
	//begin processing new atmos object
	if([elementName isEqualToString:@"DirectoryEntry"]) { 
		currentObject = [[AtmosObject alloc] init];
		NSLog(@"started new object");
	} 	
	self.currentElement = elementName;
	
	self.currentValue = [NSMutableString string];
	
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{     
    if (qName) {
        elementName = qName;
    }
	
	if([elementName isEqualToString:@"DirectoryEntry"]) {
		if(self.currentObject != nil) {
			[self.atmosObjects addObject:currentObject];
			//NSLog(@"Just added items %@",self.currentObject);
		}
	}
	else if([elementName isEqualToString:@"ObjectID"]) {
		//NSLog(@"Got object id %@",self.currentValue);
		currentObject.atmosId = [self.currentValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	}
	
	else if([elementName isEqualToString:@"FileType"]) {
		//NSLog(@"Got prop name %@",self.currentValue);
		NSString *strDir = [self.currentValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		currentObject.directory = [strDir isEqualToString:@"directory"];
	} else if([elementName isEqualToString:@"Filename"]) {
		//NSLog(@"Found value %@ = %@",self.currentAtmosProp,self.currentValue);
		NSString *strName = [self.currentValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		[currentObject.systemMeta setObject:strName forKey:@"objname"];
		if(self.atmosObj.objectPath) {
			if(currentObject.directory) {
				currentObject.objectPath = [NSString stringWithFormat:@"%@%@/",self.atmosObj.objectPath,self.currentValue];
			} else {
				currentObject.objectPath = [NSString stringWithFormat:@"%@%@",self.atmosObj.objectPath,self.currentValue];
			}
		}
	} 
	
	//NSLog(@"currentData %@",self.currentData);
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
	//NSLog(@"foundChars %@ %@",string,[self.currentValue class]);
	
	[self.currentValue appendString:string];
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
	
	NSString *strTok = [[self.httpResponse allHeaderFields] objectForKey:@"x-emc-token"];
	if(!strTok)
		strTok = [[self.httpResponse allHeaderFields] objectForKey:@"X-Emc-Token"];
	if(!strTok)
		strTok = [[self.httpResponse allHeaderFields] objectForKey:@"X-EMC-TOKEN"];
	self.emcToken = strTok;
	[self.progressListener finishedLoadingDirectory:self.atmosObj contents:atmosObjects token:self.emcToken forLabel:self.operationLabel withError:nil];
	[self.atmosStore operationFinishedInternal:self];
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
	if(parseError) {
		NSLog(@"Parse Error %@",parseError);
		AtmosError *aerr = [[AtmosError alloc] initWithCode:parseError.code message:[parseError localizedDescription]] ;
		[self.progressListener finishedLoadingDirectory:self.atmosObj contents:nil token:nil forLabel:self.operationLabel withError:aerr];
		[self.atmosStore operationFinishedInternal:self];
		[aerr release];
	}
}

@end
