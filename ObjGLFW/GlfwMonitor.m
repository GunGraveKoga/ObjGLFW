//
//  GlfwMonitor.m
//  ObjGLFW
//
//  Created by Yury Vovk on 11.12.2017.
//  Copyright © 2017 GunGraveKoga. All rights reserved.
//

#import "GlfwMonitor.h"

static OFMapTable *_monitors = nil;

static void * _Nullable _windowRetain(void * _Nullable object) {
    return [(__bridge id)object copy];
}

static void _windowRelease(void * _Nullable object) {
    [(__bridge id)object release];
}

static uint32_t _windowHash(void * _Nullable object) {
    return [(__bridge id)object hash];
}

static bool _windowIsEqual(void * _Nullable left, void * _Nullable right) {
    return [(__bridge id)left isEqual:(__bridge id)right];
}

static of_map_table_functions_t _objectMapFunctions = {
    .retain = &_windowRetain,
    .release = &_windowRelease,
    .hash = &_windowHash,
    .equal = &_windowIsEqual
};

static of_map_table_functions_t _keyMapFunctions = {
    .retain = NULL,
    .release = NULL,
    .hash = NULL,
    .equal = NULL,
};

@interface GlfwMonitor ()
- (instancetype)glfw_initWithHandle:(GLFWmonitor *)monitorHandle OF_METHOD_FAMILY(init);
+ (instancetype)glfw_findMonitor:(GLFWmonitor *)monitorHandle;
@end

static void _globalMonitorCallback(GLFWmonitor *monitor, int isConnected) {
    @synchronized(_monitors) {
        if (isConnected == GLFW_CONNECTED) {
            GlfwMonitor *_monitor = [[GlfwMonitor alloc] glfw_initWithHandle:monitor];
            
            [_monitors setObject:_monitor forKey:monitor];
        }
        else {
            [_monitors removeObjectForKey:monitor];
        }
    }
}

@implementation GlfwMonitor

@synthesize name = _name;
@synthesize monitorHandle = _monitor;

+ (void)initialize {
    if (self == [GlfwMonitor class]) {
        _monitors = [[OFMapTable alloc] initWithKeyFunctions:_keyMapFunctions objectFunctions:_objectMapFunctions];
        
        int count = 0;
        GLFWmonitor **monitors = glfwGetMonitors(&count);
        
        for (int i = 0; i < count; i++) {
            GlfwMonitor *monitor = [[GlfwMonitor alloc] glfw_initWithHandle:monitors[i]];
            
            [_monitors setObject:monitor forKey:monitors[i]];
            
            [monitor release];
        }
        
        glfwSetMonitorCallback(&_globalMonitorCallback);
    }
}

+ (instancetype)primaryMonitor {
    @synchronized(_monitors) {
        GLFWmonitor *monitor = glfwGetPrimaryMonitor();
        
        GlfwMonitor *monitorObject = [_monitors objectForKey:monitor];
        
        if (monitorObject == nil) {
            monitorObject = [[GlfwMonitor alloc] glfw_initWithHandle:monitor];
            
            [_monitors setObject:monitorObject forKey:monitor];
            
            [monitorObject release];
        }
        
        return monitorObject;
    }
}

+ (OFArray<GlfwMonitor *> *)connectedMonitors {
    @synchronized(_monitors) {
        OFMapTableEnumerator *objectsEnumirator = [_monitors objectEnumerator];
        
        OFMutableArray *monitors = [OFMutableArray arrayWithCapacity:[_monitors count]];
        
        GlfwMonitor *monitor;
        void **objectPtr;
        
        while ((objectPtr = [objectsEnumirator nextObject]) != NULL) {
            monitor = (GlfwMonitor *)(*objectPtr);
            
            [monitors addObject:monitor];
        }
        
        [monitors makeImmutable];
        
        return monitors;
    }
}

+ (instancetype)glfw_findMonitor:(GLFWmonitor *)monitorHandle {
    @synchronized(_monitors) {
        GLFWmonitor *monitor = glfwGetPrimaryMonitor();
        
        GlfwMonitor *monitorObject = [_monitors objectForKey:monitor];
        
        if (monitorObject == nil) {
            monitorObject = [[GlfwMonitor alloc] glfw_initWithHandle:monitor];
            
            [_monitors setObject:monitorObject forKey:monitor];
            
            [monitorObject release];
        }
        
        return monitorObject;
    }
}

- (instancetype)glfw_initWithHandle:(GLFWmonitor *)monitorHandle {
    self = [super init];
    
    _monitor = monitorHandle;
    _name = [[OFString alloc] initWithUTF8StringNoCopy:(char *)glfwGetMonitorName(monitorHandle) freeWhenDone:false];
    
    return self;
}

- (GlfwPoint)position {
    int x, y;
    
    glfwGetMonitorPos(_monitor, &x, &y);
    
    return GlfwPointNew(x, y);
}

- (GlfwSize)physicalSize {
    int width, height;
    
    glfwGetMonitorPhysicalSize(_monitor, &width, &height);
    
    return GlfwSizeNew(width, height);
}

- (const GLFWvidmode *)videoMode {
    return glfwGetVideoMode(_monitor);
}

- (OFData *)videoModes {
    int count = 0;
    const GLFWvidmode *modes = glfwGetVideoModes(_monitor, &count);
    
    OFData *vmodes = [OFData dataWithItemsNoCopy:modes itemSize:sizeof(GLFWvidmode *) count:count freeWhenDone:false];
    
    return vmodes;
}

- (GLFWgammaramp *)gammaRamp {
    return (GLFWgammaramp *)glfwGetGammaRamp(_monitor);
}

- (void)setGammaRamp:(GLFWgammaramp *)gammaRamp {
    glfwSetGammaRamp(_monitor, gammaRamp);
}

- (void)setGamma:(float)gammaValue {
    glfwSetGamma(_monitor, gammaValue);
}


- (bool)isEqual:(id)object {
    if (![(id<OFObject>)object isMemberOfClass:[GlfwMonitor class]])
        return false;
    
    GlfwMonitor *other = (GlfwMonitor *)object;
    
    return self->_monitor == other->_monitor;
}

- (void)dealloc {
    [_name release];
    
    [super dealloc];
}

@end
