//
//  DownloadObjectOperation.h
//  AtmosCocoaBinding
//
//  Created by Aashish Patil on 6/11/10.
//  Copyright 2010 EMC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AtmosBaseOperation.h"
#import "AtmosObject.h"

@interface DownloadObjectOperation : AtmosBaseOperation {
	
	AtmosObject *atmosObj;
	long long bytesDownloaded;
	long long totalContentSize;
	long long startByte;
	long long endByte;
	long long fileOffset;
	NSFileHandle *fileHandle;
    BOOL (^callback)(DownloadProgress*);
}

@property (nonatomic,retain) AtmosObject *atmosObj;
@property (nonatomic,retain) NSFileHandle *fileHandle;
@property (nonatomic,assign) long long startByte;
@property (nonatomic,assign) long long endByte;
@property (nonatomic,assign) long long fileOffset;
@property (nonatomic,copy) BOOL (^callback)(DownloadProgress*);

@end
