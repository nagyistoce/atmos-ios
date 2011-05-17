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

@synthesize atmosStore,cleanup,failure;


- (void)checkResult:(AtmosResult*)result 
{
    if(!result.wasSuccessful) {
        GHTestLog(@"request failed: %@", result.error.errorMessage);
    }
    GHAssertTrue(result.wasSuccessful, @"Request failed");
    GHAssertNil(result.error, @"Result error should be Nil on success");
}

- (void)checkFailure
{
    if(self.failure != nil) {
        [self failWithException:failure];
    }
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
    creds.accessPoint=@"192.168.246.152";
    creds.httpProtocol=@"http";
    creds.portNumber=80;
    
    // Set-up code here.
    atmosStore = [[AtmosStore alloc] init];
    atmosStore.atmosCredentials = creds;
    [creds release];
    
    // Clear the cleanup
    cleanup = [[NSMutableArray alloc] init];
    
    failure = nil;
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
         @try {
             GHAssertFalse(result.wasSuccessful, 
                           @"Method should have failed");
             GHAssertNotNil(result.error, 
                            @"Result should contain error");
             GHAssertTrue(result.error.errorCode == 1032, 
                          @"Expected error code 1032, got %d",
                          result.error.errorCode);
         }
         @catch (NSException *exception) {
             self.failure = exception;
             [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testGetListableTags)];
             return;
         }
         
         [self notify:kGHUnitWaitStatusSuccess 
          forSelector:@selector(testSignatureFailure)];
     }
                      withLabel:@"testSignatureFailure"];
    
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:TIMEOUT];
    [self checkFailure];
}

- (void)testGetListableTags
{
    
    // Call prepare to setup the asynchronous action.
    // This helps in cases where the action is synchronous and the
    // action occurs before the wait is actually called.
    [self prepare];
    
    [atmosStore getListableTags:nil 
                   withCallback:^(GetListableTagsResult* result){
                       @try {
                           [self checkResult:result];
                           GHAssertNotNil(result.tags, @"Tags should be non-nil");
                           GHAssertTrue([result.tags count]>0, 
                                        @"Tags count should be at least one, was %d", 
                                        [result.tags count]);
                       }
                       @catch (NSException *exception) {
                           self.failure = exception;
                           [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testGetListableTags)];
                           return;
                       }
                       
                       [self notify:kGHUnitWaitStatusSuccess 
                        forSelector:@selector(testGetListableTags)];
                   }
                      withLabel:@"tetGetListableTags"];
    
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:TIMEOUT];
    [self checkFailure];
}

- (void)subTestListObjects1:(AtmosObject*)atmosObject
{
    // Check and make sure we can find the object
    GHTestLog(@"Created AtmosObject %@", atmosObject.atmosId);
    [cleanup addObject:atmosObject.atmosId];
    
    
    [atmosStore listObjects:@"listable" 
               withCallback:^(ListObjectsResult *result) {
                   @try {
                       [self checkResult:result];
                       
                       NSLog(@"results contains %@", [result.objects description] );
                       
                       // Make sure array contains our ID.
                       GHAssertTrue(
                                    [result.objects containsObject:atmosObject],
                                    @"List objects result didn't include %@",
                                    atmosObject.atmosId);
                       
                   }
                   @catch (NSException *exception) {
                       self.failure = exception;
                       [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testListObjects)];
                       return;
                   }
                   
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
        @try {
            // Check
            [self checkResult:progress];
            
            if(progress.isComplete) {
                [self subTestListObjects1:progress.atmosObject];
            }
        }
        @catch (NSException *exception) {
            self.failure = exception;
            [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testListObjects)];
            return NO;
        }
        
        return YES;
    } withLabel:@"testCreateListableObject1"];
    
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:TIMEOUT];
    [obj release];
    [self checkFailure];
    
}

