//
//  GlfwEvent.m
//  ObjGLFW
//
//  Created by Юрий Вовк on 05.12.2017.
//  Copyright © 2017 GunGraveKoga. All rights reserved.
//

#import "GlfwRawWindow.h"
#import "GlfwEvent.h"

OF_INLINE of_rectangle_t GlfwRectToOFRect(GlfwRect rect) {
    return of_rectangle((float)(rect.origin.x + .0f), (float)(rect.origin.y + .0f), (float)(rect.size.width + .0f), (float)(rect.size.height + .0f));
}

OF_INLINE bool OFRectangleContainPoint(of_rectangle_t rect, of_point_t point) {
    return ((point.x >= rect.origin.x) &&
            (point.y >= rect.origin.y) &&
            (point.x <= (rect.origin.x + rect.size.width)) &&
            (point.y <= (rect.origin.y + rect.size.height)));
}

@implementation GlfwEvent

@synthesize type = _type;
@synthesize window = _window;
@synthesize timestamp = _timestamp;

@dynamic glfwKey, systemScancode, modifiersFlags, glfwMouseButton;
@dynamic deltaX, deltaY;
@dynamic location, locationInWindow, currentLocation, currentLocationInWindow;
@dynamic character;
@dynamic windowPosition;
@dynamic windowSize, windowContentSize;
@dynamic droppedFilesPaths;

