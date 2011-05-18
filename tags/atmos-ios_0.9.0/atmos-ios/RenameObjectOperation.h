//
//  RenameObjectOperation.h
//  atmos-ios
//
//  Created by Jason Cwik on 5/18/11.
//  Copyright 2011 EMC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AtmosBaseOperation.h"
#import "AtmosObject.h"

@interface RenameObjectOperation : AtmosBaseOperation {
    AtmosObject *source;
    AtmosObject *destination;
    BOOL force;
    void (^callback)(AtmosResult *result);
}

@property (nonatomic,retain) AtmosObject *source;
@property (nonatomic,retain) AtmosObject *destination;
@property (nonatomic,assign) BOOL force;
@property (nonatomic,copy) void (^callback)(AtmosResult *result);

@end
