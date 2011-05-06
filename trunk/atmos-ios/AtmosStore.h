//
//  AtmosLocalStore.h
//  AtmosReader
//
//  Created by Aashish Patil on 4/12/10.
//  Copyright 2010 EMC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AtmosObject.h"
#import "AtmosCredentials.h"
#import "AtmosProgressListenerDelegate.h"
#import "GetListableTagsResult.h"
#import "UploadProgress.h"
#import "AtmosRange.h"
#import "ListObjectsResult.h"
#import "DownloadProgress.h"

#define ATMOS_DEFAULT_BUF_SIZE 4194304 //4MB is the buffer Atmos uses on the server

/*!
 * @discussion Main class to perform Atmos operations.
 */
@interface AtmosStore : NSObject {
	
	@private
	NSMutableSet *currentOperations;
	NSMutableArray *pendingOperations;
	
	@public
	AtmosCredentials *atmosCredentials;
	NSInteger maxConcurrentOperations;
}

- (void) operationFinishedInternal:(id) operation;


#pragma mark CreateAndUpdateObject


/*!
 * Creates a new object from the specified AtmosObject
 * @discussion Following fields of AtmosObject should be populated 
 * - filepath specifies the local file to be uploaded. If no filepath is specified a contentless object is created
 * - objectpath (optional): The Atmos object path at which to create the object
 * - User and User listable metadata: The metadata to set on the object.
 * @return The AtmosObject is returned alongwith the new objectid of the created object
 */
- (void) createObject:(AtmosObject *) atmosObj 
         withCallback:(BOOL(^)(UploadProgress *progress))callback 
            withLabel:(NSString *)requestLabel;

/*
 Updates the content of the specified AtmosObject in the cloud. 
 Either the object path or Atmos object id must be specified
 The local filepath which represents the new content to be updated must be specified
 Any metadata to be updated can be included in the AtmosObject structure.  
 
*/
- (void) updateObject:(AtmosObject *) atmosObj          
         withCallback:(BOOL(^)(UploadProgress *progress))callback 
            withLabel:(NSString *)requestLabel;

/*
 Same as above except this updates a specified range of the cloud object from the same range in the local file
 */
- (void) updateObjectRange:(AtmosObject *)atmosObj 
                     range:(AtmosRange *)objRange          
              withCallback:(BOOL(^)(UploadProgress *progress))callback 
                 withLabel:(NSString *)requestLabel;

#pragma mark GetObject 
/*
 Gets / downloads object from atmos to the local path provided.
 AtmosObject
 caller must specify objectid or objectpath
 The returned object contains all the metadat of the object
 
 */
- (void) readObject:(AtmosObject *) atmosObj 
       withCallback:(BOOL(^)(DownloadProgress *progress))callback 
          withLabel:(NSString *)requestLabel;

- (void) readObjectRange:(AtmosObject *)atmosObj 
                   range:(AtmosRange *)objRange 
            withCallback:(BOOL(^)(DownloadProgress *progress))callback 
               withLabel:(NSString *)requestLabel;

- (void) readObjectRange:(AtmosObject *)atmosObj 
                   range:(AtmosRange *)objRange 
              fileOffset:(long long) fOffset 
            withCallback:(BOOL(^)(DownloadProgress *progress))callback 
               withLabel:(NSString *)requestLabel;

#pragma mark DeleteObject
- (void) deleteObject:(AtmosObject *) atmosObj 
         withCallback:(void(^)(AtmosResult *result))callback
            withLabel:(NSString *)requestLabel;

#pragma mark GetDirectoryContents
- (void) getDirectoryContents:(AtmosObject *) directory withToken:(NSString *) emcToken withLimit:(NSInteger) limit withDelegate:(id<AtmosProgressListenerDelegate>) delegate withLabel:(NSString *)requestLabel;

#pragma mark GetListableTags 
//get listable tags asynchronously
- (void) getListableTags:(NSString *)parentTag 
            withCallback:(void(^)(GetListableTagsResult *tags))callback 
            withLabel:(NSString *)requestLabel ;

