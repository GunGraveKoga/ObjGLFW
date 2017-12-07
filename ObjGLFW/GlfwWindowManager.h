//
//  GlfwWindowManager.h
//  ObjGLFW
//
//  Created by Yury Vovk on 06.12.2017.
//  Copyright © 2017 GunGraveKoga. All rights reserved.
//

#import <ObjFW/ObjFW.h>

#include <GLFW/glfw3.h>

@class GlfwRawWindow;
@class GlfwEvent;

OF_ASSUME_NONNULL_BEGIN

@interface GlfwWindowManager : OFObject
{
    OFMapTable *_managedWindows;
    OFSortedList OF_GENERIC(GlfwEvent *) *_eventsQueue;
#if defined(OF_HAVE_THREADS)
    OFMutex *_lock;
#endif
}

- (instancetype)init OF_UNAVAILABLE;

+ (instancetype)defaultManager;

- (void)attachWindow:(GlfwRawWindow *)window;
- (void)detachWindow:(GlfwRawWindow *)window;

- (void)fetchEvent:(GlfwEvent *)event;
- (GlfwRawWindow * _Nullable)findWindow:(GLFWwindow *)windowHandle;
- (void)dispatchEvents;
- (void)drainEvents;
- (void)drawAllWindows;

@end

OF_ASSUME_NONNULL_END
