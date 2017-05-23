#import "ZippedKeyboard.h"

@implementation ZippedKeyboard

- (id) initWithZipName:(NSString *) zipFileName{
    self = [super init];
    if (self) {
        self.zipName = zipFileName;
    }
    
    return self;
}

- (void) inititalizeZipFromDirectory: (NSString *) directoryPath{
    NSString *path = [NSString stringWithFormat: @"%@/%@", directoryPath, self.zipName];
    self.zipFile = [[OZZipFile alloc] initWithFileName: path mode: OZZipFileModeUnzip];
    self.zipFileInformation = [self.zipFile listFileInZipInfos];
}

@end