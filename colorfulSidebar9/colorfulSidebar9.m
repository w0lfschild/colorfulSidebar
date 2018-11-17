//
//  colorfulSidebar9.m
//  colorfulSidebar9
//
//  Created by Wolfgang Baird
//  Copyright 2016 - 2017 Wolfgang Baird.
//

@import AppKit;
#import "ZKSwizzle.h"

static NSDictionary *cfsbIconMappingDict = nil;
struct TFENode {
    struct OpaqueNodeRef *fNodeRef;
};
NSInteger macOS;

@interface colorfulSidebar9 : NSObject
+ (void)setUpIconMappingDict;
@end

@interface wb_NSTableRowView : NSView
@end



__attribute__((constructor)) void colorfulSidebar14() {
}

ZKSwizzleInterface(wbdd_TView, TView, NSView)
@implementation wbdd_TView

- (void)setFrameSize:(struct CGSize)arg1 {
//    NSLog(@"hacked iconveiw %@", self.accessibilityURL);
    ZKOrig(void, arg1);
}

@end

@implementation wb_NSTableRowView

- (void)layout {
    ZKOrig(void);
    NSButton *theButton = self.subviews.lastObject;
    if ([theButton respondsToSelector: @selector(action)]) {
        if ([NSStringFromSelector(theButton.action) isEqualToString:@"_outlineControlClicked:"]) {
            NSLog(@"Testing ... %@", self.className);
            if ([theButton respondsToSelector:@selector(tag)] && [theButton respondsToSelector:@selector(performClick:)]) {
                if (theButton.tag != 1337) {
                    [theButton performClick:nil];
                    [theButton performClick:nil];
                    theButton.tag = 1337;
                }
            }
        }
    }
}

@end

@interface wb_TImageView : NSImageView
@end

@implementation wb_TImageView

- (void)layout {
    NSLog(@"wb_ %s", __PRETTY_FUNCTION__);
    ZKOrig(void);
    if (self.class == NSClassFromString(@"TImageView") || self.class == NSClassFromString(@"FI_TImageView")) {
        if ([self.superview class] == NSClassFromString(@"TSidebarItemCell") || [self.superview class] == NSClassFromString(@"FI_TSidebarItemCell")) {
            [self wb_setImage:self.superview];
            
            // Shitty hack to force reload in com.apple.appkit.xpc.openAndSavePanelService
            if ([NSProcessInfo.processInfo.processName isEqualToString:@"com.apple.appkit.xpc.openAndSavePanelService"]) {
                NSView* FI_TSidebarView = self.superview.superview.superview;
                for (NSView* v in FI_TSidebarView.subviews) {
                    NSButton *theButton = v.subviews.lastObject;
                    if ([theButton respondsToSelector: @selector(action)]) {
                        if ([NSStringFromSelector(theButton.action) isEqualToString:@"_outlineControlClicked:"]) {
                            NSLog(@"Testing ... %@", self.className);
                            if ([theButton respondsToSelector:@selector(tag)] && [theButton respondsToSelector:@selector(performClick:)]) {
                                if (theButton.tag != 1337) {
                                    [theButton performClick:nil];
                                    [theButton performClick:nil];
                                    theButton.tag = 1337;
                                }
                            }
                        }
                    }
//                    if ([v.subviews.lastObject respondsToSelector:@selector(performClick:)]) {
//                        NSButton *theButton = v.subviews.lastObject;
//                        if ([theButton respondsToSelector:@selector(tag)]) {
//                            if (theButton.tag != 1337) {
//                                [theButton performSelector:@selector(performClick:) withObject:nil];
//                                [theButton performSelector:@selector(performClick:) withObject:nil];
//                                theButton.tag = 1337;
//                            }
//                        }
//                    }
                }
            }
        }
    }
}

- (void)wb_setImage:(id)itemCell {
    SEL aSEL = @selector(accessibilityAttributeNames);
    if ([itemCell respondsToSelector:aSEL] && [[itemCell performSelector:aSEL] containsObject:NSAccessibilityURLAttribute]) {
        NSImage *image = nil;
        NSURL *aURL = [itemCell accessibilityAttributeValue:NSAccessibilityURLAttribute];
        if ([aURL isFileURL]) {
            NSString *path = [aURL path];
            image = cfsbIconMappingDict[path];
            if (!image) {
                aSEL = @selector(name);
                if ([itemCell respondsToSelector:aSEL]) {
                    image = cfsbIconMappingDict[[itemCell performSelector:aSEL]];
                }
            }
            if (!image) {
                image = [[NSWorkspace sharedWorkspace] iconForFile:path];
            }
        } else {
            image = cfsbIconMappingDict[[aURL absoluteString]];
        }
        if (!image) {
            aSEL = @selector(name);
            if ([itemCell respondsToSelector:aSEL]) {
                NSString* s = [itemCell performSelector:aSEL];
                image = cfsbIconMappingDict[s];
                if ([s isEqualToString:@"iCloud Drive"])
                    image = cfsbIconMappingDict[@"x-applefinder-vnode:iCloud"];
            }
        }
        if (!image) {
            aSEL = @selector(image);
            if ([itemCell respondsToSelector:aSEL]) {
                NSImage *sidebarImage = [self image];
                aSEL = NSSelectorFromString(@"sourceImage");
                if ([sidebarImage respondsToSelector:aSEL])
                    sidebarImage = [sidebarImage performSelector:aSEL];
                if ([sidebarImage respondsToSelector:@selector(name)])
                    image = cfsbIconMappingDict[[sidebarImage name]];
                // Tags
                if (!image)
                    if ([[sidebarImage representations] count] == 1)
                        image = [self image];
            }
        }
        if (!image) {
            Class cls = NSClassFromString(@"FINode");
            if (cls) {
                struct TFENode *node = &ZKHookIvar(itemCell, struct TFENode, "_node");
                SEL nodeFromNode = NSSelectorFromString(@"nodeFromNodeRef:");
                id finode = [cls performSelector:nodeFromNode withObject:(id)node->fNodeRef];
                SEL createAlt = NSSelectorFromString(@"createAlternativeIconRepresentationWithOptions:");
                if ([finode respondsToSelector:createAlt]) {
                    IconRef iconRef = (IconRef)[finode performSelector:createAlt withObject:nil];
                    image = [[[NSImage alloc] initWithIconRef:iconRef] autorelease];
                    ReleaseIconRef(iconRef);
                }
            }
        }
        if (image)
            [self setImage:image];
    }
}

