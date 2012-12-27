//
//  GetAccessTokenInfoResult.h
//  atmos-ios
//
//  Created by Jason Cwik on 12/20/12.
//
//

#import "AtmosResult.h"
#import "TNSAccessTokenType.h"

@interface GetAccessTokenInfoResult : AtmosResult {
    TNSAccessTokenType *tokenInfo;
}

@property (retain,nonatomic) TNSAccessTokenType *tokenInfo;

@end
