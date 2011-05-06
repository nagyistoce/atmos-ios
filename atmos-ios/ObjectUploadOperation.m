//
//  ObjectUploadOperation.m
//  AtmosCocoaBinding
//
//  Created by Aashish Patil on 9/14/10.
//  Copyright 2010 EMC. All rights reserved.
//

#import "ObjectUploadOperation.h"

@interface ObjectUploadOperation (Private)

- (void) sendNewRequest;

@end

@implementation ObjectUploadOperation

@synthesize startByte,endByte,bufferSize,numBlocks,currentBlock,uploadMode,
    atmosObj,fileHandle, totalTransferSize, totalBytesTransferred, callback;


- (void) startAtmosOperation {
    
    if(!self.atmosObj) {
        [NSException raise:@"Invalid Parameter" format:@"The property atmosObj "
         "must be set on ObjectUploadOperation"];
    }
    

	if(self.atmosObj.dataMode == kDataModeFile) {
		NSFileManager *fmgr = [NSFileManager defaultManager];
		
		if(self.atmosObj.filepath && [fmgr fileExistsAtPath:self.atmosObj.filepath]) {
			
			//NSDictionary *fattrs = [fmgr fileAttributesAtPath:self.atmosObj.filepath traverseLink:YES];
            NSDictionary *fattrs = [fmgr attributesOfItemAtPath:self.atmosObj.filepath error:NULL];
			NSInteger fsize = [fattrs fileSize];
			NSLog(@"fsize %d",fsize);
			
			fullUpload = ((self.startByte == 0) && (self.endByte == -1));
			
			if(self.endByte == -1)
				self.endByte = fsize-1;
			
			totalTransferSize = self.endByte - self.startByte + 1;
			self.numBlocks = ceil((double)(totalTransferSize) / (double) self.bufferSize); 
			
			if((self.startByte < 0) || (self.endByte > (fsize-1)) || (self.startByte > self.endByte)) {
				AtmosError *err = [[AtmosError alloc] initWithCode:-1 message:@"Invalid byte range specified for file"];
                UploadProgress *event = [[UploadProgress alloc] init];
                event.bytesUploaded = 0;
                event.totalBytes = 0;
                event.label = self.operationLabel;
                event.isComplete = YES;
                event.wasSuccessful = NO;
                event.error = err;
                self->callback(event);
                
				[err release];
                [event release];
				return;
			}
			
			self.fileHandle = [NSFileHandle fileHandleForReadingAtPath:self.atmosObj.filepath];
			[self.fileHandle seekToFileOffset:self.startByte];
			
			
		} else {
			//creating a contentless object with only metadata
			totalTransferSize = 0;
			self.numBlocks = 1;
		}
		
		
		
		NSLog(@"start - end %lld %lld",startByte,endByte);
		
		self.regularMeta = self.atmosObj.userRegularMeta;
		self.listableMeta = self.atmosObj.userListableMeta;
		
		self.currentBlock = 0;
		
		[self sendNewRequest];
    
    } else if(self.atmosObj.dataMode == kDataModeBytes) {
        if(!self.atmosObj.data) {
            //creating a contentless object with only metadata
            self.atmosObj.data = [[NSData alloc] initWithBytes:"" length:0];
        }
        self.totalTransferSize = self.atmosObj.data.length;
        self.numBlocks = 1;
        fullUpload = ((self.startByte == 0) && (self.endByte == -1));
        
		NSLog(@"start - end %lld %lld",startByte,endByte);
		
		self.regularMeta = self.atmosObj.userRegularMeta;
		self.listableMeta = self.atmosObj.userListableMeta;
		
		self.currentBlock = 0;
		
		[self sendNewRequest];
        
	} else {
		NSLog(@"not atmos object or filepath %@",self.atmosObj);
	}

	
	
}

