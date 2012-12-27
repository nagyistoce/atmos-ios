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

@synthesize atmosStore,cleanup,failure,settings;

#define FN_CHARS "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-_=+*,!#%$&()"

char outerChars[] = FN_CHARS;
char innerChars[] = FN_CHARS " "; // No leading or trailing spaces

-(NSString*) generateFilename:(int)length includeExtension:(BOOL)includeExtension {
    NSMutableString *fname = [[[NSMutableString alloc] init] autorelease];
    
    for(int i=0; i<length; i++) {
        if(i == 0 || i == (length-1)) {
            [fname appendFormat:@"%c", outerChars[random()%strlen(outerChars)]];
        } else {
            [fname appendFormat:@"%c", innerChars[random()%strlen(innerChars)]];
        }
    }
    
    if(includeExtension) {
        [fname appendString:@"."];
        for(int j=0; j<3; j++) {
            [fname appendFormat:@"%c", outerChars[rand()%strlen(outerChars)]];            
        }
    }
    
    return fname;
}

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
    
    // Read the Credentials and other settings from 
    // settings.plist
    NSString* plistPath = [[NSBundle mainBundle] pathForResource:@"settings" ofType:@"plist"];
    if(!plistPath) {
        [NSException raise:@"SettingsNotFound" format:@"Could not find settings.plist in application bundle.  Copy settings.plist.template to settings.plist and configure for your test environment."];
    }
    self.settings = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    //NSLog(@"Settings loaded: %@", self.settings);
    AtmosCredentials *creds = [[AtmosCredentials alloc] init];
    
    creds.tokenId=[self.settings valueForKey:@"UID"];
    creds.sharedSecret=[self.settings valueForKey:@"secret"];
    creds.accessPoint=[self.settings valueForKey:@"host"];
    creds.portNumber=[[self.settings valueForKey:@"port"] integerValue];
    creds.httpProtocol= creds.portNumber == 443?@"https":@"http";
    
    // Set-up code here.
    AtmosStore *atmos = [[AtmosStore alloc] init];
    atmos.atmosCredentials = creds;
    self.atmosStore = atmos;
    [creds release];
    [atmos release];
    
    // Clear the cleanup
    self.cleanup = [NSMutableArray array];
    
    failure = nil;
    
    // Seed the random number generator for creating filenames
    srandomdev();
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
    
    self.cleanup = nil;
    self.atmosStore = nil;
    failure = nil;
    
}

NSString *xml_input = @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"\
"<policy>\n" \
"    <expiration>2012-12-01T12:00:00.000Z</expiration>\n"\
"    <max-uploads>1</max-uploads>\n"\
"    <source>\n"\
"        <allow>127.0.0.0/24</allow>\n"\
"    </source>\n"\
"    <content-length-range from=\"10\" to=\"11000\"/>\n"\
"    <form-field name=\"x-emc-redirect-url\"></form-field>\n"\
"    <form-field name=\"x-emc-meta\" optional=\"true\">\n"\
"        <matches>^(\\w+=\\w+)|((\\w+=\\w+),(\\w+, \\w+))$</matches>\n"\
"    </form-field>\n"\
"</policy>\n";

NSString *xml_output = @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"\
"<policy>\n"\
"  <expiration>2012-12-01T12:00:00Z</expiration>\n"\
"  <max-uploads>1</max-uploads>\n"\
"  <source>\n"\
"    <allow>127.0.0.0/24</allow>\n"\
"  </source>\n"\
"  <content-length-range from=\"10\" to=\"11000\"/>\n"\
"  <form-field name=\"x-emc-redirect-url\"/>\n"\
"  <form-field name=\"x-emc-meta\" optional=\"true\">\n"\
"    <matches>^(\\w+=\\w+)|((\\w+=\\w+),(\\w+, \\w+))$</matches>\n"\
"  </form-field>\n"\
"</policy>\n";


- (void)testXmlParse
{
    TNSPolicyType *policy;
    
    NSLog(@"XML: %@", xml_input);
    const char *xml_bytes = [xml_input UTF8String];
    
    policy = [TNSPolicyType fromPolicy:[NSData dataWithBytes:xml_bytes length:strlen(xml_bytes)]];
    
    GHAssertNotNil(policy, @"Failed to parse policy");
    GHAssertNotNil(policy.expiration, @"Expiration not set");
    GHAssertEquals(1354363200.0, [policy.expiration timeIntervalSince1970], @"Expiration incorrect");
    GHAssertNotNil(policy.maxUploads, @"Max uploads not set");
    GHAssertEquals(1, [policy.maxUploads intValue], @"Max uploads incorrect");
    GHAssertNil(policy.maxDownloads, @"Max downloads should not be set");
    GHAssertNotNil(policy.source, @"Source no set");
    GHAssertEquals(1, (int)policy.source.allow.count, @"Allow count incorrect");
    GHAssertEquals(0, (int)policy.source.disallow.count, @"Disallow count incorrect");
    GHAssertEqualStrings(@"127.0.0.0/24", (NSString*)policy.source.allow[0], @"Allow IP range incorrect");
    GHAssertEquals(10, [policy.contentLengthRange.from intValue], @"Content length range from incorrect");
    GHAssertEquals(11000, [policy.contentLengthRange.to intValue], @"Policy range to incorrect");
    GHAssertEquals(2, (int)policy.formField.count, @"Incorrect form field count");
    GHAssertEqualStrings(@"x-emc-redirect-url", ((TNSFormFieldType*)policy.formField[0]).name, @"First form field name incorrect");
    GHAssertNil(((TNSFormFieldType*)policy.formField[0]).optional, @"First form field should not have optional set.");
    GHAssertEquals(0, (int)((TNSFormFieldType*)policy.formField[0]).contains.count, @"First form field should not have any contains elements");
    GHAssertEquals(0, (int)((TNSFormFieldType*)policy.formField[0]).matches.count, @"First form field should not have any contains elements");
    GHAssertEquals(0, (int)((TNSFormFieldType*)policy.formField[0]).endsWith.count, @"First form field should not have any contains elements");
    GHAssertEquals(0, (int)((TNSFormFieldType*)policy.formField[0]).eq.count, @"First form field should not have any contains elements");
    GHAssertEqualStrings(@"x-emc-meta", ((TNSFormFieldType*)policy.formField[1]).name, @"Second form field name incorrect");
    GHAssertNotNil(((TNSFormFieldType*)policy.formField[1]).optional, @"Second form field should have optional set");
    GHAssertEquals(YES, [((TNSFormFieldType*)policy.formField[1]).optional boolValue], @"Second form field should be optional");
    GHAssertEquals(0, (int)((TNSFormFieldType*)policy.formField[1]).contains.count, @"Second form field should not have any contains elements");
    GHAssertEquals(1, (int)((TNSFormFieldType*)policy.formField[1]).matches.count, @"Second form field should have one contains elements");
    GHAssertEquals(0, (int)((TNSFormFieldType*)policy.formField[1]).endsWith.count, @"Second form field should not have any contains elements");
    GHAssertEquals(0, (int)((TNSFormFieldType*)policy.formField[1]).eq.count, @"Second form field should not have any contains elements");
    GHAssertEqualStrings(@"^(\\w+=\\w+)|((\\w+=\\w+),(\\w+, \\w+))$", ((TNSFormFieldType*)policy.formField[1]).matches[0], @"Second form field matches expression incorrect");
}

