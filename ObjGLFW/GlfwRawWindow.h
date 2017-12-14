//
//  GlfwRawWindow.h
//  ObjGLFW
//
//  Created by Юрий Вовк on 05.12.2017.
//  Copyright © 2017 GunGraveKoga. All rights reserved.
//

#import <ObjFW/ObjFW.h>
#import "GlfwGeometry.h"

#include <GLFW/glfw3.h>

@class GlfwEvent;
@class GlfwMonitor;
@class GlfwCursor;

OF_ASSUME_NONNULL_BEGIN

@interface GlfwRawWindow : OFObject <OFCopying>
{
    GLFWwindow *_windowHandle;
    OFString *_windowTitle;
    GlfwSize _minSize;
    GlfwSize _maxSize;
    GlfwCursor *_cursor;
#if defined(OF_HAVE_THREADS)
    OFMutex *_lock;
#endif
}

#ifdef OF_HAVE_CLASS_PROPERTIES
@property (class, readonly, copy) OF_KINDOF(GlfwRawWindow) *currentContextWindow;
#endif

@property (atomic, assign) GLFWwindow *windowHandle OF_RETURNS_INNER_POINTER;
#if defined(OF_WINDOWS)
@property (atomic, assign, readonly) HWND nativeWindowHandle OF_RETURNS_INNER_POINTER;
#elif defined(OF_MACOS)
@property (atomic, assign, readonly) id nativeWindowHandle OF_RETURNS_INNER_POINTER;
#elif defined(OF_LINUX)
@property (atomic, assign, readonly) Window nativeWindowHandle OF_RETURNS_INNER_POINTER;
#endif
@property (nonatomic, retain, nullable) GlfwMonitor *monitor;
@property (atomic, copy) OFString *title;
@property (atomic) GlfwRect frame;
@property (atomic) GlfwSize contentSize;
@property (atomic) GlfwSize size;
@property (atomic) GlfwSize minSize;
@property (atomic) GlfwSize maxSize;
@property (atomic) GlfwPoint pos;
@property (atomic, getter=isVisible) bool visible;
@property (atomic, getter=isIconified) bool iconified;
@property (atomic, getter=isMaximized) bool maximazed;
@property (atomic, getter=isFocused) bool focused;
@property (atomic) bool shouldClose;
@property (atomic, getter=isDecorated, readonly) bool decorated;
@property (atomic, getter=isFloating, readonly) bool floating;
@property (atomic, getter=isResizable, readonly) bool resizable;
@property (nonatomic, getter=isVisibleForUser, readonly) bool visibleForUser;
@property (nonatomic, readonly) of_point_t cursorPos;
@property (atomic, copy, nullable) GlfwCursor *cursor;
@property (nonatomic, copy, nullable) OFString *clipboardString;

+ (instancetype)currentContextWindow;
+ (instancetype)windowWithRect:(GlfwRect)windowRectangle title:(OFString *)windowTitle
                         hints:(OFDictionary OF_GENERIC(OFNumber *, OFNumber *) *)windowHints;

- (instancetype)init OF_UNAVAILABLE;

- (instancetype)initWithRect:(GlfwRect)windowRectangle title:(OFString *)windowTitle
                       hints:(OFDictionary OF_GENERIC(OFNumber *, OFNumber *) *)windowHints OF_DESIGNATED_INITIALIZER;


- (bool)isOpen;
- (void)requestWindowAttention;
- (void)draw;
- (void)sendEvent:(GlfwEvent *)event;
- (void)makeContextCurrent;
- (void)doneContext;
- (void)swapBuffers;

- (void)setValue:(int)value forInputMode:(int)inputMode;
- (int)valueForInputMode:(int)inputMode;

- (int)stateOfMouseButton:(int)mouseButton;
- (int)stateOfKey:(int)glfwKey;

@end

OF_ASSUME_NONNULL_END
