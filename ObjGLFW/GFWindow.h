//
//  GFWindow.h
//  ObjGLFW
//
//  Created by Юрий Вовк on 05.12.2017.
//  Copyright © 2017 GunGraveKoga. All rights reserved.
//

#import <ObjFW/ObjFW.h>
#import "GFGeometry.h"
#include <GLFW/glfw3.h>

@interface GFWindow : OFObject
{
    GLFWwindow *_windowHandle;
    OFString *_windowTitle;
    GFSize _minSize;
    GFSize _maxSize;
    bool _visible;
    bool _iconified;
    bool _active;
}

@property (nonatomic, copy) OFString *title;
@property (nonatomic) GFRect frame;
@property (nonatomic) GFSize contentSize;
@property (nonatomic) GFSize size;
@property (nonatomic) GFSize minSize;
@property (nonatomic) GFSize maxSize;
@property (nonatomic) GFPoint pos;
@property (nonatomic) bool visible;
@property (nonatomic) bool iconified;
@property (nonatomic) bool shouldClose;

- (instancetype)init OF_UNAVAILABLE;

- (instancetype)initWithRect:(GFRect)windowRectangle title:(OFString *)windowTitle
                       hints:(OFDictionary OF_GENERIC(OFNumber *, OFNumber *) *)windowHints OF_DESIGNATED_INITIALIZER;


- (void)close;

@end
