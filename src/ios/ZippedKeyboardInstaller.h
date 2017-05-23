#ifndef ZippedKeyboardInstaller_h
#define ZippedKeyboardInstaller_h


#endif /* ZippedKeyboardInstaller_h */

#import "ZippedKeyboard.h"

@interface ZippedKeyboardInstaller : NSObject{
    ZippedKeyboard *zippedKeyboard;
    NSString *zipName;
    NSString *targetFolderPath;
}

- (id) initWithZipName: (NSString *) name keyboardSlug: (NSString *) slug;
- (ZippedKeyboardInstaller *) installFromDirectory: (NSString *) directoryPath;

@end
