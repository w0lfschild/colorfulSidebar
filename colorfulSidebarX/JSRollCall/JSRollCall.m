//
//  JSRollCall.m
//  JSRollCall
//
//  Created by Jeremy Legendre on 3/1/20.
//  Copyright © 2020 Jeremy Legendre. All rights reserved.
//

#import "JSRollCall.h"
#include <malloc/malloc.h>
#include <objc/runtime.h>

struct rc_ctx {
    Class cls;
    CFMutableSetRef classesSet;
    CFMutableSetRef results;
    uint32_t classCount;
    boolean_t includeSubclass;
};
typedef struct rc_ctx* rc_ctx_t;

static kern_return_t
task_peek (task_t task, vm_address_t remote_address, vm_size_t size, void **local_memory) {
    *local_memory = (void*) remote_address;
    return KERN_SUCCESS;
}

void malloc_zone_enumerator(task_t task, void *context, unsigned type, vm_range_t *ranges, unsigned count) {
    rc_ctx_t ctx = (rc_ctx_t)context;
    CFMutableSetRef classesSet = ctx->classesSet;
    CFMutableSetRef results = ctx->results;
    boolean_t includeSublass = ctx->includeSubclass;
    int maxCount = MAX_RESULTS;

    for (int j = 0; j < count; j++) {
        if (CFSetGetCount(results) >= maxCount)
            break;
        
        vm_address_t potentialObject = ranges[j].address;

        Class cls = ctx->cls;
        size_t clsSize = class_getInstanceSize(cls);
        // test 1
        if (ranges[j].size < clsSize)
            continue;
        
        // ignore tagged pointer stuff
        if ((0xFFFF800000000000 & potentialObject) != 0)
            continue;

        // test 4 is a tagged pointer 0x8000000000000000
        if ((potentialObject & 0x8000000000000000) == 0x8000000000000000)
            continue;

        Class potentialClass = object_getClass((__bridge id)((void *)potentialObject));
        // test 2
        if (!CFSetContainsValue(classesSet, (__bridge const void *)(potentialClass))) {
            continue;
        }

        NSString *className = (NSString *)NSStringFromClass(potentialClass);

        // test 3
        if (malloc_good_size(class_getInstanceSize(potentialClass)) != ranges[j].size && !(BOOL)[className containsString:@"Block"]) {
            continue;
        }
        
        id obj = (__bridge id)(void *)potentialObject;
        
        if ([obj isProxy] && strchr((char*)[className UTF8String], '.') == 0)
            continue;
        
        
        if (![obj respondsToSelector:@selector(description)])
            continue;
        
        if([className isEqualToString:NSStringFromClass(cls)] ||
           (includeSublass && [potentialClass isSubclassOfClass:cls])) {
            CFSetAddValue(results, (const void *)(potentialObject));
        }
    }
}

@interface JSRollCall ()
@property (strong, atomic) NSMutableArray *contexts;
@end

@implementation JSRollCall

- (void)initCallbackCtx:(rc_ctx_t *)ctx {
    *ctx = (rc_ctx_t)calloc(1, sizeof(struct rc_ctx));
    int classCount = objc_getClassList(NULL, 0);
    CFMutableSetRef set = CFSetCreateMutable(0, classCount, NULL);
    Class *classes = (__unsafe_unretained Class *)malloc(sizeof(Class) * classCount);
    objc_getClassList(classes, classCount);
    
    for (int i = 0; i < classCount; i++) {
        Class cls = classes[i];
        CFSetAddValue(set, (__bridge const void *)(cls));
    }
    
    (*ctx)->results = (CFMutableSetRef)CFSetCreateMutable(0, MAX_RESULTS, NULL);
    (*ctx)->classesSet = set;
    (*ctx)->includeSubclass = false;
}

- (void)destroyCallbackCtx:(rc_ctx_t)ctx {
    free(ctx);
}

- (void)enumerateWithContext:(rc_ctx_t)ctx {
    vm_address_t *zones = NULL;
    unsigned int count = 0;
    

    kern_return_t error = malloc_get_all_zones(0, 0, &zones, &count);
    if(error != KERN_SUCCESS) {
        return;
    }
    
    for (unsigned i = 0; i < count; i++) {
        malloc_zone_t *zone = (malloc_zone_t *)zones[i];
        if (zone == NULL || zone->introspect == NULL){
            continue;
        }
        
        zone->introspect->enumerator(0, ctx, 1, zones[i], task_peek, malloc_zone_enumerator);
    }
}

- (NSSet *)allObjectsOfClass:(Class)cls includeSubclass:(BOOL)shouldIncludeSubclasses {
    rc_ctx_t rc_context;
    [self initCallbackCtx:&rc_context];
    rc_context->cls = cls;
    rc_context->includeSubclass = (boolean_t)shouldIncludeSubclasses;
    [self enumerateWithContext:rc_context];
    NSSet *results = [(__bridge NSSet *)(rc_context->results) copy];
    [self destroyCallbackCtx:rc_context];
    return results;
}

- (void)allObjectsOfClass:(Class)cls includeSubclass:(BOOL)shouldIncludeSubclasses performBlock:(void (^)(id))block {
    NSSet *results = [self allObjectsOfClass:cls includeSubclass:shouldIncludeSubclasses];
    for(id i in results)
        block(i);
}

- (void)allObjectsOfClassName:(NSString *)className includeSubclass:(BOOL)shouldIncludeSubclasses performBlock:(void (^)(id))block {
    [self allObjectsOfClass:objc_getClass([className UTF8String]) includeSubclass:shouldIncludeSubclasses performBlock:block];
}

- (NSSet *)allObjectsOfClassName:(NSString *)className includeSubclass:(BOOL)shouldIncludeSubclasses {
    return [self allObjectsOfClass:objc_getClass([className UTF8String]) includeSubclass:shouldIncludeSubclasses];
}

@end
