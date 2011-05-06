//
//  GetMetadataOperation.h
//  AtmosCocoaBinding
//
//  Created by Aashish Patil on 9/11/10.
//  Copyright 2010 EMC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AtmosBaseOperation.h"
#import "AtmosObject.h"

@interface GetMetadataOperation : AtmosBaseOperation {

	@private
	NSURLConnection *sysMetaConn;
	NSURLConnection *userMetaConn;
	NSInteger numConnections;
	NSInteger maxConnections;
	AtmosObject *atmosObj;
	
	@public
	NSString *atmosId;
	NSString *objectPath;
	BOOL loadUserMeta;
	BOOL loadSysMeta;
	
	
	
}

@property (nonatomic,retain) NSString *atmosId;
@property (nonatomic,retain) NSString *objectPath;
@property (nonatomic,assign) BOOL loadUserMeta;
@property (nonatomic,assign) BOOL loadSysMeta;

@property (nonatomic,retain) NSURLConnection *sysMetaConn;
@property (nonatomic,retain) NSURLConnection *userMetaConn;
@property (nonatomic,retain) AtmosObject *atmosObj;

@end