- (void) sendNewRequest {
	
	//calculate start and end range
	//calculate HTTP method - POST or PUT
	//determine atmos resource
	
	NSString *hmethod;
	if((self.currentBlock == 0) && (self.uploadMode == UPLOAD_MODE_CREATE)) {
		if(self.atmosObj.objectPath) {
			self.atmosResource = [NSString stringWithFormat:@"/rest/namespace%@",self.atmosObj.objectPath];
		} else {
			self.atmosResource = @"/rest/objects";
		}
		hmethod = @"POST";
	} else {
		if(self.atmosObj.objectPath) {
			self.atmosResource = [NSString stringWithFormat:@"/rest/namespace%@",self.atmosObj.objectPath];
		} else {
			self.atmosResource = [NSString stringWithFormat:@"/rest/objects/%@",self.atmosObj.atmosId];
		}
		hmethod = @"PUT";

	}
	
	NSMutableURLRequest *req = [self setupBaseRequestForResource:self.atmosResource];
	
	if(totalTransferSize > 0) {
		NSLog(@"got new atmos resource %@",self.atmosResource);
		long long srange = self.startByte + (self.currentBlock * self.bufferSize);
		long long erange = (self.currentBlock == (self.numBlocks - 1)) ? self.endByte : (srange + self.bufferSize - 1);
		long long nlen = erange - srange + 1;
		
		NSLog(@"Starting new request %@ %@ %lld %lld",hmethod,req,srange,erange);
		if(self.currentBlock > 0 || ((self.currentBlock == 0) && (!fullUpload))) {
			//only add this for later blocks 
			NSString *strRangeHdr = [NSString stringWithFormat:@"Bytes=%lld-%lld",srange,erange];
			[req setValue:strRangeHdr forHTTPHeaderField:@"Range"];
		}
		
		NSData *sendData;
        if( self.atmosObj.dataMode == kDataModeFile ) {
            sendData = [self.fileHandle readDataOfLength:nlen];
        } else {
            sendData = self.atmosObj.data;
        }
		[req setHTTPBody:sendData];
		NSString *clen = [NSString stringWithFormat:@"%d",nlen];
		[req setValue:clen forHTTPHeaderField:@"Content-Length"];
	}
	
	[self setMetadataOnRequest:req];
	[req setHTTPMethod:hmethod];
	
	[self signRequest:req];
	
	NSLog(@"req headers %@",[req allHTTPHeaderFields]);
	
	
	[NSURLConnection connectionWithRequest:req delegate:self];
}

#pragma mark NSURLConnection delegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{	
	NSLog(@"didReceiveResponse %@",response);
	self.httpResponse = (NSHTTPURLResponse *) response;
	[self.webData setLength:0];
	
}

- (void)connection:(NSURLConnection *)con didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
	self.totalBytesTransferred += totalBytesWritten;

    UploadProgress *event = [[UploadProgress alloc] init];
    event.atmosObject = self.atmosObj;
    event.bytesUploaded = self.totalBytesTransferred;
    event.totalBytes = self.totalTransferSize;
    event.isComplete = NO;
    event.wasSuccessful = YES;
    event.requestLabel = self.operationLabel;
    event.error = nil;
    BOOL shouldContinue = self->callback(event);
	if(!shouldContinue) {
		[con cancel];
		[self.fileHandle closeFile];
		[self.atmosStore operationFinishedInternal:self];
	}
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

    UploadProgress *event = [[UploadProgress alloc] init];
    event.bytesUploaded = 0;
    event.totalBytes = 0;
    event.label = self.operationLabel;
    event.isComplete = YES;
    event.wasSuccessful = NO;
    event.error = err;
    self->callback(event);
    
    [err release];
    [event release];

	//[connection release];
	[self.fileHandle closeFile];
	[self.atmosStore operationFinishedInternal:self];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)con
{
	NSLog(@"connectionDidFinishLoading %@",con);
	if([self.httpResponse statusCode] >= 400) {
		//some atmos error
		NSString *errStr = [[NSString alloc] initWithData:self.webData encoding:NSASCIIStringEncoding];
		AtmosError *aerr = [self extractAtmosError:errStr];

        UploadProgress *event = [[UploadProgress alloc] init];
        event.bytesUploaded = 0;
        event.totalBytes = 0;
        event.label = self.operationLabel;
        event.isComplete = YES;
        event.wasSuccessful = NO;
        event.error = aerr;
        self->callback(event);
        
        [aerr release];
        [event release];
		[self.atmosStore operationFinishedInternal:self];
	} else {
		//success
		
		if(self.currentBlock == 0 && (self.uploadMode == UPLOAD_MODE_CREATE)) {
			NSString *oid = [self extractObjectId:self.httpResponse];
			NSLog(@"Got new atmos id %@",oid);
			if(oid) 
				self.atmosObj.atmosId = oid;
		}
		
		self.currentBlock++;
		if(self.currentBlock < self.numBlocks) {
            [self sendNewRequest];                
		} else {
            self.totalBytesTransferred = self.totalTransferSize;
            
            UploadProgress *event = [[UploadProgress alloc] init];
            event.atmosObject = self.atmosObj;
            event.bytesUploaded = self.totalBytesTransferred;
            event.totalBytes = self.totalTransferSize;
            event.label = self.operationLabel;
            event.isComplete = YES;
            event.wasSuccessful = YES;
            event.error = nil;
            self->callback(event);
            
            [event release];
			[self.atmosStore operationFinishedInternal:self];
			[self.fileHandle closeFile];
		}
	}
	//[connection release];
	
}




@end