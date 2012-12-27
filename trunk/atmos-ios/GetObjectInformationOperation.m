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
#import "GetObjectInformationOperation.h"

@interface GetObjectInformationOperation ()
#pragma mark Private Properties

@property (nonatomic,retain) NSXMLParser *xmlParser;
@property (nonatomic,retain) NSString *currentElement;
@property (nonatomic,retain) NSMutableString *currentValue;
@property (nonatomic,retain) ObjectInformation *info;
@property (nonatomic,retain) Replica *currentReplica;
@end

@implementation GetObjectInformationOperation


@synthesize callback, atmosObject;
@synthesize xmlParser, currentValue, currentElement, info, currentReplica;

#pragma mark Memory Management
-(void) dealloc {
    self.xmlParser = nil;
    self.currentElement = nil;
    self.currentValue = nil;
    self.callback = nil;
    self.info = nil;
    self.currentReplica = nil;
    self.atmosObject = nil;
    
    [super dealloc];
}

#pragma mark Implementation
- (void) startAtmosOperation {
    if(self.atmosObject.atmosId) {
        self.atmosResource = [NSString stringWithFormat:@"/rest/objects/%@?info",self.atmosObject.atmosId];
    } else if(self.atmosObject.objectPath) {
        self.atmosResource = [NSString stringWithFormat:@"/rest/namespace%@?info",self.atmosObject.objectPath];
    } else {
        [NSException raise:@"InvalidArgumentException" format:@"AtmosObject should have either atmosId or objectPath set."];
    }
    
    NSMutableURLRequest *req = [self setupBaseRequestForResource:self.atmosResource];
    [req setHTTPMethod:@"GET"];
    [self signRequest:req];
    
    self.connection = [NSURLConnection connectionWithRequest:req delegate:self];
}

- (void) parseXMLData {
	if(self.xmlParser != nil) {
        self.xmlParser = nil;
	} 
	NSXMLParser *p = [[NSXMLParser alloc] initWithData:self.webData];
	self.xmlParser = p;
	[p setDelegate:self];
    [p setShouldProcessNamespaces:NO];
    [p setShouldReportNamespacePrefixes:NO];
    [p setShouldResolveExternalEntities:NO];
    [p parse];
    
	[p release];
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
    
    self.callback([ObjectInformation failureWithError:err withLabel:self.operationLabel]);
    
	[err release];
	[self.atmosStore operationFinishedInternal:self];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)con
{
	if([self.httpResponse statusCode] >= 400) {
		NSString *errStr = [[NSString alloc] initWithData:self.webData encoding:NSASCIIStringEncoding];
		AtmosError *aerr = [self extractAtmosError:errStr];
        ObjectInformation *result = [[ObjectInformation alloc]init];
        result.wasSuccessful = NO;
        result.error = aerr;
        
        self->callback(result);
        
        [result release];
        [errStr release];
	} else {
        NSString *str = [[NSString alloc] initWithData:self.webData encoding:NSASCIIStringEncoding];
        self.info = [ObjectInformation objectInformation];
        self.info.rawXml = str;
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
    
    if( [elementName isEqualToString:@"replica"] ) {
        // Start a new replica
        self.currentReplica = [Replica replica];
    } else if( [elementName isEqualToString:@"replicas"] ) {
        parseMode = kModeReplica;
    } else if( [elementName isEqualToString:@"retention"] ) {
        parseMode = kModeRetention;
    } else if( [elementName isEqualToString:@"expiration"] ) {
        parseMode = kModeExpiration;
    }
	
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{     
    if (qName) {
        elementName = qName;
    }
	
	if([elementName isEqualToString:@"replica"]) {
		// Push the completed replica into the array
        [self.info.replicas addObject:self.currentReplica];
        self.currentReplica = nil;
	} else if([elementName isEqualToString:@"selection"]) {
        self.info.selection = self.currentValue;
    } else if([elementName isEqualToString:@"id"]) {
        self.currentReplica.replicaId = self.currentValue;
    } else if([elementName isEqualToString:@"type"]) {
        self.currentReplica.replicaType = self.currentValue;
    } else if([elementName isEqualToString:@"objectId"]) {
        self.info.objectId = [self.currentValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    } else if([elementName isEqualToString:@"current"]) {
        if([@"true" isEqualToString:self.currentValue]) {
            self.info.current = YES;
        }
    } else if([elementName isEqualToString:@"location"]) {
        self.currentReplica.location = self.currentValue;
    } else if([elementName isEqualToString:@"storageType"]) {
        self.currentReplica.storageType = self.currentValue;
    } else if([elementName isEqualToString:@"enabled"]) {
        BOOL enableValue = [@"true" isEqualToString:self.currentValue];
        switch (parseMode) {
            case kModeRetention:
                self.info.retentionEnabled = enableValue;
                break;
            case kModeExpiration:
                self.info.expirationEnabled = enableValue;
                break;
            default:
                [NSException raise:@"Unexpected element parsing XML" format:@"Unexpected element %@ with value %@ encountered in parse mode %d", elementName,
                 self.currentValue, parseMode];
        }
    } else if([elementName isEqualToString:@"endAt"]) {
        if([self.currentValue length] > 0) {
            // Parse out the date string
            NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
            [fmt setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"]; // XML dateTime format
            [fmt setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
            NSDate *date = [fmt dateFromString:self.currentValue];
            switch (parseMode) {
                case kModeRetention:
                    self.info.retentionEnd = date;
                    break;
                case kModeExpiration:
                    self.info.expirationEnd = date;
                    break;
                default:
                    [NSException raise:@"Unexpected element parsing XML" format:@"Unexpected element %@ with value %@ encountered in parse mode %d", elementName,
                     self.currentValue, parseMode];
            }
            [fmt release];
        }
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
	//NSLog(@"foundChars %@ %@",string,[self.currentValue class]);
	
	[self.currentValue appendString:string];
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
	
    self.info.requestLabel = self.operationLabel;
    self.info.wasSuccessful = YES;
    self.info.error = nil;
    
    self.callback(self.info);
    
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