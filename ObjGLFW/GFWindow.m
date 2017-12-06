//
//  GFWindow.m
//  ObjGLFW
//
//  Created by Юрий Вовк on 05.12.2017.
//  Copyright © 2017 GunGraveKoga. All rights reserved.
//

#import "GFWindow.h"
#import "GFEventHandler.h"
#import "GFApplication.h"

@interface GFWindow ()

@end

@implementation GFWindow

- (instancetype)initWithRect:(GFRect)windowRectangle title:(OFString *)windowTitle hints:(OFDictionary<OFNumber *,OFNumber *> *)windowHints
{
    self = [super init];
    
    @try {
        
        _visible = true;
        _iconified = false;
        _maxSize = GFSizeNew(-1, -1);
        _minSize = GFSizeNew(-1, -1);
        
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
        
        GFSize windowSize = windowRectangle.size;
        GFPoint windowPos = windowRectangle.origin;
        
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
        
        [[(GFApplication *)[GFApplication sharedApplication] eventHandler] attachWindow:self];
        
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
    if (![_windowTitle isEqual:title]) {
        OFString *oldTitle = _windowTitle;
        _windowTitle = nil;
        
        glfwSetWindowTitle(_windowHandle, [title UTF8String]);
        
        _windowTitle = [title copy];
        [oldTitle release];
    }
}

- (GFRect)frame {
    int xpos, ypos, width, height;
    
    glfwGetWindowPos(_windowHandle, &xpos, &ypos);
    glfwGetWindowSize(_windowHandle, &width, &height);
    
    return GFRectNew(xpos, ypos, width, height);
}

- (void)setFrame:(GFRect)frame {
    glfwSetWindowPos(_windowHandle, frame.origin.x, frame.origin.y);
    glfwSetWindowSize(_windowHandle, frame.size.width, frame.size.height);
}

- (GFSize)size {
    int width, height;
    glfwGetWindowSize(_windowHandle, &width, &height);
    
    return GFSizeNew(width, height);
}

- (void)setSize:(GFSize)size {
    glfwSetWindowSize(_windowHandle, size.width, size.height);
}

- (GFPoint)pos {
    int xpos, ypos;
    glfwGetWindowPos(_windowHandle, &xpos, &ypos);
    
    return GFPointNew(xpos, ypos);
}

- (void)setPos:(GFPoint)pos {
    glfwSetWindowPos(_windowHandle, pos.x, pos.y);
}

- (GFSize)minSize {
    return _minSize;
}

- (void)setMinSize:(GFSize)minSize {
    glfwSetWindowSizeLimits(_windowHandle, minSize.width, minSize.height, GLFW_DONT_CARE, GLFW_DONT_CARE);
    _minSize = minSize;
}

- (GFSize)maxSize {
    return _maxSize;
}

- (void)setMaxSize:(GFSize)maxSize {
    glfwSetWindowSizeLimits(_windowHandle, GLFW_DONT_CARE, GLFW_DONT_CARE, maxSize.width, maxSize.height);
    _maxSize = maxSize;
}

- (GFSize)contentSize {
    int width, height;
    glfwGetFramebufferSize(_windowHandle, &width, &height);
    
    return GFSizeNew(width, height);
}

- (void)setContentSize:(GFSize)contentSize {
    int left, top, right, bottom;
    glfwGetWindowFrameSize(_windowHandle, &left, &top, &right, &bottom);
    glfwSetWindowSize(_windowHandle, (left + contentSize.width + right), (top + contentSize.height + bottom));
}

- (void)close {
    
    if (_active) {
        if (_visible)
            glfwHideWindow(_windowHandle);
        
        [[(GFApplication *)[GFApplication sharedApplication] eventHandler] detachWindow:self];
        
        glfwSetWindowUserPointer(_windowHandle, NULL);
        glfwDestroyWindow(_windowHandle);
        
        _active = false;
    }
}

- (bool)visible {
    return _visible;
}

- (void)setVisible:(bool)visible {
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

- (bool)iconified {
    return _iconified;
}

- (void)setIconified:(bool)iconified {
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

- (bool)shouldClose {
    return ((glfwWindowShouldClose(_windowHandle)) == GLFW_TRUE);
}

- (void)setShouldClose:(bool)shouldClose {
    glfwSetWindowShouldClose(_windowHandle, (shouldClose) ? GLFW_TRUE : GLFW_FALSE);
}

- (void)dealloc {
    [self close];
    
    [_windowTitle release];
    
    [super dealloc];
}

@end
