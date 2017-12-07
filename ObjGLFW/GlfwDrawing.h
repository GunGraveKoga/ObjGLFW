//
//  GlfwDrawing.h
//  ObjGLFW
//
//  Created by Юрий Вовк on 07.12.2017.
//  Copyright © 2017 GunGraveKoga. All rights reserved.
//

#import <ObjFW/OFObject.h>
#import "GlfwGeometry.h"

@class GlfwWindow;

@protocol GlfwDrawing <OFObject, OFComparing>

@required
- (void)drawInWindow:(GlfwWindow *)window;

@end
