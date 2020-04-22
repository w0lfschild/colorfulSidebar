//
//  colorfulSidebarX.m
//  colorfulSidebarX
//
//  Created by Wolfgang Baird
//  Copyright 2016 - 2020 macEnhance.
//

@import AppKit;
#import "ZKSwizzle.h"
#import "JSRollCall.h"

static NSDictionary *cfsbIconMappingDict = nil;
struct OpaqueNodeRef;
struct TFENode {
    struct OpaqueNodeRef *fNodeRef;
};
NSInteger macOS;

@interface colorfulSidebarX : NSObject
@end

ZKSwizzleInterface(mecsx_MailboxOutlineItemView, MailboxOutlineItemView, NSTableCellView)
@implementation mecsx_MailboxOutlineItemView

- (void)_updateImage {
    ZKOrig(void);
    NSImage *replacementImage = cfsbIconMappingDict[self.imageView.image.name];
    if (replacementImage != nil)
        [self.imageView setImage:replacementImage];
}

@end

@interface mecsx_NSImageView : NSImageView
@end

@implementation mecsx_NSImageView

- (void)setImage:(NSImage *)image {
    NSImage *result = image;
    if ([image.className isEqualToString:@"NSSidebarImage"]) {
        NSImage *replacementImage = cfsbIconMappingDict[image.name];
        if (replacementImage != nil)
            result = replacementImage;
    }
    ZKOrig(void, result);
}

- (void)layout {
    ZKOrig(void);
    if (self.class == NSClassFromString(@"TImageView") || self.class == NSClassFromString(@"FI_TImageView")) {
        if ([self.superview class] == NSClassFromString(@"TSidebarItemCell") || [self.superview class] == NSClassFromString(@"FI_TSidebarItemCell")) {
            [self mecsx_setImage:self.superview];
        }
    }
}

- (void)mecsx_setImage:(id)itemCell {
    SEL aSEL = @selector(accessibilityAttributeNames);
    if ([itemCell respondsToSelector:@selector(accessibilityAttributeNames)] && [[itemCell performSelector:@selector(accessibilityAttributeNames)] containsObject:NSAccessibilityURLAttribute]) {
        NSImage *image = nil;
        NSURL *aURL = [itemCell accessibilityAttributeValue:NSAccessibilityURLAttribute];
        if ([aURL isFileURL]) {
            NSString *path = [aURL path];
            image = cfsbIconMappingDict[path];
            if (!image) {
                aSEL = @selector(name);
                if ([itemCell respondsToSelector:aSEL]) {
                    image = cfsbIconMappingDict[[itemCell performSelector:@selector(name)]];
                }
            }
            if (!image) {
                image = [[NSWorkspace sharedWorkspace] iconForFile:path];
            }
        } else {
            image = cfsbIconMappingDict[[aURL absoluteString]];
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
            }
        }
        
        if (!image) {
            Class cls = NSClassFromString(@"FINode");
            if (cls) {
                struct TFENode *node = &ZKHookIvar(itemCell, struct TFENode, "_node");
                SEL nodeFromNode = NSSelectorFromString(@"nodeFromNodeRef:");
                id finode = [cls performSelector:nodeFromNode withObject:(__bridge id)node->fNodeRef];
                SEL createAlt = NSSelectorFromString(@"createAlternativeIconRepresentationWithOptions:");
                
                NSURL *aURL = [finode valueForKey:@"previewItemURL"];
                if (aURL)
                    image = cfsbIconMappingDict[[aURL absoluteString]];
                
                // Tags
                if (!image)
                    if ([[[self image] representations] count] == 1)
                        image = [self image];
                
                if (!image) {
                    if ([finode respondsToSelector:createAlt]) {
                        IconRef iconRef = (__bridge IconRef)[finode performSelector:createAlt withObject:nil];
                        image = [[NSImage alloc] initWithIconRef:iconRef];
                        ReleaseIconRef(iconRef);
                    }
                }
            }
        }
        
        if (image)
            [self setImage:image];
    }
}

