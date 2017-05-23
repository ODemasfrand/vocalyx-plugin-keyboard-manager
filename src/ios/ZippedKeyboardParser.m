#import <Foundation/Foundation.h>

#import "ZippedKeyboardParser.h"
#import "Objective-Zip.h"
#import "KeyboardHelper.h"

@implementation ZippedKeyboardParser

- (id) initWithZipName: (NSString *) name directoryPath: (NSString *) path{
    self = [super init];
    if (self) {
        zipName = name;
        directoryPath = path;
        zippedKeyboard = [[ZippedKeyboard alloc] initWithZipName: name];
        extraPropertiesList = [[NSMutableArray alloc] init];
    }
    return self;
}

- (ZippedKeyboardParser *) read{
    [zippedKeyboard inititalizeZipFromDirectory: directoryPath];
    
    for (OZFileInZipInfo *zipInformation in zippedKeyboard.zipFileInformation) {
        [zippedKeyboard.zipFile locateFileInZip: zipInformation.name];
        
        uncompressedSize += zipInformation.length;
        
        if([KeyboardHelper isIndexFile: zipInformation.name])
            [self readIndexFile: zipInformation];
        NSLog(@"%@", [NSString stringWithFormat:@"%@",  zipInformation.name]);
        if([KeyboardHelper isExtraFile: zipInformation.name])
            [self readExtraFile: zipInformation];
    }

    [zippedKeyboard.zipFile close];

    return self;
}

- (NSString *) toJSON{
    NSError * error;
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    [dictionary setValue: zipName forKey: FILE_NAME];
    [dictionary setObject: [NSNumber numberWithInteger:uncompressedSize] forKey: UNCOMPRESSED_FILE_SIZE];
    [dictionary setValue: indexString forKey: INDEX_STRING];
    [dictionary setValue: [self createExtraJson] forKey: EXTRAS_STRING];

    NSData *json = [NSJSONSerialization dataWithJSONObject: dictionary
                                                   options: NSJSONWritingPrettyPrinted
                                                     error: &error];
    //TODO: check why not send json intsead of json string
    NSString *jsonString = [[NSString alloc] initWithData: json
                                                 encoding: NSUTF8StringEncoding];

    return jsonString;
}

- (void) readIndexFile: (OZFileInZipInfo *) zipInformation{
    indexString = [self readFile: zipInformation];
}

- (void) readExtraFile: (OZFileInZipInfo *) zipInformation{
    [extraPropertiesList addObject: [self readFile: zipInformation]];
}

- (NSString *) readFile: (OZFileInZipInfo *) zipInformation{
    NSString *dataString;

    OZZipReadStream *zipReadStream= [zippedKeyboard.zipFile readCurrentFileInZip];
    NSMutableData *data= [[NSMutableData alloc] initWithLength: zipInformation.length];
    [zipReadStream readDataWithBuffer: data];

    dataString = [[NSString alloc] initWithData: data encoding: NSASCIIStringEncoding];
    [zipReadStream finishedReading];

    return dataString;
}

- (NSString *) createExtraJson{
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    NSError * error;
    for (id jsonString in extraPropertiesList) {
       NSMutableDictionary *collection=[NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]
                                                          options:kNilOptions
                                                            error:&error];

        for(NSString *key in [collection allKeys])
            [dictionary setValue: collection[key] forKey: key];
    }
    NSData *json = [NSJSONSerialization dataWithJSONObject: dictionary
                                                   options: NSJSONWritingPrettyPrinted
                                                     error: &error];
    NSString *jsonString = [[NSString alloc] initWithData: json
                                                 encoding: NSUTF8StringEncoding];
    return jsonString;
}

@end