#pragma mark GetTaggedObjects
/*
 Methods to get tagged objects - object ids and object metadata - all or selected.
 x-emc-limit header not yet implemented
*/
//gets all objects tagged with a specific tag. only object ids are returned
- (void) listObjects:(NSString *) tag 
        withCallback:(void(^)(ListObjectsResult *result))callback
           withLabel:(NSString *) requestLabel;

//gets all tagged objects and all metadata for each object
- (void) listObjectsWithAllMetadata:(NSString *) tag 
                       withCallback:(void(^)(ListObjectsResult *result))callback
                          withLabel:(NSString *) requestLabel;

//gets all tagged objects and the specified metadata for each object
- (void) listObjectsWithMetadata:(NSString *) tag 
                  systemMetadata:(NSArray *) sdata 
                    userMetadata:(NSArray *) udata 
                    withCallback:(void(^)(ListObjectsResult *result))callback
                       withLabel:(NSString *) requestLabel;

#pragma mark GetObjectMetadata
//gets all the metadata for the specified object id / object path
- (void) getAllMetadataForId:(NSString *)atmosId withDelegate:(id<AtmosProgressListenerDelegate>) delegate withLabel:(NSString *) requestLabel;
- (void) getAllMetadataForPath:(NSString *)objectPath withDelegate:(id<AtmosProgressListenerDelegate>) delegate withLabel:(NSString *) requestLabel;

//gets the system metadata for the specified id / path. To retrieve only specific metadata, specify the metadata names as a NSString array
- (void) getAllSytemMetadataForId:(NSString *) atmosId withDelegate:(id<AtmosProgressListenerDelegate>) delegate withLabel:(NSString *) requestLabel;
- (void) getAllSytemMetadataForPath:(NSString *) objectPath withDelegate:(id<AtmosProgressListenerDelegate>) delegate withLabel:(NSString *) requestLabel;
- (void) getSystemMetadataForId:(NSString *) atmosId metadata:(NSArray *) mdata withDelegate:(id<AtmosProgressListenerDelegate>) delegate withLabel:(NSString *) requestLabel;
- (void) getSystemMetadataForPath:(NSString *) objectPath metadata:(NSArray *) mdata withDelegate:(id<AtmosProgressListenerDelegate>) delegate withLabel:(NSString *) requestLabel;

//gets the user metadata for the specified id / path. To retrieve only specific metadata, specify the metadata names as a NSString aray
- (void) getAllUserMetadataForId:(NSString *) atmosId withDelegate:(id<AtmosProgressListenerDelegate>) delegate withLabel:(NSString *) requestLabel;
- (void) getAllUserMetadataForPath:(NSString *) objectPath withDelegate:(id<AtmosProgressListenerDelegate>) delegate withLabel:(NSString *) requestLabel;
- (void) getUserMetadataForId:(NSString *) atmosId metadata:(NSArray *) mdata withDelegate:(id<AtmosProgressListenerDelegate>) delegate withLabel:(NSString *) requestLabel;
- (void) getUserMetadataForPath:(NSString *) objectPath metadata:(NSArray *) mdata withDelegate:(id<AtmosProgressListenerDelegate>) delegate withLabel:(NSString *) requestLabel;

#pragma mark SetObjectMetadata
//All user metadata in the atmos object is persisted to Atmos
- (void) setObjectMetadata:(AtmosObject *) atmosObject withDelegate:(id<AtmosProgressListenerDelegate>) delegate withLabel:(NSString *) requestLabel;

#pragma mark DeleteMetadata
//Deletes the metadata specified in AtmosObject#requestTags
- (void) deleteObjectMetadata:(AtmosObject *) atmosObject withDelegate:(id<AtmosProgressListenerDelegate>) delegate withLabel:(NSString *) requestLabel;

@property (nonatomic,retain) AtmosCredentials *atmosCredentials;
@property (nonatomic,retain) NSMutableSet *currentOperations;
@property (nonatomic,retain) NSMutableArray *pendingOperations;
@property (nonatomic,assign) NSInteger maxConcurrentOperations;


@end
