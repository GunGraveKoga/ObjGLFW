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

OF_ASSUME_NONNULL_BEGIN

@protocol GlfwDrawing <OFObject, OFComparing>

@required
- (void)drawInWindow:(OF_KINDOF(GlfwWindow) *)window;

@end

OF_ASSUME_NONNULL_END