-(void)subTestCreateEmptyObject1:(AtmosObject*) atmosObject
{
    GHTestLog(@"Created AtmosObject %@", atmosObject.atmosId);
    [cleanup addObject:atmosObject.atmosId];
    
    // Read it back
    [atmosStore readObject:atmosObject 
              withCallback:^BOOL(DownloadProgress *progress) {
                  @try {
                      [self checkResult:progress];
                      if(progress.isComplete) {
                          // Check results
                          GHAssertTrue(0 == progress.atmosObject.data.length, 
                                       @"Expected data to be empty, was %@",
                                       progress.atmosObject.data.length);
                          [self notify:kGHUnitWaitStatusSuccess 
                           forSelector:@selector(testCreateEmptyObject)];
                      }
                  }
                  @catch (NSException *exception) {
                      self.failure = exception;
                      [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testCreateEmptyObject)];
                      return NO;
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
                    @try {
                        [self checkResult:progress];
                        
                        if(progress.isComplete) {
                            // Read back the created object.  Tweak the data
                            // before readback to ensure it gets rewritten 
                            // properly.
                            progress.atmosObject.data = 
                            [NSData dataWithBase64EncodedString:@"SGVsbG8gV29ybGQh"]; // Hello World!
                            [self subTestCreateEmptyObject1:progress.atmosObject];
                        }
                    }
                    @catch (NSException *exception) {
                        self.failure = exception;
                        [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testCreateEmptyObject)];
                        return NO;
                    }
                    return YES;
                } 
                   withLabel:@"testCreateEmptyObject"];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:TIMEOUT];
    [obj release];
    [self checkFailure];
    
}

- (void)subTestDeleteObject2:(AtmosObject*)atmosObject
{
    // Check to make sure the object was deleted.  Should see an error
    // on readObject
    [atmosStore readObject:atmosObject
              withCallback:^BOOL(DownloadProgress *progress) {
                  @try {
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
                  }
                  @catch (NSException *exception) {
                      self.failure = exception;
                      [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testDeleteObject)];
                      return NO;
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
                    @try {
                        [self checkResult:result];
                        [self subTestDeleteObject2:atmosObject];
                    }
                    @catch (NSException *exception) {
                        self.failure = exception;
                        [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testDeleteObject)];
                    }
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
                    @try {
                        [self checkResult:progress];
                        
                        if(progress.isComplete) {
                            [self subTestDeleteObject1:progress.atmosObject];
                        }
                    }
                    @catch (NSException *exception) {
                        self.failure = exception;
                        [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testDeleteObject)];
                        return NO;
                    }
                    return YES;
                } 
                   withLabel:@"testCreateEmptyObject"];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:TIMEOUT];
    [obj release];
    [self checkFailure];
    
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
                  @try {
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
                      }
                  }
                  @catch (NSException *exception) {
                      self.failure = exception;
                      [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testCreateObjectWithContent)];
                      return NO;
                  }
                  // Notify async test complete.
                  [self notify:kGHUnitWaitStatusSuccess 
                   forSelector:@selector(testCreateObjectWithContent)];
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
                    @try {
                        [self checkResult:progress];
                        
                        if(progress.isComplete){
                            GHAssertNotNil(progress.atmosObject,                                  
                                           @"Expected New ID to be non-Nil");
                            [self subTestCreateObjectWithContent1:obj];
                        }
                    }
                    @catch (NSException *exception) {
                        self.failure = exception;
                        [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testCreateObjectWithContent)];
                        return NO;
                    }
                    
                    return YES;
                } 
                   withLabel:@"testCreateObjectWithContent"];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:TIMEOUT];
    [obj release];
    [self checkFailure];
    
}

- (void)subTestGetSystemMetadata1:(AtmosObject*)obj
{
    // Add new object to cleanup list
    [cleanup addObject:obj.atmosId];
    
    // Read the object back and check contents.
    [atmosStore getAllSytemMetadataForId:obj.atmosId
                            withCallback:^(AtmosObjectResult *result) {
                                @try {
                                    [self checkResult:result];
                                    
                                    GHAssertEquals(12, 
                                                   [[result.atmosObject.systemMeta objectForKey:@"size"] integerValue], 
                                                   @"Size should be 12");
                                }
                                @catch (NSException *exception) {
                                    self.failure = exception;
                                   [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testGetSystemMetadata)];
                                    return;
                                }
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
                    @try {
                        [self checkResult:progress];
                        
                        if(progress.isComplete){
                            GHAssertNotNil(progress.atmosObject,                                  
                                           @"Expected New ID to be non-Nil");
                            [self subTestGetSystemMetadata1:obj];
                        }
                    }
                    @catch (NSException *exception) {
                        self.failure = exception;
                        [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testGetSystemMetadata)];
                        return NO;
                    }
                    
                    return YES;
                } 
                   withLabel:@"testGetSystemMetadata"];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:TIMEOUT];
    [obj release];
    [self checkFailure];
}

