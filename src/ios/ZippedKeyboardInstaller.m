#import <Foundation/Foundation.h>

#import "Objective-Zip.h"
#import "ZippedKeyboardInstaller.h"
#import "KeyboardHelper.h"

@implementation ZippedKeyboardInstaller

- (id) initWithZipName: (NSString *) name keyboardSlug: (NSString *) keyboardSlug
{
    self = [super init];
    if (self) {
        zippedKeyboard = [[ZippedKeyboard alloc] initWithZipName: name];
        zipName = name;
        targetFolderPath = [[KeyboardHelper documentsPath] stringByAppendingPathComponent: keyboardSlug];
    }
    return self;
}

//TODO: directoryPath in constructor
- (ZippedKeyboardInstaller *) installFromDirectory: (NSString *) directoryPath{
    [zippedKeyboard inititalizeZipFromDirectory: directoryPath];
    [self install];
    
    return self;
}

- (ZippedKeyboardInstaller *) install{
    [self createDirectoryStructure];
    
    for (OZFileInZipInfo *zipInformation in zippedKeyboard.zipFileInformation) {
        if([KeyboardHelper isImageFile: zipInformation.name])
            [self extractFile: zipInformation.name toDirectory: IMAGES_DIRECTORY];
        else if([KeyboardHelper isSoundFile: zipInformation.name])
            [self extractFile: zipInformation.name toDirectory: SOUNDS_DIRECTORY];
    }
    
    [zippedKeyboard.zipFile close];
    
    return self;
}

- (void) createDirectoryStructure{
    //TODO: capture error when unsuccessful
    [self createDirectory: IMAGES_DIRECTORY];
    [self createDirectory: SOUNDS_DIRECTORY];
}

- (void) createDirectory: (NSString *) directoryName{
    NSError *error;
    NSString *directoryPath = [targetFolderPath stringByAppendingPathComponent: directoryName];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath: directoryPath])
        [[NSFileManager defaultManager] createDirectoryAtPath: directoryPath
                                  withIntermediateDirectories: YES
                                                   attributes: nil
                                                        error: &error];
}

- (void) extractFile: (NSString *) fileName toDirectory: (NSString *) directoryName{
    NSString *trimmedFilePath = [self trimZipNameOffPath: fileName];
    
    [self createMissingNestedDirectoriesIn: directoryName forPath: trimmedFilePath];
    
    NSFileHandle *fileHandle = [self createFileHandleForFile: trimmedFilePath
                                                 inDirectory: directoryName];
    [zippedKeyboard.zipFile locateFileInZip: fileName];
    
    OZZipReadStream *readStream = [zippedKeyboard.zipFile readCurrentFileInZip];
    NSMutableData *buffer= [[NSMutableData alloc] initWithLength: BUFFER_SIZE];
    
    [buffer setLength: BUFFER_SIZE];
    int totalBytesRead = 0;
    
    do{
        long bytesRead= [readStream readDataWithBuffer: buffer];
        if (bytesRead <= 0)
            break;
        
        [buffer setLength: bytesRead];
        [fileHandle writeData: buffer];
        
        totalBytesRead += bytesRead;
    } while (YES); //TODO: while(bytesRead > 0)
    
    [fileHandle closeFile];
    [readStream finishedReading];
}

- (NSFileHandle *) createFileHandleForFile: (NSString *) fileName inDirectory: (NSString *) directoryName{
    NSString *filePath = [NSString stringWithFormat:@"%@/%@",  directoryName, fileName];
    NSString *fullFilePath = [targetFolderPath stringByAppendingPathComponent: filePath];
    
    [[NSFileManager defaultManager] createFileAtPath: fullFilePath
                                            contents: [NSData data]
                                          attributes: nil];
    
    return [NSFileHandle fileHandleForWritingAtPath: fullFilePath];
}

- (NSString *) trimZipNameOffPath: (NSString *) path{
    NSString *zipNameWithoutExtension = [zipName stringByDeletingPathExtension];
    NSUInteger zipNameIndex = [path rangeOfString: [NSString stringWithFormat:@"%@/", zipNameWithoutExtension]].location;
    
    if(zipNameIndex != NSNotFound)
        return [path substringFromIndex: (zipNameIndex + zipNameWithoutExtension.length + 1)];
    
    return path;
}

- (void) createMissingNestedDirectoriesIn: (NSString *) directoryName forPath: (NSString *) path{
    NSError *error;

    //TODO: nested path exists check?
     NSString *nestedPath = [self trimFileNameOffPath: path];
    if(nestedPath){
        NSString *nestedDirectoryPath = [NSString stringWithFormat:@"%@/%@/%@", targetFolderPath, directoryName, nestedPath];
        [[NSFileManager defaultManager] createDirectoryAtPath: nestedDirectoryPath
                                  withIntermediateDirectories: YES
                                                   attributes: nil
                                                        error: &error];
    }
}

//TODO: remove?
- (Boolean) isNestedPath: (NSString *) path{
    NSUInteger slashIndex = [path rangeOfString: @"/"].location;
    NSUInteger lastSlashIndex = [path rangeOfString: @"/"].location;
    
    return (slashIndex != NSNotFound) && [path substringToIndex: lastSlashIndex].length > 0;
}

- (NSString *) trimFileNameOffPath: (NSString *) path{
    NSUInteger lastSlashIndex = [path rangeOfString: @"/" options:NSBackwardsSearch].location;
    if(lastSlashIndex == NSNotFound)
        return nil;
    
    return [path substringToIndex: lastSlashIndex];
}

@end