@end

@implementation colorfulSidebarX

+ (NSString*)getPath:(NSString*)appID :(NSString*)iconFile {
    NSString *result = [[NSWorkspace.sharedWorkspace absolutePathForAppBundleWithIdentifier:appID] stringByAppendingFormat:@"/Contents/Resources/%@", iconFile];
    if (!result) result = @"";
    return result;
}

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        macOS = NSProcessInfo.processInfo.operatingSystemVersion.minorVersion;
        
        // Set up image dict and swizzle
        if (!cfsbIconMappingDict) {
            [colorfulSidebarX setUpIconMappingDict];
            ZKSwizzle(mecsx_NSImageView, NSImageView);
            NSLog(@"%@ loaded into %@ on macOS 10.%lu", [colorfulSidebarX class], [[NSBundle mainBundle] bundleIdentifier], (unsigned long)macOS);
        }
        
        // Force update NSSidebarImages
        JSRollCall *rc = [JSRollCall new];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSSet *imageSet = [rc allObjectsOfClass:NSImageView.class includeSubclass:1];
            for (NSImageView *sbiv in imageSet.allObjects) {
                NSImage* sbi = sbiv.image;
                if ([sbi.className isEqualToString:@"NSSidebarImage"])
                    if (cfsbIconMappingDict[sbi.name] != nil)
                        [sbiv setImage:sbi];
            }
        });
        
        // Update Finder Go menu
        if ([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.finder"]) {
            NSMenu *go = [[[NSApp mainMenu] itemAtIndex:4] submenu];
            for (NSMenuItem *i in [go itemArray]) {
                NSString *action = NSStringFromSelector([i action]);
                if (action.length > 0)
                    action = [action substringToIndex:[action length]-1];
                NSImage *image = cfsbIconMappingDict[action];
                if (image != nil) {
                    [image setSize:NSMakeSize(16, 16)];
                    [i setImage:image];
                }
            }
        }
    });
}

+ (void)setUpIconMappingDict {
    NSString *path = [[NSBundle bundleForClass:self] pathForResource:@"icons9" ofType:@"plist"];
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
                image = [[NSImage alloc] initWithContentsOfFile:key];
            } else if ([key length] == 4) {
                OSType code = UTGetOSTypeFromString((CFStringRef)CFBridgingRetain(key));
                image = [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(code)];
            } else {
                image = [NSImage imageNamed:key];
                if (image && [key rangeOfString:@"NSMediaBrowserMediaType"].length) {
                    image = [image copy];
                    NSSize size = NSMakeSize(32, 32);
                    [image setSize:size];
                    [[[image representations] lastObject] setSize:size];
                }
            }
            
            // Try expanding ~
            if (image == nil) {
                NSString *expandedkey = [key stringByExpandingTildeInPath];
                image = [[NSImage alloc] initWithContentsOfFile:expandedkey];
            }
            
            // Check if it's a bundle resource
            if (image == nil) {
                NSString *keyPath = [key stringByDeletingPathExtension];
                NSString *keyExt = [key pathExtension];
                NSString *bundleResource = [[NSBundle bundleForClass:self] pathForResource:keyPath ofType:keyExt];
                image = [[NSImage alloc] initWithContentsOfFile:bundleResource];
            }
            
            // Fix for 10.15
            if (image == nil) {
                NSString *sysFix = [@"/System" stringByAppendingString:key];
                image = [[NSImage alloc] initWithContentsOfFile:sysFix];
            }
            
            if (image) {
                NSArray *arr = dict[key];
                NSString *keyName;
                for (NSString *key in arr) {
                    keyName = key;
                    if ([keyName hasPrefix:@"~"]) {
                        keyName = [key stringByExpandingTildeInPath];
                    }
                    mdict[keyName] = image;
                }
            }
        }
        cfsbIconMappingDict = [mdict copy];
    }
}

@end
