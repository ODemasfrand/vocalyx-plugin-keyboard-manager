#ifndef KeyboardHelper_h
#define KeyboardHelper_h


#endif /* KeyboardHelper_h */

extern NSString *const FILE_NAME;
extern NSString *const UNCOMPRESSED_FILE_SIZE;
extern NSString *const INDEX_STRING;
extern NSString *const EXTRAS_STRING;
extern NSString *const KEYBOARDS_PATH;
extern NSString *const SOUNDS_DIRECTORY;
extern NSString *const IMAGES_DIRECTORY;
extern NSString *const INDEX_FILE_NAME;
extern NSString *const ZIP_EXTENSION;
extern long const BUFFER_SIZE;

@interface KeyboardHelper : NSObject

+ (NSString *) resourcePath;
+ (NSString *) keyboardsFullPath;
+ (NSString *) documentsPath;
+ (NSString *) applicationTempDirectoryPath;
+ (NSString *) tmpDirectoryPath;
+ (Boolean) isIndexFile: (NSString *) filePath;
+ (Boolean) isExtraFile: (NSString *) filePath;
+ (Boolean) isImageFile: (NSString *) filePath;
+ (Boolean) isSoundFile: (NSString *) filePath;

@end

