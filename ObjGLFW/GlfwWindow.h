//
//  GlfwWindow.h
//  ObjGLFW
//
//  Created by Юрий Вовк on 05.12.2017.
//  Copyright © 2017 GunGraveKoga. All rights reserved.
//

#import <ObjFW/ObjFW.h>
#import "GlfwGeometry.h"
#include <GLFW/glfw3.h>

@interface GlfwWindow : OFObject
{
    GLFWwindow *_windowHandle;
    OFString *_windowTitle;
    GlfwSize _minSize;
    GlfwSize _maxSize;
    bool _visible;
    bool _iconified;
    bool _active;
}

@property (nonatomic, copy) OFString *title;
@property (nonatomic) GlfwRect frame;
@property (nonatomic) GlfwSize contentSize;
@property (nonatomic) GlfwSize size;
@property (nonatomic) GlfwSize minSize;
@property (nonatomic) GlfwSize maxSize;
@property (nonatomic) GlfwPoint pos;
@property (nonatomic) bool visible;
@property (nonatomic) bool iconified;
@property (nonatomic) bool shouldClose;

- (instancetype)init OF_UNAVAILABLE;

- (instancetype)initWithRect:(GlfwRect)windowRectangle title:(OFString *)windowTitle
                       hints:(OFDictionary OF_GENERIC(OFNumber *, OFNumber *) *)windowHints OF_DESIGNATED_INITIALIZER;


@end
