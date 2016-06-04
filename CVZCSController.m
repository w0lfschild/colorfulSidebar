//
//  CVZCSController.m
//  ColorfulSidebar
//
//  Created by cvz. on 12/07/23.
//  Copyright 2012 cvz. All rights reserved.
//	ColorfulSidebar is released under the MIT License.
//	http://opensource.org/licenses/mit-license.php
//

@import AppKit;
#import "ZKSwizzle.h"

@interface CVZCSController : NSObject
@end

static NSDictionary *CVZCSgIconMappingDict = nil;

struct TFENode {
    struct OpaqueNodeRef *fNodeRef;
};

@interface wb_TSidebarItemCell : NSObject
- (id)getNodeAsResolvedNode:(BOOL)arg1;
+ (id)nodeFromNodeRef:(struct OpaqueNodeRef *)nodeRef;
- (struct OpaqueIconRef *)createAlternativeIconRepresentationWithOptions:(id)arg1;
@end

@implementation wb_TSidebarItemCell

- (void)wb_setImage:(id)i
{
    SEL aSEL = @selector(accessibilityAttributeNames);
    if ([self respondsToSelector:aSEL] && [[self performSelector:aSEL] containsObject:NSAccessibilityURLAttribute]) {
        NSURL *aURL = [self accessibilityAttributeValue:NSAccessibilityURLAttribute];
        NSImage *image = nil;
        if ([aURL isFileURL]) {
            NSString *path = [aURL path];
            image = CVZCSgIconMappingDict[path];
            if (!image) {
                aSEL = @selector(name);
                if ([self respondsToSelector:aSEL]) {
                    image = CVZCSgIconMappingDict[[self performSelector:aSEL]];
                }
            }
            if (!image) {
                image = [[NSWorkspace sharedWorkspace] iconForFile:path];
            }
        } else {
            image = CVZCSgIconMappingDict[[aURL absoluteString]];
        }
        if (!image) {
            aSEL = @selector(name);
            if ([self respondsToSelector:aSEL]) {
                NSString* s = [self performSelector:aSEL];
                image = CVZCSgIconMappingDict[s];
                if ([s isEqualToString:@"iCloud Drive"])
                    image = CVZCSgIconMappingDict[@"x-applefinder-vnode:iCloud"];
            }
        }
        if (!image) {
            aSEL = @selector(image);
            if ([i respondsToSelector:aSEL]) {
                NSImage *sidebarImage = [i performSelector:aSEL];
                aSEL = @selector(sourceImage);
                if ([sidebarImage respondsToSelector:aSEL]) {
                    sidebarImage = [sidebarImage performSelector:aSEL];
                }
                if ([sidebarImage name]) {
                    image = CVZCSgIconMappingDict[[sidebarImage name]];
                }
                // Tags
                if (!image) {
                    if ([[sidebarImage representations] count] == 1) {
                        image = [i performSelector:@selector(image)];
                    }
                }
            }
        }
        if (!image) {
            Class cls = NSClassFromString(@"FINode");
            if (cls)
            {
                struct TFENode *node = &ZKHookIvar(self, struct TFENode, "_node");
                id finode = [cls nodeFromNodeRef:node->fNodeRef];
                if ([finode respondsToSelector:@selector(createAlternativeIconRepresentationWithOptions:)]) {
                    IconRef iconRef = [finode createAlternativeIconRepresentationWithOptions:nil];
                    image = [[[NSImage alloc] initWithIconRef:iconRef] autorelease];
                    ReleaseIconRef(iconRef);
                }
            }
        }
        if (image)
            [i setImage:image];
    }
}

// 10.9 + 10.10
- (void)drawWithFrame:(struct CGRect)arg1 inView:(id)arg2
{
    [self wb_setImage:self];
    ZKOrig(void, arg1, arg2);
}

// 10.11
- (_Bool)isHighlighted
{
    SEL aSEL = @selector(subviews);
    if ([self respondsToSelector:aSEL])
        for (id i in [self performSelector:aSEL])
            if ([i class] == NSClassFromString(@"TImageView"))
                [self wb_setImage:i];
    return ZKOrig(_Bool);
}

@end

@implementation CVZCSController

+ (void)load
{
    if (NSAppKitVersionNumber < 1138)
        return;
    if (!CVZCSgIconMappingDict) {
        NSLog(@"Loading colorfulSidebar...");
        if (NSClassFromString(@"TSidebarItemCell")) {
            [self performSelector:@selector(setUpIconMappingDict)];
            ZKSwizzle(wb_TSidebarItemCell, TSidebarItemCell);
        }
        if (NSClassFromString(@"FI_TSidebarItemCell")) {
            NSLog(@"Test");
            [self performSelector:@selector(setUpIconMappingDict)];
            ZKSwizzle(wb_TSidebarItemCell, FI_TSidebarItemCell);
        }
    }
}

+ (void)setUpIconMappingDict
{
    NSString *path = [[NSBundle bundleForClass:self] pathForResource:@"icons" ofType:@"plist"];
    if ([[NSProcessInfo processInfo] operatingSystemVersion].minorVersion >= 10)
        path = [[NSBundle bundleForClass:self] pathForResource:@"icons10" ofType:@"plist"];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
    if (!dict) {
        CVZCSgIconMappingDict = [NSDictionary new];
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
        CVZCSgIconMappingDict = [mdict copy];
    }
}

@end
