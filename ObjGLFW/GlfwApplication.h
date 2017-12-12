//
//  GlfwApplication.h
//  ObjGLFW
//
//  Created by Yury Vovk on 05.12.2017.
//  Copyright © 2017 GunGraveKoga. All rights reserved.
//

#import <ObjFW/ObjFW.h>

OF_ASSUME_NONNULL_BEGIN

#define GLFW_APPLICATION_DELEGATE(cls)                    \
    int                                \
    main(int argc, char *argv[])                    \
    {                                \
        return glfw_application_main(&argc, &argv,        \
        (cls *)[[cls alloc] init]);                \
    }

#ifdef OF_HAVE_PLEDGE
# define OF_HAVE_SANDBOX
#endif

@class GlfwWindowManager;

@interface GlfwApplication : OFApplication
{
    GlfwWindowManager *_windowManager;
}

#ifdef OF_HAVE_CLASS_PROPERTIES
@property (class, atomic) int refreshRate;
#endif

+ (void)setRefreshRate:(int)refreshRate;
+ (int)refreshRate;

@end

#ifdef __cplusplus
extern "C" {
#endif
    extern int glfw_application_main(int *_Nonnull,
                                   char *_Nonnull *_Nonnull[_Nonnull], id <OFApplicationDelegate>);
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END
