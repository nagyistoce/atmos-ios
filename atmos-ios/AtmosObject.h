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

#define ATMOS_ID_LENGTH 44

/*!
 * Enum used for dataMode property.
 */
typedef enum {
    kDataModeFile,
    kDataModeBytes
} ObjectDataMode;

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

/*!
 * @class AtmosObject
 * Encapsulates information about Atmos objects.
 */
@interface AtmosObject : NSObject {
	
	NSString *atmosId;
	NSString *objectPath;
    NSString *contentType;
	
	NSMutableDictionary *systemMeta;
	NSMutableDictionary *userListableMeta;
	NSMutableDictionary *userRegularMeta;
	NSMutableSet *requestTags;
	
    /*!
     * The mode for handling object data.  If kDataModeFile, then the filepath 
     * property will be used for reading and writing object data to/from a
     * file.  If kDataModeBytes, object data will be read/written directly
     * to/from the data property (NSData).
     */
    ObjectDataMode dataMode;
	NSString *filepath;
    NSData *data;
	
	BOOL directory;
	
}

-(id) initWithObjectId:(NSString*)oid;

+ (NSDate *) tsToDate:(NSString *) tsStr;
+ (NSString *) tsToString:(NSDate *) dtObj;
+ (NSString *) formatObjectSize:(NSInteger) objSize;
+ (NSString *) formatFriendlyDate:(NSDate *) dtObj;
+ (BOOL) isSystemMetadata:(NSString *) metaName;

@property (nonatomic, retain) NSString *atmosId;
@property (nonatomic, retain) NSString *objectPath;

@property (nonatomic, retain) NSMutableDictionary *systemMeta;
@property (nonatomic, retain) NSMutableDictionary *userListableMeta;
@property (nonatomic, retain) NSMutableDictionary *userRegularMeta;
@property (nonatomic, retain) NSMutableSet *requestTags;

@property (nonatomic, retain) NSString *filepath;
@property (nonatomic, retain) NSData *data;
@property ObjectDataMode dataMode;
@property (nonatomic, retain) NSString *contentType;

@property (nonatomic, assign) BOOL directory;

@end
