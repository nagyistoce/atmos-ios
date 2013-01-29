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
#import "TNSFormFieldType.h"
        
@implementation TNSFormFieldType 

@synthesize name;
@synthesize optional;
@synthesize matches;
@synthesize eq;
@synthesize startsWith;
@synthesize endsWith;
@synthesize contains;

        
- (void) readAttributes: (xmlTextReaderPtr) reader {
  
    
    
  char* nameAttrValue = (char*) xmlTextReaderGetAttribute(reader, (xmlChar*)"name");
  if(nameAttrValue) {
    self.name = [NSString stringWithCString: nameAttrValue encoding: NSUTF8StringEncoding];
    xmlFree(nameAttrValue);
  } else {
    self.name = nil;
  }
  char* optionalAttrValue = (char*) xmlTextReaderGetAttribute(reader, (xmlChar*)"optional");
  if(optionalAttrValue) {
    self.optional = [NSNumber numberWithBool: [[NSString stringWithCString: optionalAttrValue encoding: NSUTF8StringEncoding] isEqual: @"true"]];
    xmlFree(optionalAttrValue);
  } else {
    self.optional = nil;
  }
}

- (id) initWithReader: (xmlTextReaderPtr) reader {
  int _complexTypeXmlDept = xmlTextReaderDepth(reader);
  self = [super init];
  if(self) {
    
    
  [self readAttributes: reader];

    self.matches = [NSMutableArray array];
    self.eq = [NSMutableArray array];
    self.startsWith = [NSMutableArray array];
    self.endsWith = [NSMutableArray array];
    self.contains = [NSMutableArray array];

    int _currentNodeType = xmlTextReaderRead(reader);
    int _currentXmlDept = xmlTextReaderDepth(reader);
    while(_currentNodeType != XML_READER_TYPE_NONE && _complexTypeXmlDept < _currentXmlDept) {
      if(_currentNodeType == XML_READER_TYPE_ELEMENT) {  
        NSString* _currentElementName = [NSString stringWithCString: (const char*) xmlTextReaderConstLocalName(reader) encoding:NSUTF8StringEncoding];
        if([@"matches" isEqual: _currentElementName]) {
          xmlTextReaderRead(reader);
          [(NSMutableArray*)self.matches addObject: [NSString stringWithCString: (const char*) xmlTextReaderConstValue(reader) encoding: NSUTF8StringEncoding]];
          xmlTextReaderRead(reader);
        } else if([@"eq" isEqual: _currentElementName]) {
          xmlTextReaderRead(reader);
          [(NSMutableArray*)self.eq addObject: [NSString stringWithCString: (const char*) xmlTextReaderConstValue(reader) encoding: NSUTF8StringEncoding]];
          xmlTextReaderRead(reader);
        } else if([@"starts-with" isEqual: _currentElementName]) {
          xmlTextReaderRead(reader);
          [(NSMutableArray*)self.startsWith addObject: [NSString stringWithCString: (const char*) xmlTextReaderConstValue(reader) encoding: NSUTF8StringEncoding]];
          xmlTextReaderRead(reader);
        } else if([@"ends-with" isEqual: _currentElementName]) {
          xmlTextReaderRead(reader);
          [(NSMutableArray*)self.endsWith addObject: [NSString stringWithCString: (const char*) xmlTextReaderConstValue(reader) encoding: NSUTF8StringEncoding]];
          xmlTextReaderRead(reader);
        } else if([@"contains" isEqual: _currentElementName]) {
          xmlTextReaderRead(reader);
          [(NSMutableArray*)self.contains addObject: [NSString stringWithCString: (const char*) xmlTextReaderConstValue(reader) encoding: NSUTF8StringEncoding]];
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
    
        if(self.name) {
            xmlTextWriterWriteAttribute(writer, BAD_CAST "name", BAD_CAST [self.name UTF8String]);
        }
    
        if(self.optional) {
            xmlTextWriterWriteAttribute(writer, BAD_CAST "optional", BAD_CAST ([self.optional boolValue] == YES ? "true":"false"));
        }
    
        
    // Child elements
    
        if(self.matches) {
            
                
                for(NSString *value in self.matches) {
                    xmlTextWriterWriteElement(writer, BAD_CAST "matches", BAD_CAST [value UTF8String]);
                }
                
            
        }
    
        if(self.eq) {
            
                
                for(NSString *value in self.eq) {
                    xmlTextWriterWriteElement(writer, BAD_CAST "eq", BAD_CAST [value UTF8String]);
                }
                
            
        }
    
        if(self.startsWith) {
            
                
                for(NSString *value in self.startsWith) {
                    xmlTextWriterWriteElement(writer, BAD_CAST "starts-with", BAD_CAST [value UTF8String]);
                }
                
            
        }
    
        if(self.endsWith) {
            
                
                for(NSString *value in self.endsWith) {
                    xmlTextWriterWriteElement(writer, BAD_CAST "ends-with", BAD_CAST [value UTF8String]);
                }
                
            
        }
    
        if(self.contains) {
            
                
                for(NSString *value in self.contains) {
                    xmlTextWriterWriteElement(writer, BAD_CAST "contains", BAD_CAST [value UTF8String]);
                }
                
            
        }
    
}

        
- (void) dealloc {
  self.name = nil;
  self.optional = nil;
  self.matches = nil;
  self.eq = nil;
  self.startsWith = nil;
  self.endsWith = nil;
  self.contains = nil;
        
  [super dealloc];
}

@end
	