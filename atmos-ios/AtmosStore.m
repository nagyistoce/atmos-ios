//
//  AtmosLocalStore.m
//  AtmosReader
//
//  Created by Aashish Patil on 4/12/10.
//  Copyright 2010 EMC. All rights reserved.
//

#import "AtmosStore.h"

#import "GetListableTagsOperation.h"
#import "ListObjectsOperation.h"
#import "GetMetadataOperation.h"
#import "SetMetadataOperation.h"
#import "ObjectUploadOperation.h"
#import "DownloadObjectOperation.h"
#import "DeleteObjectOperation.h"
#import "ListDirectoryOperation.h"
#import "DeleteMetadataOperation.h"

@interface AtmosStore (Private)

///
/// Private Methods
///

- (void) scheduleOperation:(id)operation;

- (void) listObjectsInternal:(NSString *) tag 
                     loadMetadata:(BOOL) loadMeta 
                   systemMetadata:(NSArray *) sdata 
                     userMetadata:(NSArray *) udata 
                     withCallback:(void(^)(ListObjectsResult*)) callback 
                        withLabel:(NSString *) requestLabel;

- (void) getObjectMetadataInternal:(NSString *) atmosId path:(NSString *)objectPath loadSystemMeta:(BOOL) loadsmeta loadUserMeta:(BOOL) loadumeta metaTags:(NSArray *) meta withDelegate:(id<AtmosProgressListenerDelegate>) delegate withLabel:(NSString *) requestLabel;

- (void) uploadObject:(AtmosObject *) atmosObj 
            startByte:(long long) sbyte 
              endByte:(long long) ebyte 
                 mode:(NSInteger) uploadMode 
           bufferSize:(NSInteger) bufSize 
         withCallback:(BOOL(^)(UploadProgress *progress)) callback
            withLabel:(NSString *) requestLabel;

- (void) downloadObject:(AtmosObject *) atmosObj 
              startByte:(long long) sbyte 
                endByte:(long long) ebyte 
             fileOffset:(long long) fOffset 
           withCallback:(BOOL(^)(DownloadProgress *progress)) callback 
              withLabel:(NSString *) requestLabel;
@end

@implementation AtmosStore

@synthesize atmosCredentials, currentOperations, pendingOperations, maxConcurrentOperations;


- (id) init {
	self = [super init];
	if(self) {
		self.maxConcurrentOperations = 10;
	}
	return self;
}

#pragma mark OperationManagement
- (NSMutableSet *) currentOperations {
	if(currentOperations == nil) {
		NSMutableSet *curOper = [[NSMutableSet alloc] initWithCapacity:10];
		self.currentOperations = curOper;
		[curOper release];
	}
	
	return currentOperations;
}

- (void) operationFinishedInternal:(id<AtmosProgressListenerDelegate>) operation {
	NSLog(@"operationFinishedInternal called %@ %@",operation, self.currentOperations);
	[self.currentOperations removeObject:operation];
	if(self.pendingOperations.count > 0) {
		id oper = [self.pendingOperations objectAtIndex:0];
		[self.currentOperations addObject:oper];
		[oper startAtmosOperation];
		[self.pendingOperations removeObject:0];
	}
}

- (void) scheduleOperation:(id)operation {
	if(self.currentOperations.count < self.maxConcurrentOperations) {
		[self.currentOperations addObject:operation];
		[operation startAtmosOperation];
	} else {
		[self.pendingOperations addObject:operation];
		NSLog(@"just added a pending operation");
	}	
	
}

#pragma mark PublicInterface

#pragma mark CreateAndUpdateObject
- (void) createObject:(AtmosObject *) atmosObj          
         withCallback:(BOOL(^)(UploadProgress *progress))callback 
            withLabel:(NSString *)requestLabel
 {
     [self uploadObject:atmosObj startByte:0 endByte:-1 
                   mode:UPLOAD_MODE_CREATE bufferSize:ATMOS_DEFAULT_BUF_SIZE 
           withCallback:callback withLabel:requestLabel];	
}

