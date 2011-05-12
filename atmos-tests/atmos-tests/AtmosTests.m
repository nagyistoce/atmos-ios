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

#import <GHUnitIOS/GHUnit.h> 
#import "AtmosTests.h"
#import "UploadProgress.h"
#import "NSData+Additions.h"

// Timeout for unit tests
#define TIMEOUT 60.0


@implementation AtmosTests

@synthesize atmosStore,cleanup;


- (void)checkResult:(AtmosResult*)result 
{
    GHAssertTrue(result.wasSuccessful, @"Request failed");
    GHAssertNil(result.error, @"Result error should be Nil on success");
}

- (void)setUp
{
    [super setUp];
    
    AtmosCredentials *creds = [[AtmosCredentials alloc] init];
    
//    creds.tokenId = @"ab105326496a4228add95d20306030fd/CONNEAABCF7F31DDF0F7";
//    creds.sharedSecret = @"ra15Bu1Gk2AX5QV1K7iC9scG/OM=";
//    creds.accessPoint = @"192.168.246.152";
//    creds.httpProtocol = @"http";
//    creds.portNumber = 80;
    creds.tokenId=@"jason";
    creds.sharedSecret=@"1/HpFFAEcbXGXnOaX4Ob3zyYXE8=";
    creds.accessPoint=@"192.168.235.129";
    creds.httpProtocol=@"http";
    creds.portNumber=80;
    
    // Set-up code here.
    atmosStore = [[AtmosStore alloc] init];
    atmosStore.atmosCredentials = creds;
    [creds release];
    
    // Clear the cleanup
    cleanup = [[NSMutableArray alloc] init];
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
    
    // Request deletion of any objects created
    for (NSString *oid in self.cleanup) {
        AtmosObject *obj = [[AtmosObject alloc] initWithObjectId:oid];
        [atmosStore deleteObject:obj
                    withCallback:^(AtmosResult *result) {
                        // Do nothing
                    } withLabel:@""];
        [obj release];
    }
    
    [cleanup release];
    [atmosStore release];
    
}

- (void)testSignatureFailure
{
    // Call prepare to setup the asynchronous action.
    // This helps in cases where the action is synchronous and the
    // action occurs before the wait is actually called.
    [self prepare];

    atmosStore.atmosCredentials.sharedSecret = @"AAAAAAAAAAAAAAAAAAAAAAAAAA=";
    [atmosStore getListableTags:nil
                   withCallback:^(GetListableTagsResult* result)
     {
         GHAssertFalse(result.wasSuccessful, 
                       @"Method should have failed");
         GHAssertNotNil(result.error, 
                        @"Result should contain error");
         GHAssertTrue(result.error.errorCode == 1032, 
                      @"Expected error code 1032, got %d",
                      result.error.errorCode);
         [self notify:kGHUnitWaitStatusSuccess 
            forSelector:@selector(testSignatureFailure)];
     }
                      withLabel:@"testSignatureFailure"];
    
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:TIMEOUT];
}

- (void)testGetListableTags
{
    
    // Call prepare to setup the asynchronous action.
    // This helps in cases where the action is synchronous and the
    // action occurs before the wait is actually called.
    [self prepare];

    [atmosStore getListableTags:nil 
                   withCallback:^(GetListableTagsResult* result){
                       [self checkResult:result];
                       GHAssertNotNil(result.tags, @"Tags should be non-nil");
                       GHAssertTrue([result.tags count]>0, 
                                    @"Tags count should be at least one, was %d", 
                                    [result.tags count]);
                       
                       [self notify:kGHUnitWaitStatusSuccess 
                        forSelector:@selector(testGetListableTags)];
                   }
                      withLabel:@"tetGetListableTags"];
    
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:TIMEOUT];
}