- (void)testXmlSerialize
{
    TNSPolicyType *policy;
    TNSFormFieldType *field;
    
    // Build a policy object and then serialize it to XML.
    policy = [[TNSPolicyType alloc] init];
    
    policy.expiration = [NSDate dateWithTimeIntervalSince1970:1354363200.0];
    policy.maxUploads = [NSNumber numberWithInt:1];
    policy.source = [[[TNSSourceType alloc] init] autorelease];
    policy.source.allow = [NSMutableArray arrayWithObject:@"127.0.0.0/24"];
    TNSContentLengthRangeType *contentRange = [[TNSContentLengthRangeType alloc] init];
    contentRange.from = [NSNumber numberWithLongLong:10];
    contentRange.to = [NSNumber numberWithLongLong:11000];
    policy.contentLengthRange = contentRange;
    [contentRange release];
    field = [[TNSFormFieldType alloc] init];
    field.name = @"x-emc-redirect-url";
    policy.formField = [NSMutableArray arrayWithObject:field];
    [field release];
    field = [[TNSFormFieldType alloc] init];
    field.name = @"x-emc-meta";
    field.optional = [NSNumber numberWithBool:YES];
    field.matches = [NSMutableArray arrayWithObject:@"^(\\w+=\\w+)|((\\w+=\\w+),(\\w+, \\w+))$"];
    [policy.formField addObject:field];
    [field release];
    
    NSData *xml = [policy toPolicy];
    [policy release];
    
    // Append a null terminator to make it a CString
    char *xmlCStr = malloc([xml length] +1);
    [xml getBytes:xmlCStr];
    xmlCStr[[xml length]] = 0;
    
    // Back to a string so we can compare it.
    NSString *xmlStr = [NSString stringWithCString:xmlCStr encoding:NSUTF8StringEncoding];
    
    free(xmlCStr);
    
    // Compare
    GHAssertEqualStrings(xml_output, xmlStr, @"Serialized XML does not match");
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
                  withToken:nil
                  withLimit:0
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
               } 
                  withLabel:@"subTestListObjects1"];
    
    
}
- (void)testListObjects
{
    [self prepare];
    
    AtmosObject *obj = [[AtmosObject alloc] init];
    NSMutableDictionary *userListableMeta = [[NSMutableDictionary alloc]
                                             initWithObjectsAndKeys:@"",@"listable", nil];
    obj.userListableMeta = userListableMeta;
    [userListableMeta release];
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

-(void) subTestListObjectsWithToken3:(AtmosObject*)atmosObject
                            withObj2:(AtmosObject*)atmosObject2
                         withResults:(NSMutableArray*)results
                           withToken:(NSString*)token
{
    GHTestLog(@"subTestListObjectsWithToken3, token:%@", token);
    
    // Continue until token is nil
    if(token == nil) {
        
        // Make sure array contains our IDs.
        GHAssertTrue(
                     [results containsObject:atmosObject],
                     @"List objects result didn't include %@",
                     atmosObject.atmosId);
        GHAssertTrue(
                     [results containsObject:atmosObject],
                     @"List objects result didn't include %@",
                     atmosObject2.atmosId);
        
        [results release];
        
        // Notify async test complete.
        [self notify:kGHUnitWaitStatusSuccess 
         forSelector:@selector(testListObjectsWithToken)];
    } else {
        [atmosStore listObjects:@"tokentest"
                      withToken:token 
                      withLimit:1
                   withCallback:^(ListObjectsResult *result) {
                       @try {
                           [self checkResult:result];
                           [results addObjectsFromArray:result.objects];
                       }   @catch (NSException *exception) {
                           self.failure = exception;
                           [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testListObjectsWithToken)];
                           return;
                       }
                       
                       [self subTestListObjectsWithToken3:atmosObject
                                                 withObj2:atmosObject2
                                              withResults:results
                                                withToken:result.token];
                       
                       
                       
                   } withLabel:@"subTestListObjectsWithToken3"];
    }
}

- (void)subTestListObjectsWithToken2:(AtmosObject*)atmosObject
                            withObj2:(AtmosObject*)atmosObject2
{
    // Check and make sure we can find the object
    GHTestLog(@"Created AtmosObject %@", atmosObject2.atmosId);
    [cleanup addObject:atmosObject2.atmosId];
    NSMutableArray *results = [[NSMutableArray alloc] init];

    
    [atmosStore listObjects:@"tokentest" 
                  withToken:nil
                  withLimit:1
               withCallback:^(ListObjectsResult *result) {
                   @try {
                       [self checkResult:result];
                       
                       // On the first pass, the token should be non-nil
                       GHAssertNotNil(result.token, 
                                      @"Token should be non-nil on first iteration");
                       [results addObjectsFromArray:result.objects];

                   }
                   @catch (NSException *exception) {
                       self.failure = exception;
                       [results release];
                       [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testListObjectsWithToken)];
                       return;
                   }
                   
                   [self subTestListObjectsWithToken3:atmosObject
                                             withObj2:atmosObject2
                                          withResults:results
                                            withToken:result.token];

               } 
                  withLabel:@"subTestListObjectsWithToken2"];
    
    
}

