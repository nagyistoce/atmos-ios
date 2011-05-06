//
//  AtmosProgressListenerDelegate.h
//  AtmosReader
//
//  Created by Aashish Patil on 4/9/10.
//  Copyright 2010 EMC. All rights reserved.
//

#import "AtmosError.h"
#import "AtmosObject.h"

@protocol AtmosProgressListenerDelegate

@optional

/*
 Called to notify of object creation (upload) progress. 
 Implementors can return a boolean (YES / NO) to indicate whether upload should continue or not.
 */
- (BOOL) uploadProgressForObject:(AtmosObject *) object bytesUploaded:(NSInteger) bUploaded totalBytes:(NSInteger) totalB forLabel:(NSString *) requestLabel withError:(AtmosError *) error;

/*
 Called to notify of object download progress.
 Upon completion the downloaded content is available at the AtmosObject.filepath specified. 
 All object metadata (system, user & listable) is also available in the AtmosObject fields.
 
 Implementors can return a boolean (YES / NO) to indicate whether download should continue or not.
 */
- (BOOL) downloadProgressForObject:(AtmosObject *) object bytesDownloaded:(NSInteger)bDownloaded totalBytes:(NSInteger) totalB forLabel:(NSString *) requestLabel withError:(AtmosError *) error;

/*
 Called when object deletion is complete
 
 status tells whether deletion was successful or not. 
 
 The object provided no longer exists in Atmos upon successful deletion
 */
- (void) finishedDeletingObject:(AtmosObject *) object status:(BOOL) success forLabel:(NSString *) requestLabel withError:(AtmosError *) error;

/*
 Called when the operation to load listable tags is complete
 */
- (void) finishedLoadingTags:(NSArray *) tags forLabel:(NSString *)requestLabel withError:(AtmosError *) error ;

/*
 Called when operation to load tagged objects is complete
 */
- (void) finishedLoadingTaggedObjects:(NSDictionary *) objects forLabel:(NSString *)requestLabel withError:(AtmosError *) error;

/*
 Called when operation to load directory contents is complete
 */
- (void) finishedLoadingDirectory:(AtmosObject *) directory contents:(NSArray *) dirContents token:(NSString *) emcToken forLabel:(NSString *)requestLabel withError:(AtmosError *) error;

/*
 Called when metadata for th e specified object has been loaded. If specific metadata values were requested, those are the only 
 ones populated
 */
- (void) finishedLoadingMetadata:(AtmosObject *) object forLabel:(NSString *) requestLabel withError:(AtmosError *) error;

/*
 Called when metadata has been set on an object. If successful, the same AtmosObject is returned.
 */
- (void) finishedSettingMetadata:(AtmosObject *) object forLabel:(NSString *) requestLabel withError:(AtmosError *) error;

/*
 Called when metadata has been deleted on an object. If successful, the same AtmosObject is returned.
 */
- (void) finishedDeletingMetadata:(AtmosObject *) object status:(BOOL) success forLabel:(NSString *) requestLabel withError:(AtmosError *) error;


@end
