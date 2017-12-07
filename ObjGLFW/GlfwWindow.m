//
//  GlfwWindow.m
//  ObjGLFW
//
//  Created by Yury Vovk on 07.12.2017.
//  Copyright © 2017 GunGraveKoga. All rights reserved.
//

#import "GlfwWindow.h"
#import "GlfwEvent.h"

@implementation GlfwWindow

- (instancetype)initWithRect:(GlfwRect)windowRectangle title:(OFString *)windowTitle hints:(OFDictionary<OFNumber *,OFNumber *> *)windowHints
{
    self = [super initWithRect:windowRectangle title:windowTitle hints:windowHints];
    
    @try {
        _eventHandlers = [[OFSortedList alloc] init];
        _drawables = [[OFSortedList alloc] init];
    }
    @catch (id e) {
        [self release];
        
        @throw e;
    }
    
    return self;
}

- (void)bindDrawble:(id<GlfwDrawing>)drawble {
    @synchronized (self) {
        if (_windowHandle) {
            
            if (![_drawables containsObjectIdenticalTo:drawble]) {
                [_drawables insertObject:drawble];
            }
        }
    }
}

- (void)unbindDrawble:(id<GlfwDrawing>)drawble {
    @synchronized (self) {
        if (_windowHandle) {
            
            if ([_drawables containsObjectIdenticalTo:drawble]) {
                of_list_object_t *object = [_drawables firstListObject];
                
                while (object != NULL) {
                    if (object->object == drawble) {
                        [_drawables removeListObject:object];
                        
                        break;
                    }
                    
                    object = object->next;
                }
            }
        }
    }
}

- (void)bindEventHandler:(id<GlfwEventHandling>)eventHndler {
    @synchronized (self) {
        if (_windowHandle) {
            if (_eventHandlers == nil)
                _eventHandlers = [[OFSortedList alloc] init];
            
            if (![_eventHandlers containsObjectIdenticalTo:eventHndler]) {
                [_eventHandlers insertObject:eventHndler];
            }
        }
    }
}

- (void)unbindEventHandler:(id<GlfwEventHandling>)eventHndler {
    @synchronized (self) {
        if (_windowHandle) {
            
            if ([_eventHandlers containsObjectIdenticalTo:eventHndler]) {
                of_list_object_t *object = [_eventHandlers firstListObject];
                
                while (object != NULL) {
                    if (object->object == eventHndler) {
                        [_eventHandlers removeListObject:object];
                        
                        break;
                    }
                    
                    object = object->next;
                }
            }
        }
    }
}

- (void)draw {
    @synchronized (self) {
        if (_windowHandle) {
            
            for (id<GlfwDrawing> drawble in _drawables) {
                void *pool = objc_autoreleasePoolPush();
                
                [drawble draw];
                
                objc_autoreleasePoolPop(pool);
            }
        }
    }
}

- (void)sendEvent:(GlfwEvent *)event {
    
}

- (void)dealloc {
    [_eventHandlers removeAllObjects];
    [_eventHandlers release];
    [_drawables removeAllObjects];
    [_drawables release];
    
    [super dealloc];
}

@end
