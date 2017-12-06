//
//  GlfwWindowManager.m
//  ObjGLFW
//
//  Created by Yury Vovk on 06.12.2017.
//  Copyright © 2017 GunGraveKoga. All rights reserved.
//

#import "GlfwWindowManager.h"
#import "GlfwWindow.h"
#import "GlfwApplication.h"

static void * _Nullable _windowRetain(void * _Nullable object) {
    return [(__bridge id)object copy];
}

static void _windowRelease(void * _Nullable object) {
    [(__bridge id)object release];
}

static uint32_t _windowHash(void * _Nullable object) {
    return [(__bridge id)object hash];
}

static bool _windowIsEqual(void * _Nullable left, void * _Nullable right) {
    return [(__bridge id)left isEqual:(__bridge id)right];
}

static of_map_table_functions_t _windowMapFunctions = {
    &_windowRetain,
    &_windowRelease,
    &_windowHash,
    &_windowIsEqual
};

OF_INLINE bool onMainThread(void) {
    return ([OFThread currentThread] == [OFThread mainThread]);
}

@interface GlfwWindowManager ()
- (instancetype)glfw_init;
@end

@implementation GlfwWindowManager

+ (instancetype)defaultManager {
    GlfwApplication *app = (id)[GlfwApplication sharedApplication];
    
    return [app windowManager];
}

- (instancetype)glfw_init {
    self = [super init];
    _eventsQueue = [[OFSortedList alloc] init];
    _managedWindows = [[OFMapTable alloc]
                       initWithKeyFunctions:(of_map_table_functions_t){NULL, NULL, NULL, NULL} objectFunctions:_windowMapFunctions];
#if defined(OF_HAVE_THREADS)
    _lock = [[OFMutex alloc] init];
#endif
    
    return self;
}

/*
 * All windows should be attached/detached asynchronously after event processing
 */

- (void)attachWindow:(GlfwWindow *)window {
#if defined(OF_HAVE_THREADS)
    if ( [_lock tryLock] ) {
#endif
        
#if defined(OF_HAVE_THREADS)
        [_lock unlock];
    }
    else {
        [self performSelectorOnMainThread:_cmd withObject:window waitUntilDone:false];
    }
#endif
}

- (void)detachWindow:(GlfwWindow *)window {
#if defined(OF_HAVE_THREADS)
    if ( [_lock tryLock] ) {
#endif
    
#if defined(OF_HAVE_THREADS)
        [_lock unlock];
    }
    else {
        [self performSelectorOnMainThread:_cmd withObject:window waitUntilDone:false];
    }
#endif
}

@end