-(void) subTestListObjectsWithToken1:(AtmosObject*)atmosObject
{
    // Check and make sure we can find the object
    GHTestLog(@"Created AtmosObject %@", atmosObject.atmosId);
    [cleanup addObject:atmosObject.atmosId];
    
    
    AtmosObject *obj = [[AtmosObject alloc] init];
    NSMutableDictionary *userListableMeta = [[NSMutableDictionary alloc]
                                             initWithObjectsAndKeys:@"",@"tokentest", nil];
    obj.userListableMeta = userListableMeta;
    [userListableMeta release];
    [atmosStore createObject:obj withCallback:^BOOL(UploadProgress *progress) {
        @try {
            // Check
            [self checkResult:progress];
            
            if(progress.isComplete) {
                [self subTestListObjectsWithToken2:atmosObject
                                          withObj2:progress.atmosObject];
            }
        }
        @catch (NSException *exception) {
            self.failure = exception;
            [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testListObjectsWithToken)];
            return NO;
        }
        
        return YES;
    } withLabel:@"subTestListObjectsWithToken1"];
    
    [obj release];
}


/*@
 * Create more than one object and list with a limit of one and make
 * sure the token is set.  Iterate through the token and make sure all
 * objects are returned.
 */
-(void) testListObjectsWithToken
{
    [self prepare];
    
    AtmosObject *obj = [[AtmosObject alloc] init];
    NSMutableDictionary *userListableMeta = [[NSMutableDictionary alloc]
                                             initWithObjectsAndKeys:@"",@"tokentest", nil];
    obj.userListableMeta = userListableMeta;
    [userListableMeta release];
    [atmosStore createObject:obj withCallback:^BOOL(UploadProgress *progress) {
        @try {
            // Check
            [self checkResult:progress];
            
            if(progress.isComplete) {
                [self subTestListObjectsWithToken1:progress.atmosObject];
            }
        }
        @catch (NSException *exception) {
            self.failure = exception;
            [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testListObjects)];
            return NO;
        }
        
        return YES;
    } withLabel:@"testListObjectsWithToken"];
    
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
        if(!result.wasSuccessful) {
            NSLog(@"Failed to get server offset: %@", result.error);
        } else {
            NSLog(@"Server offset: %lf seconds", result.offset);
            atmosStore.timeOffset = result.offset;            
        }
        
        @try {
            [self checkResult:result];
            NSLog(@"Server offset: %lf seconds", result.offset);
            atmosStore.timeOffset = result.offset;
            [self subTestGetServerOffset1];
        }
        @catch (NSException *exception) {
            NSLog(@"Failed to get server offset: %@", exception.reason);
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


- (void)subTestCreateObjectWithContentOnPath1:(AtmosObject*)atmosObject
{
    // Add new object to cleanup list
    [cleanup addObject:atmosObject.atmosId];
    
    // Read the object back and check contents.
    AtmosObject *obj2 = [[AtmosObject alloc] init];
    obj2.data = nil;
    obj2.dataMode = kDataModeBytes;
    obj2.contentType = nil;
    obj2.objectPath = atmosObject.objectPath;
    [atmosStore readObject:obj2
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
                      [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testCreateObjectWithContentOnPath)];
                      return NO;
                  }
                  // Notify async test complete.
                  [self notify:kGHUnitWaitStatusSuccess 
                   forSelector:@selector(testCreateObjectWithContentOnPath)];
                  return YES;
                  
              } 
                 withLabel:@"subTestCreateObjectWithContentOnPath1"];
    [obj2 release];
}

- (void)testCreateObjectWithContentOnPath
{
    [self prepare];
    
    AtmosObject *obj = [[AtmosObject alloc] init];
    obj.dataMode = kDataModeBytes;
    obj.data = [NSData dataWithBytes:[@"Hello World" UTF8String] length:12];
    obj.contentType = @"text/foo";
    obj.objectPath = [NSString stringWithFormat:@"/%@/%@",
                      [self generateFilename:8 includeExtension:false],
                      [self generateFilename:8 includeExtension:true]];
    GHTestLog(@"Object Path: %@",obj.objectPath);
    [atmosStore createObject:obj 
                withCallback:^BOOL(UploadProgress *progress) {
                    @try {
                        [self checkResult:progress];
                        
                        if(progress.isComplete){
                            GHAssertNotNil(progress.atmosObject,                                  
                                           @"Expected New ID to be non-Nil");
                            [self subTestCreateObjectWithContentOnPath1:obj];
                        }
                    }
                    @catch (NSException *exception) {
                        self.failure = exception;
                        [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testCreateObjectWithContentOnPath)];
                        return NO;
                    }
                    
                    return YES;
                } 
                   withLabel:@"testCreateObjectWithContentOnPath"];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:TIMEOUT];
    [obj release];
    [self checkFailure];
    
}


- (void)subTestUnicodePathname1:(AtmosObject*)atmosObject
{
    // Add new object to cleanup list
    [cleanup addObject:atmosObject.atmosId];
    
    // Read the object back and check contents.
    AtmosObject *obj2 = [[AtmosObject alloc] init];
    obj2.data = nil;
    obj2.dataMode = kDataModeBytes;
    obj2.contentType = nil;
    obj2.objectPath = atmosObject.objectPath;
    [atmosStore readObject:obj2
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
                      [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testUnicodePathname)];
                      return NO;
                  }
                  // Notify async test complete.
                  [self notify:kGHUnitWaitStatusSuccess 
                   forSelector:@selector(testUnicodePathname)];
                  return YES;
                  
              } 
                 withLabel:@"subTestUnicodePathname1"];
    [obj2 release];
}


- (void) testUnicodePathname
{
    [self prepare];
    
    AtmosObject *obj = [[AtmosObject alloc] init];
    obj.dataMode = kDataModeBytes;
    obj.data = [NSData dataWithBytes:[@"Hello World" UTF8String] length:12];
    obj.contentType = @"text/foo";
    obj.objectPath = [NSString stringWithFormat:@"/%@/спасибо.txt",
                      [self generateFilename:8 includeExtension:false]];
    GHTestLog(@"Object Path: %@",obj.objectPath);
    [atmosStore createObject:obj 
                withCallback:^BOOL(UploadProgress *progress) {
                    @try {
                        [self checkResult:progress];
                        
                        if(progress.isComplete){
                            GHAssertNotNil(progress.atmosObject,                                  
                                           @"Expected New ID to be non-Nil");
                            [self subTestUnicodePathname1:obj];
                        }
                    }
                    @catch (NSException *exception) {
                        self.failure = exception;
                        [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testUnicodePathname)];
                        return NO;
                    }
                    
                    return YES;
                } 
                   withLabel:@"testUnicodePathname"];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:TIMEOUT];
    [obj release];
    [self checkFailure];
    
}

