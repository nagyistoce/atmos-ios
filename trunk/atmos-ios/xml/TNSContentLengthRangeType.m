/*
 Copyright (c) 2012, EMC Corporation
 
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 * Neither the name of the EMC Corporation nor the names of its contributors
 may be used to endorse or promote products derived from this software
 without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 */
#import "TNSContentLengthRangeType.h"
        
@implementation TNSContentLengthRangeType 

@synthesize from;
@synthesize to;

        
- (void) readAttributes: (xmlTextReaderPtr) reader {
  
    NSNumberFormatter* intFormatter = [[[NSNumberFormatter alloc] init] autorelease];
    intFormatter.numberStyle = NSNumberFormatterDecimalStyle;
  char* fromAttrValue = (char*) xmlTextReaderGetAttribute(reader, (xmlChar*)"from");
  if(fromAttrValue) {
    self.from = [intFormatter numberFromString: [NSString stringWithCString: fromAttrValue encoding: NSUTF8StringEncoding]];
    xmlFree(fromAttrValue);
  } else {
    self.from = nil;
  }
  char* toAttrValue = (char*) xmlTextReaderGetAttribute(reader, (xmlChar*)"to");
  if(toAttrValue) {
    self.to = [intFormatter numberFromString: [NSString stringWithCString: toAttrValue encoding: NSUTF8StringEncoding]];
    xmlFree(toAttrValue);
  } else {
    self.to = nil;
  }
}

- (id) initWithReader: (xmlTextReaderPtr) reader {
  int _complexTypeXmlDept = xmlTextReaderDepth(reader);
  self = [super init];
  if(self) {
    NSNumberFormatter* intFormatter = [[[NSNumberFormatter alloc] init] autorelease];
    intFormatter.numberStyle = NSNumberFormatterDecimalStyle;
  [self readAttributes: reader];


    int _currentNodeType = xmlTextReaderRead(reader);
    int _currentXmlDept = xmlTextReaderDepth(reader);
    while(_currentNodeType != XML_READER_TYPE_NONE && _complexTypeXmlDept < _currentXmlDept) {
      if(_currentNodeType == XML_READER_TYPE_ELEMENT) {  
        NSString* _currentElementName = [NSString stringWithCString: (const char*) xmlTextReaderConstLocalName(reader) encoding:NSUTF8StringEncoding];
         if([@"#text" isEqual: _currentElementName]){
        
        } else {
          return self;
        }
      }  
      _currentNodeType = xmlTextReaderRead(reader);
      _currentXmlDept = xmlTextReaderDepth(reader);
    }
  }
  return self;
}
        

        
// Populates the current element in the textwriter with this object's data.
- (void) writeXml: (xmlTextWriterPtr) writer {
    
        
    
    // Attributes
    
        if(self.from) {
            xmlTextWriterWriteAttribute(writer, BAD_CAST "from", BAD_CAST [[self.from stringValue] UTF8String]);
        }
    
        if(self.to) {
            xmlTextWriterWriteAttribute(writer, BAD_CAST "to", BAD_CAST [[self.to stringValue] UTF8String]);
        }
    
        
    // Child elements
    
}

        
- (void) dealloc {
  self.from = nil;
  self.to = nil;
        
  [super dealloc];
}

@end
	