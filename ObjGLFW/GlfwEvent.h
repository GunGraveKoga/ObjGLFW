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
    GlfwWindowDefocused,
    GlfwWindowIconified,
    GlfwWindowRestored,
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
    GlfwWindowDefocusedMask = (1 << GlfwWindowDefocused),
    GlfwWindowIconifiedMask = (1 << GlfwWindowIconified),
    GlfwWindowRestoredMask = (1 << GlfwWindowRestored),
    GlfwCharacterMask = (1 << GlfwCharacter),
    GlfwModifiedCharacterMask = (1 << GlfwModifiedCharacter),
    GlfwFilesDropMask = (1 << GlfwFilesDrop),
    GlfwAnyEventMask = 0xffffffffU,
    GlfwKeyEventMask = (GlfwKeyUpMask | GlfwKeyDownMask),
    GlfwMouseButtonMask = (GlfwLeftMouseDownMask | GlfwLeftMouseUpMask | GlfwRightMouseDownMask
                           | GlfwRightMouseUpMask | GlfwMouseMiddleDownMask | GlfwMouseMiddleUpMask
                           | GlfwMouseOtherDownMask | GlfwMouseOtherUpMask),
    GlfwMouseEventMask = (GlfwMouseMovedMask | GlfwMouseEnteredMask | GlfwMouseExitedMask
                          | GlfwLeftMouseUpMask | GlfwLeftMouseDownMask | GlfwRightMouseUpMask
                          | GlfwRightMouseDownMask | GlfwMouseMiddleUpMask | GlfwMouseMiddleDownMask
                          | GlfwMouseOtherUpMask | GlfwMouseOtherDownMask | GlfwScrollWheelMask),
    GlfwCharacterEventMask = (GlfwCharacterMask | GlfwModifiedCharacterMask),
    GlfwWindowEventMask = (GlfwWindowMovedMask | GlfwWindowResizedMask | GlfwWindowFramebuferResizedMask
                           | GlfwWindowShouldRefreshMask | GlfwWindowShouldCloseMask | GlfwWindowFocusedMask
                           | GlfwWindowDefocusedMask | GlfwWindowIconifiedMask | GlfwWindowRestoredMask)
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
    GlfwRawWindow *_window;
    
    union _event_data_u {
        struct {
            of_point_t pos;
            int button;
            int modifiers;
            double deltaX;
            double deltaY;
        } mouse;
        struct {
            int glfwKey;
            int scancode;
            int modifiers;
        } key;
        struct {
            of_unichar_t character;
            int modifiers;
        } character;
        struct {
            GlfwPoint pos;
            GlfwSize size;
            GlfwSize contentSize;
        } window;
        
    } _event_data;
}

@property (nonatomic, readonly) double timestamp;
@property (nonatomic, readonly) GlfwEventType type;
@property (nonatomic, readonly) GlfwEventType currentType;
@property (nonatomic, readonly, retain) GlfwRawWindow *window;


@property (nonatomic, assign, readonly) int glfwKey;
@property (nonatomic, assign, readonly) int systemScancode;

@property (nonatomic, assign, readonly) of_point_t location;
@property (nonatomic, assign, readonly) of_point_t locationInWindow;
@property (nonatomic, assign, readonly) of_point_t currentLocation;
@property (nonatomic, assign, readonly) of_point_t currentLocationInWindow;
@property (nonatomic, assign, readonly) int glfwMouseButton;
@property (nonatomic, assign, readonly) double deltaX;
@property (nonatomic, assign, readonly) double deltaY;

@property (nonatomic, assign, readonly) of_unichar_t character;

@property (nonatomic, assign, readonly) int modifiersFlags;

@property (nonatomic, assign, readonly) GlfwPoint windowPosition;
@property (nonatomic, assign, readonly) GlfwSize windowSize;
@property (nonatomic, assign, readonly) GlfwSize windowContentSize;

@property (nonatomic, copy, readonly) OFArray OF_GENERIC(OFString *) *droppedFilesPaths;


- (instancetype)init OF_UNAVAILABLE;

- (instancetype)initWithType:(GlfwEventType)eventType
                   timestamp:(double)timestamp
                    window:(GlfwRawWindow *)window OF_DESIGNATED_INITIALIZER;

- (bool)isMatchEventMask:(GlfwEventMask)mask;