- (void) subTestDeleteObjectOnPath2:(AtmosObject*)atmosObject
{
    // Try to get object metadata... it should fail.
    [atmosStore getSystemMetadataForPath:atmosObject.objectPath metadata:nil withCallback:^(AtmosObjectResult *result) {
        @try {
            GHAssertFalse(result.wasSuccessful, @"Expected load after delete to fail!");
        }
        @catch (NSException *exception) {
            self.failure = exception;
            [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testDeleteObjectOnPath)];
        }
        // Notify async test complete
        [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testDeleteObjectOnPath)];
    } withLabel:@"subTestDeleteObjectOnPath2"];
}

- (void) subTestDeleteObjectOnPath1:(AtmosObject*)atmosObject
{
    // Delete the object
    AtmosObject *obj2 = [[AtmosObject alloc] init];
    obj2.objectPath = atmosObject.objectPath;
    
    [atmosStore deleteObject:obj2 withCallback:^(AtmosResult *result) {
        @try {
            [self checkResult:result];
            
            [self subTestDeleteObjectOnPath2:atmosObject];
        }
        @catch (NSException *exception) {
            self.failure = exception;
            [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testDeleteObjectOnPath)];
        }
        
    } withLabel:@"subTestDeleteObjectOnPath1"];
    
    [obj2 release];
}

- (void) testDeleteObjectOnPath
{
    [self prepare];
    
    AtmosObject *obj = [[AtmosObject alloc] init];
    obj.dataMode = kDataModeBytes;
    obj.data = [NSData dataWithBytes:[@"Hello World" UTF8String] length:12];
    obj.contentType = @"text/foo";
    obj.objectPath = [NSString stringWithFormat:@"/%@/%@",
                      [self generateFilename:8 includeExtension:false],
                      [self generateFilename:8 includeExtension:true]];
    GHTestLog(@"Object Path: %@",obj.objectPath);
    [atmosStore createObject:obj 
                withCallback:^BOOL(UploadProgress *progress) {
                    @try {
                        [self checkResult:progress];
                        
                        if(progress.isComplete){
                            GHAssertNotNil(progress.atmosObject,                                  
                                           @"Expected New ID to be non-Nil");
                            [self subTestDeleteObjectOnPath1:obj];
                        }
                    }
                    @catch (NSException *exception) {
                        self.failure = exception;
                        [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testDeleteObjectOnPath)];
                        return NO;
                    }
                    
                    return YES;
                } 
                   withLabel:@"testDeleteObjectOnPath"];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:TIMEOUT];
    [obj release];
    [self checkFailure];
    
}

- (void) subTestListDirectoryWithMetadata1:(AtmosObject*)atmosObject
withDirectory:(NSString *)dir
{
    // Queue object for cleanup
    [cleanup addObject:atmosObject.atmosId];
    
    // Read back the directory
    AtmosObject *dirObj = [[AtmosObject alloc] init];
    dirObj.objectPath = dir;
    
    [atmosStore listDirectoryWithAllMetadata:dirObj withToken:nil withLimit:0 withCallback:^(ListDirectoryResult *result) {
        @try {
            NSLog(@"listDirectoryWithAllMetadata callback");
            [self checkResult:result];
            
            // Find our object
            NSUInteger entIndex = [result.objects indexOfObject:atmosObject];
            GHAssertFalse(entIndex == NSNotFound, @"Object %@ not found in directory %@", atmosObject.objectPath,
                              dir);
            AtmosObject *dirEnt = [result.objects objectAtIndex:entIndex];
            GHAssertNotNil(dirEnt, @"Directory entry nil for index %@", entIndex);
            GHAssertTrue([[dirEnt.systemMeta valueForKey:@"size"] integerValue] == 12, @"Size metadata did not match");
            GHAssertEqualStrings([dirEnt.userRegularMeta valueForKey:@"key1"], @"value1", @"Value for key1 did not match");
            GHAssertEqualStrings([dirEnt.userRegularMeta valueForKey:@"key2"], @"value2", @"Value for key2 did not match");
                                
            [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testListDirectoryWithMetadata)];
        }
        @catch (NSException *exception) {
            self.failure = exception;
            [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testListDirectoryWithMetadata)];
        }
    } withLabel:@"subTestListDirectoryWithMetadata1"];
    [dirObj release];
}

- (void) testListDirectoryWithMetadata
{
    [self prepare];
    
    // Create an object with metadata
    NSString *dir = [NSString stringWithFormat:@"/%@/", [self generateFilename:8 includeExtension:NO]];
    
    AtmosObject *obj = [[AtmosObject alloc] init];
    obj.objectPath = [NSString stringWithFormat:@"%@%@", dir, [self generateFilename:8 includeExtension:YES]];
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
                            [self subTestListDirectoryWithMetadata1:progress.atmosObject withDirectory:dir];
                        }
                    }
                    @catch (NSException *exception) {
                        self.failure = exception;
                        [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testListDirectoryWithMetadata)];
                        return NO;
                    }
                    
                    return YES;
                } 
                   withLabel:@"testListDirectoryWithMetadata"];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:TIMEOUT];
    [obj release];
    [self checkFailure];
    
}

- (void) subTestListDirectoryWithSomeMetadata1:(AtmosObject*)atmosObject
                             withDirectory:(NSString *)dir
{
    // Queue object for cleanup
    [cleanup addObject:atmosObject.atmosId];
    
    // Read back the directory
    AtmosObject *dirObj = [[AtmosObject alloc] init];
    dirObj.objectPath = dir;
    
    [atmosStore listDirectoryWithMetadata:dirObj systemMetadata:nil userMetadata:[NSArray arrayWithObject:@"key1"] withToken:nil withLimit:0 withCallback:^(ListDirectoryResult *result) {
        @try {
            [self checkResult:result];
            
            // Find our object
            NSUInteger entIndex = [result.objects indexOfObject:atmosObject];
            GHAssertFalse(entIndex == NSNotFound, @"Object %@ not found in directory %@", atmosObject.objectPath,
                          dir);
            AtmosObject *dirEnt = [result.objects objectAtIndex:entIndex];
            GHAssertNotNil(dirEnt, @"Directory entry nil for index %@", entIndex);
            GHAssertNil([dirEnt.systemMeta valueForKey:@"size"], @"Size should not have been set");
            GHAssertEqualStrings([dirEnt.userRegularMeta valueForKey:@"key1"], @"value1", @"Value for key1 did not match");
            GHAssertNil([dirEnt.userRegularMeta valueForKey:@"key2"], @"key2 should not be set");
            
            [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testListDirectoryWithSomeMetadata)];
        }
        @catch (NSException *exception) {
            self.failure = exception;
            [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testListDirectoryWithSomeMetadata)];
        }
    } withLabel:@"subTestListDirectoryWithSomeMetadata1"];
    [dirObj release];
}

