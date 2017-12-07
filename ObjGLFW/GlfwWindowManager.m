//
//  GlfwWindowManager.m
//  ObjGLFW
//
//  Created by Yury Vovk on 06.12.2017.
//  Copyright © 2017 GunGraveKoga. All rights reserved.
//

#import "GlfwWindowManager.h"
#import "GlfwRawWindow.h"
#import "GlfwEvent.h"
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
    .retain = &_windowRetain,
    .release = &_windowRelease,
    .hash = &_windowHash,
    .equal = &_windowIsEqual
};

static of_map_table_functions_t _keyMapFunctions = {
    .retain = NULL,
    .release = NULL,
    .hash = NULL,
    .equal = NULL,
};

@interface GlfwWindowManager ()
- (instancetype)glfw_init;
@end

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

@implementation GlfwWindowManager

+ (instancetype)defaultManager {
    GlfwApplication *app = (id)[GlfwApplication sharedApplication];
    
    return [app windowManager];
}

- (instancetype)glfw_init {
    self = [super init];
    _eventsQueue = [[OFSortedList alloc] init];
    _managedWindows = [[OFMapTable alloc]
                       initWithKeyFunctions:_keyMapFunctions objectFunctions:_windowMapFunctions];
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
        
        if ([window isOpen]) {
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
        }
    
#if defined(OF_HAVE_THREADS)
        [_lock unlock];
    }
    else {
        [self performSelectorOnMainThread:_cmd withObject:window waitUntilDone:false];
    }
#endif
}

- (GlfwRawWindow *)findWindow:(GLFWwindow *)windowHandle {
    GlfwRawWindow *window = nil;
#if defined(OF_HAVE_THREADS)
    [_lock lock];
#endif
    
    window = [_managedWindows objectForKey:window];
    
#if defined(OF_HAVE_THREADS)
    [_lock unlock];
#endif
    
    return window;
}

- (void)fetchEvent:(GlfwEvent *)event {
#if defined(OF_HAVE_THREADS)
    [_lock lock];
#endif
    [_eventsQueue insertObject:event];
#if defined(OF_HAVE_THREADS)
    [_lock unlock];
#endif
}

- (void)dispatchEvents {
#if defined(OF_HAVE_THREADS)
    [_lock lock];
#endif
    
    for (GlfwEvent *event in _eventsQueue) {
        void *pool = objc_autoreleasePoolPush();
        
        GlfwRawWindow *window = [event window];
        
        if (![window shouldClose]) {
            [window sendEvent:event];
        }
        
        objc_autoreleasePoolPop(pool);
    }
    
#if defined(OF_HAVE_THREADS)
    [_lock unlock];
#endif
}

- (void)drainEvents {
#if defined(OF_HAVE_THREADS)
    [_lock lock];
#endif
    [_eventsQueue removeAllObjects];
#if defined(OF_HAVE_THREADS)
    [_lock unlock];
#endif
}

- (void)drawAllWindows {
#if defined(OF_HAVE_THREADS)
    [_lock lock];
#endif
    
    OFMapTableEnumerator *enumerator = [_managedWindows objectEnumerator];
    void **objectPtr;
    GlfwRawWindow *window;
    
    while ((objectPtr = [enumerator nextObject]) != NULL) {
        void *pool = objc_autoreleasePoolPush();
        
        window = (id)(*objectPtr);
        
        if (![window shouldClose] && [window isVisible] && ![window isIconified]) {
            [window draw];
        }
        
        objc_autoreleasePoolPop(pool);
    }
    
#if defined(OF_HAVE_THREADS)
    [_lock unlock];
#endif
}

@end

static void windowPositionCallback(GLFWwindow *glfwWindow, int x, int y) {
    uint64_t now = stm_now();
    GlfwWindowManager *wm = (GlfwWindowManager *)glfwGetWindowUserPointer(glfwWindow);
    GlfwRawWindow *window = [wm findWindow:glfwWindow];
    
    [wm fetchEvent:[GlfwEvent otherEventWithType:GlfwWindowMoved timestamp:stm_ms(now) window:window size:GlfwSizeZero() pos:GlfwPointNew(x, y) paths:nil]];
    
}

