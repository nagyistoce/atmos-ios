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
#import "GetServiceInformationOperation.h"

@interface GetServiceInformationOperation ()
-(void) parseXMLData;

@property (nonatomic,retain) NSString *currentElement;
@property (nonatomic,retain) NSMutableString *currentValue;
@property (nonatomic,retain) NSString *atmosVersion;
@end


@implementation GetServiceInformationOperation

@synthesize callback, currentElement, currentValue, atmosVersion;



#pragma mark Memory Management
- (void) dealloc {
    self.callback = nil;
    self.currentValue = nil;
    self.currentElement = nil;
    self.atmosVersion = nil;
    
    [super dealloc];
}

#pragma mark Implementation
- (void) startAtmosOperation {
    self.atmosResource = @"/rest/service";
    
    NSMutableURLRequest *req = [self setupBaseRequestForResource:self.atmosResource];
    [req setHTTPMethod:@"GET"];
    [self signRequest:req];
    
    [NSURLConnection connectionWithRequest:req delegate:self];
}

- (void) parseXMLData {
	if(xmlParser != nil) {
		[xmlParser release];
        xmlParser = nil;
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
	[self.webData appendData:data];
}

- (void)connection:(NSURLConnection *)con
  didFailWithError:(NSError *)error
{
	NSLog(@"didFailWithError %@",[error localizedDescription]);
	AtmosError *err = [[AtmosError alloc] initWithCode:-1 message:[error localizedDescription]];
    
    self.callback([ServiceInformation failureWithError:err withLabel:self.operationLabel]);
    
	[err release];
	[self.atmosStore operationFinishedInternal:self];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)con
{
	if([self.httpResponse statusCode] >= 400) {
		NSString *errStr = [[NSString alloc] initWithData:self.webData encoding:NSASCIIStringEncoding];
		AtmosError *aerr = [self extractAtmosError:errStr];
        ServiceInformation *result = [[ServiceInformation alloc]init];
        result.wasSuccessful = NO;
        result.error = aerr;
        
        self->callback(result);
        
        [result release];
        [errStr release];
	} else {
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
	
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
	
    if (qName) {
        elementName = qName;
    }
    
	self.currentElement = elementName;
	self.currentValue = [NSMutableString string];
	
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{     
    if (qName) {
        elementName = qName;
    }
	
	if([elementName isEqualToString:@"Atmos"]) {
		self.atmosVersion = self.currentValue;
	}
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
	//NSLog(@"foundChars %@ %@",string,[self.currentValue class]);
	
	[self.currentValue appendString:string];
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
	
    
    ServiceInformation *result = [[ServiceInformation alloc] init];
    result.requestLabel = self.operationLabel;
    result.wasSuccessful = YES;
    result.error = nil;
    result.atmosVersion = self.atmosVersion;
    self.callback(result);
    [result release];
    
	[self.atmosStore operationFinishedInternal:self];
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
	if(parseError) {
		NSLog(@"Parse Error %@",parseError);
		AtmosError *aerr = [[AtmosError alloc] initWithCode:parseError.code message:[parseError localizedDescription]] ;
        
        self.callback([ServiceInformation failureWithError:aerr withLabel:self.operationLabel]);
        
		[self.atmosStore operationFinishedInternal:self];
		[aerr release];
	}
}



@end