- (void) subTestGetServerOffset1
{
    // Make sure we can still get listable tags without error
    // after setting time offset
    [atmosStore getListableTags:nil 
                   withCallback:^(GetListableTagsResult *tags) {
                       @try {
                           [self checkResult:tags];
                       }
                       @catch (NSException *exception) {
                           self.failure = exception;
                           [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testGetServerOffset)];
                           return;
                       }
                       
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
        @try {
            [self checkResult:result];
            GHTestLog(@"Server offset: %lf seconds", result.offset);
            atmosStore.timeOffset = result.offset;
            [self subTestGetServerOffset1];
        }
        @catch (NSException *exception) {
            self.failure = exception;
            [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testGetServerOffset)];
            return;
        }
    } withLabel:@"testGetServerOffset"];
    
    
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:TIMEOUT];
    [self checkFailure];
   
}

- (void) subTestSetUserMetadata2:(AtmosObject*)atmosObject
{
    // Read the object back and check metadata
    [atmosStore getAllMetadataForId:atmosObject.atmosId 
                       withCallback:^(AtmosObjectResult *result) {
                           @try {
                               [self checkResult:result];
                               GHAssertEqualStrings(@"newvalue", 
                                                    [result.atmosObject.userRegularMeta 
                                                     objectForKey:@"listable"], 
                                                    @"Metadata value was not correct");
                               
                               GHAssertNil([result.atmosObject.userListableMeta objectForKey:@"listable"], @"metadata with name listable should not be in listable dictionary");
                           }
                           @catch (NSException *exception) {
                               self.failure = exception;
                               [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testSetUserMetadata)];
                               return;
                           }
                           
                           
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
        @try {
            [self checkResult:result];
            
            [self subTestSetUserMetadata2:atmosObject];
        }
        @catch (NSException *exception) {
            self.failure = exception;
            [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testSetUserMetadata)];
            return;
        }
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
        @try {
            // Check
            [self checkResult:progress];
            
            if(progress.isComplete) {
                [self subTestSetUserMetadata1:progress.atmosObject];
            }
        }
        @catch (NSException *exception) {
            self.failure = exception;
            [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testSetUserMetadata)];
            return NO;
        }
        
        return YES;
    } withLabel:@"subTestSetUserMetadata1"];
    
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:TIMEOUT];
    [obj release];
    [self checkFailure];
    
}


- (void) subTestDeleteObjectMetadata2:(AtmosObject*)atmosObject
{
    // Read back the metadata and verify that key1 is gone.
    [atmosStore getAllMetadataForId:atmosObject.atmosId withCallback:^(AtmosObjectResult *result) {
        @try {
            [self checkResult:result];
            
            GHAssertNil([result.atmosObject.userRegularMeta objectForKey:@"key1"], @"Key1 should have been nil");
            GHAssertEqualStrings([result.atmosObject.userRegularMeta objectForKey:@"key2"], @"value2" , @"key2 should have been value2");
        }
        @catch (NSException *exception) {
            self.failure = exception;
            [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testDeleteObjectMetadata)];
            return;
        }
        
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
        @try {
            [self checkResult:result];
            [self subTestDeleteObjectMetadata2:atmosObject];
        }
        @catch (NSException *exception) {
            self.failure = exception;
            [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testDeleteObjectMetadata)];
            return;
        }
    } withLabel:@"subTestDeleteObjectMetadata1"];
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
        @try {
            // Check
            [self checkResult:progress];
            
            if(progress.isComplete) {
                [self subTestDeleteObjectMetadata1:progress.atmosObject];
            }
        }
        @catch (NSException *exception) {
            self.failure = exception;
            [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testDeleteObjectMetadata)];
            return NO;
        }
        
        return YES;
    } withLabel:@"testDeleteObjectMetadata"];
    
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:TIMEOUT];
    [obj release];
    [self checkFailure];
    
}

- (void) subTestUpdateObject3:(AtmosObject*)atmosObject
{
    // Check results
    GHAssertNotNil(atmosObject.data, 
                   @"Expected data to be non-Nil");
    GHAssertEqualStrings(@"Hello Me!",
                         [NSString stringWithUTF8String:[atmosObject.data bytes]], 
                         @"Expected strings to match");
    GHAssertEqualStrings([atmosObject.userRegularMeta objectForKey:@"key1"], 
                         @"newvalue", @"Expected key1 to be updated");
    GHAssertEqualStrings([atmosObject.userRegularMeta objectForKey:@"key2"], 
                         @"value2", @"Expected key2 to be unmodified");
    
    // Notify async test complete.
    [self notify:kGHUnitWaitStatusSuccess 
     forSelector:@selector(testUpdateObject)];
}

