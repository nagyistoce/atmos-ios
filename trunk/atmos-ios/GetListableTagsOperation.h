//
//  GetListableTagsOperation.h
//  AtmosCocoaBinding
//
//  Created by Aashish Patil on 7/9/10.
//  Copyright 2010 EMC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AtmosBaseOperation.h"
#import "GetListableTagsResult.h"

@interface GetListableTagsOperation : AtmosBaseOperation {
	void (^callback)(GetListableTagsResult *tags);
}

@property (assign,readwrite) void (^callback)(GetListableTagsResult *tags);

@end
