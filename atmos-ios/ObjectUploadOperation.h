//
//  ObjectUploadOperation.h
//  AtmosCocoaBinding
//
//  Created by Aashish Patil on 9/14/10.
//  Copyright 2010 EMC. All rights reserved.
//

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
@property (assign,readwrite) BOOL (^callback)(UploadProgress *progress);


@end
