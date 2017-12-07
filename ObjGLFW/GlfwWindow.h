//
//  GlfwWindow.h
//  ObjGLFW
//
//  Created by Юрий Вовк on 05.12.2017.
//  Copyright © 2017 GunGraveKoga. All rights reserved.
//

#import <ObjFW/ObjFW.h>
#import "GlfwGeometry.h"
#import "GlfwEventHandling.h"
#import "GlfwDrawing.h"

#include <GLFW/glfw3.h>

@class GlfwEvent;

@interface GlfwWindow : OFObject
{
    GLFWwindow *_windowHandle;
    OFString *_windowTitle;
    GlfwSize _minSize;
    GlfwSize _maxSize;
    bool _visible;
    bool _iconified;
    bool _active;
#if defined(OF_HAVE_THREADS)
    OFRecursiveMutex *_lock;
#endif
    OFSortedList OF_GENERIC(id<GlfwEventHandling>) *_eventHandlers;
    OFSortedList OF_GENERIC(id<GlfwDrawing>) *_drawables;
}

@property (nonatomic, assign) GLFWwindow *windowHandle;

@property (nonatomic, copy) OFString *title;
@property (nonatomic) GlfwRect frame;
@property (nonatomic) GlfwSize contentSize;
@property (nonatomic) GlfwSize size;
@property (nonatomic) GlfwSize minSize;
@property (nonatomic) GlfwSize maxSize;
@property (nonatomic) GlfwPoint pos;
@property (nonatomic) bool visible;
@property (nonatomic) bool iconified;
@property (nonatomic) bool focused;
@property (nonatomic) bool shouldClose;

- (instancetype)init OF_UNAVAILABLE;

- (instancetype)initWithRect:(GlfwRect)windowRectangle title:(OFString *)windowTitle
                       hints:(OFDictionary OF_GENERIC(OFNumber *, OFNumber *) *)windowHints OF_DESIGNATED_INITIALIZER;

- (void)bindEventHandler:(id<GlfwEventHandling>)eventHndler;
- (void)unbindEventHandler:(id<GlfwEventHandling>)eventHndler;
- (void)bindDrawble:(id<GlfwDrawing>)drawble;
- (void)unbindDrawble:(id<GlfwDrawing>)drawble;

- (void)destroy;
- (void)draw;
- (void)sendEvent:(GlfwEvent *)event;
- (void)swapBuffers;

@end
