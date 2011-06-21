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
#import "GetServerOffsetOperation.h"


@implementation GetServerOffsetOperation

@synthesize callback;

- (void) dealloc
{
    self.callback = nil;
    [super dealloc];
}

- (void) startAtmosOperation {
	
	NSString *strResource = [NSString stringWithFormat:@"/rest"];
	self.atmosResource = strResource;
	
	NSMutableURLRequest *req = [super setupBaseRequestForResource:strResource];
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
    GetServerOffsetResult *result = [[GetServerOffsetResult alloc]init];
	result.wasSuccessful = NO;
    result.error = err;
    
    self->callback(result);
    [result release];
    [err release];
    
	[self.atmosStore operationFinishedInternal:self];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)con
{
	NSLog(@"connectionDidFinishLoading %@",con);
	if([self.httpResponse statusCode] >= 400) {
		NSString *errStr = [[NSString alloc] initWithData:self.webData encoding:NSASCIIStringEncoding];
		AtmosError *aerr = [self extractAtmosError:errStr];
        GetServerOffsetResult *result = [[GetServerOffsetResult alloc]init];
        result.wasSuccessful = NO;
        result.error = aerr;
        
        self->callback(result);
        
        [result release];
        [errStr release];
	} else {
		NSLog(@"response header fields %@",[self.httpResponse allHeaderFields]);
        NSString *serverDate = [self.httpResponse.allHeaderFields objectForKey:@"Date"];
        NSLog(@"Server date: %@", serverDate);
        
        NSTimeZone *tz = [NSTimeZone timeZoneWithName:@"GMT"];
        NSLocale *enUS = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
        NSDateFormatter *fmter = [[NSDateFormatter alloc] init];
        [fmter setDateFormat:@"EEE, d MMM yyyy HH:mm:ss z"];
        [fmter setLocale:enUS];
        fmter.timeZone = tz;
        NSDate *now = [[NSDate alloc] init];
        NSDate *server = [fmter dateFromString:serverDate];
        
        NSTimeInterval difference = [server timeIntervalSinceDate:now];
        
        if(difference > 0.0) {
            NSLog(@"Server is ahead by %lf seconds", difference);
        } else {
            NSLog(@"Server is behind by %lf seconds", difference);
        }
        
        GetServerOffsetResult *result = [[GetServerOffsetResult alloc] init];
        result.wasSuccessful = YES;
        result.offset = difference;

        self->callback(result);
        
        [result release];
        [fmter release];
        [enUS release];
        [now release];
	}
	[self.atmosStore operationFinishedInternal:self];
	
}

@end
