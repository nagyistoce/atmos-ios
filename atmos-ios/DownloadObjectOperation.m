//
//  DownloadObjectOperation.m
//  AtmosCocoaBinding
//
//  Created by Aashish Patil on 6/11/10.
//  Copyright 2010 EMC. All rights reserved.
//

#import "DownloadObjectOperation.h"


@implementation DownloadObjectOperation

@synthesize atmosObj, fileHandle, startByte, endByte, fileOffset, callback;

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
			NSString *rangeStr = [NSString stringWithFormat:@"Bytes=%d-%d",startByte,endByte];
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
            webData = [[NSMutableData alloc] initWithCapacity:totalContentSize];
        }
    }
}

- (void)connection:(NSURLConnection *)con didReceiveData:(NSData *)data
{
	if([self.httpResponse statusCode] >= 400) {
		[self.webData appendData:data];
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

	[err release];
	[self.fileHandle closeFile];
	[self.atmosStore operationFinishedInternal:self];
	
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	NSLog(@"Finished loading ");
	if([self.httpResponse statusCode] >= 400) {
		//some atmos error
		//some atmos error
		NSString *errStr = [[NSString alloc] initWithData:self.webData encoding:NSASCIIStringEncoding];
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

		[self.atmosStore operationFinishedInternal:self];
	}

	
}

@end