- (void) testListDirectoryWithSomeMetadata
{
    [self prepare];
    
    // Create an object with metadata
    NSString *dir = [NSString stringWithFormat:@"/%@/", [self generateFilename:8 includeExtension:NO]];
    
    AtmosObject *obj = [[AtmosObject alloc] init];
    obj.objectPath = [NSString stringWithFormat:@"%@%@", dir, [self generateFilename:8 includeExtension:YES]];
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
                            [self subTestListDirectoryWithSomeMetadata1:progress.atmosObject withDirectory:dir];
                        }
                    }
                    @catch (NSException *exception) {
                        self.failure = exception;
                        [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testListDirectoryWithSomeMetadata)];
                        return NO;
                    }
                    
                    return YES;
                } 
                   withLabel:@"testListDirectoryWithSomeMetadata"];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:TIMEOUT];
    [obj release];
    [self checkFailure];
    
}

- (void) subTestRenameObject2:(AtmosObject*) atmosObject
{
    
    AtmosObject *obj = [[AtmosObject alloc] init];
    obj.objectPath = atmosObject.objectPath;
    obj.dataMode = kDataModeBytes;

    // Read the object back from its new location
    [atmosStore readObject:obj withCallback:^BOOL(DownloadProgress *progress) {
        @try {
            [self checkResult:progress];
            if(progress.isComplete) {
                GHAssertNotNil(progress.atmosObject.data, 
                               @"Expected data to be non-Nil");
                GHAssertEqualStrings(@"Hello World",
                                     [NSString stringWithUTF8String:[progress.atmosObject.data bytes]], 
                                     @"Expected strings to match");
                GHAssertEqualStrings([progress.atmosObject.userRegularMeta valueForKey:@"key1"], @"value1", @"Value for key1 did not match");
                GHAssertEqualStrings([progress.atmosObject.userRegularMeta valueForKey:@"key2"], @"value2", @"Value for key2 did not match");
                
                // Notify async test complete.
                [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testRenameObject)];                
            }
        }
        @catch (NSException *exception) {
            self.failure = exception;
            [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testRenameObject)];
            return NO;
        }
        return YES;
    } withLabel:@"subTestRenameObject2"];
    [obj release];
}

- (void) subTestRenameObject1:(AtmosObject*) atmosObject
{
    // Add the object to the cleanup queue
    [self.cleanup addObject:atmosObject.atmosId];
    
    // Rename the object
    AtmosObject *dest = [[AtmosObject alloc] init];
    dest.objectPath = [NSString stringWithFormat:@"/%@/%@", [self generateFilename:8 includeExtension:NO], [self generateFilename:8 includeExtension:YES]];
    [atmosStore rename:atmosObject to:dest force:NO withCallback:^(AtmosResult *result) {
        @try {
            [self checkResult:result];
            
            [self subTestRenameObject2:dest];
        }
        @catch (NSException *exception) {
            self.failure = exception;
            [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testRenameObject)];
        }
    } withLabel:@"subTestRenameObject1"];
    
    [dest release];
}

- (void) testRenameObject
{
    [self prepare];
    
    // Create an object with metadata
    NSString *dir = [NSString stringWithFormat:@"/%@/", [self generateFilename:8 includeExtension:NO]];
    
    AtmosObject *obj = [[AtmosObject alloc] init];
    obj.objectPath = [NSString stringWithFormat:@"%@%@", dir, [self generateFilename:8 includeExtension:YES]];
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
                            [self subTestRenameObject1:progress.atmosObject];
                        }
                    }
                    @catch (NSException *exception) {
                        self.failure = exception;
                        [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testRenameObject)];
                        return NO;
                    }
                    
                    return YES;
                } 
                   withLabel:@"testRenameObject"];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:TIMEOUT];
    [obj release];
    [self checkFailure];

}

- (void) subTestRenameObjectForce3:(AtmosObject*)obj2
{
    // Read the object back and make sure we have obj1's content
    AtmosObject *obj3 = [[AtmosObject alloc] init];
    obj3.objectPath = obj2.objectPath;
    obj3.dataMode = kDataModeBytes;
    [atmosStore readObject:obj3 withCallback:^BOOL(DownloadProgress *progress) {
        @try {
            [self checkResult:progress];
            if(progress.isComplete) {
                GHAssertNotNil(progress.atmosObject.data, 
                               @"Expected data to be non-Nil");
                GHAssertEqualStrings(@"Hello World",
                                     [NSString stringWithUTF8String:[progress.atmosObject.data bytes]], 
                                     @"Expected strings to match");
                // Notify async test complete
                [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testRenameObjectForce)];
            }
        }
        @catch (NSException *exception) {
            self.failure = exception;
            [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testRenameObjectForce)];
            return NO;
        }
        return YES;
    } withLabel:@"subTestRenameObjectForce3"];
    
    [obj3 release];
}

- (void) subTestRenameObjectForce2:(AtmosObject*)obj1 overwrite:(AtmosObject*)obj2
{
    [cleanup addObject:obj2.atmosId];
    
    // Perform the overwrite
    [atmosStore rename:obj1 to:obj2 force:YES withCallback:^(AtmosResult *result) {
        @try {
            [self checkResult:result];
            
            //
            // Pause 5 seconds.  Overwrites are not synchronous!
            //
            sleep(5);
            
            [self subTestRenameObjectForce3:obj2];
        }
        @catch (NSException *exception) {
            self.failure = exception;
            [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testRenameObjectForce)];
        }
    } withLabel:@"subTestRenameObjectForce2"];
}

- (void) subTestRenameObjectForce1:(AtmosObject*)obj1
{
    [cleanup addObject:obj1.atmosId];
    
    // Create another object.  This one will be overwritten.
    AtmosObject *obj2 = [[AtmosObject alloc] init];
    obj2.objectPath = [NSString stringWithFormat:@"/%@/%@", [self generateFilename:8 includeExtension:NO], [self generateFilename:8 includeExtension:YES]];
    obj2.dataMode = kDataModeBytes;
    obj2.data = [NSData dataWithBytes:[@"Something Else" UTF8String] length:12];
    [atmosStore createObject:obj2 
                withCallback:^BOOL(UploadProgress *progress) {
                    @try {
                        [self checkResult:progress];
                        
                        if(progress.isComplete){
                            GHAssertNotNil(progress.atmosObject,                                  
                                           @"Expected New ID to be non-Nil");
                            [self subTestRenameObjectForce2:obj1 overwrite:obj2];
                        }
                    }
                    @catch (NSException *exception) {
                        self.failure = exception;
                        [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testRenameObjectForce)];
                        return NO;
                    }
                    
                    return YES;
                } 
                   withLabel:@"subTestRenameObjectForce1"];
    [obj2 release];
    
}

