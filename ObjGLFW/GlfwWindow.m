//
//  GlfwWindow.m
//  ObjGLFW
//
//  Created by Юрий Вовк on 05.12.2017.
//  Copyright © 2017 GunGraveKoga. All rights reserved.
//

#import "GlfwWindow.h"
#import "GlfwApplication.h"
#import "GlfwWindowManager.h"

@interface GlfwWindow ()

@end

#if defined(OF_HAVE_THREADS)
#define LOCK() do { \
                    [_lock lock]; \
                } while (0)
#define UNLOCK() do { \
                        [_lock unlock]; \
                    } while (0)
#else
#define LOCK() do { ; } while (0)
#define UNLOCK() do { ; } while (0)
#endif

@implementation GlfwWindow

@synthesize windowHandle = _windowHandle;

- (instancetype)initWithRect:(GlfwRect)windowRectangle title:(OFString *)windowTitle hints:(OFDictionary<OFNumber *,OFNumber *> *)windowHints
{
    self = [super init];
    
    @try {
        
        _visible = true;
        _iconified = false;
        _maxSize = GlfwSizeNew(-1, -1);
        _minSize = GlfwSizeNew(-1, -1);
        
#if defined(OF_HAVE_THREADS)
        _lock = [[OFRecursiveMutex alloc] init];
#endif
        
        _drawables = nil;
        _eventHandlers = nil;
        
        for (OFNumber *hint in windowHints) {
            OFNumber *hintValue = [windowHints objectForKey:hint];
            
            int glfwHint = [hint intValue];
            int glfwHintFlag = [hintValue intValue];
            
            glfwWindowHint(glfwHint, glfwHintFlag);
            
            if ((glfwHint == GLFW_VISIBLE) && (glfwHintFlag == GLFW_FALSE))
                _visible = false;
            
            if ((glfwHint == GLFW_ICONIFIED) && (glfwHintFlag == GLFW_TRUE))
                _iconified = true;
        }
        
        GlfwSize windowSize = windowRectangle.size;
        GlfwPoint windowPos = windowRectangle.origin;
        
        if ((windowPos.x != 0) && (windowPos.y != 0)) {
            glfwWindowHint(GLFW_VISIBLE, GLFW_FALSE);
        }
        
        if ((_windowHandle = glfwCreateWindow(windowSize.width, windowSize.height, [windowTitle UTF8String], NULL, NULL)) == NULL) {
            @throw [OFInitializationFailedException exceptionWithClass:[self class]];
        }
        
        _active = true;
        
        _windowTitle = [windowTitle copy];
        
#if defined(OF_MACOS)
        /* Poll for events once before starting a potentially
         lengthy loading process. This is needed to be
         classified as "interactive" by other software such
         as iTerm2 */
        
        glfwPollEvents();
#endif
        
        if (windowPos.x != 0 && windowPos.y != 0) {
            glfwSetWindowPos(_windowHandle, windowPos.x, windowPos.y);
            
            if (_visible)
                glfwShowWindow(_windowHandle);
        }
        
        glfwSetWindowUserPointer(_windowHandle, (__bridge void *)self);
        
    }
    @catch (id e) {
        [self release];
        
        @throw e;
    }
    @finally {
        glfwDefaultWindowHints();
    }
    
    return self;
}

- (OFString *)title {
    return _windowTitle;
}

- (void)setTitle:(OFString *)title {
    LOCK();
    if (_windowHandle) {
        if (![_windowTitle isEqual:title]) {
            OFString *oldTitle = _windowTitle;
            _windowTitle = nil;
            
            glfwSetWindowTitle(_windowHandle, [title UTF8String]);
            
            _windowTitle = [title copy];
            [oldTitle release];
        }
    }
    UNLOCK();
}

- (GlfwRect)frame {
    LOCK();
    if (_windowHandle) {
        int xpos, ypos, width, height;
        
        glfwGetWindowPos(_windowHandle, &xpos, &ypos);
        glfwGetWindowSize(_windowHandle, &width, &height);
        
        return GlfwRectNew(xpos, ypos, width, height);
    }
    UNLOCK();
    return GlfwRectZero();
}

- (void)setFrame:(GlfwRect)frame {
    LOCK();
    if (_windowHandle) {
        glfwSetWindowPos(_windowHandle, frame.origin.x, frame.origin.y);
        glfwSetWindowSize(_windowHandle, frame.size.width, frame.size.height);
    }
    UNLOCK();
}

- (GlfwSize)size {
    LOCK();
    if (_windowHandle) {
        int width, height;
        glfwGetWindowSize(_windowHandle, &width, &height);
        
        return GlfwSizeNew(width, height);
    }
    UNLOCK();
    return GlfwSizeZero();
}

- (void)setSize:(GlfwSize)size {
    LOCK();
    if (_windowHandle) {
        glfwSetWindowSize(_windowHandle, size.width, size.height);
    }
    UNLOCK();
}

- (GlfwPoint)pos {
    LOCK();
    if (_windowHandle) {
        int xpos, ypos;
        glfwGetWindowPos(_windowHandle, &xpos, &ypos);
        
        return GlfwPointNew(xpos, ypos);
    }
    UNLOCK();
    return GlfwPointZero();
}

- (void)setPos:(GlfwPoint)pos {
    LOCK();
    if (_windowHandle) {
        glfwSetWindowPos(_windowHandle, pos.x, pos.y);
    }
    UNLOCK();
}

- (GlfwSize)minSize {
    return _minSize;
}

