//
//  GlfwEvent.h
//  ObjGLFW
//
//  Created by Юрий Вовк on 05.12.2017.
//  Copyright © 2017 GunGraveKoga. All rights reserved.
//

#import <ObjFW/ObjFW.h>
#import "GlfwGeometry.h"
#include <GLFW/glfw3.h>



enum _GlfwEventType {
    Glfw_LEFT_MOUSE_DOWN = 1,
    Glfw_LEFT_MOUSE_UP,
    Glfw_RIGHT_MOUSE_DOWN,
    Glfw_RIGHT_MOUSE_UP,
    Glfw_MOUSE_MIDDLE_DOWN,
    Glfw_MOUSE_MIDDLE_UP,
    Glfw_MOUSE_OTHER_DOWN,
    Glfw_MOUSE_OTHER_UP,
    Glfw_MOUSE_MOVED,
    Glfw_MOUSE_ENTERED,
    Glfw_MOUSE_EXITED,
    Glfw_KEY_DOW,
    Glfw_KEY_UP,
};
typedef size_t GlfwEventType;

enum {
    Glfw_LEFT_MOUSE_DOWN_MASK = (1 << Glfw_LEFT_MOUSE_DOWN),
    Glfw_LEFT_MOUSE_UP_MASK = (1 << Glfw_LEFT_MOUSE_UP),
    Glfw_RIGHT_MOUSE_DOWN_MASK = (1 << Glfw_RIGHT_MOUSE_DOWN),
    Glfw_RIGHT_MOUSE_UP_MASK = (1 << Glfw_RIGHT_MOUSE_UP),
    Glfw_MOUSE_MIDDLE_DOWN_MASK = (1 << Glfw_MOUSE_MIDDLE_DOWN),
    Glfw_MOUSE_MIDDLE_UP_MASK = (1 << Glfw_MOUSE_MIDDLE_UP),
    Glfw_MOUSE_OTHER_DOWN_MASK = (1 << Glfw_MOUSE_OTHER_DOWN),
    Glfw_MOUSE_OTHER_UP_MASK = (1 << Glfw_MOUSE_OTHER_UP),
    Glfw_MOUSE_MOVED_MASK = (1 << Glfw_MOUSE_MOVED),
    Glfw_MOUSE_ENTERED_MASK = (1 << Glfw_MOUSE_ENTERED),
    Glfw_MOUSE_EXITED_MASK = (1 << Glfw_MOUSE_EXITED),
    Glfw_KEY_DOW_MASK = (1 << Glfw_KEY_DOW),
    Glfw_KEY_UP_MASK = (1 << Glfw_KEY_UP),
    GlfwAnyEventMask = 0xffffffffU,
};
typedef unsigned long long GlfwEventMask;

OF_INLINE GlfwEventMask GlfwEventMaskFromType(GlfwEventType type) {
    return (1 << type);
}

@class GlfwWindow;

@interface GlfwEvent : OFObject
{
    double _timestamp;
    
}

@property (nonatomic, readonly) double timestamp;
@property (nonatomic, readonly) GlfwEventType type;
@property (nonatomic, readonly) of_point_t mouseLoaction;
@property (nonatomic, readonly, retain) GlfwWindow *window;

+ (instancetype)enterExitEventWithType:(GlfwEventType)type
                             timestamp:(double)timestamp
                                window:(GlfwWindow *)window;

+ (instancetype)keyEventWithType:(GlfwEventType)type
                       timestamp:(double)timestamp
                          window:(GlfwWindow *)window
                        scanCode:(int)scanCode
                       modifiers:(int)mods;

- (instancetype)initWithType:(GlfwEventType)type
                    location:(of_point_t)location
               modifierFlags:(int)flags
                   timestamp:(double)timestamp
                      window:(GlfwWindow *)window
                   character:(of_unichar_t)character
 charactersIgnoringModifiers:(int)mods
                    scanCode:(int)scanCode
                      deltaX:(double)deltaX
                      deltaY:(double)deltaY;

- (bool)isEventMatchEventMask:(GlfwEventMask)mask;

@end
