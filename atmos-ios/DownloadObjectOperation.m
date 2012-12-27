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


#import "DownloadObjectOperation.h"


@implementation DownloadObjectOperation

@synthesize atmosObj, fileHandle, startByte, endByte, fileOffset, callback;

- (void) dealloc {
    self.atmosObj = nil;
    self.fileHandle = nil;
    self.callback = nil;
    if(webData) {
        [webData release];
        webData = nil;
    }
    
    [super dealloc];
}

- (void) startAtmosOperation {
	
	bytesDownloaded = 0;
	
	if(self.atmosObj.atmosId && self.atmosObj.atmosId.length == ATMOS_ID_LENGTH) {
		self.atmosResource = [NSString stringWithFormat:@"/rest/objects/%@",self.atmosObj.atmosId];
	} else if(self.atmosObj.objectPath) {
		self.atmosResource = [NSString stringWithFormat:@"/rest/namespace%@",self.atmosObj.objectPath];
	} else {
		return; //no resource - nothing to download
	}
	
	
	if(self.atmosObj.dataMode == kDataModeFile) {
        //
        // Download to a File
        //
        if(self.atmosObj.filepath) {
            NSFileManager *fmgr = [NSFileManager defaultManager];
            if(![fmgr fileExistsAtPath:self.atmosObj.filepath]) {
                NSString *str = [[NSString alloc] initWithString:@""];
                //[str writeToFile:self.atmosObj.filepath atomically:NO];
                [str writeToFile:self.atmosObj.filepath atomically:NO encoding:NSUTF8StringEncoding error:NULL];
                [str release];
            }
            self.fileHandle = [NSFileHandle fileHandleForWritingAtPath:self.atmosObj.filepath];
            
            if(self.fileOffset == -1) {
                [self.fileHandle seekToEndOfFile];
            } else {
                [self.fileHandle seekToFileOffset:self.fileOffset];
            }

        } else {
            AtmosError *err = [[AtmosError alloc] initWithCode:-1 message:@"Target file for download not specified or invalid"];

            DownloadProgress *progress = [[DownloadProgress alloc] init];
            progress.atmosObject = atmosObj;
            progress.bytesDownloaded = bytesDownloaded;
            progress.error = err;
            progress.isComplete = YES;
            progress.wasSuccessful = NO;
            progress.requestLabel = self.operationLabel;
            progress.totalBytes = totalContentSize;
            self.callback(progress);
            [err release];
            [progress release];
            return;
        }
    } else if(self.atmosObj.dataMode == kDataModeBytes) {
        //
        // Download to byte array
        //
        if( startByte == 0 && endByte == -1 ) {
            // Unknown length
            webData = [[NSMutableData alloc] init];
        } else {
            webData = [[NSMutableData alloc] initWithCapacity:endByte-startByte];
        }
    }
	
	NSMutableURLRequest *req = [super setupBaseRequestForResource:self.atmosResource];
	[req setHTTPMethod:@"GET"];
	if(!(startByte == 0 && endByte == -1)) {
		if(endByte < startByte) {
			AtmosError *err = [[AtmosError alloc] initWithCode:-1 message:@"Invalid byte range specified"];

            DownloadProgress *progress = [[DownloadProgress alloc] init];
            progress.atmosObject = atmosObj;
            progress.bytesDownloaded = 0;
            progress.totalBytes = 0;
            progress.error = err;
            progress.isComplete = YES;
            progress.wasSuccessful = NO;
            progress.requestLabel = self.operationLabel;
            self.callback(progress);
			[err release];
            [progress release];
			return;
		} else {
			NSString *rangeStr = [NSString stringWithFormat:@"Bytes=%lld-%lld",startByte,endByte];
			[req setValue:rangeStr forHTTPHeaderField:@"Range"]; 
		}
	}
	
		
	[super signRequest:req];
	
	[NSURLConnection connectionWithRequest:req delegate:self];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	NSLog(@"didReceiveResponse %@",[((NSHTTPURLResponse *)response) allHeaderFields]);
	self.httpResponse = (NSHTTPURLResponse *) response;
	
	NSString *strTotalSize = [[self.httpResponse allHeaderFields] valueForKey:@"Content-Length"];
	if(strTotalSize && strTotalSize.length > 0) {
		totalContentSize = [strTotalSize longLongValue];
        if(atmosObj.dataMode == kDataModeBytes && 
           startByte == 0 && endByte == -1) {
            
            // We didn't know the length before, re-init now with a valid
            // capacity.
            if(webData) {
                [webData release];
            }
            webData = [[NSMutableData alloc] initWithCapacity:totalContentSize];
        }
    }
    
    NSString *contentType = [self.httpResponse.allHeaderFields valueForKey:@"Content-Type"];
    if(contentType) {
        atmosObj.contentType = contentType;
    }
}