- (void)subTestListObjects1:(AtmosObject*)atmosObject
{
    // Check and make sure we can find the object
    GHTestLog(@"Created AtmosObject %@", atmosObject.atmosId);
    [cleanup addObject:atmosObject.atmosId];
    
    
    [atmosStore listObjects:@"listable" 
               withCallback:^(ListObjectsResult *result) {
                   [self checkResult:result];
                   
                   NSLog(@"results contains %@", [result.objects description] );

                   // Make sure array contains our ID.
                   GHAssertTrue(
                        [result.objects containsObject:atmosObject],
                                @"List objects result didn't include %@",
                                atmosObject.atmosId);
                   
                   // Notify async test complete.
                   [self notify:kGHUnitWaitStatusSuccess 
                    forSelector:@selector(testListObjects)];
               } withLabel:@"subTestListObjects1"];
    
    
}
- (void)testListObjects
{
    [self prepare];
    
    AtmosObject *obj = [[AtmosObject alloc] init];
    obj.userListableMeta = [[NSMutableDictionary alloc] 
                            initWithObjectsAndKeys:@"",@"listable", nil];
    [atmosStore createObject:obj withCallback:^BOOL(UploadProgress *progress) {
        // Check
        [self checkResult:progress];
        
        if(progress.isComplete) {
            [self subTestListObjects1:progress.atmosObject];
        }
        
        return YES;
    } withLabel:@"testCreateListableObject1"];

    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:TIMEOUT];
    [obj release];

}

-(void)subTestCreateEmptyObject1:(AtmosObject*) atmosObject
{
    GHTestLog(@"Created AtmosObject %@", atmosObject.atmosId);
    [cleanup addObject:atmosObject.atmosId];

    // Read it back
    [atmosStore readObject:atmosObject 
              withCallback:^BOOL(DownloadProgress *progress) {
                  [self checkResult:progress];
                  
                  if(progress.isComplete) {
//                      NSLog( @"Loaded data %@", 
//                            [NSString stringWithUTF8String:progress.atmosObject.data.bytes]);
                            
                      // Check results
                      GHAssertTrue(0 == progress.atmosObject.data.length, 
                                     @"Expected data to be empty, was %@",
                                   progress.atmosObject.data.length);
                      [self notify:kGHUnitWaitStatusSuccess 
                       forSelector:@selector(testCreateEmptyObject)];
                  }
                  return YES;
              } 
                 withLabel:@"subTestCreateEmptyObject1"];
}

- (void)testCreateEmptyObject
{
    [self prepare];
    
    AtmosObject *obj = [[AtmosObject alloc] init];
    obj.dataMode = kDataModeBytes;
    [atmosStore createObject:obj 
                withCallback:^BOOL(UploadProgress *progress) {
                    [self checkResult:progress];
                    
                    if(progress.isComplete) {
                        // Read back the created object.  Tweak the data
                        // before readback to ensure it gets rewritten 
                        // properly.
                        progress.atmosObject.data = 
                            [NSData dataWithBase64EncodedString:@"SGVsbG8gV29ybGQh"]; // Hello World!
                        [self subTestCreateEmptyObject1:progress.atmosObject];
                    }
                    return YES;
                } 
                   withLabel:@"testCreateEmptyObject"];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:TIMEOUT];
    [obj release];

}

- (void)subTestDeleteObject2:(AtmosObject*)atmosObject
{
    // Check to make sure the object was deleted.  Should see an error
    // on readObject
    [atmosStore readObject:atmosObject
              withCallback:^BOOL(DownloadProgress *progress) {
                  if(progress.isComplete) {
                      // Make sure request failed with object not found
                      GHAssertFalse(progress.wasSuccessful, 
                                    @"Reading deleted object should have failed.");
                      GHAssertNotNil(progress.error, 
                                     @"Result should contain error");
                      GHAssertTrue(progress.error.errorCode == 1003,
                                   @"Expected error code 1003");
                  
                      // Notify async test complete.
                      [self notify:kGHUnitWaitStatusSuccess 
                       forSelector:@selector(testDeleteObject)];
                  }
                  return YES;
                                
              }
              withLabel:@"subTestDeleteObject2"];
    
    
}

- (void)subTestDeleteObject1:(AtmosObject*)atmosObject
{
    // We have the object, now delete it
    [atmosStore deleteObject:atmosObject
                 withCallback:^(AtmosResult *result) {
                     [self checkResult:result];
                     [self subTestDeleteObject2:atmosObject];
                 } 
                    withLabel:@"subTestDeleteObject1"];
}

- (void)testDeleteObject
{
    [self prepare];
    
    // Create an object
    AtmosObject *obj = [[AtmosObject alloc] init];
    obj.dataMode = kDataModeBytes;
    [atmosStore createObject:obj 
                withCallback:^BOOL(UploadProgress *progress) {
                    [self checkResult:progress];
                    
                    if(progress.isComplete) {
                        [self subTestDeleteObject1:progress.atmosObject];
                    }
                    return YES;
                } 
                   withLabel:@"testCreateEmptyObject"];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:TIMEOUT];
    [obj release];
    
}