- (void) subTestUpdateObject2:(AtmosObject*)atmosObject 
{
    AtmosObject *obj3 = [[AtmosObject alloc] init];
    obj3.dataMode = kDataModeBytes;
    obj3.atmosId = atmosObject.atmosId;
    [obj3 retain];
    [atmosStore readObject:obj3 withCallback:^BOOL(DownloadProgress *progress) {
        @try {
            [self checkResult:progress];
            if(progress.isComplete){
                [obj3 release];
                [self subTestUpdateObject3:progress.atmosObject];
            }
        }
        @catch (NSException *exception) {
            self.failure = exception;
            [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testUpdateObject)];
            return NO;
        }
        
        
        return YES;
    } withLabel:@"subTestUpdateObject2"];
    
    [obj3 release];
}

- (void) subTestUpdateObject1:(AtmosObject*)atmosObject
{
    // Queue object for cleanup
    [cleanup addObject:atmosObject.atmosId];
    
    // Update the object and change some stuff
    AtmosObject *obj2 = [[AtmosObject alloc] init];
    obj2.atmosId = atmosObject.atmosId;
    obj2.dataMode = kDataModeBytes;
    obj2.data = [NSData dataWithBytes:[@"Hello Me!" UTF8String] length:10];
    obj2.userRegularMeta = [NSMutableDictionary 
                            dictionaryWithObjectsAndKeys:@"newvalue",@"key1", nil];
    [obj2 retain];
    
    [atmosStore updateObject:obj2 withCallback:^BOOL(UploadProgress *progress) {
        @try {
            [self checkResult:progress];
            if(progress.isComplete){
                if(progress.wasSuccessful) {
                    [obj2 release];
                    // Check results
                    [self subTestUpdateObject2:progress.atmosObject];
                }
            } 
        }
        @catch (NSException *exception) {
            self.failure = exception;
            [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testUpdateObject)];
            return NO;
        }
        return YES;
        
    } withLabel:@"subTestUpdateObject1"];
    
    [obj2 release];
}

- (void) testUpdateObject
{
    [self prepare];
    
    // Create an object with content
    AtmosObject *obj = [[AtmosObject alloc] init];
    obj.dataMode = kDataModeBytes;
    obj.data = [NSData dataWithBytes:[@"Hello World" UTF8String] length:12];
    obj.userRegularMeta = [NSMutableDictionary 
                           dictionaryWithObjectsAndKeys:@"value1",@"key1", 
                           @"value2",@"key2", nil];
    
    [atmosStore createObject:obj 
                withCallback:^BOOL(UploadProgress *progress) {
                    @try {
                        [self checkResult:progress];
                        
                        if(progress.isComplete){
                            GHAssertNotNil(progress.atmosObject,                                  
                                           @"Expected New ID to be non-Nil");
                            [self subTestUpdateObject1:progress.atmosObject];
                        }
                    }
                    @catch (NSException *exception) {
                        self.failure = exception;
                        [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testUpdateObject)];
                        return NO;
                    }
                    
                    return YES;
                } 
                   withLabel:@"testUpdateObject"];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:TIMEOUT];
    [obj release];
    [self checkFailure];
    
}

- (void) subTestReadObjectRange1:(AtmosObject*)atmosObject
{
    // Enqueue object ID for cleanup
    [cleanup addObject:atmosObject.atmosId];
    
    // Read back data
    AtmosObject *obj2 = [[AtmosObject alloc] initWithObjectId:atmosObject.atmosId];
    obj2.dataMode = kDataModeBytes;
    AtmosRange *range = [[AtmosRange alloc] init];
    range.location = 6;
    range.length = 6;
    
    [atmosStore readObjectRange:obj2 range:range withCallback:^BOOL(DownloadProgress *progress) {
        @try {
            [self checkResult:progress];
            if(progress.isComplete) {
                // Check string
                GHAssertNotNil(progress.atmosObject.data, @"Object data should be non-nil");
                GHAssertTrue(progress.atmosObject.data.length==6, @"Data length wrong.  Expected 6 got %lu", progress.atmosObject.data.length);
                NSString *str = [NSString stringWithCString:[progress.atmosObject.data bytes] encoding:NSUTF8StringEncoding];
                GHAssertEqualStrings(str, @"World", @"String content wrong");
                // Notify async test complete.
                [self notify:kGHUnitWaitStatusSuccess 
                 forSelector:@selector(testReadObjectRange)];
            }
        }
        @catch (NSException *exception) {
            self.failure = exception;
            [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testReadObjectRange)];
            return NO;
        }
        
        return YES;
    } withLabel:@"subTestReadObjectRange1"];
    
    [obj2 release];
    [range release];
}

