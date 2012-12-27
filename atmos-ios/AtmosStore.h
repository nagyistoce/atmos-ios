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
#import "AtmosCredentials.h"
#import "GetListableTagsResult.h"
#import "UploadProgress.h"
#import "AtmosRange.h"
#import "ListObjectsResult.h"
#import "DownloadProgress.h"
#import "AtmosObjectResult.h"
#import "ListDirectoryResult.h"
#import "GetServerOffsetResult.h"
#import "ServiceInformation.h"
#import "ObjectInformation.h"
#import "TNSAccessTokensListType.h"
#import "TNSPolicyType.h"
#import "CreateAccessTokenResult.h"
#import "GetAccessTokenInfoResult.h"
#import "ListAccessTokensResult.h"

#define ATMOS_DEFAULT_BUF_SIZE 4194304 //4MB is the buffer Atmos uses on the server

/*!
 * @discussion Main class to perform Atmos operations.
 */
@interface AtmosStore : NSObject {
	
	@private
	NSMutableSet *currentOperations;
	NSMutableArray *pendingOperations;
    NSTimeInterval timeOffset;
	
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
 * @param callback the callback block to invoke when operation is complete.
 * @param requestLabel user-defined label for the request.
 */
- (void) createObject:(AtmosObject *) atmosObj 
         withCallback:(BOOL(^)(UploadProgress *progress))callback 
            withLabel:(NSString *)requestLabel;

/*!
 * Updates the content of the specified AtmosObject in the cloud.
 * @param atmosObject an AtmosObject containing the atmosId/objectPath/keypool,
 * user metadata, and/or content to apply to the object in Atmos.
 * @param callback the callback block to invoke when operation is complete.
 * @param requestLabel user-defined label for the request.
 */
- (void) updateObject:(AtmosObject *) atmosObj          
         withCallback:(BOOL(^)(UploadProgress *progress))callback 
            withLabel:(NSString *)requestLabel;

/*!
 * Same as updateObject except this updates a specified range of the cloud 
 * object from the same range in the local file or with the contents of 
 * the AtmosObject's data buffer.
 * @param callback the callback block to invoke when operation is complete.
 * @param requestLabel a user-defined label to tag the request with.
 */
- (void) updateObjectRange:(AtmosObject *)atmosObj 
                     range:(AtmosRange *)objRange          
              withCallback:(BOOL(^)(UploadProgress *progress))callback 
                 withLabel:(NSString *)requestLabel;

#pragma mark GetObject 
/*!
 * Reads / downloads object from Atmos
 * @discussion if the AtmosObject's dataMode property is set to kDataModeBytes,
 * the object's content will be stored in the object's data property.  If the
 * dataMode property is set to kDataModeFile, the contents of the object will
 * be written to the local path provided.
 * @param callback the callback block to invoke when operation is complete.
 * @param requestLabel a user-defined label to tag the request with.
 */
- (void) readObject:(AtmosObject *) atmosObj 
       withCallback:(BOOL(^)(DownloadProgress *progress))callback 
          withLabel:(NSString *)requestLabel;

/*!
 * Reads / Downloads an object from Atmos
 * @discussion Same as readObject, except that only the specified range of the
 * object is downloaded. Useful for downloading a large object in chunks so
 * you can read in parallel and/or implement resume logic on chunk boundaries.
 *
 * If using kDataModeFile, you might be more interested in 
 * readObjectRange:range:fileOffset:withCallback:withLabel 
 * @param callback the callback block to invoke when operation is complete.
 * @param requestLabel a user-defined label to tag the request with.
 */
- (void) readObjectRange:(AtmosObject *)atmosObj 
                   range:(AtmosRange *)objRange 
            withCallback:(BOOL(^)(DownloadProgress *progress))callback 
               withLabel:(NSString *)requestLabel;

/*!
 * Reads / Downloads an object from Atmos
 * @discussion Same as readObject, except that only the specified range of the
 * object is downloaded. Useful for downloading a large object in chunks so
 * you can read in parallel and/or implement resume logic on chunk boundaries.
 * The file will be opened and seeked to fOffset.
 *
 * If using kDataModeBytes, you might be more interested in 
 * readObjectRange:range:withCallback:withLabel 
 * @param callback the callback block to invoke when operation is complete.
 * @param requestLabel a user-defined label to tag the request with.
 */
- (void) readObjectRange:(AtmosObject *)atmosObj 
                   range:(AtmosRange *)objRange 
              fileOffset:(long long) fOffset 
            withCallback:(BOOL(^)(DownloadProgress *progress))callback 
               withLabel:(NSString *)requestLabel;

#pragma mark DeleteObject
/*!
 * Deletes an object from Atmos.
 * @param atmosObj the Atmos object to delete.
 * @param callback the callback block to invoke when operation is complete.
 * @param requestLabel a user-defined label to tag the request with.
 */
- (void) deleteObject:(AtmosObject *) atmosObj 
         withCallback:(void(^)(AtmosResult *result))callback
            withLabel:(NSString *)requestLabel;

#pragma mark ListDirectory
/*!
 * Lists the contents of a directory
 * Be sure to check the pagination token from the ListDirectoryResult after
 * every call to check and see if there are additional results pending.
 * @param directory the directory to list.  The objectPath property must be set
 * on the object.
 * @param emcToken when listing a large directory, check the 
 * ListDirectoryResult's token field. If the value is non-nil, call the method
 * until the value is nil and concatenate the results of each call.
 * @param limit the maximum number of results to return. Set to 0 to request
 * all results. Note that Atmos may enforce a limit (generally 5000) even if 
 * this is set to zero.
 * @param callback the callback block to invoke when operation is complete.
 * @param requestLabel a user-defined label to tag the request with.
 */
- (void) listDirectory:(AtmosObject *) directory 
             withToken:(NSString *) emcToken 
             withLimit:(NSInteger) limit 
          withCallback:(void(^)(ListDirectoryResult *result))callback
             withLabel:(NSString *)requestLabel;

/*!
 * Lists the contents of a directory, including all metadata for the objects.
 * Be sure to check the pagination token from the ListDirectoryResult after
 * every call to check and see if there are additional results pending.
 * @param directory an AtmosObject whose objectPath is set to the directory to
 * list.
 * @param emcToken pagination token to continue an object listing.  Set to nil
 * for the initial request.
 * @param limit the number of objects to return per page.  Set to zero for the
 * default (usually 500 with metadata).
 * @param callback the callback block to invoke when operation is complete.
 * @param requestLabel a user-defined label to tag the request with.
 */
- (void) listDirectoryWithAllMetadata:(AtmosObject *) directory 
                            withToken:(NSString *) emcToken 
                            withLimit:(NSInteger) limit 
                         withCallback:(void(^)(ListDirectoryResult *result))callback
                            withLabel:(NSString *)requestLabel;

/*!
 * Lists the contents of a directory, including all metadata for the objects.
 * Be sure to check the pagination token from the ListDirectoryResult after
 * every call to check and see if there are additional results pending.
 * @param directory an AtmosObject whose objectPath is set to the directory to
 * list.
 * @param sdata an array of system metadata tags to fetch with the
 * results.
 * @param udata an array of user metadata tags to fetch with the results.
 * @param emcToken pagination token to continue an object listing.  Set to nil
 * for the initial request.
 * @param limit the number of objects to return per page.  Set to zero for the
 * default (usually 500 with metadata).
 * @param callback the callback block to invoke when operation is complete.
 * @param requestLabel a user-defined label to tag the request with.
 */
- (void) listDirectoryWithMetadata:(AtmosObject *) directory
                    systemMetadata:(NSArray *) sdata 
                      userMetadata:(NSArray *) udata 
                         withToken:(NSString *) emcToken 
                         withLimit:(NSInteger) limit
                      withCallback:(void(^)(ListDirectoryResult *result))callback
                         withLabel:(NSString *)requestLabel;

#pragma mark GetListableTags 

/*!
 * Gets the set of listable tags for the given parent tag.
 * @param parentTag the parent tag to list.  Set to nil to fetch toplevel tags.
 * @param callback the callback block to invoke when operation is complete.
 * @param requestLabel a user-defined label to tag the request with.
 */
- (void) getListableTags:(NSString *)parentTag 
            withCallback:(void(^)(GetListableTagsResult *tags))callback 
            withLabel:(NSString *)requestLabel ;

#pragma mark GetTaggedObjects

/*!
 * @abstract List objects tagged with a listable tag.
 * @param tag the listable tag to search for
 * @param token if the previous result had a non-nil token,
 * pass it here to retrieve more results. Continue until the
 * token is nil to ensure you get all results.
 * @param limit the maximum number of results to return. Set
 * to zero to retrieve the server maximum (generally 5000).
 * @param callback the callback block to invoke when operation is complete.
 * @param requestLabel a user-defined label to tag the request with.
 */
- (void) listObjects:(NSString *) tag
           withToken:(NSString *) token
           withLimit:(NSInteger) limit
        withCallback:(void(^)(ListObjectsResult *result))callback
           withLabel:(NSString *) requestLabel;


/*!
 * @deprecated use the versions withToken and withLimit to 
 * ensure that you get all of the results in the list.  Atmos
 * will only return about 5000 results before it requires
 * iteration with a token.
 */
- (void) listObjects:(NSString *) tag
        withCallback:(void(^)(ListObjectsResult *result))callback
           withLabel:(NSString *) requestLabel __attribute__((deprecated));

/*!
 * Lists objects indexed by a listable tag.  This version will include all
 * object metadata.  Always check the pagination token in the ListObjectsResult
 * object to see if there are more results pending.
 * @param tag the listable tag to search
 * @param token the pagination token for the request.  Set to nil to fetch the
 * first page of results.
 * @param limit the number of items to fetch per page.  Set to zero to get the
 * default limit (generally 500 with metadata).
 * @param callback the callback block to invoke when operation is complete.
 * @param requestLabel a user-defined label to tag the request with.
 */
- (void) listObjectsWithAllMetadata:(NSString *) tag
                          withToken:(NSString *) token
                          withLimit:(NSInteger) limit
                       withCallback:(void(^)(ListObjectsResult *result))callback
                          withLabel:(NSString *) requestLabel;

/*!
 * Lists objects indexed by a listable tag.  This version will include all
 * object metadata.  Always check the pagination token in the ListObjectsResult
 * object to see if there are more results pending.
 * @param tag the listable tag to search
 * @param sdata an array containing the system metadata tags to fetch.
 * @param udata an array containing the user metadata tags to fetch.
 * @param token the pagination token for the request.  Set to nil to fetch the
 * first page of results.
 * @param limit the number of items to fetch per page.  Set to zero to get the
 * default limit (generally 500 with metadata).
 * @param callback the callback block to invoke when operation is complete.
 * @param requestLabel a user-defined label to tag the request with.
 */
- (void) listObjectsWithMetadata:(NSString *) tag
                  systemMetadata:(NSArray *) sdata 
                    userMetadata:(NSArray *) udata 
                       withToken:(NSString *) token
                       withLimit:(NSInteger) limit
                    withCallback:(void(^)(ListObjectsResult *result))callback
                       withLabel:(NSString *) requestLabel;

#pragma mark GetObjectMetadata
/*!
 * Gets all of the metadata for the given Atmos Object ID.
 * @param atmosId the Atmos Object ID to read the metadata of.
 * @param callback the callback block to invoke when operation is complete.
 * @param requestLabel a user-defined label to tag the request with.
 */
- (void) getAllMetadataForId:(NSString *)atmosId
                withCallback:(void(^)(AtmosObjectResult *result))callback
                   withLabel:(NSString *) requestLabel;

/*!
 * Gets all of the metadata for the given Atmos Object Path.
 * @param objectPath the Atmos namespace path to read the metadata of.
 * @param callback the callback block to invoke when operation is complete.
 * @param requestLabel a user-defined label to tag the request with.
 */
- (void) getAllMetadataForPath:(NSString *)objectPath
                  withCallback:(void(^)(AtmosObjectResult *result))callback
                     withLabel:(NSString *) requestLabel;
/*!
 * Gets all of the metadata for the given Atmos keypool object.
 * @param pool the Atmos keypool containing the object.
 * @param key the object's key in the pool.
 * @param callback the callback block to invoke when operation is complete.
 * @param requestLabel a user-defined label to tag the request with.
 * @since Atmos 2.1.0
 */
- (void) getAllMetadataForKeypool:(NSString *)pool
                          withKey:(NSString *)key
                     withCallback:(void(^)(AtmosObjectResult *result))callback
                        withLabel:(NSString *) requestLabel;

/*!
 * Gets all system metadata for the given Atmos Object.
 * @param atmosId the Atmos Object ID of the object to read.
 * @param callback the callback block to invoke when operation is complete.
 * @param requestLabel a user-defined label to tag the request with.
 */
- (void) getAllSytemMetadataForId:(NSString *) atmosId
                     withCallback:(void(^)(AtmosObjectResult *result))callback
                        withLabel:(NSString *) requestLabel;
/*!
 * Gets all system metadata for the given Atmos Object.
 * @param objectPath the Atmos namespace path of the object to read.
 * @param callback the callback block to invoke when operation is complete.
 * @param requestLabel a user-defined label to tag the request with.
 */
- (void) getAllSytemMetadataForPath:(NSString *) objectPath
                       withCallback:(void(^)(AtmosObjectResult *result))callback
                          withLabel:(NSString *) requestLabel;
/*!
 * Gets all system metadata for the given Atmos Object.
 * @param pool the Atmos keypool containing the object.
 * @param key the object's key in the keypool.
 * @param callback the callback block to invoke when operation is complete.
 * @param requestLabel a user-defined label to tag the request with.
 * @since Atmos 2.1.0
 */
- (void) getAllSytemMetadataForKeypool:(NSString *) pool
                               withKey:(NSString *) key
                          withCallback:(void(^)(AtmosObjectResult *result))callback
                             withLabel:(NSString *) requestLabel;

/*!
 * Gets selected system metadata for the given Atmos object.
 * @param atmosId the Atmos Object ID of the object to read.
 * @param mdata an array of system metadata tags to fetch (e.g. @"size")
 * @param callback the callback block to invoke when operation is complete.
 * @param requestLabel a user-defined label to tag the request with.
 */
- (void) getSystemMetadataForId:(NSString *) atmosId 
                       metadata:(NSArray *) mdata 
                   withCallback:(void(^)(AtmosObjectResult *result))callback
                      withLabel:(NSString *) requestLabel;
/*!
 * Gets selected system metadata for the given Atmos Object.
 * @param objectPath the Atmos namespace path of the object to read.
 * @param mdata an array of system metadata tags to fetch (e.g. @"size")
 * @param callback the callback block to invoke when operation is complete.
 * @param requestLabel a user-defined label to tag the request with.
 */
- (void) getSystemMetadataForPath:(NSString *) objectPath
                         metadata:(NSArray *) mdata
                     withCallback:(void(^)(AtmosObjectResult *result))callback
                        withLabel:(NSString *) requestLabel;
/*!
 * Gets selected system metadata for the given Atmos Object.
 * @param pool the Atmos keypool containing the object.
 * @param key the object's key in the keypool.
 * @param mdata an array of system metadata tags to fetch (e.g. @"size")
 * @param callback the callback block to invoke when operation is complete.
 * @param requestLabel a user-defined label to tag the request with.
 * @since Atmos 2.1.0
 */
- (void) getSystemMetadataForKeypool:(NSString *) pool
                             withKey:(NSString *)key
                            metadata:(NSArray *) mdata
                        withCallback:(void(^)(AtmosObjectResult *result))callback
                           withLabel:(NSString *) requestLabel;

/*!
 * Gets all user metadata for the given Atmos Object.
 * @param atmosId the Atmos Object ID of the object to read.
 * @param callback the callback block to invoke when operation is complete.
 * @param requestLabel a user-defined label to tag the request with.
 */
- (void) getAllUserMetadataForId:(NSString *) atmosId
                    withCallback:(void(^)(AtmosObjectResult *result))callback
                       withLabel:(NSString *) requestLabel;
/*!
 * Gets all user metadata for the given Atmos Object.
 * @param objectPath the Atmos namespace path of the object to read.
 * @param callback the callback block to invoke when operation is complete.
 * @param requestLabel a user-defined label to tag the request with.
 */
- (void) getAllUserMetadataForPath:(NSString *) objectPath
                      withCallback:(void(^)(AtmosObjectResult *result))callback
                         withLabel:(NSString *) requestLabel;
/*!
 * Gets all user metadata for the given Atmos Object.
 * @param pool the Atmos keypool containing the object.
 * @param key the object's key in the keypool.
 * @param callback the callback block to invoke when operation is complete.
 * @param requestLabel a user-defined label to tag the request with.
 * @since Atmos 2.1.0
 */
- (void) getAllUserMetadataForKeypool:(NSString *) pool
                              withKey:(NSString *) key
                         withCallback:(void(^)(AtmosObjectResult *result))callback
                            withLabel:(NSString *) requestLabel;


/*!
 * Gets selected user metadata for the given Atmos Object.
 * @param atmosId the Atmos Object ID of the object to read.
 * @param mdata an array of user metadata tags to fetch
 * @param callback the callback block to invoke when operation is complete.
 * @param requestLabel a user-defined label to tag the request with.
 */
- (void) getUserMetadataForId:(NSString *) atmosId
                     metadata:(NSArray *) mdata 
                 withCallback:(void(^)(AtmosObjectResult *result))callback
                    withLabel:(NSString *) requestLabel;
/*!
 * Gets selected user metadata for the given Atmos Object.
 * @param objectPath the Atmos namespace path of the object to read.
 * @param mdata an array of user metadata tags to fetch
 * @param callback the callback block to invoke when operation is complete.
 * @param requestLabel a user-defined label to tag the request with.
 */
- (void) getUserMetadataForPath:(NSString *) objectPath
                       metadata:(NSArray *) mdata
                   withCallback:(void(^)(AtmosObjectResult *result))callback
                      withLabel:(NSString *) requestLabel;
/*!
 * Gets selected user metadata for the given Atmos Object.
 * @param pool the Atmos keypool containing the object.
 * @param key the object's key in the keypool.
 * @param mdata an array of user metadata tags to fetch
 * @param callback the callback block to invoke when operation is complete.
 * @param requestLabel a user-defined label to tag the request with.
 * @since Atmos 2.1.0
 */
- (void) getUserMetadataForKeypool:(NSString *) pool
                           withKey:(NSString *) key
                          metadata:(NSArray *) mdata
                      withCallback:(void(^)(AtmosObjectResult *result))callback
                         withLabel:(NSString *) requestLabel;

#pragma mark SetObjectMetadata
/*!
 * Updates the metadata on an Atmos object.  The user metadata values from the
 * supplied object will be persisted on the object in Atmos.  Note that this
 * will only create and/or update existing values.  If you wish to remove
 * metadata from an object you need to use deleteObjectMetadata:withCallback:withLabel.
 * @param atmosObject the AtmosObject containing the ID/Path/Keypool and the
 * metadata to apply to the object.
 * @param callback the callback block to invoke when operation is complete.
 * @param requestLabel a user-defined label to tag the request with.
 */
- (void) setObjectMetadata:(AtmosObject *) atmosObject
              withCallback:(void(^)(AtmosResult *result))callback
                 withLabel:(NSString *) requestLabel;

#pragma mark DeleteMetadata
/*!
 * Deletes metadata from an object in Atmos.
 * @param atmosObject the AtmosObject containing the ID/Path/Keypool of the
 * object to update and requestTags containg the list of user metadata tags
 * to remove from the object.
 * @param callback the callback block to invoke when operation is complete.
 * @param requestLabel a user-defined label to tag the request with.
 */
- (void) deleteObjectMetadata:(AtmosObject *) atmosObject
                 withCallback:(void(^)(AtmosResult *result))callback
                    withLabel:(NSString *) requestLabel;

#pragma mark GetServerOffset
/*!
 * Determines the clock skew between the local device and the Atmos server.
 * This is especially important for iPod Touch and iPad devices without
 * cellular service since they do not automatically set their clocks.  After
 * calling this method, apply the offset from the result to the AtmosStore
 * object.  The AtmosStore object will then use the supplied offset to sign
 * requests.  If you're getting timestamp errors from your requests, this is
 * usually the problem.
 * @param callback the callback block to invoke when operation is complete.
 * @param requestLabel a user-defined label to tag the request with.
 */
- (void) getServerOffset:(void(^)(GetServerOffsetResult *result))callback
               withLabel:(NSString *)requestLabel;

#pragma mark RenameObject
/*!
 * Renames (moves) an object in Atmos.  Note that Atmos internally contains
 * a namespace lookup cache with a lifetime of 5 seconds.  Therefore, within
 * 5 seconds of renaming an object it may still be accessible at the old path
 * and/or with 'force' the old object may be visible on nodes that have not
 * flushed their caches yet.
 * @param source an AtmosObject containing the objectPath of the existing 
 * object.
 * @param destination an AtmosObject containing the objectPath to move the 
 * source to.
 * @param force if YES, if an object exists at the destination, it will be
 * overwritten with the source object.
 * @param callback the callback block to invoke when operation is complete.
 * @param requestLabel a user-defined label to tag the request with.
 */
- (void) rename:(AtmosObject*) source 
             to:(AtmosObject*) destination 
          force:(BOOL) force
   withCallback:(void(^)(AtmosResult *result)) callback
      withLabel:(NSString*) requestLabel;

#pragma mark GetServiceInformation
/*!
 * Gets the version of Atmos running on the server.  Note that this method is
 * also good for checking a user's credentials since it is fast and does not
 * have any side effects on the server's content (i.e. it does not modify any
 * content on the server).  It is highly recommended to call this operation
 * before any others (except maybe getServerOffset:withLabel).
 * @param callback the callback block to invoke when operation is complete.
 * @param requestLabel a user-defined label to tag the request with.
 */
- (void) getServiceInformation:(void(^)(ServiceInformation *result)) callback
                     withLabel:(NSString*) requestLabel;

#pragma mark GetObjectInformation
/*!
 * @abstract Gets replica, retention, and expiration information
 * about an object.
 * @param atmosObject the AtmosObject to query information for
 * @param callback the block to execute when the operation is
 * complete.
 * @param requestLabel the label for the request.
 */
- (void) getObjectInformation:(AtmosObject*) atmosObject
                 withCallback:(void(^)(ObjectInformation *result)) callback
                    withLabel:(NSString*) requestLabel;

#pragma mark Access Tokens

/*!
 * @abstract Creates a new, empty access token.  This token will be
 * created with one upload.  You must capture the HTTP response to
 * extract the HTTP "Location" header or put x-emc-redirect-url in an HTTP
 * form to get the created ObjectId.  See the Atmos Programmer's Guide
 * for more information on using tokens.
 * @param callback the block to execute when the operation is
 * complete.
 * @param requestLabel the label for the request.
 * @since Atmos 2.1.0
 */
- (void) createAccessToken:(void(^)(CreateAccessTokenResult *result)) callback
                             withLabel:(NSString*) requestLabel;

/*!
 * @abstract Creates a new access token.  The supplied policy will be
 * applied to the token.  If userMetadata, listableMetadata, or acl are non-nil,
 * they will be applied to the created object.  You must capture the HTTP 
 * response to extract the HTTP "Location" header or put x-emc-redirect-url in 
 * an HTTP form to get the created ObjectId.  See the Atmos Programmer's Guide
 * for more information on using tokens.
 * @param policy if non-nil, the policy to apply to the token.  If nil, a
 * default policy will be applied (1 upload, expires in 24 hours).
 * @param userMetadata if non-nil, the User Metadata to apply to the object.
 * @param listableMetadata if non-nil, the Listable Metadata tags to apply to
 * the object.
 * @param acl if non-nil, the ACL to apply to the new object.  If nil, the
 * object will get the default ACL (uid=FULL_CONTROL,other=NONE).
 * @param callback the block to execute when the operation is
 * complete.
 * @param requestLabel the label for the request.
 * @since Atmos 2.1.0
 */
- (void) createAccessTokenWithPolicy:(TNSPolicyType*) policy
                        withMetadata:(NSDictionary*) userMetadata
                withListableMetadata:(NSDictionary*) listableMetadata
                             withAcl:(NSArray*) acl
                        withCallback:(void(^)(CreateAccessTokenResult *result)) callback
                           withLabel:(NSString*) requestLabel;

/*!
 * @abstract Creates a new access token for the given Object.  The object
 * parameter may contain an object ID, a namespace path, metadata, and an
 * ACL.  These values will be applied to an object created with the token.
 * If not using namespace, you must capture the HTTP response to extract the 
 * HTTP "Location" header or put x-emc-redirect-url in an HTTP form to get the 
 * created ObjectId.  See the Atmos Programmer's Guide for more information on 
 * using tokens.
 * @param object the AtmosObject containing parameters for the object associated
 * with the token.  If objectId and path are nil in the object, a new
 * objectId will be created when the token is uploaded to.  If a path is 
 * specified for an upload token, the object will be created on that path.  For
 * download tokens, you should specify either a path or objectId.  If both are
 * specified, the path will take precedence.
 * @param policy if non-nil, the policy to apply to the token.  If nil, a
 * default policy will be applied (1 upload, expires in 24 hours).
 * @param callback the block to execute when the operation is
 * complete.
 * @param requestLabel the label for the request.
 * @since Atmos 2.1.0
 */
- (void) createAccessTokenForObject:(AtmosObject*)object
                         withPolicy:(TNSPolicyType*) policy
                       withCallback:(void(^)(CreateAccessTokenResult *result)) callback
                          withLabel:(NSString*) requestLabel;

/*!
 * @abstract deletes an access token.
 * @param accessTokenId the ID of the token to delete.
 * @param callback the block to execute when the operation is
 * complete.
 * @param requestLabel the label for the request.
 * @since Atmos 2.1.0
 */ 
- (void) deleteAccessToken:(NSString*)accessTokenId
              withCallback:(void(^)(AtmosResult* result)) callback
                 withLabel:(NSString*) requestLabel;

/*!
 * @abstract gets information about an access token.
 * @param accessTokenId the ID of the access token to fetch information about.
 * @param callback the block to execute when the operation is
 * complete.
 * @param requestLabel the label for the request.
 * @since Atmos 2.1.0
 */
- (void) getAccessTokenInfo:(NSString*)accessTokenId
               withCallback:(void(^)(GetAccessTokenInfoResult *result)) callback
                  withLabel:(NSString*) requestLabel;

/*!
 * @abstract Lists access tokens for the current subtenant.  Be sure to check
 * the result object for a pagination token.  If the token is non-nil, execute
 * this method again with the token set to continue the listing.
 * @param if nonzero, the maximum number of tokens to return in the listing.
 * the default limit is 5000.
 * @param token the pagination token to continue listing from.  Set to nil on
 * your first request.
 * @param callback the block to execute when the operation is
 * complete.
 * @param requestLabel the label for the request.
 * @since Atmos 2.1.0
 */
- (void) listAccessTokensWithLimit:(int)limit
                         withToken:(NSString*)token
                      withCallback:(void(^)(ListAccessTokensResult *result)) callback
                         withLabel:(NSString*) requestLabel;

#pragma mark Properties
/*!
 * Credentials to use for making requests with this object.
 */
@property (nonatomic,retain) AtmosCredentials *atmosCredentials;
/*!
 * Operations currently executing
 */
@property (nonatomic,retain) NSMutableSet *currentOperations;
/*!
 * Operations currently waiting in queue to execute.
 */
@property (nonatomic,retain) NSMutableArray *pendingOperations;
/*!
 * Maximum concurrent operations to execute.  Default limit is 10.
 */
@property (nonatomic,assign) NSInteger maxConcurrentOperations;
/*!
 * Time offset between the local device and the server.  See 
 * getServerOffset:withLabel for more information.
 */
@property (nonatomic) NSTimeInterval timeOffset;

@end