- (void)setMinSize:(GlfwSize)minSize {
    LOCK();
    if (_windowHandle) {
        glfwSetWindowSizeLimits(_windowHandle, minSize.width, minSize.height, GLFW_DONT_CARE, GLFW_DONT_CARE);
        _minSize = minSize;
    }
    UNLOCK();
}

- (GlfwSize)maxSize {
    return _maxSize;
}

- (void)setMaxSize:(GlfwSize)maxSize {
    LOCK();
    if (_windowHandle) {
        glfwSetWindowSizeLimits(_windowHandle, GLFW_DONT_CARE, GLFW_DONT_CARE, maxSize.width, maxSize.height);
        _maxSize = maxSize;
    }
    UNLOCK();
}

- (GlfwSize)contentSize {
    LOCK();
    if (_windowHandle) {
        int width, height;
        glfwGetFramebufferSize(_windowHandle, &width, &height);
        
        return GlfwSizeNew(width, height);
    }
    UNLOCK();
    return GlfwSizeZero();
}

- (void)setContentSize:(GlfwSize)contentSize {
    LOCK();
    if (_windowHandle) {
        int left, top, right, bottom;
        glfwGetWindowFrameSize(_windowHandle, &left, &top, &right, &bottom);
        glfwSetWindowSize(_windowHandle, (left + contentSize.width + right), (top + contentSize.height + bottom));
    }
    UNLOCK();
}

- (bool)visible {
    return _visible;
}

- (void)setVisible:(bool)visible {
    LOCK();
    if (_windowHandle) {
        if (_visible != visible) {
            if (visible) {
                glfwShowWindow(_windowHandle);
            }
            else {
                glfwHideWindow(_windowHandle);
            }
            
            _visible = visible;
        }
    }
    UNLOCK();
}

- (bool)iconified {
    return _iconified;
}

- (void)setIconified:(bool)iconified {
    LOCK();
    if (_windowHandle) {
        if (_iconified != iconified) {
            if (iconified) {
                glfwIconifyWindow(_windowHandle);
            }
            else {
                glfwRestoreWindow(_windowHandle);
            }
            
            _iconified = iconified;
        }
    }
    UNLOCK();
}

- (bool)shouldClose {
    LOCK();
    if (_windowHandle) {
        return ((glfwWindowShouldClose(_windowHandle)) == GLFW_TRUE);
    }
    UNLOCK();
    return true;
}

- (void)setShouldClose:(bool)shouldClose {
    LOCK();
    if (_windowHandle) {
        glfwSetWindowShouldClose(_windowHandle, (shouldClose) ? GLFW_TRUE : GLFW_FALSE);
    }
    UNLOCK();
}

- (void)bindDrawble:(id<GlfwDrawing>)drawble {
    LOCK();
    if (_windowHandle) {
        
        if (![_drawables containsObjectIdenticalTo:drawble]) {
            [_drawables appendObject:drawble];
        }
    }
    UNLOCK();
}

- (void)unbindDrawble:(id<GlfwDrawing>)drawble {
    LOCK();
    if (_windowHandle) {
        
        if ([_drawables containsObjectIdenticalTo:drawble]) {
            of_list_object_t *object = [_drawables firstListObject];
            
            while (object != NULL) {
                if (object->object == drawble) {
                    [_drawables removeListObject:object];
                    
                    break;
                }
                
                object = object->next;
            }
        }
    }
    UNLOCK();
}

- (void)bindEventHandler:(id<GlfwEventHandling>)eventHndler {
    LOCK();
    if (_windowHandle) {
        if (_eventHandlers == nil)
            _eventHandlers = [[OFSortedList alloc] init];
        
        if (![_eventHandlers containsObjectIdenticalTo:eventHndler]) {
            [_eventHandlers appendObject:eventHndler];
        }
    }
    UNLOCK();
}

- (void)unbindEventHandler:(id<GlfwEventHandling>)eventHndler {
    LOCK();
    if (_windowHandle) {
        
        if ([_eventHandlers containsObjectIdenticalTo:eventHndler]) {
            [_eventHandlers appendObject:eventHndler];
        }
    }
    UNLOCK();
}

- (void)_destroy {
    glfwDestroyWindow(_windowHandle);
    
    _windowHandle = NULL;
}

- (void)destroy {
    LOCK();
    if (_windowHandle) {
        [[GlfwWindowManager defaultManager] detachWindow:self];
        
        [self _destroy];
    }
    UNLOCK();
}

- (void)draw {
    LOCK();
    if (_windowHandle) {
        
        for (id<GlfwDrawing> drawble in _drawables) {
            void *pool = objc_autoreleasePoolPush();
            
            [drawble draw];
            
            objc_autoreleasePoolPop(pool);
        }
    }
    UNLOCK();
}

- (void)sendEvent:(GlfwEvent *)event {
    LOCK();
    if (_windowHandle) {
        
    }
    UNLOCK();
}

- (void)swapBuffers {
    LOCK();
    if (_windowHandle) {
        
        glfwSwapBuffers(_windowHandle);
    }
    UNLOCK();
}

- (void)dealloc {
    if (_windowHandle) {
        [self _destroy];
    }
    
    [_windowTitle release];
#if defined(OF_HAVE_THREADS)
    [_lock release];
#endif
    [_drawables removeAllObjects];
    [_drawables release];
    [_eventHandlers removeAllObjects];
    [_eventHandlers release];
    
    [super dealloc];
}

@end
