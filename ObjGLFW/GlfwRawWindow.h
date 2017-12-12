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

OF_ASSUME_NONNULL_BEGIN

@protocol GlfwWindow <OFObject>

@optional
- (void)prepareForEventsHandling;
- (void)endEventsHandling;

@end

@interface GlfwRawWindow : OFObject <OFCopying>
{
    GLFWwindow *_windowHandle;
    OFString *_windowTitle;
    GlfwSize _minSize;
    GlfwSize _maxSize;
#if defined(OF_HAVE_THREADS)
    OFMutex *_lock;
#endif
}

@property (atomic, assign) GLFWwindow *windowHandle;
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

- (instancetype)init OF_UNAVAILABLE;

- (instancetype)initWithRect:(GlfwRect)windowRectangle title:(OFString *)windowTitle
                       hints:(OFDictionary OF_GENERIC(OFNumber *, OFNumber *) *)windowHints OF_DESIGNATED_INITIALIZER;


- (bool)isOpen;
- (void)requestWindowAttention;
- (void)destroy;
- (void)draw;
- (void)sendEvent:(GlfwEvent *)event;
- (void)makeContextCurrent;
- (void)doneContext;
- (void)swapBuffers;

@end

OF_ASSUME_NONNULL_END
