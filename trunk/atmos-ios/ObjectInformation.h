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
#import <Foundation/Foundation.h>
#import "AtmosResult.h"
#import "Replica.h"

@interface ObjectInformation : AtmosResult {
    @private
    NSString *objectId;
    NSString *rawXml;
    NSString *selection;
    BOOL current;
    NSMutableArray *replicas;
    BOOL retentionEnabled;
    NSDate *retentionEnd;
    BOOL expirationEnabled;
    NSDate *expirationEnd;
}

@property (nonatomic,retain) NSString *objectId;
@property (nonatomic,retain) NSString *selection;
@property (nonatomic,assign) BOOL current;
@property (nonatomic,retain) NSString *rawXml;
@property (nonatomic,retain) NSMutableArray *replicas;
@property (nonatomic,assign) BOOL retentionEnabled;
@property (nonatomic,retain) NSDate *retentionEnd;
@property (nonatomic,assign) BOOL expirationEnabled;
@property (nonatomic,retain) NSDate *expirationEnd;

+ (id) objectInformation;
@end