static void windowSizeCallback(GLFWwindow *glfwWindow, int width, int height) {
    uint64_t now = stm_now();
    GlfwWindowManager *wm = (GlfwWindowManager *)glfwGetWindowUserPointer(glfwWindow);
    GlfwRawWindow *window = [wm findWindow:glfwWindow];
    
    [wm fetchEvent:[GlfwEvent otherEventWithType:GlfwWindowResized timestamp:stm_ms(now) window:window size:GlfwSizeNew(width, height) pos:GlfwPointZero() paths:nil]];
}

static void windowCloseCallback(GLFWwindow *glfwWindow) {
    uint64_t now = stm_now();
    GlfwWindowManager *wm = (GlfwWindowManager *)glfwGetWindowUserPointer(glfwWindow);
    GlfwRawWindow *window = [wm findWindow:glfwWindow];
    
    [wm fetchEvent:[GlfwEvent otherEventWithType:GlfwWindowShouldClose timestamp:stm_ms(now) window:window size:GlfwSizeZero() pos:GlfwPointZero() paths:nil]];
}

static void windowRefreshCallback(GLFWwindow *glfwWindow) {
    uint64_t now = stm_now();
    GlfwWindowManager *wm = (GlfwWindowManager *)glfwGetWindowUserPointer(glfwWindow);
    GlfwRawWindow *window = [wm findWindow:glfwWindow];
    
    [wm fetchEvent:[GlfwEvent otherEventWithType:GlfwWindowShouldRefresh timestamp:stm_ms(now) window:window size:GlfwSizeZero() pos:GlfwPointZero() paths:nil]];
}

static void windowFocusCallback(GLFWwindow *glfwWindow, int hasFocus) {
    uint64_t now = stm_now();
    GlfwWindowManager *wm = (GlfwWindowManager *)glfwGetWindowUserPointer(glfwWindow);
    GlfwRawWindow *window = [wm findWindow:glfwWindow];
    
    [wm fetchEvent:[GlfwEvent otherEventWithType:GlfwWindowFocused timestamp:stm_ms(now) window:window size:GlfwSizeZero() pos:GlfwPointZero() paths:nil]];
}

static void windowIconifyCallback(GLFWwindow *glfwWindow, int toIconify) {
    uint64_t now = stm_now();
    GlfwWindowManager *wm = (GlfwWindowManager *)glfwGetWindowUserPointer(glfwWindow);
    GlfwRawWindow *window = [wm findWindow:glfwWindow];
    
    [wm fetchEvent:[GlfwEvent otherEventWithType:GlfwWindowIconified timestamp:stm_ms(now) window:window size:GlfwSizeZero() pos:GlfwPointZero() paths:nil]];
}

static void windowFramebufferSizeCallback(GLFWwindow *glfwWindow, int width, int height) {
    uint64_t now = stm_now();
    GlfwWindowManager *wm = (GlfwWindowManager *)glfwGetWindowUserPointer(glfwWindow);
    GlfwRawWindow *window = [wm findWindow:glfwWindow];
    
    [wm fetchEvent:[GlfwEvent otherEventWithType:GlfwWindowFramebuferResized timestamp:stm_ms(now) window:window size:GlfwSizeNew(width, height) pos:GlfwPointZero() paths:nil]];
}

static void inputMouseButtonCallback(GLFWwindow *glfwWindow, int button, int action, int mods) {
    uint64_t now = stm_now();
    GlfwWindowManager *wm = (GlfwWindowManager *)glfwGetWindowUserPointer(glfwWindow);
    GlfwRawWindow *window = [wm findWindow:glfwWindow];
    
    GlfwEventType mouseEventType = 0;
    
    switch (button) {
        case GLFW_MOUSE_BUTTON_LEFT:
            mouseEventType = (action == GLFW_RELEASE) ? GlfwLeftMouseUp : GlfwLeftMouseDown;
            break;
        case GLFW_MOUSE_BUTTON_RIGHT:
            mouseEventType = (action == GLFW_RELEASE) ? GlfwRightMouseUp : GlfwRightMouseDown;
            break;
        case GLFW_MOUSE_BUTTON_MIDDLE:
            mouseEventType = (action == GLFW_RELEASE) ? GlfwMouseMiddleUp : GlfwMouseMiddleDown;
        default:
            mouseEventType = (action == GLFW_RELEASE) ? GlfwMouseOtherUp : GlfwMouseOtherDown;
            break;
    }
    
    [wm fetchEvent:[GlfwEvent mouseEventWithType:mouseEventType timestamp:stm_ms(now) window:window location:of_point(0, 0) button:button modifiers:mods deltaX:0 deltaY:0]];
}