- (void) testRenameObjectForce
{
    [self prepare];
    
    // Create an object with metadata
    AtmosObject *obj = [[AtmosObject alloc] init];
    obj.objectPath = [NSString stringWithFormat:@"/%@/%@", [self generateFilename:8 includeExtension:NO], [self generateFilename:8 includeExtension:YES]];
    obj.dataMode = kDataModeBytes;
    obj.data = [NSData dataWithBytes:[@"Hello World" UTF8String] length:12];
    [atmosStore createObject:obj 
                withCallback:^BOOL(UploadProgress *progress) {
                    @try {
                        [self checkResult:progress];
                        
                        if(progress.isComplete){
                            GHAssertNotNil(progress.atmosObject,                                  
                                           @"Expected New ID to be non-Nil");
                            [self subTestRenameObjectForce1:progress.atmosObject];
                        }
                    }
                    @catch (NSException *exception) {
                        self.failure = exception;
                        [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testRenameObjectForce)];
                        return NO;
                    }
                    
                    return YES;
                } 
                   withLabel:@"testRenameObjectForce"];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:TIMEOUT];
    [obj release];
    [self checkFailure];
    
}

- (void) testGetServiceInformation
{
    [self prepare];
    
    [atmosStore getServiceInformation:^(ServiceInformation *result) {
        @try {
            [self checkResult:result];
            
            GHAssertNotNil(result.atmosVersion, @"Atmos Version should not be nil");
            
            GHTestLog(@"Atmos Version is %@", result.atmosVersion);
            [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testGetServiceInformation)];
        }
        @catch (NSException *exception) {
            self.failure = exception;
            [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testGetServiceInformation)];
            return;
        }
        
    } withLabel:@"testGetServiceInformation"];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:TIMEOUT];
    [self checkFailure];
}

- (void) subTestGetObjectInformation1:(AtmosObject*) atmosObject
{
    // Read back the object information
    [atmosStore getObjectInformation:atmosObject withCallback:^(ObjectInformation *result) {
        
        @try {
            [self checkResult:result];
            
            
            GHAssertNotNil(result.replicas, @"Replicas should be non-nil");
            GHAssertNotNil(result.rawXml, @"rawXml should be non-nil");
            GHAssertNotNil(result.selection, @"selection should be non-nil");
            GHAssertEqualStrings(atmosObject.atmosId, result.objectId, @"ObjectIDs should be equal");
            
            GHAssertGreaterThan((int)result.replicas.count, 0, @"There should be at least 1 replica");
            Replica *r = [result.replicas objectAtIndex:0];
            GHAssertNotNil(r.replicaId, @"replicaId should be non-nil");
            GHAssertNotNil(r.replicaType, @"replicaType should be non-nil");
            GHAssertNotNil(r.location, @"location should be non-nil");
            GHAssertNotNil(r.storageType, @"storageType should be non-nil");
            
            GHAssertNotNil(result.retentionEnd, @"Retention not enabled.  See settings.plist.template and create the required policies and selectors to run this test.");
            GHAssertTrue(result.expirationEnabled, @"Expiration not enabled.  See settings.plist.template and create the required policies and selectors to run this test.");
            
            NSDate *now = [NSDate date];
            NSTimeInterval untilRetentionEnds = [result.retentionEnd timeIntervalSinceDate:now];
            NSTimeInterval untilExpiration = [result.expirationEnd timeIntervalSinceDate:now];
            
            GHAssertGreaterThan((long)untilRetentionEnds, 0L, @"Expected retention to end after 'now'");
            GHAssertGreaterThan((long)untilExpiration, 0L, @"Expected expiration to be after 'now'");
            [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testGetObjectInformation)];
        }
        @catch (NSException *exception) {
            self.failure = exception;
            [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testGetObjectInformation)];
        }
        
    } withLabel:@"subTestGetObjectInformation1"];
}

/*!
 * Test getting object replica/retention/expiration information.
 * Note that you must create a policy and selector for this
 * to work properly.  See settings.plist.template.
 */
- (void) testGetObjectInformation
{
    [self prepare];
    
    // Update the object and change some stuff
    AtmosObject *obj = [[AtmosObject alloc] init];
    obj.dataMode = kDataModeBytes;
    obj.data = [NSData dataWithBytes:[@"Hello Me!" UTF8String] length:10];
    obj.userRegularMeta = [NSMutableDictionary 
                            dictionaryWithObjectsAndKeys:[self.settings valueForKey:@"retain_policy_value"],[self.settings valueForKey:@"retain_policy_key"], nil];

    [atmosStore createObject:obj withCallback:^BOOL(UploadProgress *progress) {
        @try {
            [self checkResult:progress];
            
            if ([progress isComplete]) {
                [self subTestGetObjectInformation1:progress.atmosObject];
            }
            
            return YES;
        }
        @catch (NSException *exception) {
            self.failure = exception;
            [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testGetObjectInformation)];
            return NO;
        }
    } withLabel:@"testGetObjectInformation"];
    
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:TIMEOUT];
    [self checkFailure];
    [obj release];
    
}

-(void) subTestCreateAccessToken1:(NSString*)accessTokenId {
    GHAssertNotNil(accessTokenId, @"Access token ID was Nil");
    NSLog(@"Created Access Token %@", accessTokenId);
    
    // Delete it.
    [atmosStore deleteAccessToken:accessTokenId withCallback:^(AtmosResult *result) {
        @try {
            [self checkResult:result];
            [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testCreateAccessToken)];
        }
        @catch (NSException *exception) {
            self.failure = exception;
            [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testCreateAccessToken)];
        }
        
    } withLabel:@"subTestCreateAccessToken1"];
}

/*!
 * Test creating and deleting an access token
 */
- (void) testCreateAccessToken
{
    [self prepare];
    [atmosStore createAccessToken:^void(CreateAccessTokenResult *result) {
        @try {
            [self checkResult:result];
            
            GHAssertNotNil(result.accessTokenId, @"Access token ID should not be nil");
            NSURL *url = [result getURLForToken];
            GHAssertNotNil(url, @"URL for token should not be nil.");
            NSLog(@"Token URL: %@", [url absoluteString]);
            
            [self subTestCreateAccessToken1:result.accessTokenId];
            
        }
        @catch (NSException *exception) {
            self.failure = exception;
            [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testCreateAccessToken)];
        }
    } withLabel:@"testCreateAccessToken"];
    
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:TIMEOUT];
    [self checkFailure];
}

