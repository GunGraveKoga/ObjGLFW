//
//  GlfwRawWindow.m
//  ObjGLFW
//
//  Created by Юрий Вовк on 05.12.2017.
//  Copyright © 2017 GunGraveKoga. All rights reserved.
//

#import "GlfwRawWindow.h"
#import "GlfwApplication.h"
#import "GlfwWindowManager.h"
#import "GlfwMonitor.h"
#import "GlfwCursor.h"

@interface GlfwMonitor ()
+ (instancetype)glfw_findMonitor:(GLFWmonitor *)monitorHandle;
@end

@interface GlfwRawWindow ()

@end

@implementation GlfwRawWindow

@synthesize windowHandle = _windowHandle;

+ (instancetype)currentContextWindow {
    return [[GlfwWindowManager defaultManager] findWindow:glfwGetCurrentContext()];
}

+ (instancetype)windowWithRect:(GlfwRect)windowRectangle title:(OFString *)windowTitle hints:(OFDictionary<OFNumber *,OFNumber *> *)windowHints {
    
    return [[[self alloc] initWithRect:windowRectangle title:windowTitle hints:windowHints] autorelease];
}

- (instancetype)initWithRect:(GlfwRect)windowRectangle title:(OFString *)windowTitle hints:(OFDictionary<OFNumber *,OFNumber *> *)windowHints
{
    self = [super init];
    
    @try {
        
        bool visible = true;
        _maxSize = GlfwSizeNull();
        _minSize = GlfwSizeNull();
#if defined(OF_HAVE_THREADS)
        _lock = [[OFMutex alloc] init];
#endif
        
        for (OFNumber *hint in windowHints) {
            OFNumber *hintValue = [windowHints objectForKey:hint];
            
            int glfwHint = [hint intValue];
            int glfwHintFlag = [hintValue intValue];
            
            glfwWindowHint(glfwHint, glfwHintFlag);
            
            if ((glfwHint == GLFW_VISIBLE) && (glfwHintFlag == GLFW_FALSE))
                visible = false;
        }
        
        GlfwSize windowSize = windowRectangle.size;
        GlfwPoint windowPos = windowRectangle.origin;
        
        if ((windowPos.x != 0) && (windowPos.y != 0)) {
            glfwWindowHint(GLFW_VISIBLE, GLFW_FALSE);
        }
        
        if ((_windowHandle = glfwCreateWindow(windowSize.width, windowSize.height, [windowTitle UTF8String], NULL, NULL)) == NULL) {
            @throw [OFInitializationFailedException exceptionWithClass:[self class]];
        }
        
        _windowTitle = [windowTitle copy];
        
#if defined(OF_MACOS)
        
        glfwPollEvents();
#endif
        
        if (windowPos.x != 0 && windowPos.y != 0) {
            glfwSetWindowPos(_windowHandle, windowPos.x, windowPos.y);
            
            if (visible)
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

- (GlfwMonitor *)monitor {
    @synchronized(self) {
        if (_windowHandle) {
            return [GlfwMonitor glfw_findMonitor:glfwGetWindowMonitor(_windowHandle)];
        }
    }
    
    return nil;
}

- (void)setMonitor:(GlfwMonitor *)monitor {
    @synchronized(self) {
        if (_windowHandle) {
            const GLFWvidmode *vmode = [monitor videoMode];
            glfwSetWindowMonitor(_windowHandle, [monitor monitorHandle], 0, 0, vmode->width, vmode->height, vmode->refreshRate);
        }
    }
}

- (OFString *)title {
    return _windowTitle;
}

- (void)setTitle:(OFString *)title {
    @synchronized (self) {
        if (_windowHandle) {
            if (![_windowTitle isEqual:title]) {
                OFString *oldTitle = _windowTitle;
                _windowTitle = nil;
                
                glfwSetWindowTitle(_windowHandle, [title UTF8String]);
                
                _windowTitle = [title copy];
                [oldTitle release];
            }
        }
    }
}

- (GlfwRect)frame {
    @synchronized (self) {
        if (_windowHandle) {
            int xpos, ypos, width, height;
            
            glfwGetWindowPos(_windowHandle, &xpos, &ypos);
            glfwGetWindowSize(_windowHandle, &width, &height);
            
            return GlfwRectNew(xpos, ypos, width, height);
        }
    }
    
    return GlfwRectZero();
}

- (void)setFrame:(GlfwRect)frame {
    @synchronized (self) {
        if (_windowHandle) {
            glfwSetWindowPos(_windowHandle, frame.origin.x, frame.origin.y);
            glfwSetWindowSize(_windowHandle, frame.size.width, frame.size.height);
        }
    }
}

- (GlfwSize)size {
    @synchronized (self) {
        if (_windowHandle) {
            int width, height;
            glfwGetWindowSize(_windowHandle, &width, &height);
            
            return GlfwSizeNew(width, height);
        }
    }
    
    return GlfwSizeZero();
}

- (void)setSize:(GlfwSize)size {
    @synchronized (self) {
        if (_windowHandle) {
            glfwSetWindowSize(_windowHandle, size.width, size.height);
        }
    }
}

- (GlfwPoint)pos {
    @synchronized (self) {
        if (_windowHandle) {
            int xpos, ypos;
            glfwGetWindowPos(_windowHandle, &xpos, &ypos);
            
            return GlfwPointNew(xpos, ypos);
        }
    }
    
    return GlfwPointZero();
}

- (void)setPos:(GlfwPoint)pos {
    @synchronized (self) {
        if (_windowHandle) {
            glfwSetWindowPos(_windowHandle, pos.x, pos.y);
        }
    }
}

- (GlfwSize)minSize {
    @synchronized (self) {
        return _minSize;
    }
}

- (void)setMinSize:(GlfwSize)minSize {
    @synchronized (self) {
        if (_windowHandle) {
            glfwSetWindowSizeLimits(_windowHandle, minSize.width, minSize.height, GLFW_DONT_CARE, GLFW_DONT_CARE);
            _minSize = minSize;
        }
    }
}

- (GlfwSize)maxSize {
    @synchronized (self) {
        return _maxSize;
    }
}

- (void)setMaxSize:(GlfwSize)maxSize {
    @synchronized (self) {
        if (_windowHandle) {
            glfwSetWindowSizeLimits(_windowHandle, GLFW_DONT_CARE, GLFW_DONT_CARE, maxSize.width, maxSize.height);
            _maxSize = maxSize;
        }
    }
}

- (GlfwSize)contentSize {
    @synchronized (self) {
        if (_windowHandle) {
            int width, height;
            glfwGetFramebufferSize(_windowHandle, &width, &height);
            
            return GlfwSizeNew(width, height);
        }
    }
    
    return GlfwSizeZero();
}

- (void)setContentSize:(GlfwSize)contentSize {
    @synchronized (self) {
        if (_windowHandle) {
            int left, top, right, bottom;
            glfwGetWindowFrameSize(_windowHandle, &left, &top, &right, &bottom);
            glfwSetWindowSize(_windowHandle, (left + contentSize.width + right), (top + contentSize.height + bottom));
        }
    }
}

- (bool)isVisible {
    @synchronized (self) {
        if (_windowHandle) {
            return ((glfwGetWindowAttrib(_windowHandle, GLFW_VISIBLE)) == GLFW_TRUE);
        }
        
        return false;
    }
}

- (void)setVisible:(bool)visible {
    @synchronized (self) {
        if (_windowHandle) {
            if ([self isVisible] != visible) {
                if (visible) {
                    glfwShowWindow(_windowHandle);
                }
                else {
                    glfwHideWindow(_windowHandle);
                }
            }
        }
    }
}

- (bool)isIconified {
    @synchronized (self) {
        if (_windowHandle) {
            return ((glfwGetWindowAttrib(_windowHandle, GLFW_ICONIFIED)) == GLFW_TRUE);
        }
        
        return false;
    }
}

- (void)setIconified:(bool)iconified {
    @synchronized (self) {
        if (_windowHandle) {
            if ([self isIconified] != iconified) {
                if (iconified) {
                    glfwIconifyWindow(_windowHandle);
                }
                else {
                    glfwRestoreWindow(_windowHandle);
                }
            }
        }
    }
}

- (bool)isMaximized {
    @synchronized (self) {
        if (_windowHandle) {
            return ((glfwGetWindowAttrib(_windowHandle, GLFW_MAXIMIZED)) == GLFW_TRUE);
        }
        
        return false;
    }
}

- (void)setMaximazed:(bool)maximazed {
    @synchronized (self) {
        if (_windowHandle) {
            if ([self isMaximized] != maximazed) {
                if (maximazed) {
                    glfwMaximizeWindow(_windowHandle);
                }
                else {
                    glfwMaximizeWindow(_windowHandle);
                }
            }
        }
    }
}

- (bool)isFocused {
    @synchronized (self) {
        if (_windowHandle) {
            return ((glfwGetWindowAttrib(_windowHandle, GLFW_FOCUSED)) == GLFW_TRUE);
        }
        
        return false;
    }
}

- (void)setFocused:(bool)focused {
    @synchronized (self) {
        if (_windowHandle) {
            glfwFocusWindow(_windowHandle);
        }
    }
}

- (bool)shouldClose {
    @synchronized (self) {
        if (_windowHandle) {
            return ((glfwWindowShouldClose(_windowHandle)) == GLFW_TRUE);
        }
    }
    return true;
}

- (void)setShouldClose:(bool)shouldClose {
    @synchronized (self) {
        if (_windowHandle) {
            glfwSetWindowShouldClose(_windowHandle, (shouldClose) ? GLFW_TRUE : GLFW_FALSE);
        }
    }
}

- (bool)isDecorated {
    @synchronized (self) {
        if (_windowHandle) {
            return ((glfwGetWindowAttrib(_windowHandle, GLFW_DECORATED)) == GLFW_TRUE);
        }
        
        return false;
    }
}

- (bool)isFloating {
    @synchronized (self) {
        if (_windowHandle) {
            return ((glfwGetWindowAttrib(_windowHandle, GLFW_FLOATING)) == GLFW_TRUE);
        }
        
        return false;
    }
}

- (bool)isResizable {
    @synchronized (self) {
        if (_windowHandle) {
            return ((glfwGetWindowAttrib(_windowHandle, GLFW_RESIZABLE)) == GLFW_TRUE);
        }
        
        return false;
    }
}

- (bool)isVisibleForUser {
    return ([self isVisible] && ![self isIconified]);
}

- (of_point_t)cursorPos {
    @synchronized(self) {
        if (_windowHandle) {
            double x, y;
            
            glfwGetCursorPos(_windowHandle, &x, &y);
            
            return of_point(x, y);
        }
    }
    
    return of_point_null();
}

- (void)setCursorPos:(of_point_t)cursorPos {
    @synchronized(self) {
        if (_windowHandle) {
            glfwSetCursorPos(_windowHandle, cursorPos.x, cursorPos.y);
        }
    }
}

- (GlfwCursor *)cursor {
    @synchronized(self) {
        if (_windowHandle) {
            return _cursor;
        }
    }
    
    return nil;
}

- (void)setCursor:(GlfwCursor *)cursor {
    @synchronized(self) {
        if (_windowHandle) {
            [_cursor release];
            _cursor = nil;
            
            if (cursor != nil) {
                _cursor = [cursor copy];
                
                glfwSetCursor(_windowHandle, [_cursor cursorHandle]);
            }
            else {
                glfwSetCursor(_windowHandle, NULL);
            }
        }
    }
}

- (OFString *)clipboardString {
    @synchronized(self) {
        if (_windowHandle) {
            const char *clipboardString = glfwGetClipboardString(_windowHandle);
            if (clipboardString != NULL)
                return [OFString stringWithUTF8StringNoCopy:(char *)clipboardString freeWhenDone:false];
        }
    }
    return nil;
}

-(void)setClipboardString:(OFString *)clipboardString {
    @synchronized(self) {
        if (_windowHandle) {
            glfwSetClipboardString(_windowHandle, [clipboardString UTF8String]);
        }
    }
}

- (bool)isOpen {
    @synchronized (self) {
        return (_windowHandle != NULL);
    }
}

- (void)requestWindowAttention {
    @synchronized (self) {
        if (_windowHandle) {
            glfwRequestWindowAttention(_windowHandle);
        }
    }
}

- (void)_destroy {
    glfwDestroyWindow(_windowHandle);
    
    _windowHandle = NULL;
}

- (void)destroy {
    @synchronized (self) {
        if (_windowHandle) {
            [[GlfwWindowManager defaultManager] detachWindow:self];
            
            [self _destroy];
        }
    }
}

- (void)draw {
    OF_UNRECOGNIZED_SELECTOR;
}

- (void)sendEvent:(GlfwEvent *)event {
    OF_UNRECOGNIZED_SELECTOR;
}

- (void)makeContextCurrent {
    @synchronized(self) {
        [_lock lock];
        
        if (_windowHandle) {
            glfwMakeContextCurrent(_windowHandle);
        }
    }
}

- (void)doneContext {
    @synchronized(self) {
        [_lock unlock];
    }
}

- (void)swapBuffers {
    @synchronized (self) {
        if (_windowHandle) {
            
            glfwSwapBuffers(_windowHandle);
        }
    }
}

- (void)setValue:(int)value forInputMode:(int)inputMode {
    @synchronized(self) {
        if (_windowHandle) {
            glfwSetInputMode(_windowHandle, inputMode, value);
        }
    }
}

- (int)valueForInputMode:(int)inputMode {
    @synchronized(self) {
        if (_windowHandle) {
            return glfwGetInputMode(_windowHandle, inputMode);
        }
    }
    
    return -1;
}

- (int)stateOfMouseButton:(int)mouseButton {
    @synchronized(self) {
        if (_windowHandle) {
            return glfwGetMouseButton(_windowHandle, mouseButton);
        }
    }
    
    return -1;
}

- (int)stateOfKey:(int)glfwKey {
    @synchronized(self) {
        if (_windowHandle) {
            return glfwGetKey(_windowHandle, glfwKey);
        }
    }
    
    return -1;
}

- (id)copy {
    return [self retain];
}

- (bool)isEqual:(id)object {
    if (![((id<OFObject>)object) isMemberOfClass:[self class]])
        return false;
    
    GlfwRawWindow *other = (GlfwRawWindow *)object;
    
    return (self->_windowHandle == other->_windowHandle);
}

- (uint32_t)hash {
    @synchronized(self) {
        if (_windowHandle) {
            uint32_t hash;
            
            OF_HASH_INIT(hash);
            
            for (size_t i = 0; i < sizeof(GLFWwindow *); i++)
                OF_HASH_ADD(hash, ((uint8_t *)_windowHandle)[i]);
            
            OF_HASH_FINALIZE(hash);
            
            return hash;
        }
    }
    
    return [super hash];
}

- (void)dealloc {
    if (_windowHandle) {
        [self _destroy];
    }
    
    [_windowTitle release];
#if defined(OF_HAVE_THREADS)
    [_lock release];
#endif
    
    [super dealloc];
}

@end
