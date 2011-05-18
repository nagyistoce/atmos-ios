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
#import "GetServerOffsetOperation.h"
#import "RenameObjectOperation.h"

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

- (void) getObjectMetadataInternal:(NSString *) atmosId 
                              path:(NSString *)objectPath 
                              mode:(MetadataLoadType)mode
                          metaTags:(NSArray *) meta 
                      withCallback:(void(^)(AtmosObjectResult*)) callback 
                         withLabel:(NSString *) requestLabel;

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

@synthesize atmosCredentials, currentOperations, pendingOperations, maxConcurrentOperations, timeOffset;


- (id) init {
	self = [super init];
	if(self) {
		self.maxConcurrentOperations = 10;
        self.timeOffset = 0.0;
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

- (void) operationFinishedInternal:(AtmosBaseOperation *)operation {
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
- (void) listDirectory:(AtmosObject *) directory 
                    withToken:(NSString *) emcToken 
                    withLimit:(NSInteger) limit 
                 withCallback:(void(^)(ListDirectoryResult *result))callback
                    withLabel:(NSString *)requestLabel {
	ListDirectoryOperation *oper = [[ListDirectoryOperation alloc] init];
	oper.atmosCredentials = self.atmosCredentials;
	oper.callback = callback;
	oper.atmosStore = self;
	oper.operationLabel = requestLabel;
	oper.atmosObj = directory;
	oper.emcToken = emcToken;
	oper.emcLimit = limit;
	
	[self scheduleOperation:oper];
}

- (void) listDirectoryWithAllMetadata:(AtmosObject *) directory 
                            withToken:(NSString *) emcToken 
                            withLimit:(NSInteger) limit 
                         withCallback:(void(^)(ListDirectoryResult *result))callback
                            withLabel:(NSString *)requestLabel 
{
    [self listDirectoryWithMetadata:directory systemMetadata:nil userMetadata:nil withToken:emcToken withLimit:limit withCallback:callback withLabel:requestLabel];
}

- (void) listDirectoryWithMetadata:(AtmosObject *) directory 
                    systemMetadata:(NSArray *) sdata 
                      userMetadata:(NSArray *) udata 
                         withToken:(NSString *) emcToken 
                         withLimit:(NSInteger) limit
                      withCallback:(void(^)(ListDirectoryResult *result))callback
                         withLabel:(NSString *)requestLabel
{
    ListDirectoryOperation *oper = [[ListDirectoryOperation alloc] init];
	oper.atmosCredentials = self.atmosCredentials;
	oper.callback = callback;
	oper.atmosStore = self;
	oper.operationLabel = requestLabel;
	oper.atmosObj = directory;
	oper.emcToken = emcToken;
	oper.emcLimit = limit;
    oper.includeMetadata = YES;
    oper.includeUserTags = udata;
    oper.includeSystemTags = sdata;
	
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
- (void) getAllMetadataForId:(NSString *)atmosId 
                withCallback:(void(^)(AtmosObjectResult *result))callback
                   withLabel:(NSString *) requestLabel {
	if(atmosId && atmosId.length == ATMOS_ID_LENGTH) {
		[self getObjectMetadataInternal:atmosId path:nil mode:kMetaLoadAll metaTags:nil withCallback:callback withLabel:requestLabel];
	}	
}

- (void) getAllMetadataForPath:(NSString *)objectPath 
                  withCallback:(void(^)(AtmosObjectResult *result))callback
                     withLabel:(NSString *) requestLabel {
	if(objectPath && objectPath.length > 0) {
		[self getObjectMetadataInternal:nil path:objectPath mode:kMetaLoadAll metaTags:nil withCallback:callback withLabel:requestLabel];
	}
	
}


//gets the system metadata for the specified id / path. To retrieve only specific metadata, specify the metadata names as a NSString array
- (void) getAllSytemMetadataForId:(NSString *) atmosId 
                     withCallback:(void(^)(AtmosObjectResult *result))callback
                        withLabel:(NSString *) requestLabel {
	if(atmosId && (atmosId.length == ATMOS_ID_LENGTH)) {
		[self getObjectMetadataInternal:atmosId path:nil mode:kMetaLoadSystem metaTags:nil withCallback:callback withLabel:requestLabel];
	}
}

- (void) getAllSytemMetadataForPath:(NSString *) objectPath 
                       withCallback:(void(^)(AtmosObjectResult *result))callback
                          withLabel:(NSString *) requestLabel {
	if(objectPath && objectPath.length > 0) {
		[self getObjectMetadataInternal:nil path:objectPath mode:kMetaLoadSystem metaTags:nil withCallback:callback withLabel:requestLabel];
	}
}


- (void) getSystemMetadataForId:(NSString *) atmosId 
                       metadata:(NSArray *) mdata 
                   withCallback:(void(^)(AtmosObjectResult *result))callback
                      withLabel:(NSString *) requestLabel {
	if(atmosId && (atmosId.length == ATMOS_ID_LENGTH)) {
		[self getObjectMetadataInternal:atmosId path:nil mode:kMetaLoadSystem metaTags:mdata withCallback:callback withLabel:requestLabel];
	}
}

- (void) getSystemMetadataForPath:(NSString *) objectPath 
                         metadata:(NSArray *) mdata 
                     withCallback:(void(^)(AtmosObjectResult *result))callback
                        withLabel:(NSString *) requestLabel {
	if(objectPath && objectPath.length > 0) {
		[self getObjectMetadataInternal:nil path:objectPath mode:kMetaLoadSystem metaTags:mdata withCallback:callback withLabel:requestLabel];
	}
}

//gets the user metadata for the specified id / path. To retrieve only specific metadata, specify the metadata names as a NSString aray
- (void) getAllUserMetadataForId:(NSString *) atmosId 
                    withCallback:(void(^)(AtmosObjectResult *result))callback
                       withLabel:(NSString *) requestLabel {
	if(atmosId && (atmosId.length == ATMOS_ID_LENGTH)) {
		[self getObjectMetadataInternal:atmosId path:nil mode:kMetaLoadUser metaTags:nil withCallback:callback withLabel:requestLabel];

	}
}
- (void) getAllUserMetadataForPath:(NSString *) objectPath 
                      withCallback:(void(^)(AtmosObjectResult *result))callback
                         withLabel:(NSString *) requestLabel {
	if(objectPath && (objectPath.length > 0)) {
		[self getObjectMetadataInternal:nil path:objectPath mode:kMetaLoadUser metaTags:nil withCallback:callback withLabel:requestLabel];
	}
}


- (void) getUserMetadataForId:(NSString *) atmosId 
                     metadata:(NSArray *) mdata 
                 withCallback:(void(^)(AtmosObjectResult *result))callback
                    withLabel:(NSString *) requestLabel {
	if(atmosId && (atmosId.length == ATMOS_ID_LENGTH)) {
		[self getObjectMetadataInternal:atmosId path:nil mode:kMetaLoadUser metaTags:mdata withCallback:callback withLabel:requestLabel];
	}
}

- (void) getUserMetadataForPath:(NSString *) objectPath 
                       metadata:(NSArray *) mdata 
                   withCallback:(void(^)(AtmosObjectResult *result))callback
                      withLabel:(NSString *) requestLabel {
	if(objectPath && objectPath.length > 0) {
		[self getObjectMetadataInternal:nil path:objectPath mode:kMetaLoadUser metaTags:mdata withCallback:callback withLabel:requestLabel];
	}
}


- (void) getObjectMetadataInternal:(NSString *) atmosId 
                              path:(NSString *)objectPath 
                              mode:(MetadataLoadType)mode
                          metaTags:(NSArray*)meta
                      withCallback:(void(^)(AtmosObjectResult *result))callback
                         withLabel:(NSString *) requestLabel {
	
	GetMetadataOperation *oper = [[GetMetadataOperation alloc] init];
	oper.atmosCredentials = self.atmosCredentials;
	oper.atmosStore = self;
	oper.atmosId = atmosId;
	oper.objectPath = objectPath;
	oper.metaLoadType = mode;
	oper.requestTags = [NSMutableArray arrayWithArray:meta];
	oper.callback = callback;
	oper.operationLabel = requestLabel;
	
	[self scheduleOperation:oper];
	
	[oper release];
}

#pragma mark SetObjectMetadata
- (void) setObjectMetadata:(AtmosObject *) atmosObject 
              withCallback:(void(^)(AtmosResult *result))callback
                 withLabel:(NSString *) requestLabel {
	
	SetMetadataOperation *oper = [[SetMetadataOperation alloc] init];
	oper.atmosStore = self;
	oper.atmosCredentials = self.atmosCredentials;
	oper.curObj = atmosObject;
	oper.callback = callback;
	oper.operationLabel = requestLabel;
	
	[self scheduleOperation:oper];
	[oper release];
}

#pragma mark DeleteMetadata
- (void) deleteObjectMetadata:(AtmosObject *) atmosObject 
                 withCallback:(void(^)(AtmosResult *result))callback
                    withLabel:(NSString *) requestLabel {
	DeleteMetadataOperation *oper = [[DeleteMetadataOperation alloc] init];
	oper.atmosStore = self;
	oper.atmosCredentials = self.atmosCredentials;
	oper.atmosObj = atmosObject;
	oper.callback = callback;
	oper.operationLabel = requestLabel;
	
	[self scheduleOperation:oper];
	[oper release];
}

- (void) getServerOffset:(void(^)(GetServerOffsetResult *result))callback
               withLabel:(NSString *)requestLabel;
{
    GetServerOffsetOperation *oper = [[GetServerOffsetOperation alloc] init];
    
	oper.atmosStore = self;
	oper.atmosCredentials = self.atmosCredentials;
	oper.callback = callback;
    oper.operationLabel = requestLabel;
    
    [self scheduleOperation:oper];
    [oper release];
}

#pragma mark RenameObject
- (void) rename:(AtmosObject*) source 
             to:(AtmosObject*) destination
          force:(BOOL) force
   withCallback:(void(^)(AtmosResult *result)) callback
      withLabel:(NSString*) requestLabel {
    RenameObjectOperation *oper = [[RenameObjectOperation alloc] init];
    
    oper.atmosStore = self;
    oper.atmosCredentials = self.atmosCredentials;
    oper.callback = callback;
    oper.source = source;
    oper.destination = destination;
    oper.force = force;
    oper.operationLabel = requestLabel;
          
    [self scheduleOperation:oper];
    [oper release];
}


#pragma mark MemoryManagement

- (void) dealloc {
	[currentOperations release];
	[pendingOperations release];
    
    self.atmosCredentials = nil;
    
	[super dealloc];
}


@end
