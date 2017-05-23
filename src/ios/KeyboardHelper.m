#import <Foundation/Foundation.h>

#import "KeyboardHelper.h"

NSString *const FILE_NAME = @"fileName";
NSString *const UNCOMPRESSED_FILE_SIZE = @"uncompressedFileSize";
NSString *const INDEX_STRING = @"indexString";
NSString *const EXTRAS_STRING = @"extras";
NSString *const KEYBOARDS_PATH = @"www/assets/keyboards";
NSString *const SOUNDS_DIRECTORY = @"sounds";
NSString *const IMAGES_DIRECTORY = @"images";
NSString *const INDEX_FILE_NAME = @"index.csv";
NSString *const ZIP_EXTENSION = @".zip";
long const BUFFER_SIZE = 8192;

NSString *TEMP_DIRECTORY_NAME = @"temp";
NSString *IMAGE_PREFIX_PATTERN = @"\\bimage-[\\w]*";
NSString *IMAGE_EXTENSION_PATTERN = @"(^[^\\.]+(\\.(?i)(jpg|png|gif))$)";
NSString *SOUND_PREFIX_PATTERN = @"\\bsound-[\\w]*";
NSString *SOUND_EXTENSION_PATTERN = @"(^[^\\.]+(\\.(?i)(3gp|wav|mp3|m4a))$)";
NSString *EXTRA_PATTERN = @"(^[a-zA-Z].*\\.extra\\.json$)";

@implementation KeyboardHelper

+ (NSString *) resourcePath{
    return [[NSBundle mainBundle] resourcePath];
}

+ (NSString *) keyboardsFullPath{
    return [[[self class] resourcePath] stringByAppendingPathComponent: KEYBOARDS_PATH];
}

+ (NSString *) documentsPath{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [paths objectAtIndex:0];
}

+ (NSString *) applicationTempDirectoryPath{
    NSString *documentsPath = [[self class] documentsPath];

    return [NSString stringWithFormat:@"%@/%@",  documentsPath, TEMP_DIRECTORY_NAME];
}

+ (NSString *) tmpDirectoryPath{
    return NSTemporaryDirectory();
}

+ (Boolean) isIndexFile: (NSString *) filePath{
    return [[filePath lastPathComponent] isEqualToString: INDEX_FILE_NAME];
}

+ (Boolean) isExtraFile: (NSString *) filePath{
    Boolean result = [[self class] string: [filePath lastPathComponent] matchesPattern: EXTRA_PATTERN];

    return result;
}

+ (Boolean) isImageFile: (NSString *) filePath{
    Boolean result = [[self class] string: [filePath lastPathComponent] matchesPattern: IMAGE_EXTENSION_PATTERN];
    Boolean prefixResult = [[self class] string: [filePath lastPathComponent] matchesPattern: IMAGE_PREFIX_PATTERN];

    return result || prefixResult;
}

+ (Boolean) isSoundFile: (NSString *) filePath{
    Boolean result = [[self class] string: [filePath lastPathComponent] matchesPattern: SOUND_EXTENSION_PATTERN];
    Boolean prefixResult = [[self class] string: [filePath lastPathComponent] matchesPattern: SOUND_PREFIX_PATTERN];

    return result || prefixResult;
}

+ (Boolean) string: (NSString *) string matchesPattern: (NSString *) pattern{
    NSRange searchedRange = NSMakeRange(0, [string length]);
    NSError *error = nil;
    
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern: pattern
                                                                           options: 0
                                                                             error: &error];
    NSUInteger count = [regex numberOfMatchesInString: string
                                              options: 0
                                                range: searchedRange];
    
    return count != 0;
}

@end
