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


#import "AtmosObject.h"

static NSDateFormatter *tsFmter = nil;
static NSDateFormatter *friendlyDateFmter = nil;
static NSSet *systemMetaNames = nil;

@implementation AtmosObject

@synthesize atmosId, objectPath, userRegularMeta, userListableMeta, systemMeta, requestTags, contentType;
@synthesize filepath, data, keypool;
@synthesize dataMode = kDataModeFile;
@synthesize directory;

- (NSMutableDictionary *) userRegularMeta {
	if(userRegularMeta == nil) {
		userRegularMeta = [[NSMutableDictionary alloc] init];
	}
	return userRegularMeta;
}

- (NSMutableDictionary *) userListableMeta {
	if(userListableMeta == nil) {
		userListableMeta = [[NSMutableDictionary alloc] init];
	}
	return userListableMeta;
}

- (NSMutableDictionary *) systemMeta { 
	if(systemMeta == nil) {
		systemMeta = [[NSMutableDictionary alloc] init];
	}
	return systemMeta;
}

- (NSMutableSet *) requestTags {
	if(requestTags == nil) {
		requestTags = [[NSMutableSet alloc] init];
	}
	return requestTags;
}

+ (BOOL) isSystemMetadata:(NSString *) metaName {
	if(systemMetaNames == nil) {
		systemMetaNames = [[NSSet alloc] initWithObjects:@"atime", @"ctime",
                           @"gid", @"itime", @"mtime", @"nlink", @"objectid",
                           @"objname", @"policyname", @"size", @"type",
                           @"uid", nil];
	}
	return [systemMetaNames containsObject:metaName];
}

+ (NSDate *) tsToDate: (NSString *) tsStr {
	if(tsFmter == nil) {
		tsFmter = [[NSDateFormatter alloc] init];
		[tsFmter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
	}
	
	return [tsFmter dateFromString:tsStr];	
}

+ (NSString *) tsToString:(NSDate *) dtObj {
	if(tsFmter == nil) {
		tsFmter = [[NSDateFormatter alloc] init];
		[tsFmter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        [tsFmter retain];
	}
	return [tsFmter stringFromDate:dtObj];
}

+ (NSString *) formatObjectSize:(NSInteger) objSize {
	float fSize = (float) objSize;
	if (objSize < 1023)
		return([NSString stringWithFormat:@"%dB",objSize]);
	fSize = fSize / 1024.0;
	if (fSize<1023.0)
		return([NSString stringWithFormat:@"%1.0fKB",round(fSize)]);
	fSize = fSize / 1024.0;
	if (fSize<1023.0)
		return([NSString stringWithFormat:@"%1.0fMB",round(fSize)]);
	fSize = fSize / 1024.0;
	
	return([NSString stringWithFormat:@"%1.0fGB",round(fSize)]);
}

+ (NSString *) formatFriendlyDate:(NSDate *) dtObj {	
	if(friendlyDateFmter == nil) {
		friendlyDateFmter = [[NSDateFormatter alloc] init];
		[friendlyDateFmter setDateFormat:@"MMM dd"];
        [friendlyDateFmter retain];
	}
	
	NSTimeInterval diff = [dtObj timeIntervalSinceNow];
	diff = -diff;
	NSInteger numDays = floor(diff / 86400.0);
	NSString *strTimeInterval = nil;
	if(numDays > 0) {
		strTimeInterval = [NSString stringWithFormat:@"%d days ago",numDays];
	} else {
		NSInteger numHours = floor(diff / 3600.0);
		if(numHours > 0 ) {
			strTimeInterval = [NSString stringWithFormat:@"%d hours ago",numHours];
		} else {
			NSInteger numMins = floor(diff/60.0);	
			if(numMins > 0) {
				strTimeInterval = [NSString stringWithFormat:@"%d mins ago",numMins];
			} else {
				strTimeInterval = @"Less than a minute ago";
			}
		}
	}
	
	NSString *dtStr = [friendlyDateFmter stringFromDate:dtObj];
	NSString *retStr = [NSString stringWithFormat:@"%@, %@",dtStr,strTimeInterval];
	return retStr;
}

-(id) initWithObjectId:(NSString *)oid
{
    self = [super init];
    if(self) {
        self.atmosId = oid;
    }
    
    return self;
}

-(id) initWithObjectPath:(NSString*)path {
    self = [super init];
    if(self) {
        self.objectPath = path;
    }
    
    return self;
}

-(id) initWithKeypool:(NSString*)pool withKey:(NSString*)key {
    self = [super init];
    if(self) {
        self.keypool = pool;
        self.objectPath = key;
    }
    
    return self;    
}



- (BOOL) isEqual:(id)object 
{
    return [((AtmosObject*)object).atmosId isEqualToString:self.atmosId] || [((AtmosObject*)object).objectPath isEqualToString:self.objectPath];
}

- (NSUInteger) hash
{
    if( self.objectPath ) {
        return self.objectPath.hash;
    } else if( self.atmosId ){
        return self.atmosId.hash;
    } else {
        return 0;
    }
}

- (void) dealloc {
    
    // Release properties marked retain.
    self.atmosId = nil;
    self.objectPath = nil;
    self.keypool = nil;
    self.systemMeta = nil;
    self.userListableMeta = nil;
    self.userRegularMeta = nil;
    self.requestTags = nil;
    self.filepath = nil;
    self.data = nil;
    self.contentType = nil;
    
	[super dealloc];
}
@end
