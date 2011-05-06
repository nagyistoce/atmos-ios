//
//  DeleteMetadataOperation.h
//  AtmosCocoaBinding
//
//  Created by Aashish Patil on 9/24/10.
//  Copyright 2010 EMC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AtmosBaseOperation.h"
#import "AtmosObject.h"
#import "AtmosError.h"

@interface DeleteMetadataOperation : AtmosBaseOperation {

	AtmosObject *atmosObj;
	
}

@property (nonatomic,retain) AtmosObject *atmosObj;

@end