- (instancetype)initWithType:(GlfwEventType)eventType
                   timestamp:(double)timestamp
                    window:(GlfwRawWindow *)window
{
    self = [super init];
    
    _type = eventType;
    _timestamp = timestamp;
    _window = [window retain];
    
    memset(&_event_data, 0, sizeof(union _event_data_u));
    
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

- (bool)isEqual:(id)object {
    if ([(id<OFObject>)object isMemberOfClass:[self class]]) {
        return (self->_type == ((GlfwEvent *)object)->_type);
    }
    
    return false;
}

- (OFString *)description {
    
    static const char *_typeNames[] = {
        "GlfwLeftMouseDown",
        "GlfwLeftMouseUp",
        "GlfwRightMouseDown",
        "GlfwRightMouseUp",
        "GlfwMouseMiddleDown",
        "GlfwMouseMiddleUp",
        "GlfwMouseOtherDown",
        "GlfwMouseOtherUp",
        "GlfwMouseMoved",
        "GlfwMouseEntered",
        "GlfwMouseExited",
        "GlfwKeyDown",
        "GlfwKeyUp",
        "GlfwScrollWheel",
        "GlfwWindowMoved",
        "GlfwWindowResized",
        "GlfwWindowFramebuferResized",
        "GlfwWindowShouldRefresh",
        "GlfwWindowShouldClose",
        "GlfwWindowFocused",
        "GlfwWindowIconified",
        "GlfwCharacter",
        "GlfwModifiedCharacter",
        "GlfwFilesDrop"
    };
    
    return [OFString stringWithFormat:@"<%@::%s>", [super className], _typeNames[_type]];
}

- (void)dealloc {
    [_window release];
    
    [super dealloc];
}

@end

@implementation GlfwKeyEvent

+ (instancetype)keyEventWithType:(GlfwEventType)eventType timestamp:(double)timestamp window:(GlfwRawWindow *)window glfwKey:(int)glfwKey modifiers:(int)modifiersFlags systemScancode:(int)systemScancode
{
    return [[[self alloc] initWithType:eventType timestamp:timestamp window:window glfwKey:glfwKey modifiers:modifiersFlags systemScancode:systemScancode] autorelease];
}

- (instancetype)initWithType:(GlfwEventType)eventType timestamp:(double)timestamp window:(GlfwRawWindow *)window glfwKey:(int)glfwKey modifiers:(int)modifiersFlags systemScancode:(int)systemScancode
{
    self = [super initWithType:eventType timestamp:timestamp window:window];
    
    @try {
        GlfwEventMask typeMask = GlfwEventMaskFromType(eventType);
        
        if ((GlfwKeyEventMask & typeMask) != typeMask)
            @throw [OFInvalidArgumentException exception];
        
        _event_data.key.glfwKey = glfwKey;
        _event_data.key.scancode = systemScancode;
        _event_data.key.modifiers = modifiersFlags;
    }
    @catch (id e) {
        [self release];
        
        @throw e;
    }
    
    return self;
}

- (int)glfwKey {
    return _event_data.key.glfwKey;
}

- (int)systemScancode {
    return _event_data.key.scancode;
}

- (int)modifiersFlags {
    return _event_data.key.modifiers;
}

- (bool)isEqual:(id)object {
    if ([super isEqual:object]) {
        
        GlfwKeyEvent *other = (GlfwKeyEvent *)object;
        return ((memcmp(&(self->_event_data.key), &(other->_event_data.key), sizeof(_event_data.key))) == 0);
    }
    
    return false;
}

@end

@implementation GlfwMouseEvent

+ (instancetype)enterExitEventWithType:(GlfwEventType)eventType timestamp:(double)timestamp window:(GlfwRawWindow *)window
{
    return [[[self alloc] initWithType:eventType timestamp:timestamp window:window mouseButton:NAN modifiersFlags:NAN location:of_point_null() deltaX:NAN deltaY:NAN] autorelease];
}

+ (instancetype)mouseMoveEventWithTimestamp:(double)timestamp window:(GlfwRawWindow *)window loaction:(of_point_t)location
{
    return [[[self alloc] initWithType:GlfwMouseMoved timestamp:timestamp window:window mouseButton:0 modifiersFlags:0 location:location deltaX:NAN deltaY:NAN] autorelease];
}

+ (instancetype)scrollWheelEventWithTimestamp:(double)timestamp window:(GlfwRawWindow *)window deltaX:(double)deltaX deltaY:(double)deltaY
{
    return [[[self alloc] initWithType:GlfwScrollWheel timestamp:timestamp window:window mouseButton:NAN modifiersFlags:NAN location:of_point_null() deltaX:deltaX deltaY:deltaY] autorelease];
}

+ (instancetype)mouseButtonEventWithType:(GlfwEventType)eventType timestamp:(double)timestamp window:(GlfwRawWindow *)window mouseButton:(int)mouseButton modifiersFlags:(int)modifiersFlags
{
    return [[[self alloc] initWithType:eventType timestamp:timestamp window:window mouseButton:mouseButton modifiersFlags:modifiersFlags location:of_point_null() deltaX:NAN deltaY:NAN] autorelease];
}

- (instancetype)initWithType:(GlfwEventType)eventType timestamp:(double)timestamp window:(GlfwRawWindow *)window mouseButton:(int)mouseButton modifiersFlags:(int)modifiersFlags location:(of_point_t)location deltaX:(double)deltaX deltaY:(double)delraY
{
    self = [super initWithType:eventType timestamp:timestamp window:window];
    
    @try {
        GlfwEventMask typeMask = GlfwEventMaskFromType(eventType);
        
        if ((GlfwMouseEventMask & typeMask) != typeMask)
            @throw [OFInvalidArgumentException exception];
        
        _event_data.mouse.button = mouseButton;
        _event_data.mouse.modifiers = modifiersFlags;
        _event_data.mouse.pos = location;
        _event_data.mouse.deltaX = deltaX;
        _event_data.mouse.deltaY = delraY;
    }
    @catch (id e) {
        [self release];
        
        @throw e;
    }
    
    return self;
}

- (of_point_t)location {
    return _event_data.mouse.pos;
}

- (of_point_t)currentLocation {
    double x, y;
    
    glfwGetCursorPos([_window windowHandle], &x, &y);
    
    return of_point(x, y);
}

- (of_point_t)locationInWindow {
    GlfwRect windowRect = [_window frame];
    
    if (OFRectangleContainPoint(GlfwRectToOFRect(windowRect), _event_data.mouse.pos))
        return of_point((float)(_event_data.mouse.pos.x - windowRect.origin.x), (float)(_event_data.mouse.pos.y - windowRect.origin.y));
    
    return of_point_null();
}

- (of_point_t)currentLocationInWindow {
    GlfwRect windowRect = [_window frame];
    of_point_t currentLocation = [self currentLocation];
    
    if (OFRectangleContainPoint(GlfwRectToOFRect(windowRect), currentLocation))
        return of_point((float)(currentLocation.x - windowRect.origin.x), (float)(currentLocation.y - windowRect.origin.y));
    
    return of_point_null();
}

- (int)glfwMouseButton {
    return _event_data.mouse.button;
}

- (int)modifiersFlags {
    return _event_data.mouse.modifiers;
}

- (double)deltaX {
    return _event_data.mouse.deltaX;
}

- (double)deltaY {
    return _event_data.mouse.deltaY;
}

- (bool)isEqual:(id)object {
    if ([super isEqual:object]) {
        
        GlfwMouseEvent *other = (GlfwMouseEvent *)object;
        return ((memcmp(&(self->_event_data.mouse), &(other->_event_data.mouse), sizeof(_event_data.mouse))) == 0);
    }
    
    return false;
}

@end

@implementation GlfwCharacterEvent

+ (instancetype)characterEventWithTimestamp:(double)timestamp window:(GlfwRawWindow *)window character:(of_unichar_t)character modifiersFlags:(int)modifiersFlags
{
    return [[[self alloc] initWithType:GlfwModifiedCharacter timestamp:timestamp window:window character:character modifiersFlags:modifiersFlags] autorelease];
}

+ (instancetype)characterEventWithTimestamp:(double)timestamp window:(GlfwRawWindow *)window character:(of_unichar_t)character
{
    return [[[self alloc] initWithType:GlfwCharacter timestamp:timestamp window:window character:character modifiersFlags:NAN] autorelease];
}

- (instancetype)initWithType:(GlfwEventType)eventType timestamp:(double)timestamp window:(GlfwRawWindow *)window character:(of_unichar_t)character modifiersFlags:(int)modifiersFlags
{
    self = [super initWithType:eventType timestamp:timestamp window:window];
    
    @try {
        GlfwEventMask typeMask = GlfwEventMaskFromType(eventType);
        
        if ((GlfwCharacterEventMask & typeMask) != typeMask)
            @throw [OFInvalidArgumentException exception];
        
        _event_data.character.character = character;
        _event_data.character.modifiers = modifiersFlags;
    }
    @catch (id e) {
        [self release];
        
        @throw e;
    }
    
    return self;
}

- (of_unichar_t)character {
    return _event_data.character.character;
}

- (int)modifiersFlags {
    return _event_data.character.modifiers;
}

- (bool)isEqual:(id)object {
    if ([super isEqual:object]) {
        
        GlfwCharacterEvent *other = (GlfwCharacterEvent *)object;
        
        return ((memcmp(&(self->_event_data.character), &(other->_event_data.character), sizeof(_event_data.character))) == 0);
    }
    
    return false;
}

@end

@implementation GlfwWindowEvent

+ (instancetype)windowMovedEventWithTimestamp:(double)timestamp window:(GlfwRawWindow *)window windowPos:(GlfwPoint)newPos
{
    return [[[self alloc] initWithType:GlfwWindowMoved timestamp:timestamp window:window windowPos:newPos windowSize:GlfwSizeNull() contentSize:GlfwSizeNull()] autorelease];
}

+ (instancetype)windowResizedEventWithTimestamp:(double)timestamp window:(GlfwRawWindow *)window windowSize:(GlfwSize)newSize
{
    return [[[self alloc] initWithType:GlfwWindowResized timestamp:timestamp window:window windowPos:GlfwPointNull() windowSize:newSize contentSize:GlfwSizeNull()] autorelease];
}

+ (instancetype)windowFramebuferResizedEventWithTimestamp:(double)timestamp window:(GlfwRawWindow *)window contentSize:(GlfwSize)newContentSize
{
    return [[[self alloc] initWithType:GlfwWindowFramebuferResized timestamp:timestamp window:window windowPos:GlfwPointNull() windowSize:GlfwSizeNull() contentSize:newContentSize] autorelease];
}

+ (instancetype)otherWindowEventWithType:(GlfwEventType)eventType timestamp:(double)timestamp window:(GlfwRawWindow *)window
{
    return [[[self alloc] initWithType:eventType timestamp:timestamp window:window windowPos:GlfwPointNull() windowSize:GlfwSizeNull() contentSize:GlfwSizeNull()] autorelease];
}

- (instancetype)initWithType:(GlfwEventType)eventType timestamp:(double)timestamp window:(GlfwRawWindow *)window windowPos:(GlfwPoint)newPos windowSize:(GlfwSize)newSize contentSize:(GlfwSize)newContentSize
{
    self = [super initWithType:eventType timestamp:timestamp window:window];
    
    @try {
        GlfwEventMask typeMask = GlfwEventMaskFromType(eventType);
        
        if ((GlfwWindowEventMask & typeMask) != typeMask)
            @throw [OFInvalidArgumentException exception];
        
        _event_data.window.pos = newPos;
        _event_data.window.size = newSize;
        _event_data.window.contentSize = newContentSize;
    }
    @catch (id e) {
        [self release];
        
        @throw e;
    }
    
    return self;
}

- (GlfwPoint)windowPosition {
    return _event_data.window.pos;
}

- (GlfwSize)windowSize {
    return _event_data.window.size;
}

- (GlfwSize)windowContentSize {
    return _event_data.window.contentSize;
}

- (bool)isEqual:(id)object {
    if ([super isEqual:object]) {
        
        GlfwWindowEvent *other = (GlfwWindowEvent *)object;
        return ((memcmp(&(self->_event_data.window), &(other->_event_data.window), sizeof(_event_data.window))) == 0);
    }
    
    return false;
}

@end

@implementation GlfwFileDropEvent

+ (instancetype)fileDropEventWithTimestamp:(double)timestamp window:(GlfwRawWindow *)window droppedFiles:(OFArray<OFString *> *)filesPaths
{
    return [[[self alloc] initWithType:GlfwFilesDrop timestamp:timestamp window:window droppedFiles:filesPaths] autorelease];
}

- (instancetype)initWithType:(GlfwEventType)eventType timestamp:(double)timestamp window:(GlfwRawWindow *)window droppedFiles:(OFArray<OFString *> *)filesPaths
{
    self = [super initWithType:eventType timestamp:timestamp window:window];
    
    @try {
        if (eventType != GlfwFilesDrop)
            @throw [OFInvalidArgumentException exception];
        
        _filesPaths = [filesPaths copy];
    }
    @catch (id e) {
        [self release];
        
        @throw e;
    }
    
    return self;
}

- (bool)isEqual:(id)object {
    if ([super isEqual:object]) {
        
        GlfwFileDropEvent *other = (GlfwFileDropEvent *)object;
        return [self->_filesPaths isEqual:other->_filesPaths];
    }
    
    return false;
}

- (void)dealloc {
    [_filesPaths release];
    
    [super dealloc];
}

@end
