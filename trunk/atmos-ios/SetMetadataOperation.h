//
//  SetMetadataOperation.h
//  AtmosCocoaBinding
//
//  Created by Aashish Patil on 9/12/10.
//  Copyright 2010 EMC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AtmosBaseOperation.h"
#import "AtmosObject.h"

@interface SetMetadataOperation : AtmosBaseOperation {

	AtmosObject *curObj;
}

@property (nonatomic,retain) AtmosObject *curObj;

@end