- (void) subTestCreateAccessTokenWithPolicy2:(NSString*)tokenId {
    // Delete the token.
    [atmosStore deleteAccessToken:tokenId
                     withCallback:^(AtmosResult *result) {
                         @try {
                             [self checkResult:result];
                             [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testCreateAccessTokenWithPolicy)];
                         }
                         @catch (NSException *exception) {
                             self.failure = exception;
                             [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testCreateAccessTokenWithPolicy)];
                         }
                         
                     }
                        withLabel:@"subTestCreateAccessTokenWithPolicy2"];
}


- (void) subTestCreateAccessTokenWithPolicy1:(NSString*)tokenId withExpiration:(NSDate*)expiration {
    // Read back the token and check the policy.
    [atmosStore getAccessTokenInfo:tokenId
                      withCallback:^(GetAccessTokenInfoResult *result) {
                          @try {
                              [self checkResult:result];
                              
                              TNSAccessTokenType *token = result.tokenInfo;
                              GHAssertNotNil(token, @"Failed to parse token info");
                              GHAssertEqualStrings(tokenId, token.accessTokenId, @"Access token ID incorrect");
                              GHAssertNotNil(token.expiration, @"Expiration not set");
                              GHAssertEquals([expiration timeIntervalSince1970], [token.expiration timeIntervalSince1970], @"Expiration incorrect");
                              GHAssertNotNil(token.maxUploads, @"Max uploads not set");
                              GHAssertEquals(1, [token.maxUploads intValue], @"Max uploads incorrect");
                              GHAssertNotNil(token.maxDownloads, @"Max downloads should be set");
                              GHAssertEquals(0, [token.maxDownloads intValue], @"Max downloads incorrect");
                              GHAssertNotNil(token.source, @"Source no set");
                              GHAssertEquals(1, (int)token.source.allow.count, @"Allow count incorrect");
                              GHAssertEquals(0, (int)token.source.disallow.count, @"Disallow count incorrect");
                              GHAssertEqualStrings(@"127.0.0.0/24", (NSString*)token.source.allow[0], @"Allow IP range incorrect");
                              GHAssertEquals(10, [token.contentLengthRange.from intValue], @"Content length range from incorrect");
                              GHAssertEquals(11000, [token.contentLengthRange.to intValue], @"Policy range to incorrect");

                              [self subTestCreateAccessTokenWithPolicy2:tokenId];
                              
                          }
                          @catch (NSException *exception) {
                              self.failure = exception;
                              [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testCreateAccessTokenWithPolicy)];
                          }
                          
                      }
                         withLabel:@"subTestCreateAccessTokenWithPolicy1"];
}

- (void) testCreateAccessTokenWithPolicy
{
    [self prepare];
    
    NSDate *expiration = [[NSDate alloc] initWithTimeIntervalSinceNow:3600.0];
    
    // Expirations are only accurate to the second.  Round to nearest second.
    NSTimeInterval seconds = [expiration timeIntervalSince1970];
    seconds = floor(seconds);
    [expiration release];
    expiration = [[NSDate alloc] initWithTimeIntervalSince1970:seconds];
    
    TNSPolicyType *policy = [[TNSPolicyType alloc] init];
    TNSFormFieldType *field;
    
    policy.expiration = expiration;
    policy.maxUploads = [NSNumber numberWithInt:1];
    policy.source = [[[TNSSourceType alloc] init] autorelease];
    policy.source.allow = [NSMutableArray arrayWithObject:@"127.0.0.0/24"];
    TNSContentLengthRangeType *contentRange = [[TNSContentLengthRangeType alloc] init];
    contentRange.from = [NSNumber numberWithLongLong:10];
    contentRange.to = [NSNumber numberWithLongLong:11000];
    policy.contentLengthRange = contentRange;
    [contentRange release];
    field = [[TNSFormFieldType alloc] init];
    field.name = @"x-emc-redirect-url";
    policy.formField = [NSMutableArray arrayWithObject:field];
    [field release];
    field = [[TNSFormFieldType alloc] init];
    field.name = @"x-emc-meta";
    field.optional = [NSNumber numberWithBool:YES];
    field.matches = [NSMutableArray arrayWithObject:@"^(\\w+=\\w+)|((\\w+=\\w+),(\\w+, \\w+))$"];
    [policy.formField addObject:field];
    [field release];
    
    [atmosStore createAccessTokenWithPolicy:policy
                               withMetadata:nil
                       withListableMetadata:nil
                                    withAcl:nil
                               withCallback:^(CreateAccessTokenResult *result) {
                                   @try {
                                       [self checkResult:result];
                                       
                                       GHAssertNotNil(result.accessTokenId, @"Access token ID should not be nil");
                                       NSURL *url = [result getURLForToken];
                                       GHAssertNotNil(url, @"URL for token should not be nil.");
                                       NSLog(@"Token URL: %@", [url absoluteString]);
                                       
                                       [self subTestCreateAccessTokenWithPolicy1:result.accessTokenId withExpiration:expiration];
                                       
                                   }
                                   @catch (NSException *exception) {
                                       self.failure = exception;
                                       [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testCreateAccessTokenWithPolicy)];
                                   }
                                   
                               }
                                  withLabel:@"testCreateAccessTokenWithPolicy"];
    
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:TIMEOUT];
    [self checkFailure];
    [policy release];
    [expiration release];
    
}

- (void) subTestDownloadToken2:(NSURL*)url {
    NSURLRequest *req = [[NSURLRequest alloc] initWithURL:url];
    NSHTTPURLResponse *res;
    NSError *error;
    
    NSData *body = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&error];
    
    GHAssertEquals(200, res.statusCode, @"Bad status code downloading URL");
    GHAssertNotNil(body, @"Failed to load URL: %@", error);
    GHAssertNotNil(res, @"Response body nil.");
    GHAssertEqualStrings(@"text/plain; charset=UTF-8", [[res allHeaderFields] valueForKey:@"Content-Type"], @"Content type incorrect");
    GHAssertEqualStrings(@"Hello World", [NSString stringWithUTF8String:[body bytes]], @"Body conntent incorrect");
    [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testDownloadToken)];
}
    