static void inputCursorPositionCallback(GLFWwindow *glfwWindow, double x, double y) {
    uint64_t now = stm_now();
    GlfwWindowManager *wm = (GlfwWindowManager *)glfwGetWindowUserPointer(glfwWindow);
    GlfwRawWindow *window = [wm findWindow:glfwWindow];
    
    [wm fetchEvent:[GlfwEvent mouseEventWithType:GlfwMouseMoved timestamp:stm_ms(now) window:window location:of_point(x, y) button:0 modifiers:0 deltaX:0 deltaY:0]];
}

static void inputCursorEnterCallback(GLFWwindow *glfwWindow, int enter) {
    uint64_t now = stm_now();
    GlfwWindowManager *wm = (GlfwWindowManager *)glfwGetWindowUserPointer(glfwWindow);
    GlfwRawWindow *window = [wm findWindow:glfwWindow];
    
    GlfwEventType cursorEnterType = (enter == GLFW_TRUE) ? GlfwMouseEntered : GlfwMouseExited;
    
    [wm fetchEvent:[GlfwEvent enterExitEventWithType:cursorEnterType timestamp:stm_ms(now) window:window]];
}

static void inputScrollCallback(GLFWwindow *glfwWindow, double xOffset, double yOffset) {
    uint64_t now = stm_now();
    GlfwWindowManager *wm = (GlfwWindowManager *)glfwGetWindowUserPointer(glfwWindow);
    GlfwRawWindow *window = [wm findWindow:glfwWindow];
    
    [wm fetchEvent:[GlfwEvent mouseEventWithType:GlfwScrollWheel timestamp:stm_ms(now) window:window location:of_point(0, 0) button:0 modifiers:0 deltaX:xOffset deltaY:yOffset]];
}

static void inputKeyCallback(GLFWwindow *glfwWindow, int key, int scancode, int action, int mods) {
    uint64_t now = stm_now();
    GlfwWindowManager *wm = (GlfwWindowManager *)glfwGetWindowUserPointer(glfwWindow);
    GlfwRawWindow *window = [wm findWindow:glfwWindow];
    
    GlfwEventType keyEventType = (action == GLFW_RELEASE) ? GlfwKeyUp : GlfwKeyDown;
    
    [wm fetchEvent:[GlfwEvent keyEventWithType:keyEventType timestamp:stm_ms(now) window:window key:key scanCode:scancode modifiers:mods]];
}

static void inputCharCallback(GLFWwindow *glfwWindow, unsigned int codepoint) {
    uint64_t now = stm_now();
    GlfwWindowManager *wm = (GlfwWindowManager *)glfwGetWindowUserPointer(glfwWindow);
    GlfwRawWindow *window = [wm findWindow:glfwWindow];
    
    [wm fetchEvent:[GlfwEvent characterEventWithType:GlfwCharacter timestamp:stm_ms(now) window:window character:(of_unichar_t)codepoint characterModifiers:0]];
}

static void inputCharModCallback(GLFWwindow *glfwWindow, unsigned int codepoint, int mods) {
    uint64_t now = stm_now();
    GlfwWindowManager *wm = (GlfwWindowManager *)glfwGetWindowUserPointer(glfwWindow);
    GlfwRawWindow *window = [wm findWindow:glfwWindow];
    
    [wm fetchEvent:[GlfwEvent characterEventWithType:GlfwModifiedCharacter timestamp:stm_ms(now) window:window character:(of_unichar_t)codepoint characterModifiers:mods]];
}

static void inputDropCallback(GLFWwindow *glfwWindow, int count, const char **paths) {
    uint64_t now = stm_now();
    GlfwWindowManager *wm = (GlfwWindowManager *)glfwGetWindowUserPointer(glfwWindow);
    GlfwRawWindow *window = [wm findWindow:glfwWindow];
    
    void *pool = objc_autoreleasePoolPush();
    
    OFMutableArray *pathsArray = [OFMutableArray array];
    
    for (int i = 0; i < count; i++) {
        [pathsArray addObject:[OFString stringWithUTF8String:paths[i]]];
    }
    
    [wm fetchEvent:[GlfwEvent otherEventWithType:GlfwFilesDrop timestamp:stm_ms(now) window:window size:GlfwSizeZero() pos:GlfwPointZero() paths:pathsArray]];
    
    objc_autoreleasePoolPop(pool);
    
}