- (void) updateObject:(AtmosObject *) atmosObj 
         withCallback:(BOOL(^)(UploadProgress *progress))callback 
            withLabel:(NSString *)requestLabel 
{
		
	[self uploadObject:atmosObj startByte:0 endByte:-1 mode:UPLOAD_MODE_UPDATE 
            bufferSize:ATMOS_DEFAULT_BUF_SIZE 
          withCallback:callback withLabel:requestLabel];
}

- (void) updateObjectRange:(AtmosObject *)atmosObj 
                     range:(AtmosRange *)objRange 
              withCallback:(BOOL(^)(UploadProgress *progress))callback 
                 withLabel:(NSString *)requestLabel 
{
	NSInteger er = objRange.location + objRange.length - 1;
	[self uploadObject:atmosObj startByte:objRange.location endByte:er 
                  mode:UPLOAD_MODE_UPDATE bufferSize:ATMOS_DEFAULT_BUF_SIZE 
          withCallback:callback withLabel:requestLabel];
	
}

- (void) uploadObject:(AtmosObject *) atmosObj 
            startByte:(long long) sbyte 
              endByte:(long long) ebyte 
                 mode:(NSInteger)uploadMode 
           bufferSize:(NSInteger) bufSize 
         withCallback:(BOOL(^)(UploadProgress *progress))callback
            withLabel:(NSString *)requestLabel 
{
	
	ObjectUploadOperation *oper = [[ObjectUploadOperation alloc] init];
	oper.atmosCredentials = self.atmosCredentials;
	oper.callback = callback;
	oper.atmosStore = (AtmosStore*)self;
	oper.operationLabel = requestLabel;
	oper.startByte = sbyte;
	oper.endByte = ebyte;
	oper.atmosObj = atmosObj;
	oper.uploadMode = uploadMode;
	oper.bufferSize = bufSize;
	[self scheduleOperation:oper];
	
	[oper release];
}

#pragma mark GetObject 
- (void) readObject:(AtmosObject *) atmosObj 
       withCallback:(BOOL(^)(DownloadProgress *progress))callback 
          withLabel:(NSString *)requestLabel
{
	[self downloadObject:atmosObj 
               startByte:0 
                 endByte:-1 
              fileOffset:0 
            withCallback:callback 
               withLabel:requestLabel];
}

- (void) readObjectRange:(AtmosObject *)atmosObj 
                   range:(AtmosRange *)objRange 
            withCallback:(BOOL(^)(DownloadProgress *progress))callback 
               withLabel:(NSString *)requestLabel
{
	long long end = objRange.location + objRange.length - 1;
	[self downloadObject:atmosObj 
               startByte:objRange.location 
                 endByte:end 
              fileOffset:-1 
            withCallback:callback 
               withLabel:requestLabel];
}

- (void) readObjectRange:(AtmosObject *)atmosObj 
                   range:(AtmosRange *)objRange 
              fileOffset:(long long) fOffset 
            withCallback:(BOOL(^)(DownloadProgress *progress))callback 
               withLabel:(NSString *)requestLabel
{
	long long end = objRange.location + objRange.length - 1;
	[self downloadObject:atmosObj 
               startByte:objRange.location 
                 endByte:end 
              fileOffset:fOffset 
            withCallback:callback 
               withLabel:requestLabel];
}

- (void) downloadObject:(AtmosObject *) atmosObj 
              startByte:(long long) sbyte 
                endByte:(long long) ebyte 
             fileOffset:(long long) fOffset 
           withCallback:(BOOL(^)(DownloadProgress* progress))callback
              withLabel:(NSString *)requestLabel {
	
	DownloadObjectOperation *oper = [[DownloadObjectOperation alloc] init];
	oper.atmosCredentials = self.atmosCredentials;
	oper.callback = callback;
	oper.atmosStore = self;
	oper.operationLabel = requestLabel;
	oper.startByte = sbyte;
	oper.endByte = ebyte;
	oper.fileOffset = fOffset;
	oper.atmosObj = atmosObj;
	
	[self scheduleOperation:oper];
	
	[oper release];
}

