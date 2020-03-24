//
//  JSRollCall.h
//  JSRollCall
//
//  Created by Jeremy Legendre on 3/1/20.
//  Copyright © 2020 Jeremy Legendre. All rights reserved.
//

#import <Foundation/Foundation.h>

#define MAX_RESULTS 128

@interface JSRollCall : NSObject

- (NSSet *)allObjectsOfClass:(Class)cls includeSubclass:(BOOL)shouldIncludeSubclasses;
- (NSSet *)allObjectsOfClassName:(NSString *)className includeSubclass:(BOOL)shouldIncludeSubclasses;
- (void)allObjectsOfClass:(Class)cls includeSubclass:(BOOL)shouldIncludeSubclasses performBlock:(void (^)(id))block;
- (void)allObjectsOfClassName:(NSString *)cls includeSubclass:(BOOL)shouldIncludeSubclasses performBlock:(void (^)(id))block;

@end