- (void)subTestCreateObjectWithContent1:(AtmosObject*)atmosObject
{
    // Add new object to cleanup list
    [cleanup addObject:atmosObject.atmosId];
    
    // Read the object back and check contents.
    atmosObject.data = nil;
    atmosObject.dataMode = kDataModeBytes;
    atmosObject.contentType = nil;
    [atmosStore readObject:atmosObject
              withCallback:^BOOL(DownloadProgress *progress) {
                  [self checkResult:progress];
                  if(progress.isComplete){
                      GHAssertNotNil(progress.atmosObject.data, 
                                     @"Expected data to be non-Nil");
                      GHAssertEqualStrings(@"Hello World",
                                           [NSString stringWithUTF8String:[progress.atmosObject.data bytes]], 
                                           @"Expected strings to match");
                      GHAssertEqualStrings(@"text/foo", 
                                     progress.atmosObject.contentType, 
                                     @"Expected MIME types to match");
                      // Notify async test complete.
                      [self notify:kGHUnitWaitStatusSuccess 
                       forSelector:@selector(testCreateObjectWithContent)];
                  }
                  return YES;
                
              } 
                 withLabel:@"subTestCreateObjectWithContent1"];
}

- (void)testCreateObjectWithContent
{
    [self prepare];
    
    AtmosObject *obj = [[AtmosObject alloc] init];
    obj.dataMode = kDataModeBytes;
    obj.data = [NSData dataWithBytes:[@"Hello World" UTF8String] length:12];
    obj.contentType = @"text/foo";
    
    [atmosStore createObject:obj 
                withCallback:^BOOL(UploadProgress *progress) {
                    [self checkResult:progress];
                    
                    if(progress.isComplete){
                        GHAssertNotNil(progress.atmosObject,                                  
                                       @"Expected New ID to be non-Nil");
                        [self subTestCreateObjectWithContent1:obj];
                    }
                    
                    return YES;
                } 
                   withLabel:@"testCreateObjectWithContent"];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:TIMEOUT];
    [obj release];
    
}

- (void)subTestGetSystemMetadata1:(AtmosObject*)obj
{
    // Add new object to cleanup list
    [cleanup addObject:obj.atmosId];
    
    // Read the object back and check contents.
    [atmosStore getAllSytemMetadataForId:obj.atmosId
        withCallback:^(AtmosObjectResult *result) {
            [self checkResult:result];
            
            GHAssertEquals(12, 
            [[result.atmosObject.systemMeta objectForKey:@"size"] integerValue], 
                           @"Size should be 12");
            // Notify async test complete.
            [self notify:kGHUnitWaitStatusSuccess 
             forSelector:@selector(testGetSystemMetadata)];

        } 
           withLabel:@"subTestGetSystemMetadata1"];
}

- (void)testGetSystemMetadata
{
    [self prepare];
    
    // Create an object with content, verify size
    AtmosObject *obj = [[AtmosObject alloc] init];
    obj.dataMode = kDataModeBytes;
    obj.data = [NSData dataWithBytes:[@"Hello World" UTF8String] length:12];
    
    [atmosStore createObject:obj 
                withCallback:^BOOL(UploadProgress *progress) {
                    [self checkResult:progress];
                    
                    if(progress.isComplete){
                        GHAssertNotNil(progress.atmosObject,                                  
                                       @"Expected New ID to be non-Nil");
                        [self subTestGetSystemMetadata1:obj];
                    }
                    
                    return YES;
                } 
                   withLabel:@"testGetSystemMetadata"];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:TIMEOUT];
    [obj release];
}

- (void) subTestGetServerOffset1
{
    // Make sure we can still get listable tags without error
    // after setting time offset
    [atmosStore getListableTags:nil 
                   withCallback:^(GetListableTagsResult *tags) {
                       [self checkResult:tags];
                       
                       // Notify async test complete.
                       [self notify:kGHUnitWaitStatusSuccess 
                        forSelector:@selector(testGetServerOffset)];
                   } 
                      withLabel:@"subTestGetServerOffset1"];
    
    
}

- (void) testGetServerOffset
{
    [self prepare];
    
    [atmosStore getServerOffset:^(GetServerOffsetResult *result) {
        [self checkResult:result];
        GHTestLog(@"Server offset: %lf seconds", result.offset);
        atmosStore.timeOffset = result.offset;
        [self subTestGetServerOffset1];
    } withLabel:@"testGetServerOffset"];
    
    
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:TIMEOUT];
    
}