#pragma mark DeleteObject
- (void) deleteObject:(AtmosObject *) atmosObj 
         withCallback:(void(^)(AtmosResult *result))callback
            withLabel:(NSString *)requestLabel {
	DeleteObjectOperation *oper = [[DeleteObjectOperation	alloc] init];
	oper.atmosCredentials = self.atmosCredentials;
	oper.callback = callback;
	oper.atmosStore = self;
	oper.operationLabel = requestLabel;
	oper.atmosObj = atmosObj;
	
	[self scheduleOperation:oper];
	[oper release];
	
}


#pragma mark GetListableTags 
- (void) getListableTags:(NSString *)parentTag 
            withCallback:(void(^)(GetListableTagsResult *tags))callback 
            withLabel:(NSString *)requestLabel{
	GetListableTagsOperation *listableTagsOper = [[GetListableTagsOperation alloc] init];
	listableTagsOper.atmosCredentials = self.atmosCredentials;
	listableTagsOper.callback = callback;
	listableTagsOper.atmosStore = self;
	listableTagsOper.operationLabel = requestLabel;
	if(parentTag) {
		[listableTagsOper.requestTags addObject:parentTag];
	} else {
		[listableTagsOper.requestTags addObject:@""];
	}
	
	[self scheduleOperation:listableTagsOper];
			 
	[listableTagsOper release];
} 

#pragma mark GetDirectoryContents
- (void) getDirectoryContents:(AtmosObject *) directory withToken:(NSString *) emcToken withLimit:(NSInteger) limit withDelegate:(id<AtmosProgressListenerDelegate>) delegate withLabel:(NSString *)requestLabel {
	ListDirectoryOperation *oper = [[ListDirectoryOperation alloc] init];
	oper.atmosCredentials = self.atmosCredentials;
	oper.progressListener = delegate;
	oper.atmosStore = self;
	oper.operationLabel = requestLabel;
	oper.atmosObj = directory;
	oper.emcToken = emcToken;
	oper.emcLimit = limit;
	
	[self scheduleOperation:oper];
}


#pragma mark ListObjects
//gets all objects tagged with a specific tag. only object ids are returned
- (void) listObjects:(NSString *) tag 
        withCallback:(void(^)(ListObjectsResult *result))callback
           withLabel:(NSString *) requestLabel {
	
	if(tag && tag.length > 0) {
		[self listObjectsInternal:tag 
                          loadMetadata:NO 
                        systemMetadata:nil 
                          userMetadata:nil 
                          withCallback:callback 
                             withLabel:requestLabel];
	}
}

//gets all tagged objects and all metadata for each object
- (void) listObjectsWithAllMetadata:(NSString *) tag 
                            withCallback:(void(^)(ListObjectsResult *result))callback
                               withLabel:(NSString *) requestLabel {
	if(tag && tag.length > 0) {
		[self listObjectsInternal:tag 
                          loadMetadata:YES 
                        systemMetadata:nil 
                          userMetadata:nil 
                          withCallback:callback 
                             withLabel:requestLabel];
		
	}
	
}

//gets all tagged objects and the specified metadata for each object
- (void) listObjectsWithMetadata:(NSString *) tag 
                       systemMetadata:(NSArray *) sdata 
                         userMetadata:(NSArray *) udata 
                         withCallback:(void(^)(ListObjectsResult *result))callback
                            withLabel:(NSString *) requestLabel {
	if(tag && tag.length > 0) {
		[self listObjectsInternal:tag 
                          loadMetadata:NO 
                        systemMetadata:sdata 
                          userMetadata:udata 
                          withCallback:callback
                             withLabel:requestLabel];
	}
}