@end

@interface GlfwKeyEvent : GlfwEvent

+ (instancetype)keyEventWithType:(GlfwEventType)eventType
                       timestamp:(double)timestamp
                          window:(GlfwRawWindow *)window
                         glfwKey:(int)glfwKey
                       modifiers:(int)modifiersFlags
                  systemScancode:(int)systemScancode;

- (instancetype)initWithType:(GlfwEventType)eventType
                   timestamp:(double)timestamp
                      window:(GlfwRawWindow *)window
                     glfwKey:(int)glfwKey
                   modifiers:(int)modifiersFlags
              systemScancode:(int)systemScancode;

@end

@interface GlfwMouseEvent : GlfwEvent


+ (instancetype)enterExitEventWithType:(GlfwEventType)eventType
                              timestamp:(double)timestamp
                                 window:(GlfwRawWindow *)window;

+ (instancetype)mouseMoveEventWithTimestamp:(double)timestamp
                               window:(GlfwRawWindow *)window
                             loaction:(of_point_t)location;

+ (instancetype)scrollWheelEventWithTimestamp:(double)timestamp
                                  window:(GlfwRawWindow *)window
                                  deltaX:(double)deltaX
                                  deltaY:(double)deltaY;

+ (instancetype)mouseButtonEventWithType:(GlfwEventType)eventType
                               timestamp:(double)timestamp
                                  window:(GlfwRawWindow *)window
                             mouseButton:(int)mouseButton
                          modifiersFlags:(int)modifiersFlags;

- (instancetype)initWithType:(GlfwEventType)eventType
                   timestamp:(double)timestamp
                      window:(GlfwRawWindow *)window
                 mouseButton:(int)mouseButton
              modifiersFlags:(int)modifiersFlags
                    location:(of_point_t)location
                      deltaX:(double)deltaX
                      deltaY:(double)delraY;

@end

@interface GlfwCharacterEvent : GlfwEvent

+ (instancetype)characterEventWithTimestamp:(double)timestamp
                                window:(GlfwRawWindow *)window
                             character:(of_unichar_t)character
                        modifiersFlags:(int)modifiersFlags;

+ (instancetype)characterEventWithTimestamp:(double)timestamp
                                window:(GlfwRawWindow *)window
                             character:(of_unichar_t)character;

- (instancetype)initWithType:(GlfwEventType)eventType
                   timestamp:(double)timestamp
                      window:(GlfwRawWindow *)window
                   character:(of_unichar_t)character
              modifiersFlags:(int)modifiersFlags;

@end


@interface GlfwWindowEvent : GlfwEvent

+ (instancetype)windowMovedEventWithTimestamp:(double)timestamp
                                  window:(GlfwRawWindow *)window
                                    windowPos:(GlfwPoint)newPos;

+ (instancetype)windowResizedEventWithTimestamp:(double)timestamp
                                         window:(GlfwRawWindow *)window
                                     windowSize:(GlfwSize)newSize;

+ (instancetype)windowFramebuferResizedEventWithTimestamp:(double)timestamp
                                                   window:(GlfwRawWindow *)window
                                              contentSize:(GlfwSize)newContentSize;

+ (instancetype)otherWindowEventWithType:(GlfwEventType)eventType
                               timestamp:(double)timestamp
                                  window:(GlfwRawWindow *)window;

- (instancetype)initWithType:(GlfwEventType)eventType
                   timestamp:(double)timestamp
                      window:(GlfwRawWindow *)window
                   windowPos:(GlfwPoint)newPos
                  windowSize:(GlfwSize)newSize
                 contentSize:(GlfwSize)newContentSize;

@end

@interface GlfwFileDropEvent : GlfwEvent
{
    OFArray OF_GENERIC(OFString *) *_filesPaths;
}

+ (instancetype)fileDropEventWithTimestamp:(double)timestamp
                                    window:(GlfwRawWindow *)window
                              droppedFiles:(OFArray OF_GENERIC(OFString *) *)filesPaths;

- (instancetype)initWithType:(GlfwEventType)eventType
                   timestamp:(double)timestamp
                      window:(GlfwRawWindow *)window
                droppedFiles:(OFArray OF_GENERIC(OFString *) *)filesPaths;

@end

OF_ASSUME_NONNULL_END
