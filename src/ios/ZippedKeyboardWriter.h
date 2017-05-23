#ifndef ZippedKeyboardWriter_h
#define ZippedKeyboardWriter_h


#endif /* ZippedKeyboardWriter_h */

#import "Objective-Zip.h"

@interface ZippedKeyboardWriter : NSObject{
    NSString *keyboardName;
    NSString *keyboardDirectoryPath;
    NSString *zipOutputPath;
    NSString *tmpFilesPath;
    NSString *zipFileName;
    OZZipFile *zipFile;
}

- (id) initWithKeyboardName: (NSString *) name;
- (ZippedKeyboardWriter *) zip;
- (NSString *) getZipName;

@end
