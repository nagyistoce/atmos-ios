/*
 
 Copyright (c) 2009, EMC Corporation
 
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


#import <Foundation/Foundation.h>
#import "NSData+Additions.h"
#import "CommonCrypto/CommonHMAC.h"
#import "AtmosCredentials.h"
#import "AtmosError.h"
#import "AtmosStore.h"

@interface AtmosBaseOperation : NSOperation {
	
	id appData; //app specific data
	
	NSString *baseUrl;
	NSMutableData *webData;
	
	AtmosCredentials *_atmosCredentials;
	
	NSMutableDictionary *listableMeta;
	NSMutableDictionary *regularMeta;
	
	NSMutableArray *requestTags;
	
	NSString *_atmosResource;
	
	BOOL operExecuting;
	BOOL operFinished;
	
	NSDictionary *responseHeaders;
	
	AtmosStore *atmosStore; //the atmos store object on which this operation was called
	

	
	NSHTTPURLResponse *httpResponse;
	
	NSString *operationLabel;
	
	NSURLConnection *connection;
	
}

/*
 Signs a NSMutableRequest as per the rules for signing an Atmos request. Check Atmos REST API Guide for the exact rules
 */
- (void) signRequest:(NSMutableURLRequest *) request ;
- (NSMutableURLRequest *) setupBaseRequestForResource:(NSString *) resource;
- (NSString *) getSharedSecret;
- (NSString	*) getMetaValue:(NSMutableDictionary *) metaVals;
- (NSString *) extractLocation:(NSHTTPURLResponse *) resp;
- (NSString *) extractObjectId:(NSHTTPURLResponse *) resp;
- (void) setMetadataOnRequest:(NSMutableURLRequest *) req;
- (void) setFilterTagsOnRequest:(NSMutableURLRequest *) req;
- (void) extractEMCMetaFromResponse:(NSHTTPURLResponse *) resp toObject:(AtmosObject *) object;
- (AtmosError *) extractAtmosError:(NSString *) errStr; 
- (void) startAtmosOperation;

@property (nonatomic, retain) NSString *baseUrl;
@property (nonatomic, retain) NSMutableData *webData;
@property (nonatomic, retain) NSMutableDictionary *listableMeta;
@property (nonatomic, retain) NSMutableDictionary *regularMeta;
@property (nonatomic, retain) NSMutableArray *requestTags;

@property (nonatomic, assign) BOOL operExecuting;
@property (nonatomic, assign) BOOL operFinished;
@property (nonatomic, retain) NSDictionary *responseHeaders;

@property (nonatomic,retain) AtmosCredentials *atmosCredentials;
@property (nonatomic, retain) NSString *atmosResource;

@property (nonatomic,retain) id appData;
@property (nonatomic,retain) AtmosStore *atmosStore;
@property (nonatomic,retain) NSString *operationLabel;
@property (retain) NSURLConnection *connection;

@property (nonatomic,retain) NSHTTPURLResponse *httpResponse;

@end


