//
//  AtmosError.h
//  AtmosCocoaBinding
//
//  Created by Aashish Patil on 8/26/10.
//  Copyright 2010 EMC. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface AtmosError : NSObject {
	
	NSInteger errorCode;
	NSString *errorMessage;

}

@property NSInteger errorCode;
@property (nonatomic,retain) NSString *errorMessage;

- (id)initWithCode:(NSInteger)code message:(NSString *) errMsg;

@end
