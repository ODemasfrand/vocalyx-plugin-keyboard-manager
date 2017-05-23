#ifndef ZippedKeyboard_h
#define ZippedKeyboard_h


#endif /* ZippedKeyboard_h */

#import <Foundation/Foundation.h>

#import "Objective-Zip.h"

@interface ZippedKeyboard : NSObject

@property NSString *zipName;
@property (strong) OZZipFile *zipFile;
@property (strong) NSArray *zipFileInformation;

- (id) initWithZipName: (NSString *) zipFileName;
- (void) inititalizeZipFromDirectory: (NSString *) directoryPath;

@end