- (void)connection:(NSURLConnection *)con didReceiveData:(NSData *)data
{
	if([self.httpResponse statusCode] >= 400) {
		[webData appendData:data];
	} else {
		bytesDownloaded += data.length;
        if(atmosObj.dataMode == kDataModeFile) {
            [self.fileHandle writeData:data];
        } else {
            // kDataModeBytes
            [webData appendData:data];
        }
        
        DownloadProgress *progress = [[DownloadProgress alloc] init];
        progress.atmosObject = atmosObj;
        progress.bytesDownloaded = bytesDownloaded;
        progress.totalBytes = totalContentSize;
        progress.wasSuccessful = YES;
        progress.isComplete = NO;
        progress.requestLabel = self.operationLabel;
		BOOL shouldContinue = self.callback(progress);
        [progress release];
        
		if(!shouldContinue) {
            //
            // Cancel the Download
            //
			[con cancel];
            if(atmosObj.dataMode == kDataModeFile) {
                [self.fileHandle closeFile];
            }
            AtmosError *cancelErr = [[AtmosError alloc] initWithCode:-2 message:@"Operation Canceled"];
            DownloadProgress *cancelProgress = [[DownloadProgress alloc] init];
            cancelProgress.atmosObject = atmosObj;
            cancelProgress.bytesDownloaded = bytesDownloaded;
            cancelProgress.totalBytes = totalContentSize;
            cancelProgress.wasSuccessful = NO;
            cancelProgress.isComplete = YES;
            cancelProgress.error = cancelErr;
            self.callback(cancelProgress);
            [cancelProgress release];
            [cancelErr release];
            
			[self.atmosStore operationFinishedInternal:self];
		}
	}
	NSLog(@"didReceiveData %d",data.length);
	
}

- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error
{
	NSLog(@"Connection failed! Error - %@ %@",
		  [error localizedDescription],
		  [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
	
	AtmosError *err = [[AtmosError alloc] initWithCode:-1 message:[error localizedDescription]];

    DownloadProgress *progress = [[DownloadProgress alloc] init];
    progress.atmosObject = atmosObj;
    progress.bytesDownloaded = 0;
    progress.totalBytes = 0;
    progress.error = err;
    progress.isComplete = YES;
    progress.wasSuccessful = NO;
    progress.requestLabel = self.operationLabel;
    self.callback(progress);
    [err release];
    [progress release];

	[self.fileHandle closeFile];
	[self.atmosStore operationFinishedInternal:self];
	
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	NSLog(@"Finished loading ");
	if([self.httpResponse statusCode] >= 400) {
		//some atmos error
		//some atmos error
		NSString *errStr = [[NSString alloc] initWithData:webData encoding:NSASCIIStringEncoding];
		AtmosError *aerr = [self extractAtmosError:errStr];
        DownloadProgress *progress = [[DownloadProgress alloc] init];
        progress.atmosObject = atmosObj;
        progress.bytesDownloaded = 0;
        progress.totalBytes = 0;
        progress.error = aerr;
        progress.isComplete = YES;
        progress.wasSuccessful = NO;
        progress.requestLabel = self.operationLabel;
        self.callback(progress);
        [progress release];
        [errStr release];
	} else {
		
		[self extractEMCMetaFromResponse:self.httpResponse toObject:self.atmosObj];
		
        if( atmosObj.dataMode == kDataModeFile ) {
            [self.fileHandle closeFile];
        } else {
            // Move data into destination
            atmosObj.data = [NSData dataWithData:webData];
        }
        DownloadProgress *progress = [[DownloadProgress alloc] init];
        progress.atmosObject = atmosObj;
        progress.bytesDownloaded = bytesDownloaded;
        progress.totalBytes = totalContentSize;
        progress.wasSuccessful = YES;
        progress.isComplete = YES;
        progress.requestLabel = self.operationLabel;
		self.callback(progress);
        [progress release];

	}
    [self.atmosStore operationFinishedInternal:self];

	
}

@end
