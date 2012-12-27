//NSData additions from colloquy project

@interface NSData (NSDataAdditions)
+ (NSData *) dataWithBase64EncodedString:(NSString *) string;
- (id) initWithBase64EncodedString:(NSString *) string;

- (NSString *) base64Encoding;

- (BOOL) hasPrefix:(NSData *) prefix;
- (BOOL) hasPrefixBytes:(void *) prefix length:(unsigned int) length;
@end