- (void) subTestDownloadToken1:(AtmosObject*)atmosObject {
    TNSPolicyType *policy = [[TNSPolicyType alloc] init];
    
    policy.maxDownloads = [NSNumber numberWithInt:1];
    
    [atmosStore createAccessTokenForObject:atmosObject withPolicy:policy withCallback:^(CreateAccessTokenResult *result) {
        @try {
            [self checkResult:result];
            
            GHAssertNotNil(result.accessTokenId, @"Access token ID should not be nil");
            NSURL *url = [result getURLForToken];
            GHAssertNotNil(url, @"URL for token should not be nil.");
            NSLog(@"Token URL: %@", [url absoluteString]);
            
            [self subTestDownloadToken2:url];
            
        }
        @catch (NSException *exception) {
            self.failure = exception;
            [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testDownloadToken)];
        }

    } withLabel:@"subTestDownloadToken1"];
    
    [policy release];
}

- (void) testDownloadToken {
    [self prepare];
    
    AtmosObject *obj = [[AtmosObject alloc] init];
    obj.dataMode = kDataModeBytes;
    obj.data = [NSData dataWithBytes:[@"Hello World" UTF8String] length:12];
    obj.contentType = @"text/plain; charset=UTF-8";
    
    [atmosStore createObject:obj
                withCallback:^BOOL(UploadProgress *progress) {
                    @try {
                        [self checkResult:progress];
                        
                        if(progress.isComplete){
                            GHAssertNotNil(progress.atmosObject,
                                           @"Expected New ID to be non-Nil");
                            GHAssertNotNil(progress.atmosObject.atmosId,
                                           @"Expected New ID to be non-Nil");
                            [self.cleanup addObject:progress.atmosObject.atmosId];
                            [self subTestDownloadToken1:progress.atmosObject];
                        }
                    }
                    @catch (NSException *exception) {
                        self.failure = exception;
                        [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testDownloadToken)];
                        return NO;
                    }
                    
                    return YES;
                }
                   withLabel:@"testCreateObjectWithContent"];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:TIMEOUT];
    [obj release];
    [self checkFailure];
    
}

- (void) subTestListAccessTokens1:(NSString*)accessTokenId
                   withExpiration:(NSDate*)expiration
                    withPageToken:(NSString*)token
                       tokenFound:(BOOL)found
                        withCount:(NSInteger)pageCount {
    [atmosStore listAccessTokensWithLimit:1
                                withToken:token
                             withCallback:^(ListAccessTokensResult *result) {
             BOOL localFind = found;
             NSInteger localCount = pageCount;
             @try {
                 [self checkResult:result];
                 localCount++;
                 NSLog(@"Page %d", localCount);
                 
                 GHAssertNotNil(result.results, @"Results object should be non-nil");
                 GHAssertNotNil(result.results.accessTokensList, @"Access token list should be non-nil");
                 GHAssertNotNil(result.results.accessTokensList.accessToken, @"Access token array should be non-nil");
                 NSMutableArray *tokenlist = result.results.accessTokensList.accessToken;
                 for(TNSAccessTokenType *token in tokenlist) {
                     if([token.accessTokenId isEqualToString:accessTokenId]) {
                         localFind = YES;
                         GHAssertEquals(1, [token.maxUploads intValue], @"Found token but maxUploads is wrong");
                         GHAssertEquals([expiration timeIntervalSince1970], [token.expiration timeIntervalSince1970], @"Found token but expiration is wrong");
                     }
                 }
                 
                 // See if there is more results
                 if(result.token != nil) {
                     [self subTestListAccessTokens1:accessTokenId
                                     withExpiration:expiration
                                      withPageToken:result.token
                                         tokenFound:localFind
                                          withCount:localCount];
                 } else {
                     // Done.
                     GHAssertTrue(localFind, @"Access token not found");
                     [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testListAccessTokens)];                     
                 }
             }
             @catch (NSException *exception) {
                 self.failure = exception;
                 [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testListAccessTokens)];
             }
        
    } withLabel:@"subTestListAccessTokens1"];
    
}

- (void) testListAccessTokens {
    [self prepare];
    
    NSDate *expiration = [[NSDate alloc] initWithTimeIntervalSinceNow:3600.0];
    
    // Expirations are only accurate to the second.  Round to nearest second.
    NSTimeInterval seconds = [expiration timeIntervalSince1970];
    seconds = floor(seconds);
    [expiration release];
    expiration = [[NSDate alloc] initWithTimeIntervalSince1970:seconds];
    
    TNSPolicyType *policy = [[TNSPolicyType alloc] init];
    TNSFormFieldType *field;
    
    policy.expiration = expiration;
    policy.maxUploads = [NSNumber numberWithInt:1];
    policy.source = [[[TNSSourceType alloc] init] autorelease];
    policy.source.allow = [NSMutableArray arrayWithObject:@"127.0.0.0/24"];
    TNSContentLengthRangeType *contentRange = [[TNSContentLengthRangeType alloc] init];
    contentRange.from = [NSNumber numberWithLongLong:10];
    contentRange.to = [NSNumber numberWithLongLong:11000];
    policy.contentLengthRange = contentRange;
    [contentRange release];
    field = [[TNSFormFieldType alloc] init];
    field.name = @"x-emc-redirect-url";
    policy.formField = [NSMutableArray arrayWithObject:field];
    [field release];
    field = [[TNSFormFieldType alloc] init];
    field.name = @"x-emc-meta";
    field.optional = [NSNumber numberWithBool:YES];
    field.matches = [NSMutableArray arrayWithObject:@"^(\\w+=\\w+)|((\\w+=\\w+),(\\w+, \\w+))$"];
    [policy.formField addObject:field];
    [field release];
    
    [atmosStore createAccessTokenWithPolicy:policy
                               withMetadata:nil
                       withListableMetadata:nil
                                    withAcl:nil
                               withCallback:^(CreateAccessTokenResult *result) {
                                   @try {
                                       [self checkResult:result];
                                       
                                       GHAssertNotNil(result.accessTokenId, @"Access token ID should not be nil");
                                       NSURL *url = [result getURLForToken];
                                       GHAssertNotNil(url, @"URL for token should not be nil.");
                                       NSLog(@"Token URL: %@", [url absoluteString]);
                                       
                                       [self subTestListAccessTokens1:result.accessTokenId
                                                       withExpiration:expiration
                                                        withPageToken:nil
                                                           tokenFound:NO
                                                            withCount:0];
                                       
                                   }
                                   @catch (NSException *exception) {
                                       self.failure = exception;
                                       [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testListAccessTokens)];
                                   }
                                   
                               }
                                  withLabel:@"testListAccessTokens"];
    
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:TIMEOUT];
    [self checkFailure];
    [policy release];
    [expiration release];
    
    
}


@end
