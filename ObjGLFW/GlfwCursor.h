//
//  GlfwCursor.h
//  ObjGLFW
//
//  Created by Yury Vovk on 12.12.2017.
//  Copyright © 2017 GunGraveKoga. All rights reserved.
//

#import <ObjFW/ObjFW.h>
#import "GlfwGeometry.h"

#include <GLFW/glfw3.h>

OF_ASSUME_NONNULL_BEGIN

@interface GlfwCursor : OFObject <OFCopying>
{
    GLFWcursor *_cursorHandle;
}

@property (atomic, readonly) GLFWcursor *cursorHandle;

- (instancetype)init OF_UNAVAILABLE;

- (instancetype)initWithImage:(GLFWimage)image hotspot:(GlfwPoint)hotspotPoint;

@end

OF_ASSUME_NONNULL_END
