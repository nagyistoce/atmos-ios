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
#import "TNSPolicyType.h"
        
@implementation TNSPolicyType 

@synthesize expiration;
@synthesize maxUploads;
@synthesize maxDownloads;
@synthesize source;
@synthesize contentLengthRange;
@synthesize formField;

        
- (void) readAttributes: (xmlTextReaderPtr) reader {
  
    NSNumberFormatter* intFormatter = [[[NSNumberFormatter alloc] init] autorelease];
    intFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    NSDateFormatter* dateFormatter = [[[NSDateFormatter alloc] init] autorelease]; 
    dateFormatter.timeStyle = NSDateFormatterFullStyle;
    dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
            
}

- (id) initWithReader: (xmlTextReaderPtr) reader {
  int _complexTypeXmlDept = xmlTextReaderDepth(reader);
  self = [super init];
  if(self) {
    NSNumberFormatter* intFormatter = [[[NSNumberFormatter alloc] init] autorelease];
    intFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    NSDateFormatter* dateFormatter = [[[NSDateFormatter alloc] init] autorelease]; 
    dateFormatter.timeStyle = NSDateFormatterFullStyle;
    dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
            
  [self readAttributes: reader];

    self.expiration = nil;
    self.maxUploads = nil;
    self.maxDownloads = nil;
    self.source = nil;
    self.contentLengthRange = nil;
    self.formField = [NSMutableArray array];

    int _currentNodeType = xmlTextReaderRead(reader);
    int _currentXmlDept = xmlTextReaderDepth(reader);
    while(_currentNodeType != XML_READER_TYPE_NONE && _complexTypeXmlDept < _currentXmlDept) {
      if(_currentNodeType == XML_READER_TYPE_ELEMENT) {  
        NSString* _currentElementName = [NSString stringWithCString: (const char*) xmlTextReaderConstLocalName(reader) encoding:NSUTF8StringEncoding];
        if([@"expiration" isEqual: _currentElementName]) {
          {xmlTextReaderRead(reader);
                NSString *dateValue = [NSString stringWithCString: (const char*) xmlTextReaderConstValue(reader) encoding: NSUTF8StringEncoding];
                // Remove bogus .000 milliseconds if they exist
                dateValue = [dateValue stringByReplacingOccurrencesOfString:@".000" withString:@""];
                self.expiration = [dateFormatter dateFromString:dateValue];
                xmlTextReaderRead(reader);}
        } else if([@"max-uploads" isEqual: _currentElementName]) {
          xmlTextReaderRead(reader);
          self.maxUploads = [intFormatter numberFromString: [NSString stringWithCString: (const char*) xmlTextReaderConstValue(reader) encoding: NSUTF8StringEncoding]];
          xmlTextReaderRead(reader);
        } else if([@"max-downloads" isEqual: _currentElementName]) {
          xmlTextReaderRead(reader);
          self.maxDownloads = [intFormatter numberFromString: [NSString stringWithCString: (const char*) xmlTextReaderConstValue(reader) encoding: NSUTF8StringEncoding]];
          xmlTextReaderRead(reader);
        } else if([@"source" isEqual: _currentElementName]) {
          self.source = [[[TNSSourceType alloc] initWithReader: reader] autorelease];
        } else if([@"content-length-range" isEqual: _currentElementName]) {
          self.contentLengthRange = [[[TNSContentLengthRangeType alloc] initWithReader: reader] autorelease];
        } else if([@"form-field" isEqual: _currentElementName]) {
          [self.formField addObject: [[[TNSFormFieldType alloc] initWithReader: reader] autorelease]];
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
        

+ (TNSPolicyType*) fromPolicy: (NSData*) data {
  TNSPolicyType* obj = nil;
  xmlTextReaderPtr reader = xmlReaderForMemory([data bytes], 
                                               (int)[data length], 
                                               NULL, 
                                               NULL, 
                                               0);
  if(reader != nil) {
    int ret = xmlTextReaderRead(reader);
    if(ret == XML_READER_TYPE_ELEMENT) {
      obj = [[[TNSPolicyType alloc] initWithReader: reader] autorelease];
    }
    xmlFreeTextReader(reader);      
  }
  return obj;        
}

// Creates a new document from this object.  The toplevel element will be
// 'policy'
- (NSData*) toPolicy {
    xmlDocPtr doc;
    xmlTextWriterPtr writer;
    NSData *data;
    xmlChar *xmlbuff; \
    int buffersize; \

    writer = xmlNewTextWriterDoc(&doc, 0);
    xmlTextWriterStartDocument(writer, "1.0", "UTF-8", NULL);
    xmlTextWriterStartElement(writer, BAD_CAST "policy");

    [self writeXml:writer];

    xmlTextWriterEndElement(writer);
    xmlTextWriterEndDocument(writer);

    xmlFreeTextWriter(writer);
    
    xmlDocDumpFormatMemoryEnc(doc, &xmlbuff, &buffersize, "UTF-8", 1);
    data = [NSData dataWithBytes:(const char*)xmlbuff length:buffersize];
    xmlFreeDoc(doc);
    xmlFree(xmlbuff);
    return data;
}


        
// Populates the current element in the textwriter with this object's data.
- (void) writeXml: (xmlTextWriterPtr) writer {
    
        
    
        NSDateFormatter* dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
                dateFormatter.timeStyle = NSDateFormatterFullStyle;
                dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
                dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
    
    // Attributes
    
        
    // Child elements
    
        if(self.expiration) {
            
                
                xmlTextWriterWriteElement(writer, BAD_CAST "expiration", BAD_CAST [[dateFormatter stringFromDate:self.expiration] UTF8String]);
                
            
        }
    
        if(self.maxUploads) {
            
                
                xmlTextWriterWriteElement(writer, BAD_CAST "max-uploads", BAD_CAST [[self.maxUploads stringValue] UTF8String]);
                
            
        }
    
        if(self.maxDownloads) {
            
                
                xmlTextWriterWriteElement(writer, BAD_CAST "max-downloads", BAD_CAST [[self.maxDownloads stringValue] UTF8String]);
                
            
        }
    
        if(self.source) {
            
                
                xmlTextWriterStartElement(writer, BAD_CAST "source");
                [self.source writeXml:writer];
                xmlTextWriterEndElement(writer);
                
            
        }
    
        if(self.contentLengthRange) {
            
                
                xmlTextWriterStartElement(writer, BAD_CAST "content-length-range");
                [self.contentLengthRange writeXml:writer];
                xmlTextWriterEndElement(writer);
                
            
        }
    
        if(self.formField) {
            
                
                for(TNSFormFieldType *value in self.formField) {
                xmlTextWriterStartElement(writer, BAD_CAST "form-field");
                [value writeXml:writer];
                xmlTextWriterEndElement(writer);
                }
                
            
        }
    
}

        
- (void) dealloc {
  self.expiration = nil;
  self.maxUploads = nil;
  self.maxDownloads = nil;
  self.source = nil;
  self.contentLengthRange = nil;
  self.formField = nil;
        
  [super dealloc];
}

@end
	