@end

@implementation colorfulSidebar9

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        macOS = NSProcessInfo.processInfo.operatingSystemVersion.minorVersion;
        if (macOS < 9)
            return;
        
        if (!cfsbIconMappingDict) {
//            if (NSClassFromString(@"TImageView") || NSClassFromString(@"FI_TImageView")) {
                NSLog(@"wb_ Loading colorfulSidebar...");
                [colorfulSidebar9 setUpIconMappingDict];
                static dispatch_once_t onceToken;
                dispatch_once(&onceToken, ^{
                    ZKSwizzle(wb_TImageView, NSImageView);
                });
                NSLog(@"%@ loaded into %@ on macOS 10.%ld", [colorfulSidebar9 class], [[NSBundle mainBundle] bundleIdentifier], macOS);
//            }
        }
        
        NSDictionary *menuDict = @{@"cmdGoToAllMyFiles:":@"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AllMyFiles.icns",
                                   @"cmdGoToDocuments:":@"/Applications/iBooks.app/Contents/Resources/iBooksAppIcon.icns",
                                   @"cmdGoToDesktop:":@"/System/Library/PreferencePanes/Displays.prefPane/Contents/Resources/Displays.icns",
                                   @"cmdGoToDownloads:":@"/System/Library/CoreServices/Installer.app/Contents/Resources/Installer.icns",
                                   @"cmdGoHome:":@"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/HomeFolderIcon.icns",
                                   @"cmdGoToUserLibrary:":@"/System/Library/CoreServices/Siri.app/Contents/Resources/AppIcon.icns",
                                   @"cmdGoToComputer:":@"/System/Library/CoreServices/Finder.app/Contents/Applications/Computer.app/Contents/Resources/OpenComputerAppIcon.icns",
                                   @"cmdGoToNetwork:":@"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericNetworkIcon.icns",
                                   @"cmdGoToICloud:":@"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/iDiskGenericIcon.icns",
                                   @"cmdGoToApplications:":@"/Applications/App Store.app/Contents/Resources/AppIcon.icns",
                                   @"cmdGoToUtilities:":@"/Applications/Utilities/ColorSync Utility.app/Contents/Resources/ColorSyncUtility.icns",
                                   @"cmdGoToMeetingRoom:":@"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AirDrop.icns",
                                   @"cmdGoToAirDrop:":@"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AirDrop.icns",
                                   };
        
        NSMutableDictionary *mutableDict = [menuDict mutableCopy];
        if (macOS > 13) [mutableDict setValue:@"/Applications/Books.app/Contents/Resources/iBooksAppIcon.icns" forKey:@"cmdGoToDocuments:"];
        [mutableDict setObject:@"myObject" forKey:@"myKey"];
        menuDict = [mutableDict mutableCopy];
        
        if ([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.finder"]) {
            NSMenu *go = [[[NSApp mainMenu] itemAtIndex:4] submenu];
            for (NSMenuItem *i in [go itemArray]) {
                NSString *action = NSStringFromSelector([i action]);
                NSImage *image = [[NSImage alloc] initWithContentsOfFile:menuDict[action]];
                if (image) {
                    [image setSize:NSMakeSize(16, 16)];
                    [i setImage:image];
                }
            }
        }
    });
}

+ (void)setUpIconMappingDict {
    NSString *path = [[NSBundle bundleForClass:self] pathForResource:@"icons" ofType:@"plist"];
    if (macOS > 9)
        path = [[NSBundle bundleForClass:self] pathForResource:@"icons10" ofType:@"plist"];
    if (macOS > 13)
        path = [[NSBundle bundleForClass:self] pathForResource:@"icons14" ofType:@"plist"];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
    if (!dict) {
        cfsbIconMappingDict = [NSDictionary new];
    } else {
        NSMutableDictionary *mdict = [NSMutableDictionary dictionaryWithCapacity:0];
        for (NSString *key in dict) {
            NSImage *image;
            if ([key isAbsolutePath]) {
                image = [[[NSImage alloc] initWithContentsOfFile:key] autorelease];
            } else if ([key length] == 4) {
                OSType code = UTGetOSTypeFromString((CFStringRef)CFBridgingRetain(key));
                image = [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(code)];
            } else {
                image = [NSImage imageNamed:key];
                if (image && [key rangeOfString:@"NSMediaBrowserMediaType"].length) {
                    image = [[image copy] autorelease];
                    NSSize size = NSMakeSize(32, 32);
                    [image setSize:size];
                    [[[image representations] lastObject] setSize:size];
                }
            }
            if (image) {
                NSArray *arr = dict[key];
                for (key in arr) {
                    if ([key hasPrefix:@"~"]) {
                        key = [key stringByExpandingTildeInPath];
                    }
                    mdict[key] = image;
                }
            }
        }
        cfsbIconMappingDict = [mdict copy];
    }
}

@end
