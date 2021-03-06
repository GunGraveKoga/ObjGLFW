//
//  GlfwMonitor.h
//  ObjGLFW
//
//  Created by Yury Vovk on 11.12.2017.
//  Copyright © 2017 GunGraveKoga. All rights reserved.
//

#import <ObjFW/ObjFW.h>
#import "GlfwGeometry.h"

#include <GLFW/glfw3.h>

OF_ASSUME_NONNULL_BEGIN

@interface GlfwMonitor : OFObject
{
    GLFWmonitor *_monitor;
    OFString *_name;
}
#ifdef OF_HAVE_CLASS_PROPERTIES
@property (class, nonatomic, copy, readonly) GlfwMonitor *primaryMonitor;
@property (class, nonatomic, copy, readonly) OFArray OF_GENERIC(GlfwMonitor *) *connectedMonitors;
#endif

@property (nonatomic, assign, readonly) GLFWmonitor *monitorHandle;
@property (nonatomic, copy, readonly) OFString *name;
@property (nonatomic, assign, readonly) GlfwPoint position;
@property (nonatomic, assign, readonly) GlfwSize physicalSize;
@property (nonatomic, assign) GLFWgammaramp *gammaRamp;
@property (nonatomic, assign, readonly) const GLFWvidmode *videoMode;
@property (nonatomic, copy, readonly) OFData *videoModes;

+ (OFArray OF_GENERIC(GlfwMonitor *) *)connectedMonitors;
+ (instancetype)primaryMonitor;

- (instancetype)init OF_UNAVAILABLE;
- (void)setGamma:(float)gammaValue;

@end

OF_ASSUME_NONNULL_END
