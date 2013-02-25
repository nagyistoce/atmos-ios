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


#import <Foundation/Foundation.h>
#import "AtmosObject.h"
#import "AtmosBaseOperation.h"
#import "UploadProgress.h"

#define UPLOAD_MODE_CREATE 0
#define UPLOAD_MODE_UPDATE 1

@interface ObjectUploadOperation : AtmosBaseOperation {
	
	AtmosObject *atmosObj;
	
	long long startByte;
	long long endByte;
	
	NSInteger bufferSize;
	NSInteger numBlocks;
	NSInteger currentBlock;
	unsigned long long totalTransferSize;
	unsigned long long totalBytesTransferred;
	
	NSFileHandle *fileHandle;
	
	NSInteger uploadMode; //0=Create, 1=Update 
    
	BOOL (^callback)(UploadProgress *progress);
	
	BOOL fullUpload;
}

@property (nonatomic,retain) AtmosObject *atmosObj;
@property (nonatomic,assign) long long startByte;
@property (nonatomic,assign) long long endByte;
@property (nonatomic,assign) NSInteger bufferSize;
@property (nonatomic,assign) NSInteger numBlocks;
@property (nonatomic,assign) NSInteger currentBlock;
@property (nonatomic,assign) unsigned long long totalTransferSize;
@property (nonatomic,assign) unsigned long long totalBytesTransferred;
@property (nonatomic,retain) NSFileHandle *fileHandle;
@property (nonatomic,assign) NSInteger uploadMode;
@property (copy,readwrite) BOOL (^callback)(UploadProgress *progress);


@end
