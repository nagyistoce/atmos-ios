//
//  AtmosTests.m
//  atmos-tests
//
//  Created by Jason Cwik on 5/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <GHUnitIOS/GHUnit.h> 
#import "AtmosTests.h"
#import "UploadProgress.h"
#import "NSData+Additions.h"

// Timeout for unit tests
#define TIMEOUT 10.0


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
    creds.accessPoint=@"192.168.246.152";
    creds.httpProtocol=@"http";
    creds.portNumber=80;
    
    // Set-up code here.
    atmosStore = [[AtmosStore alloc] init];
    atmosStore.atmosCredentials = creds;
    
    // Clear the cleanup
    self.cleanup = [[NSMutableArray alloc] init];
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
    
    // Request deletion of any objects created
    for (NSString *oid in self.cleanup) {
        [atmosStore deleteObject:[[AtmosObject alloc] initWithObjectId:oid]
                    withCallback:^(AtmosResult *result) {
                        // Do nothing
                    } withLabel:@""];
    }
    
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
                   
                   NSLog(@"results contains keys %@", [result.objects.allKeys description] );

                   // Make sure array contains our ID.
                   GHAssertTrue(
                        [result.objects.allKeys containsObject:atmosObject.atmosId],
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

@end