- (void) testReadObjectRange
{
    [self prepare];
    
    // Create an object with content
    AtmosObject *obj = [[AtmosObject alloc] init];
    obj.dataMode = kDataModeBytes;
    obj.data = [NSData dataWithBytes:[@"Hello World" UTF8String] length:12];
    obj.userRegularMeta = [NSMutableDictionary 
                           dictionaryWithObjectsAndKeys:@"value1",@"key1", 
                           @"value2",@"key2", nil];
    
    [atmosStore createObject:obj 
                withCallback:^BOOL(UploadProgress *progress) {
                    @try {
                        [self checkResult:progress];
                        
                        if(progress.isComplete){
                            GHAssertNotNil(progress.atmosObject,                                  
                                           @"Expected New ID to be non-Nil");
                            [self subTestReadObjectRange1:progress.atmosObject];
                        }
                    }
                    @catch (NSException *exception) {
                        self.failure = exception;
                        [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testReadObjectRange)];
                        return NO;
                    }
                    
                    return YES;
                } 
                   withLabel:@"testUpdateObject"];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:TIMEOUT];
    [obj release];
    [self checkFailure];
}

- (void) subTestUpdateObjectRange2:(AtmosObject*)atmosObject
{
    // Read back data
    AtmosObject *obj2 = [[AtmosObject alloc] initWithObjectId:atmosObject.atmosId];
    obj2.dataMode = kDataModeBytes;
    
    [atmosStore readObject:obj2 withCallback:^BOOL(DownloadProgress *progress) {
        @try {
            [self checkResult:progress];
            if(progress.isComplete) {
                // Check string
                GHAssertNotNil(progress.atmosObject.data, @"Object data should be non-nil");
                GHAssertTrue(progress.atmosObject.data.length==12, @"Data length wrong.  Expected 12 got %lu", progress.atmosObject.data.length);
                NSString *str = [NSString stringWithCString:[progress.atmosObject.data bytes] encoding:NSUTF8StringEncoding];
                GHAssertEqualStrings(str, @"Hello Atmos", @"String content wrong");
                // Notify async test complete.
                [self notify:kGHUnitWaitStatusSuccess 
                 forSelector:@selector(testUpdateObjectRange)];
            }
        }
        @catch (NSException *exception) {
            self.failure = exception;
            [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testUpdateObjectRange)];
            return NO;
        }
        
        return YES;
    } withLabel:@"subTestUpdateObjectRange2"];
    
    [obj2 release];
    
}

- (void) subTestUpdateObjectRange1:(AtmosObject*)atmosObject
{
    // Enqueue object ID for cleanup
    [cleanup addObject:atmosObject.atmosId];

    // Update a section of the object
    AtmosObject *obj2 = [[AtmosObject alloc] initWithObjectId:atmosObject.atmosId];
    obj2.dataMode = kDataModeBytes;
    AtmosRange *range = [[AtmosRange alloc] init];
    range.location = 6;
    range.length = 5;
    obj2.data = [NSData dataWithBytes:[@"Atmos" UTF8String] length:5];

    [atmosStore updateObjectRange:obj2 range:range withCallback:^BOOL(UploadProgress *progress) {
        @try {
            [self checkResult:progress];
            
            if(progress.isComplete){
                [self subTestUpdateObjectRange2:progress.atmosObject];
            }
        }
        @catch (NSException *exception) {
            self.failure = exception;
            [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testUpdateObjectRange)];
            return NO;
        }
        
        return YES;
    } withLabel:@"subTestUpdateObjectRange1"];
    
    [obj2 release];
    [range release];
}

- (void) testUpdateObjectRange
{
    [self prepare];
    
    // Create an object with content
    AtmosObject *obj = [[AtmosObject alloc] init];
    obj.dataMode = kDataModeBytes;
    obj.data = [NSData dataWithBytes:[@"Hello World" UTF8String] length:12];
    obj.userRegularMeta = [NSMutableDictionary 
                           dictionaryWithObjectsAndKeys:@"value1",@"key1", 
                           @"value2",@"key2", nil];
    
    [atmosStore createObject:obj 
                withCallback:^BOOL(UploadProgress *progress) {
                    @try {
                        [self checkResult:progress];
                        
                        if(progress.isComplete){
                            GHAssertNotNil(progress.atmosObject,                                  
                                           @"Expected New ID to be non-Nil");
                            [self subTestUpdateObjectRange1:progress.atmosObject];
                        }
                    }
                    @catch (NSException *exception) {
                        self.failure = exception;
                        [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testUpdateObjectRange)];
                        return NO;
                    }
                    
                    return YES;
                } 
                   withLabel:@"testUpdateObject"];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:TIMEOUT];
    [obj release];
    [self checkFailure];
}



@end
