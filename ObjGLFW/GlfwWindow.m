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

@implementation GlfwWindow

- (instancetype)initWithRect:(GlfwRect)windowRectangle title:(OFString *)windowTitle hints:(OFDictionary<OFNumber *,OFNumber *> *)windowHints
{
    self = [super init];
    
    @try {
        
        _visible = true;
        _iconified = false;
        _maxSize = GlfwSizeNew(-1, -1);
        _minSize = GlfwSizeNew(-1, -1);
        
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
    if (![_windowTitle isEqual:title]) {
        OFString *oldTitle = _windowTitle;
        _windowTitle = nil;
        
        glfwSetWindowTitle(_windowHandle, [title UTF8String]);
        
        _windowTitle = [title copy];
        [oldTitle release];
    }
}

- (GlfwRect)frame {
    int xpos, ypos, width, height;
    
    glfwGetWindowPos(_windowHandle, &xpos, &ypos);
    glfwGetWindowSize(_windowHandle, &width, &height);
    
    return GlfwRectNew(xpos, ypos, width, height);
}

- (void)setFrame:(GlfwRect)frame {
    glfwSetWindowPos(_windowHandle, frame.origin.x, frame.origin.y);
    glfwSetWindowSize(_windowHandle, frame.size.width, frame.size.height);
}

- (GlfwSize)size {
    int width, height;
    glfwGetWindowSize(_windowHandle, &width, &height);
    
    return GlfwSizeNew(width, height);
}

- (void)setSize:(GlfwSize)size {
    glfwSetWindowSize(_windowHandle, size.width, size.height);
}

- (GlfwPoint)pos {
    int xpos, ypos;
    glfwGetWindowPos(_windowHandle, &xpos, &ypos);
    
    return GlfwPointNew(xpos, ypos);
}

- (void)setPos:(GlfwPoint)pos {
    glfwSetWindowPos(_windowHandle, pos.x, pos.y);
}

- (GlfwSize)minSize {
    return _minSize;
}

- (void)setMinSize:(GlfwSize)minSize {
    glfwSetWindowSizeLimits(_windowHandle, minSize.width, minSize.height, GLFW_DONT_CARE, GLFW_DONT_CARE);
    _minSize = minSize;
}

- (GlfwSize)maxSize {
    return _maxSize;
}

- (void)setMaxSize:(GlfwSize)maxSize {
    glfwSetWindowSizeLimits(_windowHandle, GLFW_DONT_CARE, GLFW_DONT_CARE, maxSize.width, maxSize.height);
    _maxSize = maxSize;
}

- (GlfwSize)contentSize {
    int width, height;
    glfwGetFramebufferSize(_windowHandle, &width, &height);
    
    return GlfwSizeNew(width, height);
}

- (void)setContentSize:(GlfwSize)contentSize {
    int left, top, right, bottom;
    glfwGetWindowFrameSize(_windowHandle, &left, &top, &right, &bottom);
    glfwSetWindowSize(_windowHandle, (left + contentSize.width + right), (top + contentSize.height + bottom));
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
    
    [_windowTitle release];
    
    [super dealloc];
}

@end
