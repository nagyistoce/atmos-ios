//
//  UploadProgress.h
//  atmos-ios
//
//  Created by Jason Cwik on 5/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AtmosResult.h"
#import "AtmosObject.h"

@interface UploadProgress : AtmosResult {
    BOOL isComplete;
    unsigned long long bytesUploaded;
    unsigned long long totalBytes;
    NSString *label;
    AtmosObject *atmosObject;
}

@property BOOL isComplete;
@property unsigned long long bytesUploaded;
@property unsigned long long totalBytes;
@property (retain,readwrite) NSString *label;
@property (retain,readwrite) AtmosObject *atmosObject;

@end
