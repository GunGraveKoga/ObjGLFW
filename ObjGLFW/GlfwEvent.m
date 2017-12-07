//
//  GlfwEvent.m
//  ObjGLFW
//
//  Created by Юрий Вовк on 05.12.2017.
//  Copyright © 2017 GunGraveKoga. All rights reserved.
//

#import "GlfwEvent.h"

@implementation GlfwEvent

@synthesize timestamp = _timestamp, deltaX =_deltaX, deltaY = _deltaY;
@synthesize type = _type;
@synthesize mouseLoaction = _mouseLocation;
@synthesize window = _window;
@synthesize modifierFlags = _modifierFlags, scanCode = _scanCode, key = _key, characterModifiers = _characterModifiers, mouseButton = _mouseButton, mouseModifiers = _mouseModifiers;
@synthesize paths = _paths;
@synthesize size = _size;
@synthesize pos = _pos;

+ (instancetype)mouseEventWithType:(GlfwEventType)type timestamp:(double)timestamp window:(GlfwRawWindow *)window location:(of_point_t)location button:(int)mouseButton modifiers:(int)mouseButtonModifiers deltaX:(double)deltaX deltaY:(double)deltaY
{
    
    return [[[self alloc] initWithType:type location:location modifierFlags:0 timestamp:timestamp window:window character:0 characterModifiers:0 key:0 scanCode:0 mouseButton:mouseButton mouseModifiers:mouseButtonModifiers deltaX:deltaX deltaY:deltaY size:GlfwSizeZero() pos:GlfwPointZero() paths:nil] autorelease];
}

+ (instancetype)keyEventWithType:(GlfwEventType)type timestamp:(double)timestamp window:(GlfwRawWindow *)window scanCode:(int)scanCode modifiers:(int)mods
{
    return [[[self alloc] initWithType:type location:of_point(0, 0) modifierFlags:mods timestamp:timestamp window:window character:0 characterModifiers:0 key:0 scanCode:scanCode mouseButton:0 mouseModifiers:0 deltaX:0 deltaY:0 size:GlfwSizeZero() pos:GlfwPointZero() paths:nil] autorelease];
}

+ (instancetype)enterExitEventWithType:(GlfwEventType)type timestamp:(double)timestamp window:(GlfwRawWindow *)window
{
    return [[[self alloc] initWithType:type location:of_point(0, 0) modifierFlags:0 timestamp:timestamp window:window character:0 characterModifiers:0 key:0 scanCode:0 mouseButton:0 mouseModifiers:0 deltaX:0 deltaY:0 size:GlfwSizeZero() pos:GlfwPointZero() paths:nil] autorelease];
}

+ (instancetype)characterEventWithType:(GlfwEventType)type timestamp:(double)timestamp window:(GlfwRawWindow *)window character:(of_unichar_t)character characterModifiers:(int)mods
{
    return [[[self alloc] initWithType:type location:of_point(0, 0) modifierFlags:0 timestamp:timestamp window:window character:character characterModifiers:mods key:0 scanCode:0 mouseButton:0 mouseModifiers:0 deltaX:0 deltaY:0 size:GlfwSizeZero() pos:GlfwPointZero() paths:nil] autorelease];
}

+ (instancetype)otherEventWithType:(GlfwEventType)type timestamp:(double)timestamp window:(GlfwRawWindow *)window size:(GlfwSize)size pos:(GlfwPoint)pos paths:(OFArray<OFString *> *)paths
{
    return [[[self alloc] initWithType:type location:of_point(0, 0) modifierFlags:0 timestamp:timestamp window:window character:0 characterModifiers:0 key:0 scanCode:0 mouseButton:0 mouseModifiers:0 deltaX:0 deltaY:0 size:size pos:pos paths:paths] autorelease];
}

- (instancetype)initWithType:(GlfwEventType)type location:(of_point_t)location modifierFlags:(int)flags timestamp:(double)timestamp window:(GlfwRawWindow *)window character:(of_unichar_t)character characterModifiers:(int)mods key:(int)key scanCode:(int)scanCode mouseButton:(int)mouseButton mouseModifiers:(int)mouseButtonModifiers deltaX:(double)deltaX deltaY:(double)deltaY size:(GlfwSize)size pos:(GlfwPoint)pos paths:(OFArray<OFString *> *)paths
{
    self = [super init];
    
    _type = type;
    _mouseLocation = location;
    _modifierFlags = flags;
    _timestamp = timestamp;
    _window = [window retain];
    _character = character;
    _characterModifiers = mods;
    _key = key;
    _scanCode = scanCode;
    _mouseButton = mouseButton;
    _mouseModifiers = mouseButtonModifiers;
    _deltaX = deltaY;
    _deltaY = deltaY;
    _size = size;
    _pos = pos;
    _paths = [paths copy];
    
    return self;
}

- (bool)isMatchEventMask:(GlfwEventMask)mask {
    GlfwEventMask eventMask = GlfwEventMaskFromType(_type);
    
    return ((mask & eventMask) == eventMask);
}

- (of_comparison_result_t)compare:(id<OFComparing>)object {
    if (![(id<OFObject>)object isMemberOfClass:[self class]])
        @throw [OFInvalidArgumentException exception];
    
    GlfwEvent *other = (GlfwEvent *)object;
    
    if (self->_timestamp < other->_timestamp)
        return OF_ORDERED_ASCENDING;
    
    if (self->_timestamp > other->_timestamp)
        return OF_ORDERED_DESCENDING;
    
    return OF_ORDERED_SAME;
}

@end
