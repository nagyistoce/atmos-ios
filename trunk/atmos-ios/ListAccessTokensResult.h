//
//  ListAccessTokensResult.h
//  atmos-ios
//
//  Created by Jason Cwik on 12/20/12.
//
//

#import "AtmosResult.h"
#import "TNSListAccessTokenResultType.h"

@interface ListAccessTokensResult : AtmosResult {
    TNSListAccessTokenResultType *results;
    NSString *token;
}

@property (retain,nonatomic) TNSListAccessTokenResultType* results;
@property (retain,nonatomic) NSString* token;

@end
