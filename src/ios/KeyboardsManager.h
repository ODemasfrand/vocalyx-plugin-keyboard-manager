#import <Cordova/CDV.h>

@interface KeyboardsManager: CDVPlugin

- (void) listEmbeddedKeyboards: (CDVInvokedUrlCommand*)command;
- (void) installEmbedded: (CDVInvokedUrlCommand*)command;
- (void) install: (CDVInvokedUrlCommand*)command;
- (void) zipKeyboard: (CDVInvokedUrlCommand*)command;
- (void) parseKeyboardZip: (CDVInvokedUrlCommand*)command;
- (void) getFolderSize: (CDVInvokedUrlCommand*)command;

@end
