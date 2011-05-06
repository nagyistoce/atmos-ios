//
//  DeleteObjectOperation.h
//  AtmosCocoaBinding
//
//  Created by Aashish Patil on 9/20/10.
//  Copyright 2010 EMC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AtmosBaseOperation.h"
#import "AtmosObject.h"

@interface DeleteObjectOperation : AtmosBaseOperation {

	AtmosObject *atmosObj;
    void (^callback)(AtmosResult *result);
}

@property (nonatomic,retain) AtmosObject *atmosObj;
@property (nonatomic,copy) void (^callback)(AtmosResult *result);
@end
