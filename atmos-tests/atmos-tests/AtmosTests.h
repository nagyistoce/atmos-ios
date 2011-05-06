//
//  AtmosTests.h
//  atmos-tests
//
//  Created by Jason Cwik on 5/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AtmosStore.h>

@interface AtmosTests : GHAsyncTestCase {
    
@private
    AtmosStore *atmosStore;
    NSMutableArray *cleanup;
}

@property(retain,readwrite) AtmosStore *atmosStore;
@property(retain,readwrite) NSMutableArray *cleanup;

-(void) checkResult:(AtmosResult*)result;

@end
