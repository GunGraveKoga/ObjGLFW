//
//  main.m
//  nuklear
//
//  Created by Yury Vovk on 12.12.2017.
//  Copyright © 2017 GunGraveKoga. All rights reserved.
//

#define GLFW_INCLUDE_NONE
#import "ObjGLFW.h"
#include "flextGL.h"

#import <ObjFW/ObjFW.h>

#define NK_INCLUDE_FIXED_TYPES
#define NK_INCLUDE_STANDARD_IO
#define NK_INCLUDE_STANDARD_VARARGS
#define NK_INCLUDE_DEFAULT_ALLOCATOR
#define NK_INCLUDE_VERTEX_BUFFER_OUTPUT
#define NK_INCLUDE_FONT_BAKING
#define NK_INCLUDE_DEFAULT_FONT
#define NK_IMPLEMENTATION
#include "nuklear.h"

@interface AppDelegate : OFObject <OFApplicationDelegate, OFCopying, GlfwDrawing, GlfwEventHandling>
{
    struct nk_context ctx;
    struct nk_glfw_device ogl;
}

@end

GLFW_APPLICATION_DELEGATE(AppDelegate)

@implementation AppDelegate

#ifdef __APPLE__
#define NK_SHADER_VERSION "#version 150\n"
#else
#define NK_SHADER_VERSION "#version 300 es\n"
#endif

- (void)applicationDidFinishLaunching {
    GlfwWindow *window = [GlfwWindow windowWithRect:GlfwRectNew(0, 0, 640, 480) title:@"Demo" hints:
  @{
    @(GLFW_CONTEXT_VERSION_MAJOR): @(3),
    @(GLFW_CONTEXT_VERSION_MINOR): @(3),
    @(GLFW_OPENGL_PROFILE): @(GLFW_OPENGL_CORE_PROFILE)
#ifdef __APPLE__
    , @(GLFW_OPENGL_FORWARD_COMPAT): @(GL_TRUE)
#endif
    }];
    
    [window bindDrawble:self];
    [window bindEventHandler:self];
    
    [window makeContextCurrent];
    
    flextInit([window windowHandle]);
    
    nk_init_default(&ctx, 0);
    
    
    [window doneContext];
    
    [[GlfwWindowManager defaultManager] attachWindow:window];
}

- (id)copy {
    return self;
}

- (void)drawInWindow:(__kindof GlfwWindow *)window {
    
}

- (GlfwEventMask)handledEventsMask {
    return GlfwAnyEventMask;
}

- (void)handleEvent:(__kindof GlfwEvent *)event fromWindow:(__kindof GlfwWindow *)window {
    
}

@end
