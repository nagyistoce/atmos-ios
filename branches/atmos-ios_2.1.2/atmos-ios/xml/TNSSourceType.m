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
#import "TNSSourceType.h"
        
@implementation TNSSourceType 

@synthesize allow;
@synthesize disallow;

        
- (void) readAttributes: (xmlTextReaderPtr) reader {
  
    
}

- (id) initWithReader: (xmlTextReaderPtr) reader {
  int _complexTypeXmlDept = xmlTextReaderDepth(reader);
  self = [super init];
  if(self) {
    
  [self readAttributes: reader];

    self.allow = [NSMutableArray array];
    self.disallow = [NSMutableArray array];

    int _currentNodeType = xmlTextReaderRead(reader);
    int _currentXmlDept = xmlTextReaderDepth(reader);
    while(_currentNodeType != XML_READER_TYPE_NONE && _complexTypeXmlDept < _currentXmlDept) {
      if(_currentNodeType == XML_READER_TYPE_ELEMENT) {  
        NSString* _currentElementName = [NSString stringWithCString: (const char*) xmlTextReaderConstLocalName(reader) encoding:NSUTF8StringEncoding];
        if([@"allow" isEqual: _currentElementName]) {
          xmlTextReaderRead(reader);
          [(NSMutableArray*)self.allow addObject: [NSString stringWithCString: (const char*) xmlTextReaderConstValue(reader) encoding: NSUTF8StringEncoding]];
          xmlTextReaderRead(reader);
        } else if([@"disallow" isEqual: _currentElementName]) {
          xmlTextReaderRead(reader);
          [(NSMutableArray*)self.disallow addObject: [NSString stringWithCString: (const char*) xmlTextReaderConstValue(reader) encoding: NSUTF8StringEncoding]];
          xmlTextReaderRead(reader);
        } else  if([@"#text" isEqual: _currentElementName]){
        
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
    
        
    // Child elements
    
        if(self.allow) {
            
                
                for(NSString *value in self.allow) {
                    xmlTextWriterWriteElement(writer, BAD_CAST "allow", BAD_CAST [value UTF8String]);
                }
                
            
        }
    
        if(self.disallow) {
            
                
                for(NSString *value in self.disallow) {
                    xmlTextWriterWriteElement(writer, BAD_CAST "disallow", BAD_CAST [value UTF8String]);
                }
                
            
        }
    
}

        
- (void) dealloc {
  self.allow = nil;
  self.disallow = nil;
        
  [super dealloc];
}

@end
	