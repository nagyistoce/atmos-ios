//
//  AtmosRange.h
//  atmos-ios
//
//  Created by Jason Cwik on 5/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 * Large file-compatible version of NSRange
 */
@interface AtmosRange : NSObject {
    unsigned long long location;
    unsigned long long length;    
}

@property (readwrite) unsigned long long location;
@property (readwrite) unsigned long long length;


@end
