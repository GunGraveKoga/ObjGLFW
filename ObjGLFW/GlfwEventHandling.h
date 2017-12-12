//
//  GlfwEventHandling.h
//  ObjGLFW
//
//  Created by Юрий Вовк on 07.12.2017.
//  Copyright © 2017 GunGraveKoga. All rights reserved.
//

#import <ObjFW/OFObject.h>
#import "GlfwEvent.h"

@class GlfwWindow;

@protocol GlfwEventHandling <OFObject, OFComparing>

@required
- (GlfwEventMask)handledEventsMask;
- (void)handleEvent:(OF_KINDOF(GlfwEvent) *)event fromWindow:(OF_KINDOF(GlfwWindow) *)window;

@end
