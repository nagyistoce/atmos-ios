/*
 Copyright (c) 2012, EMC Corporation
 
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 * Neither the name of the EMC Corporation nor the names of its contributors
 may be used to endorse or promote products derived from this software
 without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 */

#import "AtmosBaseOperation.h"

@implementation AtmosBaseOperation

@synthesize baseUrl, webData, listableMeta, regularMeta, responseHeaders,
operExecuting, operFinished, operationLabel;

@synthesize atmosCredentials = _atmosCredentials;
@synthesize atmosResource = _atmosResource;
@synthesize atmosStore;
@synthesize appData;
@synthesize requestTags;
@synthesize httpResponse;
@synthesize connection;

- (NSString *) baseUrl {
	if(baseUrl == nil) {
		self.baseUrl = [NSString stringWithFormat:@"%@://%@:%d",
                        self.atmosCredentials.httpProtocol,
                        self.atmosCredentials.accessPoint,
                        self.atmosCredentials.portNumber];
	}
	return baseUrl;
}

- (NSMutableURLRequest *) setupBaseRequestForResource:(NSString *) resource {
	
	//NSLog(@"setupBaseURL %@ %@",self.baseUrl,
	NSString *urlStr = [NSString stringWithFormat:@"%@%@",self.baseUrl,resource];
	urlStr = [urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    if(!urlStr) {
        [NSException raise:@"Illegal Argument" format:@"Could not escape URL: %@%@", self.baseUrl, resource];
    }
	//NSLog(@"urlStr %@",urlStr);
	NSURL *url = [NSURL URLWithString:urlStr];
    
    if(!url) {
        [NSException raise:@"URL Parse Error" format:@"Could not parse URL: %@", urlStr];
    }
    
	//NSLog(@"url %@",url);
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
	
	//[req addValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
	[req addValue:self.atmosCredentials.tokenId forHTTPHeaderField:@"x-emc-uid"];
	//[req addValue:@"ednSimpleApp" forHTTPHeaderField:@"x-emc-tags"];
	//[req addValue:@APP_TAG forHTTPHeaderField:@"x-emc-tags"];
	[req addValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
	
	NSTimeZone *tz = [NSTimeZone timeZoneWithName:@"GMT"];
	NSDateFormatter *fmter = [[NSDateFormatter alloc] init];
	[fmter setDateFormat:@"EEE, d MMM yyyy HH:mm:ss z"];
	fmter.timeZone = tz;
	NSDate *now = [[NSDate alloc] init];
    
    NSDate *adjdate = [now dateByAddingTimeInterval:atmosStore.timeOffset];
    
	NSString *fmtDate = [fmter stringFromDate:adjdate];
	fmtDate = [fmtDate stringByReplacingOccurrencesOfString:@"+00:00" withString:@""];
	//NSLog(@"Formatted date %@",fmtDate);
	[req addValue:fmtDate forHTTPHeaderField:@"Date"];
	[fmter release];
	[now release];
	
	return req;
	
}


-(void) signRequest:(NSMutableURLRequest *) request {
	
	NSDictionary *headers = [request allHTTPHeaderFields];
	NSArray *keys = [headers allKeys];
	NSMutableArray *emcKeys = [[NSMutableArray alloc] init];
	for(int i=0;i<keys.count;i++) {
		NSString *strKey = (NSString *) [keys objectAtIndex:i];
		
		//NSLog(@"header %@",strKey);
		if([[strKey lowercaseString] hasPrefix:@"x-emc-"]) {
			[emcKeys addObject:strKey];
		}
	}
	NSArray *sortedEmcKeys = [emcKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	
	//HTTP Method
	NSMutableString *signStr = [[NSMutableString alloc] init];
	[signStr appendString:request.HTTPMethod];
	[signStr appendString:@"\n"];
	
	//Content-Type
	NSString *contentTypeVal = [headers objectForKey:@"Content-Type"];
	if(contentTypeVal != nil) {
		[signStr appendString:contentTypeVal];
	}
	[signStr appendString:@"\n"];
	
	//Range
	NSString *rangeVal = [headers objectForKey:@"Range"];
	if(rangeVal != nil) {
		[signStr appendString:rangeVal];
	}
	[signStr appendString:@"\n"];
	
	//Date must exist since its a required field. TODO - check for non-existence of data in future
	[signStr appendString:(NSString *)[headers objectForKey:@"Date"]];
	[signStr appendString:@"\n"];
	
	//append resource
	[signStr appendString:[self.atmosResource lowercaseString]];
	[signStr appendString:@"\n"];
	
	for(int i=0;i < sortedEmcKeys.count;i++) {
		[signStr appendString:[[sortedEmcKeys objectAtIndex:i] lowercaseString]];
		[signStr appendString:@":"];
		NSString *trimmedStr = [[headers objectForKey:[sortedEmcKeys objectAtIndex:i]] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		NSString *nlReplaced1 = [trimmedStr stringByReplacingOccurrencesOfString:@"\r\n" withString:@""];
		NSString *nlReplaced2 = [nlReplaced1 stringByReplacingOccurrencesOfString:@"\n" withString:@""];
		NSString *nlReplaced3 = [nlReplaced2 stringByReplacingOccurrencesOfString:@"\r" withString:@""];
		[signStr appendString:nlReplaced3];
		if(i < (sortedEmcKeys.count -1)) {
			[signStr appendString:@"\n"];
		}
	}
	
	NSData *keyData = [NSData dataWithBase64EncodedString:self.atmosCredentials.sharedSecret];
	NSData *clearTextData = [signStr dataUsingEncoding:NSUTF8StringEncoding];
	
	uint8_t digest[CC_SHA1_DIGEST_LENGTH] = {0};
	
	CCHmacContext hmacContext;
	CCHmacInit(&hmacContext, kCCHmacAlgSHA1, keyData.bytes, keyData.length);
	CCHmacUpdate(&hmacContext, clearTextData.bytes, clearTextData.length);
	CCHmacFinal(&hmacContext, digest);
	
	NSData *out = [NSData dataWithBytes:digest length:CC_SHA1_DIGEST_LENGTH];
	NSString *base64Enc = [out base64Encoding];
	//NSLog(@"signStr from method %@",signStr);
	//NSLog(@"Base 64 sig from method: %@",base64Enc);
	
	[request setValue:base64Enc forHTTPHeaderField:@"x-emc-signature"];
	
	[emcKeys release];
	[signStr release];
	
}

- (NSString *) getSharedSecret {
	return self.atmosCredentials.sharedSecret;
}

- (NSArray *) requestTags {
	if(requestTags == nil) {
        NSMutableArray *rtags = [[NSMutableArray alloc] init];
		self.requestTags = rtags;
        [rtags release];
	}
	return requestTags;
}

- (NSMutableDictionary *) listableMeta {
	if(listableMeta == nil) {
        NSMutableDictionary *m = [[NSMutableDictionary alloc] init];
		self.listableMeta = m;
        [m release];
	}
	return listableMeta;
}

- (NSMutableDictionary *)regularMeta {
	if(regularMeta == nil) {
        NSMutableDictionary *m = [[NSMutableDictionary alloc] init];
		self.regularMeta = m;
        [m release];
	}
	return regularMeta;
}

- (NSString *) getMetaValue: (NSMutableDictionary *) metaVals {
	NSArray *listableKeys = [metaVals allKeys];
	NSMutableString *listableMetaValue = [[[NSMutableString alloc] init] autorelease];
	NSLog(@"keyCount %d",listableKeys.count);
	for(int i=0;i<listableKeys.count;i++) {
		NSString *key = (NSString *) [listableKeys objectAtIndex:i];
		NSLog(@"got key %@",key);
		NSString *value = (NSString *) [metaVals valueForKey:key];
		[listableMetaValue appendFormat:@"%@=%@",key,value];
		if(i < (listableKeys.count - 1)) {
			[listableMetaValue appendString:@","];
		}
	}
	NSLog(@"listableMetaStr %@",listableMetaValue);
	return listableMetaValue;
}

- (void) setMetadataOnRequest:(NSMutableURLRequest *) req {
	
	if(self.listableMeta && self.listableMeta.count > 0) {
		NSString *listableMetaStr = [self getMetaValue:self.listableMeta];
		if(listableMetaStr && listableMetaStr.length > 0) {
			[req addValue:listableMetaStr forHTTPHeaderField:@"x-emc-listable-meta"];
		}
	}
	
	if(self.regularMeta && self.regularMeta.count > 0) {
		NSString *regularMetaStr = [self getMetaValue:self.regularMeta];
		if(regularMetaStr && regularMetaStr.length > 0) {
			[req addValue:regularMetaStr forHTTPHeaderField:@"x-emc-meta"];
		}
	}
}

/*
 Adds x-emc-tags header based on the tag array or if array is nil or zero length, it sets a blank header
 */
- (void) setFilterTagsOnRequest:(NSMutableURLRequest *) req {
	if(self.requestTags && self.requestTags.count > 0) {
		NSMutableString *tagVal = [[NSMutableString alloc] init];
		for(int i=0;i<self.requestTags.count;i++) {
			NSString *tag = [self.requestTags objectAtIndex:i];
			[tagVal appendString:tag];
			if(i < (self.requestTags.count - 1)) {
				[tagVal appendString:@","];
			}
		}
		[req addValue:tagVal forHTTPHeaderField:@"x-emc-tags"];
        [tagVal release];
	} else {
		[req addValue:@"" forHTTPHeaderField:@"x-emc-tags"];
	}
    
}

- (NSString *) extractLocation:(NSHTTPURLResponse *) resp {
	NSDictionary *hdrFields = [resp allHeaderFields];
	NSString *locationVal = [hdrFields valueForKey:@"location"];
	if(locationVal == nil || locationVal.length == 0)
		locationVal = [hdrFields valueForKey:@"Location"];
	if(locationVal == nil || locationVal.length == 0)
		locationVal = [hdrFields valueForKey:@"LOCATION"];
    
    return locationVal;
}


- (NSString *) extractObjectId:(NSHTTPURLResponse *) resp {
	NSString *locationVal = [self extractLocation:resp];
    
	if(locationVal) {
		NSArray *pcomps = [locationVal pathComponents];
		NSString *atmosId = (NSString *) [pcomps lastObject];
		return atmosId;
	} else {
		return nil;
	}
    
}

- (AtmosError *) extractAtmosError:(NSString *) errorString {
	NSLog(@"Got error String %@",errorString);
	NSString *errStr = [errorString lowercaseString];
	NSRange codeRange = [errStr rangeOfString:@"<code>"];
	NSRange codeEndRange = [errStr rangeOfString:@"</code>"];
	if((codeRange.location != NSNotFound) && (codeEndRange.location != NSNotFound)) {
		AtmosError *aerr = [[[AtmosError alloc] init] autorelease];
		NSInteger codeStartPoint = codeRange.location + 6;
		NSInteger codeLength = (codeEndRange.location - codeStartPoint);
		NSLog(@"Range %d %d",codeStartPoint,codeLength);
		NSString *codeValue = [errStr substringWithRange:NSMakeRange(codeStartPoint,codeLength )];
		aerr.errorCode = [codeValue integerValue];
		NSLog(@"got atmos error code %@",codeValue);
		
		NSRange msgRange = [errStr rangeOfString:@"<message>"];
		NSRange msgEndRange = [errStr rangeOfString:@"</message>"];
		if((msgRange.location != NSNotFound) && (msgEndRange.location != NSNotFound)) {
			NSInteger msgStartPoint = msgRange.location + 9;
			NSInteger msgLength = msgEndRange.location - msgStartPoint;
			NSString *errMsg = [errStr substringWithRange:NSMakeRange(msgStartPoint,msgLength)];
			NSLog(@"errMsg %@",errMsg);
			aerr.errorMessage = errMsg;
		}
		return aerr;
	} else {
		return nil;
	}
}

- (void) extractEMCMetaFromResponse:(NSHTTPURLResponse *) resp toObject:(AtmosObject *) object {
	NSString *sysMetaStr = [[resp allHeaderFields] objectForKey:@"x-emc-meta"];
	if(sysMetaStr == nil || sysMetaStr.length == 0)
		sysMetaStr = [[resp allHeaderFields] objectForKey:@"X-Emc-Meta"];
	if(sysMetaStr == nil || sysMetaStr.length == 0)
		sysMetaStr = [[resp allHeaderFields] objectForKey:@"X-EMC-META"];
	
	if(sysMetaStr && sysMetaStr.length > 0) {
		NSArray *arr = [sysMetaStr componentsSeparatedByString:@", "];
		for(int i=0;i < arr.count;i++) {
			NSString *str = [arr objectAtIndex:i];
			NSArray *comps = [str componentsSeparatedByString:@"="];
			if([AtmosObject isSystemMetadata:[comps objectAtIndex:0]])
				[object.systemMeta setObject:[comps objectAtIndex:1] forKey:[comps objectAtIndex:0]];
			else {
				[object.userRegularMeta	setObject:[comps objectAtIndex:1] forKey:[comps objectAtIndex:0]];
			}
			
		}
		
	}
	
	NSString *listableMetaStr = [[resp allHeaderFields] objectForKey:@"x-emc-listable-meta"];
	if(listableMetaStr == nil || listableMetaStr.length == 0)
		listableMetaStr = [[resp allHeaderFields] objectForKey:@"X-Emc-Listable-Meta"];
	if(listableMetaStr == nil || listableMetaStr.length == 0)
		listableMetaStr = [[resp allHeaderFields] objectForKey:@"X-EMC-LISTABLE-META"];
	
	if(listableMetaStr && listableMetaStr.length > 0) {
		NSArray *arr = [listableMetaStr componentsSeparatedByString:@", "];
		for(int i=0;i < arr.count;i++) {
			NSString *str = [arr objectAtIndex:i];
			NSArray *comps = [str componentsSeparatedByString:@"="];
			[object.userListableMeta setObject:[comps objectAtIndex:1] forKey:[comps objectAtIndex:0]];
		}
	}
	
	
}

- (NSMutableData *) webData {
	if(webData == nil) {
		webData = [[NSMutableData alloc] init];
	}
	return webData;
}

- (void) startAtmosOperation {}


#pragma mark Memory mgmt
- (void) dealloc {
    self.baseUrl = nil;
    self.webData = nil;
    self.listableMeta = nil;
    self.regularMeta = nil;
    self.requestTags = nil;
    self.responseHeaders = nil;
    self.atmosResource = nil;
    self.appData = nil;
    self.atmosStore = nil;
    self.operationLabel = nil;
    self.connection = nil;
    self.httpResponse = nil;
    self.atmosCredentials = nil;
    
	[super dealloc];
}



@end
