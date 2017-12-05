//
//  GFApplication.m
//  ObjGLFW
//
//  Created by Yury Vovk on 05.12.2017.
//  Copyright © 2017 GunGraveKoga. All rights reserved.
//

#import "GFApplication.h"

#if defined(OF_WINDOWS)
# include <windows.h>

extern int _CRT_glob;
extern void __wgetmainargs(int *, wchar_t ***, wchar_t ***, int, int *);
#endif

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

- (void)glfw_run {
    
}

@end
