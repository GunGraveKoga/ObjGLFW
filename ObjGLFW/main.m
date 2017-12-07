//
//  main.m
//  ObjGLFW
//
//  Created by Yury Vovk on 05.12.2017.
//  Copyright © 2017 GunGraveKoga. All rights reserved.
//

#import <ObjFW/ObjFW.h>
#import "GlfwGeometry.h"
#import "GlfwApplication.h"
#import "GlfwWindowManager.h"
#import "GlfwEventHandling.h"
#import "GlfwDrawing.h"
#import "GlfwWindow.h"
#import "GlfwEvent.h"

@interface AppDelegate: OFObject <OFApplicationDelegate, GlfwDrawing, GlfwEventHandling>

@end

GLFW_APPLICATION_DELEGATE(AppDelegate);

@implementation AppDelegate

- (void)applicationDidFinishLaunching {
    
    GlfwWindow *newWindow = [[[GlfwWindow alloc] initWithRect:GlfwRectNew(0, 0, 640, 480) title:@"Test" hints:@{}] autorelease];
    
    [newWindow bindDrawble:self];
    [newWindow bindEventHandler:self];
    
    [[GlfwWindowManager defaultManager] attachWindow:newWindow];
}

- (void)drawInWindow:(GlfwWindow *)window {
    of_log(@"Drawing in %@", window);
}

- (GlfwEventMask)handledEventsMask {
    return GlfwAnyEventMask;
}

- (void)handleEvent:(GlfwEvent *)event fromWindow:(GlfwWindow *)window {
    of_log(@"Event %@ for window %@", event, window);
}

- (of_comparison_result_t)compare:(id<OFComparing>)object {
    return OF_ORDERED_SAME;
}

@end
