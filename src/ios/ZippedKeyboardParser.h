#ifndef ZippedKeyboardParser_h
#define ZippedKeyboardParser_h


#endif /* ZippedKeyboardParser_h */

#import "ZippedKeyboard.h"

@interface ZippedKeyboardParser : NSObject {
    ZippedKeyboard *zippedKeyboard;
    NSString *zipName;
    NSString *directoryPath;
    NSString *indexString;
    NSMutableArray *extraPropertiesList;
    long uncompressedSize;
}

- (id) initWithZipName: (NSString *) name directoryPath: (NSString *) path;
- (ZippedKeyboardParser *) read;
- (NSString *) toJSON;

@end