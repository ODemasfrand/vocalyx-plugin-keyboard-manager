#import <Foundation/Foundation.h>

#import "ZippedKeyboardWriter.h"
#import "KeyboardHelper.h"

NSString *const FILES_FOLDER_NAME = @"files";

@implementation ZippedKeyboardWriter

- (id)initWithKeyboardName:(NSString *) name{
    self = [super init];
    
    if (self) {
        keyboardName = name;
        keyboardDirectoryPath = [NSString stringWithFormat: @"%@/%@",  [KeyboardHelper documentsPath],  name];
        tmpFilesPath = [NSString stringWithFormat: @"%@/%@", [KeyboardHelper tmpDirectoryPath], FILES_FOLDER_NAME];
        zipFileName = [self generateZipFileName];
        zipOutputPath = [NSString stringWithFormat: @"%@/%@", tmpFilesPath, zipFileName];

        [self cleanupTempDirectory];
    }
    
    return self;
}

- (NSString *)getZipName{
    return zipFileName;
}

- (NSString *) generateZipFileName{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat: @"yyyy-MM-dd_HH-mm-ss"];
    
    NSString *formattedDateString = [formatter stringFromDate: [NSDate date]];
    
    return [NSString stringWithFormat: @"%@-%@%@", keyboardName, formattedDateString, ZIP_EXTENSION];
    
}

- (ZippedKeyboardWriter *) zip{
    NSError *error;

    zipFile = [[OZZipFile alloc] initWithFileName: zipOutputPath
                                             mode: OZZipFileModeCreate
                                  legacy32BitMode: YES];

    NSArray *filesSubPaths = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath: keyboardDirectoryPath
                                                                                 error: &error];

    for(NSString *subPath in filesSubPaths){
        if([self isFile: subPath])
            [self addFileToZipFromPath: [NSString stringWithFormat: @"%@/%@",  keyboardDirectoryPath, subPath]
                              withName: [self sanitizePath: subPath]];
    }

    [self addIndexAndExtraFilesToZip];

    [zipFile close];
    return self;
}

- (NSString *) sanitizePath: (NSString *) path{
    if([KeyboardHelper isImageFile: path])
        return [path substringFromIndex: (0 + IMAGES_DIRECTORY.length + 1)];
    if([KeyboardHelper isSoundFile: path])
        return [path substringFromIndex: (0 + SOUNDS_DIRECTORY.length + 1)];

    return path;
}

- (void) addFileToZipFromPath: (NSString *) path withName: (NSString *) name{
    OZZipWriteStream *stream = nil ;
    
    stream = [zipFile writeFileInZipWithName: name
                            compressionLevel: OZZipCompressionLevelBest];

    NSData *data = [NSData dataWithContentsOfFile: path];

    [stream writeData: data];
    [stream finishedWriting];
}

- (Boolean) isFile: (NSString *) path{
    return [KeyboardHelper isSoundFile: path] || [KeyboardHelper isImageFile: path] || [KeyboardHelper isIndexFile: path] || [KeyboardHelper isExtraFile: path];
}

- (void) cleanupTempDirectory{
    NSError *error;

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *fileArray = [fileManager contentsOfDirectoryAtPath: tmpFilesPath error: &error];
    for (NSString *filename in fileArray)
        [fileManager removeItemAtPath: [tmpFilesPath stringByAppendingPathComponent: filename]
                                error: &error];
}

- (void) addIndexAndExtraFilesToZip{
    NSError *error;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *filesPaths = [fileManager contentsOfDirectoryAtPath: [NSString stringWithFormat:@"%@/%@", [KeyboardHelper applicationTempDirectoryPath], keyboardName]
                                                           error: &error];
    
    for(NSString *subPath in filesPaths)
        if([self isFile: subPath])
            [self addFileToZipFromPath: [NSString stringWithFormat:@"%@/%@/%@", [KeyboardHelper applicationTempDirectoryPath], keyboardName, subPath] withName: subPath];
}

@end
