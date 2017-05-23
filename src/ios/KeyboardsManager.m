#import <Cordova/CDV.h>

#import "Objective-Zip.h"
#import "KeyboardsManager.h"

#import "ZippedKeyboardParser.h"
#import "ZippedKeyboardInstaller.h"
#import "ZippedKeyboardWriter.h"

#import "KeyboardHelper.h"

@implementation KeyboardsManager

- (void) listEmbeddedKeyboards: (CDVInvokedUrlCommand*) command{
    [self.commandDelegate runInBackground:^{
        CDVPluginResult* pluginResult = nil;
        @try {
            NSError *error;
            
            NSString *keyboardsFullPath = [KeyboardHelper keyboardsFullPath];
            
            NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath: keyboardsFullPath error: &error];
            
            NSPredicate *filter = [NSPredicate predicateWithFormat: @"self ENDSWITH '.zip'"];
            NSArray *filterredDirectoryContents = [dirContents filteredArrayUsingPredicate: filter];
            
            NSMutableArray *keyboardsData = [[NSMutableArray alloc] init];
            
            for (id file in filterredDirectoryContents) {
                ZippedKeyboardParser *zippedKeyboardParser = [[ZippedKeyboardParser alloc] initWithZipName: file
                                                                                             directoryPath: [KeyboardHelper keyboardsFullPath]];
                [zippedKeyboardParser read];
                
                NSString* data = [zippedKeyboardParser toJSON];
                [keyboardsData addObject: data];
            }
            
            pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK messageAsArray: keyboardsData];
        } @catch(NSException *e){
            pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_ERROR];
        }
        
        [self.commandDelegate sendPluginResult: pluginResult callbackId: command.callbackId];
    }];
}

- (void)installEmbedded: (CDVInvokedUrlCommand *) command{
    NSString* zipName = [command.arguments objectAtIndex: 0];
    NSString* keyboardSlug = [command.arguments objectAtIndex: 1];
    
    [self.commandDelegate runInBackground:^{
        CDVPluginResult* pluginResult = nil;
        @try {
            ZippedKeyboardInstaller *zippedKeyboardInstaller = [[ZippedKeyboardInstaller alloc] initWithZipName: zipName
                                                                                                   keyboardSlug: keyboardSlug];
            [zippedKeyboardInstaller installFromDirectory: [KeyboardHelper keyboardsFullPath]];
            
            pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK];
        } @catch(NSException *e){
            pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_ERROR];
        }
        
        [self.commandDelegate sendPluginResult: pluginResult  callbackId: command.callbackId];
    }];
}

- (void)install: (CDVInvokedUrlCommand *) command{
    NSString* zipName = [command.arguments objectAtIndex: 0];
    NSString* keyboardSlug = [command.arguments objectAtIndex: 1];
    
    [self.commandDelegate runInBackground:^{
        CDVPluginResult* pluginResult = nil;
        @try {
            ZippedKeyboardInstaller *zippedKeyboardInstaller = [[ZippedKeyboardInstaller alloc] initWithZipName: zipName
                                                                                                   keyboardSlug: keyboardSlug];
            
            [zippedKeyboardInstaller installFromDirectory: [KeyboardHelper applicationTempDirectoryPath]];
            
            pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK];
        } @catch(NSException *e){
            pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_ERROR];
        }
        [self.commandDelegate sendPluginResult: pluginResult  callbackId: command.callbackId];
    }];
}

- (void)parseKeyboardZip: (CDVInvokedUrlCommand *) command{
    NSString* zipName = [NSString stringWithFormat:@"%@%@", [command.arguments objectAtIndex: 0], ZIP_EXTENSION];
    
    [self.commandDelegate runInBackground:^{
        CDVPluginResult* pluginResult = nil;
        @try {
            ZippedKeyboardParser *zippedKeyboardParser = [[ZippedKeyboardParser alloc] initWithZipName: zipName
                                                                                         directoryPath: [KeyboardHelper applicationTempDirectoryPath]];
            [zippedKeyboardParser read];
            
            NSString* data = [zippedKeyboardParser toJSON];
            pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK messageAsString: data];
        } @catch(NSException *e){
            pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_ERROR];
        }
        
        [self.commandDelegate sendPluginResult: pluginResult callbackId: command.callbackId];
    }];
}

- (void)zipKeyboard: (CDVInvokedUrlCommand *) command{
    
    NSString* keyboardName = [command.arguments objectAtIndex: 0];
    
    [self.commandDelegate runInBackground:^{
        CDVPluginResult* pluginResult = nil;
        @try {
            ZippedKeyboardWriter *zippedKeyboardWriter = [[ZippedKeyboardWriter alloc] initWithKeyboardName: keyboardName];
            [zippedKeyboardWriter zip];
            
            pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK messageAsString: [zippedKeyboardWriter getZipName]];
        } @catch(NSException *e){
            pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_ERROR];
        }
        
        [self.commandDelegate sendPluginResult: pluginResult callbackId: command.callbackId];
    }];
    
}

- (void)getFolderSize: (CDVInvokedUrlCommand *) command{
    NSString* folderName = [command.arguments objectAtIndex: 0];
    
    [self.commandDelegate runInBackground:^{
        CDVPluginResult* pluginResult = nil;
        @try {
            
            long size = [self sizeOfFolder: [NSString stringWithFormat:@"%@/%@", [KeyboardHelper documentsPath], folderName]];
            
            pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK messageAsDouble: size];
        } @catch(NSException *e){
            pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_ERROR];
        }
        [self.commandDelegate sendPluginResult: pluginResult callbackId: command.callbackId];
    }];
}

-(unsigned long long int) sizeOfFolder: (NSString *)folderPath{
    NSArray *contents = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath: folderPath error: nil];
    
    NSEnumerator *contentsEnumurator = [contents objectEnumerator];
    
    NSString *file;
    unsigned long long int folderSize = 0;
    
    while (file = [contentsEnumurator nextObject]) {
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath: [folderPath stringByAppendingPathComponent: file]
                                                                                        error: nil];
        folderSize += [[fileAttributes objectForKey: NSFileSize] intValue];
    }
    
    return folderSize;
}
@end
