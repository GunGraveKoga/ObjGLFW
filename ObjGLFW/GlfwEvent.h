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
    GlfwLeftMouseDown = 1,
    GlfwLeftMouseUp,
    GlfwRightMouseDown,
    GlfwRightMouseUp,
    GlfwMouseMiddleDown,
    GlfwMouseMiddleUp,
    GlfwMouseOtherDown,
    GlfwMouseOtherUp,
    GlfwMouseMoved,
    GlfwMouseEntered,
    GlfwMouseExited,
    GlfwKeyDown,
    GlfwKeyUp,
};
typedef uint32_t GlfwEventType;

enum {
    GlfwLeftMouseDownMask = (1 << GlfwLeftMouseDown),
    GlfwLeftMouseUpMask = (1 << GlfwLeftMouseUp),
    GlfwRightMouseDownMask = (1 << GlfwRightMouseDown),
    GlfwRightMouseUpMask = (1 << GlfwRightMouseUp),
    GlfwMouseMiddleDownMask = (1 << GlfwMouseMiddleDown),
    GlfwMouseMiddleUpMask = (1 << GlfwMouseMiddleUp),
    GlfwMouseOtherDownMask = (1 << GlfwMouseOtherDown),
    GlfwMouseOtherUpMask = (1 << GlfwMouseOtherUp),
    GlfwMouseMovedMask = (1 << GlfwMouseMoved),
    GlfwMouseEnteredMask = (1 << GlfwMouseEntered),
    GlfwMouseExitedMask = (1 << GlfwMouseExited),
    GlfwKeyDownMask = (1 << GlfwKeyDown),
    GlfwKeyUpMask = (1 << GlfwKeyUp),
    GlfwAnyEventMask = 0xffffffffU,
};
typedef unsigned long long GlfwEventMask;

OF_INLINE GlfwEventMask GlfwEventMaskFromType(GlfwEventType type) {
    return (1 << type);
}

@class GlfwRawWindow;

@interface GlfwEvent : OFObject
{
    double _timestamp;
    
}

@property (nonatomic, readonly) double timestamp;
@property (nonatomic, readonly) GlfwEventType type;
@property (nonatomic, readonly) of_point_t mouseLoaction;
@property (nonatomic, readonly, retain) GlfwRawWindow *window;

+ (instancetype)enterExitEventWithType:(GlfwEventType)type
                             timestamp:(double)timestamp
                                window:(GlfwRawWindow *)window;

+ (instancetype)keyEventWithType:(GlfwEventType)type
                       timestamp:(double)timestamp
                          window:(GlfwRawWindow *)window
                        scanCode:(int)scanCode
                       modifiers:(int)mods;

- (instancetype)initWithType:(GlfwEventType)type
                    location:(of_point_t)location
               modifierFlags:(int)flags
                   timestamp:(double)timestamp
                      window:(GlfwRawWindow *)window
                   character:(of_unichar_t)character
 charactersIgnoringModifiers:(int)mods
                    scanCode:(int)scanCode
                      deltaX:(double)deltaX
                      deltaY:(double)deltaY;

- (bool)isEventMatchEventMask:(GlfwEventMask)mask;

@end
