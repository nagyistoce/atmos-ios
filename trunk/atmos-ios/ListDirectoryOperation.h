//
//  ListDirectoryOperation.h
//  AtmosCocoaBinding
//
//  Created by Aashish Patil on 9/21/10.
//  Copyright 2010 EMC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AtmosBaseOperation.h"
#import "AtmosError.h"
#import "AtmosObject.h"

@interface ListDirectoryOperation : AtmosBaseOperation <NSXMLParserDelegate> {
	
	AtmosObject *atmosObj;
	NSMutableArray *atmosObjects;
	AtmosObject *currentObject;
	NSString *currentElement;
	NSMutableString *currentValue;
	NSXMLParser *xmlParser;
	NSString *emcToken;
	NSInteger emcLimit;

}

@property (nonatomic,retain) AtmosObject *atmosObj;
@property (nonatomic,retain) NSMutableString *currentValue;
@property (nonatomic,retain) NSString *emcToken;
@property (nonatomic,assign) NSInteger emcLimit;
@property (nonatomic,retain) NSMutableArray *atmosObjects;
@property (nonatomic,retain) NSString *currentElement;
@property (nonatomic,retain) AtmosObject *currentObject;

@end
