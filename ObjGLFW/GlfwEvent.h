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
    GlfwScrollWheel,
    GlfwWindowMoved,
    GlfwWindowResized,
    GlfwWindowFramebuferResized,
    GlfwWindowShouldRefresh,
    GlfwWindowShouldClose,
    GlfwWindowFocused,
    GlfwWindowIconified,
    GlfwCharacter,
    GlfwModifiedCharacter,
    GlfwFilesDrop,
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
    GlfwScrollWheelMask = (1 << GlfwScrollWheel),
    GlfwWindowMovedMask = (1 << GlfwWindowMoved),
    GlfwWindowResizedMask = (1 << GlfwWindowResized),
    GlfwWindowFramebuferResizedMask = (1 << GlfwWindowFramebuferResized),
    GlfwWindowShouldRefreshMask = (1 << GlfwWindowShouldRefresh),
    GlfwWindowShouldCloseMask = (1 << GlfwWindowShouldClose),
    GlfwWindowFocusedMask = (1 << GlfwWindowFocused),
    GlfwWindowIconifiedMask = (1 << GlfwWindowIconified),
    GlfwCharacterMask = (1 << GlfwCharacter),
    GlfwModifiedCharacterMask = (1 << GlfwModifiedCharacter),
    GlfwFilesDropMask = (1 << GlfwFilesDrop),
    GlfwAnyEventMask = 0xffffffffU,
};
typedef unsigned long long GlfwEventMask;

OF_INLINE GlfwEventMask GlfwEventMaskFromType(GlfwEventType type) {
    return (1 << type);
}

@class GlfwRawWindow;

OF_ASSUME_NONNULL_BEGIN

@interface GlfwEvent : OFObject <OFComparing>
{
    double _timestamp;
    GlfwEventType _type;
    of_point_t _mouseLocation;
    GlfwRawWindow *_window;
    int _modifierFlags;
    of_unichar_t _character;
    int _characterModifiers;
    int _key;
    int _scanCode;
    int _mouseButton;
    int _mouseModifiers;
    double _deltaX, _deltaY;
    GlfwSize _size;
    GlfwPoint _pos;
    OFArray OF_GENERIC(OFString *) *_paths;
}

@property (nonatomic, readonly) double timestamp;
@property (nonatomic, readonly) GlfwEventType type;
@property (nonatomic, readonly) of_point_t mouseLoaction;
@property (nonatomic, readonly, retain) GlfwRawWindow *window;
@property (nonatomic, readonly) int modifierFlags;
@property (nonatomic, readonly) of_unichar_t character;
@property (nonatomic, readonly) int characterModifiers;
@property (nonatomic, readonly) int key;
@property (nonatomic, readonly) int scanCode;
@property (nonatomic, readonly) int mouseButton;
@property (nonatomic, readonly) int mouseModifiers;
@property (nonatomic, readonly) double deltaX;
@property (nonatomic, readonly) double deltaY;
@property (nonatomic, readonly) GlfwPoint pos;
@property (nonatomic, readonly) GlfwSize size;
@property (nonatomic, readonly, nullable, copy) OFArray OF_GENERIC(OFString *) *paths;

+ (instancetype)enterExitEventWithType:(GlfwEventType)type
                             timestamp:(double)timestamp
                                window:(GlfwRawWindow *)window;

+ (instancetype)keyEventWithType:(GlfwEventType)type
                       timestamp:(double)timestamp
                          window:(GlfwRawWindow *)window
                             key:(int)key
                        scanCode:(int)scanCode
                       modifiers:(int)mods;

+ (instancetype)mouseEventWithType:(GlfwEventType)type
                         timestamp:(double)timestamp
                            window:(GlfwRawWindow *)window
                          location:(of_point_t)location
                            button:(int)mouseButton
                         modifiers:(int)mouseButtonModifiers
                            deltaX:(double)deltaX
                            deltaY:(double)deltaY;

+ (instancetype)characterEventWithType:(GlfwEventType)type
                             timestamp:(double)timestamp
                                window:(GlfwRawWindow *)window
                             character:(of_unichar_t)character
           characterModifiers:(int)mods;

+ (instancetype)otherEventWithType:(GlfwEventType)type
                         timestamp:(double)timestamp
                            window:(GlfwRawWindow *)window
                              size:(GlfwSize)size
                               pos:(GlfwPoint)pos
                             paths:(OFArray OF_GENERIC(OFString *) * _Nullable)paths;

- (instancetype)init OF_UNAVAILABLE;

- (instancetype)initWithType:(GlfwEventType)type
                    location:(of_point_t)location
               modifierFlags:(int)flags
                   timestamp:(double)timestamp
                      window:(GlfwRawWindow *)window
                   character:(of_unichar_t)character
          characterModifiers:(int)mods
                         key:(int)key
                    scanCode:(int)scanCode
                 mouseButton:(int)mouseButton
              mouseModifiers:(int)mouseButtonModifiers
                      deltaX:(double)deltaX
                      deltaY:(double)deltaY
                        size:(GlfwSize)size
                        pos:(GlfwPoint)pos
                       paths:(OFArray OF_GENERIC(OFString *) * _Nullable)paths OF_DESIGNATED_INITIALIZER;

- (bool)isMatchEventMask:(GlfwEventMask)mask;

@end

OF_ASSUME_NONNULL_END