- (void) listObjectsInternal:(NSString *) tag 
                     loadMetadata:(BOOL) loadMeta 
                   systemMetadata:(NSArray *) sdata 
                     userMetadata:(NSArray *) udata 
                     withCallback:(void(^)(ListObjectsResult *result))callback
                        withLabel:(NSString *) requestLabel {
	
	ListObjectsOperation *getObjs = [[ListObjectsOperation alloc] init];
	getObjs.atmosCredentials = self.atmosCredentials;
	getObjs.callback = callback;
	getObjs.atmosStore = self;
	getObjs.operationLabel = requestLabel;
	[getObjs.requestTags addObject:tag];
	getObjs.loadMetadata =  loadMeta;
	getObjs.systemMetadata = sdata;
	getObjs.userMetadata = udata;
	
	[self scheduleOperation:getObjs];
	
	[getObjs release];
}




#pragma mark GetObjectMetadata
//gets all the metadata for the specified object id / object path
- (void) getAllMetadataForId:(NSString *)atmosId withDelegate:(id<AtmosProgressListenerDelegate>) delegate withLabel:(NSString *) requestLabel {
	if(atmosId && atmosId.length == ATMOS_ID_LENGTH) {
		[self getObjectMetadataInternal:atmosId path:nil loadSystemMeta:YES loadUserMeta:YES metaTags:nil withDelegate:delegate withLabel:requestLabel];
	}	
}

- (void) getAllMetadataForPath:(NSString *)objectPath withDelegate:(id<AtmosProgressListenerDelegate>) delegate withLabel:(NSString *) requestLabel {
	if(objectPath && objectPath.length > 0) {
		[self getObjectMetadataInternal:nil path:objectPath loadSystemMeta:YES loadUserMeta:YES metaTags:nil withDelegate:delegate withLabel:requestLabel];
	}
	
}


//gets the system metadata for the specified id / path. To retrieve only specific metadata, specify the metadata names as a NSString array
- (void) getAllSytemMetadataForId:(NSString *) atmosId withDelegate:(id<AtmosProgressListenerDelegate>) delegate withLabel:(NSString *) requestLabel {
	if(atmosId && (atmosId.length == ATMOS_ID_LENGTH)) {
		[self getObjectMetadataInternal:atmosId path:nil loadSystemMeta:YES loadUserMeta:NO metaTags:nil withDelegate:delegate withLabel:requestLabel];
	}
}

- (void) getAllSytemMetadataForPath:(NSString *) objectPath withDelegate:(id<AtmosProgressListenerDelegate>) delegate withLabel:(NSString *) requestLabel {
	if(objectPath && objectPath.length > 0) {
		[self getObjectMetadataInternal:nil path:objectPath loadSystemMeta:YES loadUserMeta:NO metaTags:nil withDelegate:delegate withLabel:requestLabel];
	}
}


- (void) getSystemMetadataForId:(NSString *) atmosId metadata:(NSArray *) mdata withDelegate:(id<AtmosProgressListenerDelegate>) delegate withLabel:(NSString *) requestLabel {
	if(atmosId && (atmosId.length == ATMOS_ID_LENGTH)) {
		[self getObjectMetadataInternal:atmosId path:nil loadSystemMeta:YES loadUserMeta:NO metaTags:mdata withDelegate:delegate withLabel:requestLabel];
	}
}

- (void) getSystemMetadataForPath:(NSString *) objectPath metadata:(NSArray *) mdata withDelegate:(id<AtmosProgressListenerDelegate>) delegate withLabel:(NSString *) requestLabel {
	if(objectPath && objectPath.length > 0) {
		[self getObjectMetadataInternal:nil path:objectPath loadSystemMeta:YES loadUserMeta:NO metaTags:mdata withDelegate:delegate withLabel:requestLabel];
	}
}