- (void) subTestSetUserMetadata2:(AtmosObject*)atmosObject
{
    // Read the object back and check metadata
    [atmosStore getAllMetadataForId:atmosObject.atmosId 
                       withCallback:^(AtmosObjectResult *result) {
        [self checkResult:result];
        
        GHAssertEqualStrings(@"newvalue", 
                             [result.atmosObject.userRegularMeta 
                              objectForKey:@"listable"], 
                             @"Metadata value was not correct");
                           
       GHAssertNil([result.atmosObject.userListableMeta objectForKey:@"listable"], @"metadata with name listable should not be in listable dictionary");
                           
       // Notify async test complete.
       [self notify:kGHUnitWaitStatusSuccess 
        forSelector:@selector(testSetUserMetadata)];
    } withLabel:@"subTestSetUserMetadata2"];
    
}

- (void) subTestSetUserMetadata1:(AtmosObject*)atmosObject
{
    // Add to cleanup
    [cleanup addObject:atmosObject.atmosId];
    
    // Update the metadata, change the value and make it non-listable.
    atmosObject.userListableMeta = [NSMutableDictionary dictionary];
    atmosObject.userRegularMeta = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"newvalue",@"listable", nil];
    [atmosStore setObjectMetadata:atmosObject withCallback:^(AtmosResult *result) {
        [self checkResult:result];
        
        [self subTestSetUserMetadata2:atmosObject];
    } withLabel:@"subTestListObjects1"];
    
}

- (void) testSetUserMetadata
{
    [self prepare];
    
    // Create an object with some metadata
    AtmosObject *obj = [[AtmosObject alloc] init];
    obj.userListableMeta = [NSMutableDictionary 
                            dictionaryWithObjectsAndKeys:@"",@"listable", nil];
    [atmosStore createObject:obj withCallback:^BOOL(UploadProgress *progress) {
        // Check
        [self checkResult:progress];
        
        if(progress.isComplete) {
            [self subTestSetUserMetadata1:progress.atmosObject];
        }
        
        return YES;
    } withLabel:@"subTestSetUserMetadata1"];
    
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:TIMEOUT];
    [obj release];
    
}


- (void) subTestDeleteObjectMetadata2:(AtmosObject*)atmosObject
{
    // Read back the metadata and verify that key1 is gone.
    [atmosStore getAllMetadataForId:atmosObject.atmosId withCallback:^(AtmosObjectResult *result) {
        [self checkResult:result];
        
        GHAssertNil([result.atmosObject.userRegularMeta objectForKey:@"key1"], @"Key1 should have been nil");
        GHAssertEqualStrings([result.atmosObject.userRegularMeta objectForKey:@"key2"], @"value2" , @"key2 should have been value2");
        
        // Notify async test complete.
        [self notify:kGHUnitWaitStatusSuccess 
         forSelector:@selector(testDeleteObjectMetadata)];
        
    } withLabel:@"subTestDeleteObjectMetadata2"];
}

- (void) subTestDeleteObjectMetadata1:(AtmosObject*)atmosObject
{
    // Add the ID to cleanup
    [cleanup addObject:atmosObject.atmosId];
    
    // Delete one of the metadata values
    AtmosObject *delObj = [[AtmosObject alloc] init];
    delObj.atmosId = atmosObject.atmosId;
    delObj.requestTags = [NSMutableSet setWithObject:@"key1"];
    [atmosStore deleteObjectMetadata:delObj withCallback:^(AtmosResult *result) {
        [self checkResult:result];
        [self subTestDeleteObjectMetadata2:atmosObject];
    } withLabel:@""];
    [delObj release];
}

- (void) testDeleteObjectMetadata
{
    [self prepare];
    
    // Create an object with some metadata
    AtmosObject *obj = [[AtmosObject alloc] init];
    obj.userRegularMeta = [NSMutableDictionary 
                           dictionaryWithObjectsAndKeys:@"value1",@"key1", 
                           @"value2",@"key2", nil];
    [atmosStore createObject:obj withCallback:^BOOL(UploadProgress *progress) {
        // Check
        [self checkResult:progress];
        
        if(progress.isComplete) {
            [self subTestDeleteObjectMetadata1:progress.atmosObject];
        }
        
        return YES;
    } withLabel:@"testDeleteObjectMetadata"];
    
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:TIMEOUT];
    [obj release];

}

- (void) testUpdateObject
{
    
}

- (void) testReadObjectRange
{
    
}

- (void) testUpdateObjectRange
{
}



@end
