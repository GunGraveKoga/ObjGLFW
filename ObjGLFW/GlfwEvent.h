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
    GF_LEFT_MOUSE_DOWN = 1,
    GF_LEFT_MOUSE_UP,
    GF_RIGHT_MOUSE_DOWN,
    GF_RIGHT_MOUSE_UP,
    GF_MOUSE_MIDDLE_DOWN,
    GF_MOUSE_MIDDLE_UP,
    GF_MOUSE_OTHER_DOWN,
    GF_MOUSE_OTHER_UP,
    GF_MOUSE_MOVED,
    GF_MOUSE_ENTERED,
    GF_MOUSE_EXITED,
    GF_KEY_DOW,
    GF_KEY_UP,
};
typedef size_t GlfwEventType;

enum {
    GF_LEFT_MOUSE_DOWN_MASK = (1 << GF_LEFT_MOUSE_DOWN),
    GF_LEFT_MOUSE_UP_MASK = (1 << GF_LEFT_MOUSE_UP),
    GF_RIGHT_MOUSE_DOWN_MASK = (1 << GF_RIGHT_MOUSE_DOWN),
    GF_RIGHT_MOUSE_UP_MASK = (1 << GF_RIGHT_MOUSE_UP),
    GF_MOUSE_MIDDLE_DOWN_MASK = (1 << GF_MOUSE_MIDDLE_DOWN),
    GF_MOUSE_MIDDLE_UP_MASK = (1 << GF_MOUSE_MIDDLE_UP),
    GF_MOUSE_OTHER_DOWN_MASK = (1 << GF_MOUSE_OTHER_DOWN),
    GF_MOUSE_OTHER_UP_MASK = (1 << GF_MOUSE_OTHER_UP),
    GF_MOUSE_MOVED_MASK = (1 << GF_MOUSE_MOVED),
    GF_MOUSE_ENTERED_MASK = (1 << GF_MOUSE_ENTERED),
    GF_MOUSE_EXITED_MASK = (1 << GF_MOUSE_EXITED),
    GF_KEY_DOW_MASK = (1 << GF_KEY_DOW),
    GF_KEY_UP_MASK = (1 << GF_KEY_UP),
    GFAnyEventMask = 0xffffffffU,
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