//gets the user metadata for the specified id / path. To retrieve only specific metadata, specify the metadata names as a NSString aray
- (void) getAllUserMetadataForId:(NSString *) atmosId withDelegate:(id<AtmosProgressListenerDelegate>) delegate withLabel:(NSString *) requestLabel {
	if(atmosId && (atmosId.length == ATMOS_ID_LENGTH)) {
		[self getObjectMetadataInternal:atmosId path:nil loadSystemMeta:NO loadUserMeta:YES metaTags:nil withDelegate:delegate withLabel:requestLabel];

	}
}
- (void) getAllUserMetadataForPath:(NSString *) objectPath withDelegate:(id<AtmosProgressListenerDelegate>) delegate withLabel:(NSString *) requestLabel {
	if(objectPath && (objectPath.length > 0)) {
		[self getObjectMetadataInternal:nil path:objectPath loadSystemMeta:NO loadUserMeta:YES metaTags:nil withDelegate:delegate withLabel:requestLabel];
	}
}


- (void) getUserMetadataForId:(NSString *) atmosId metadata:(NSArray *) mdata withDelegate:(id<AtmosProgressListenerDelegate>) delegate withLabel:(NSString *) requestLabel {
	if(atmosId && (atmosId.length == ATMOS_ID_LENGTH)) {
		[self getObjectMetadataInternal:atmosId path:nil loadSystemMeta:NO loadUserMeta:YES metaTags:mdata withDelegate:delegate withLabel:requestLabel];
	}
}

- (void) getUserMetadataForPath:(NSString *) objectPath metadata:(NSArray *) mdata withDelegate:(id<AtmosProgressListenerDelegate>) delegate withLabel:(NSString *) requestLabel {
	if(objectPath && objectPath.length > 0) {
		[self getObjectMetadataInternal:nil path:objectPath loadSystemMeta:NO loadUserMeta:YES metaTags:mdata withDelegate:delegate withLabel:requestLabel];
	}
}


- (void) getObjectMetadataInternal:(NSString *) atmosId path:(NSString *)objectPath loadSystemMeta:(BOOL) loadsmeta loadUserMeta:(BOOL) loadumeta metaTags:(NSArray *) meta withDelegate:(id<AtmosProgressListenerDelegate>) delegate withLabel:(NSString *) requestLabel {
	
	GetMetadataOperation *oper = [[GetMetadataOperation alloc] init];
	oper.atmosCredentials = self.atmosCredentials;
	oper.atmosStore = self;
	oper.atmosId = atmosId;
	oper.objectPath = objectPath;
	oper.loadSysMeta = loadsmeta;
	oper.loadUserMeta = loadumeta;
	oper.requestTags = [NSMutableArray arrayWithArray:meta];
	oper.progressListener = delegate;
	oper.operationLabel = requestLabel;
	
	[self scheduleOperation:oper];
	
	[oper release];
}

#pragma mark SetObjectMetadata
- (void) setObjectMetadata:(AtmosObject *) atmosObject withDelegate:(id<AtmosProgressListenerDelegate>) delegate withLabel:(NSString *) requestLabel {
	
	SetMetadataOperation *oper = [[SetMetadataOperation alloc] init];
	oper.atmosStore = self;
	oper.atmosCredentials = self.atmosCredentials;
	oper.curObj = atmosObject;
	oper.progressListener = delegate;
	oper.operationLabel = requestLabel;
	
	[self scheduleOperation:oper];
	[oper release];
}

#pragma mark DeleteMetadata
- (void) deleteObjectMetadata:(AtmosObject *) atmosObject withDelegate:(id<AtmosProgressListenerDelegate>) delegate withLabel:(NSString *) requestLabel {
	DeleteMetadataOperation *oper = [[DeleteMetadataOperation alloc] init];
	oper.atmosStore = self;
	oper.atmosCredentials = self.atmosCredentials;
	oper.atmosObj = atmosObject;
	oper.progressListener = delegate;
	oper.operationLabel = requestLabel;
	
	[self scheduleOperation:oper];
	[oper release];
}

#pragma mark MemoryManagement

- (void) dealloc {
	[currentOperations release];
	[pendingOperations release];
	[super dealloc];
}


@end
