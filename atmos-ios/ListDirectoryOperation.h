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
#import "AtmosBaseOperation.h"
#import "AtmosError.h"
#import "AtmosObject.h"
#import "ListDirectoryResult.h"

@interface ListDirectoryOperation : AtmosBaseOperation <NSXMLParserDelegate> {
	
	AtmosObject *atmosObj;
	NSMutableArray *atmosObjects;
	AtmosObject *currentObject;
	NSString *currentElement;
	NSMutableString *currentValue;
	NSXMLParser *xmlParser;
	NSString *emcToken;
	NSInteger emcLimit;
    void(^callback)(ListDirectoryResult *result);
    BOOL includeMetadata;
    NSArray *includeUserTags;
    NSArray *includeSystemTags;
    NSMutableDictionary *currentMetadata;
    NSMutableDictionary *currentListableMetadata;
    NSString *currentMetaName;
    NSString *currentMetaValue;
    BOOL currentMetaListable;
}

@property (nonatomic,retain) AtmosObject *atmosObj;
@property (nonatomic,retain) NSMutableString *currentValue;
@property (nonatomic,retain) NSString *emcToken;
@property (nonatomic,assign) NSInteger emcLimit;
@property (nonatomic,retain) NSMutableArray *atmosObjects;
@property (nonatomic,retain) NSString *currentElement;
@property (nonatomic,retain) AtmosObject *currentObject;
@property (nonatomic,copy) void(^callback)(ListDirectoryResult *result);
@property (nonatomic,assign) BOOL includeMetadata;
@property (nonatomic,retain) NSArray *includeUserTags;
@property (nonatomic,retain) NSArray *includeSystemTags;
@property (nonatomic,retain) NSMutableDictionary *currentMetadata;
@property (nonatomic,retain) NSMutableDictionary *currentListableMetadata;
@property (nonatomic,retain) NSString *currentMetaName;
@property (nonatomic,retain) NSString *currentMetaValue;
@property (nonatomic,assign) BOOL currentMetaListable;

@end
