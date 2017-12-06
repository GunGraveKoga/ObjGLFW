//
//  GFApplication.m
//  ObjGLFW
//
//  Created by Yury Vovk on 05.12.2017.
//  Copyright © 2017 GunGraveKoga. All rights reserved.
//

#import "GFApplication.h"
#import "GFEventHandler.h"
#import "GFWindow.h"
#import "GFEvent.h"

#if defined(OF_WINDOWS)
# include <windows.h>

extern int _CRT_glob;
extern void __wgetmainargs(int *, wchar_t ***, wchar_t ***, int, int *);
#endif

#include <GLFW/glfw3.h>
#include "sokol_time.h"

@interface OFApplication ()
- (instancetype)of_init OF_METHOD_FAMILY(init);
- (void)of_setArgumentCount: (int *)argc
          andArgumentValues: (char **[])argv;
#ifdef OF_WINDOWS
- (void)of_setArgumentCount: (int)argc
      andWideArgumentValues: (wchar_t *[])argv;
#endif
@end

@interface GFApplication ()
- (void)glfw_run;
@end

@interface OFRunLoop ()
+ (void)of_setMainRunLoop: (OFRunLoop *)runLoop;
@end

#ifdef OF_HAVE_THREADS
@interface OFThread ()
+ (void)of_createMainThread;
@end
#endif

static GFApplication *GFApp = nil;

int
glfw_application_main(int *argc, char **argv[],
                    id <OFApplicationDelegate> delegate) {
    
    stm_setup();
    glfwInit();
    
#ifdef OF_WINDOWS
    wchar_t **wargv, **wenvp;
    int wargc, si = 0;
#endif
    
    [[OFLocalization alloc] init];
    
    GFApp = [[GFApplication alloc] of_init];
    
    [GFApp of_setArgumentCount: argc
             andArgumentValues: argv];
    
#ifdef OF_WINDOWS
    __wgetmainargs(&wargc, &wargv, &wenvp, _CRT_glob, &si);
    [GFApp of_setArgumentCount: wargc
         andWideArgumentValues: wargv];
#endif
    
    [GFApp setDelegate: delegate];
    
    [GFApp glfw_run];
    
    [delegate release];
    
    return 0;
}

@implementation GFApplication

+ (void)initialize {
    if (self == [GFApplication class]) {
        [OFApplication replaceClassMethod:@selector(sharedApplication) withMethodFromClass:self];
        [OFApplication replaceClassMethod:@selector(programName) withMethodFromClass:self];
        [OFApplication replaceClassMethod:@selector(arguments) withMethodFromClass:self];
#ifdef OF_HAVE_SANDBOX
        [OFApplication replaceClassMethod:@selector(activateSandbox:) withMethodFromClass:self];
#endif
    }
}

+ (OFApplication *)sharedApplication {
    return GFApp;
}

+ (OFString *)programName {
    return [GFApp programName];
}

+ (OFArray<OFString *> *)arguments {
    return [GFApp arguments];
}

+ (OFDictionary<OFString *,OFString *> *)environment {
    return [GFApp environment];
}

#ifdef OF_HAVE_SANDBOX
+ (void)activateSandbox:(OFSandbox *)sandbox
{
    [GFApp activateSandbox: sandbox];
}
#endif

- (instancetype)of_init {
    self = [super of_init];
    
    _eventHandler = [[GFEventHandler alloc] init];
    
    return self;
}

- (void)glfw_run {
    void *pool = objc_autoreleasePoolPush();
    OFRunLoop *runLoop;
    
#ifdef OF_HAVE_THREADS
    [OFThread of_createMainThread];
    runLoop = [OFRunLoop currentRunLoop];
#else
    runLoop = [[[OFRunLoop alloc] init] autorelease];
#endif
    
    [OFRunLoop of_setMainRunLoop: runLoop];
    
    objc_autoreleasePoolPop(pool);
    
    pool = objc_autoreleasePoolPush();
    [_delegate applicationDidFinishLaunching];
    objc_autoreleasePoolPop(pool);
    
    _isActive = true;
    
    GLFWmonitor *mainMonitor = glfwGetPrimaryMonitor();
    const GLFWvidmode *vmode = glfwGetVideoMode(mainMonitor);
    
    double expectedLooptTime = (1000 / vmode->refreshRate); //expected loop time in ms
    uint64_t currentTime = 0;
    
    while (_isActive) {
        pool = objc_autoreleasePoolPush();
        uint64_t elapsedTime = stm_laptime(&currentTime);
        
        glfwPollEvents();
        
        /*
         * processing events
         */
        
        
        /*
         * draw
         */
        
        elapsedTime = stm_laptime(&currentTime);
        
        double runloopTimeInterval = expectedLooptTime - stm_ms(elapsedTime);
        
        [runLoop runUntilDate:[OFDate dateWithTimeIntervalSinceNow:runloopTimeInterval * 1000]];
        
        objc_autoreleasePoolPop(pool);

        
    }
}

@end