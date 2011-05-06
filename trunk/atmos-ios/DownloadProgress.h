//
//  DownloadProgress.h
//  atmos-ios
//
//  Created by Jason Cwik on 5/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AtmosObject.h"
#import "AtmosResult.h"

@interface DownloadProgress : AtmosResult {
    BOOL isComplete;
    unsigned long long bytesDownloaded;
    unsigned long long totalBytes;
    AtmosObject *atmosObject;
    
}

@property BOOL isComplete;
@property unsigned long long bytesDownloaded;
@property unsigned long long totalBytes;
@property (retain,readwrite) AtmosObject *atmosObject;


@end
