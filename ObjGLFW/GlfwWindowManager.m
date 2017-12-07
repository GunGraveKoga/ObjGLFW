//
//  GlfwWindowManager.m
//  ObjGLFW
//
//  Created by Yury Vovk on 06.12.2017.
//  Copyright © 2017 GunGraveKoga. All rights reserved.
//

#import "GlfwWindowManager.h"
#import "GlfwRawWindow.h"
#import "GlfwApplication.h"

#include "sokol_time.h"

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

static void windowPositionCallback(GLFWwindow *glfwWindow, int x, int y);
static void windowSizeCallback(GLFWwindow *glfwWindow, int width, int height);
static void windowCloseCallback(GLFWwindow *glfwWindow);
static void windowRefreshCallback(GLFWwindow *glfwWindow);
static void windowFocusCallback(GLFWwindow *glfwWindow, int hasFocus);
static void windowIconifyCallback(GLFWwindow *glfwWindow, int toIconify);
static void windowFramebufferSizeCallback(GLFWwindow *glfwWindow, int width, int height);
static void inputMouseButtonCallback(GLFWwindow *glfwWindow, int button, int action, int mods);
static void inputCursorPositionCallback(GLFWwindow *glfwWindow, double x, double y);
static void inputCursorEnterCallback(GLFWwindow *glfwWindow, int enter);
static void inputScrollCallback(GLFWwindow *glfwWindow, double xOffset, double yOffset);
static void inputKeyCallback(GLFWwindow *glfwWindow, int key, int scancode, int action, int mods);
static void inputCharCallback(GLFWwindow *glfwWindow, unsigned int codepoint);
static void inputCharModCallback(GLFWwindow *glfwWindow, unsigned int codepoint, int mods);
static void inputDropCallback(GLFWwindow *glfwWindow, int count, const char **paths);

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

- (void)attachWindow:(GlfwRawWindow *)window {
#if defined(OF_HAVE_THREADS)
    if ( [_lock tryLock] ) {
#endif
      
        if ([window isOpen] && ![window shouldClose]) {
            GLFWwindow *handle = [window windowHandle];
            glfwSetWindowUserPointer(handle, (void *)self);
            
            glfwSetWindowPosCallback(handle, &windowPositionCallback);
            glfwSetWindowSizeCallback(handle, &windowSizeCallback);
            glfwSetWindowCloseCallback(handle, &windowCloseCallback);
            glfwSetWindowRefreshCallback(handle, &windowRefreshCallback);
            glfwSetWindowFocusCallback(handle, &windowFocusCallback);
            glfwSetWindowIconifyCallback(handle, &windowIconifyCallback);
            glfwSetFramebufferSizeCallback(handle, &windowFramebufferSizeCallback);
            glfwSetCharCallback(handle, &inputCharCallback);
            glfwSetCharModsCallback(handle, &inputCharModCallback);
            glfwSetCursorEnterCallback(handle, &inputCursorEnterCallback);
            glfwSetCursorPosCallback(handle, &inputCursorPositionCallback);
            glfwSetDropCallback(handle, &inputDropCallback);
            glfwSetKeyCallback(handle, &inputKeyCallback);
            glfwSetMouseButtonCallback(handle, &inputMouseButtonCallback);
            glfwSetScrollCallback(handle, &inputScrollCallback);
            
            [_managedWindows setObject:(void *)window forKey:handle];
        }
        
#if defined(OF_HAVE_THREADS)
        [_lock unlock];
    }
    else {
        [self performSelectorOnMainThread:_cmd withObject:window waitUntilDone:false];
    }
#endif
}

- (void)detachWindow:(GlfwRawWindow *)window {
#if defined(OF_HAVE_THREADS)
    if ( [_lock tryLock] ) {
#endif
        
        GLFWwindow *handle = [window windowHandle];
        
        glfwSetWindowPosCallback(handle, NULL);
        glfwSetWindowSizeCallback(handle, NULL);
        glfwSetWindowCloseCallback(handle, NULL);
        glfwSetWindowRefreshCallback(handle, NULL);
        glfwSetWindowFocusCallback(handle, NULL);
        glfwSetWindowIconifyCallback(handle, NULL);
        glfwSetFramebufferSizeCallback(handle, NULL);
        glfwSetCharCallback(handle, NULL);
        glfwSetCharModsCallback(handle, NULL);
        glfwSetCursorEnterCallback(handle, NULL);
        glfwSetCursorPosCallback(handle, NULL);
        glfwSetDropCallback(handle, NULL);
        glfwSetKeyCallback(handle, NULL);
        glfwSetMouseButtonCallback(handle, NULL);
        glfwSetScrollCallback(handle, NULL);
        
        glfwSetWindowUserPointer(handle, NULL);
        
        [_managedWindows removeObjectForKey:handle];
    
#if defined(OF_HAVE_THREADS)
        [_lock unlock];
    }
    else {
        [self performSelectorOnMainThread:_cmd withObject:window waitUntilDone:false];
    }
#endif
}

@end
