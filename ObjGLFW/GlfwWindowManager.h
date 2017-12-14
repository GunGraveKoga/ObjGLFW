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

@protocol GlfwWindow <OFObject>

@optional
- (void)prepareForEventsHandling;
- (void)endEventsHandling;

@end

@interface GlfwEventsQueue OF_GENERIC(ObjectType): OFSortedList

@end

@interface GlfwWindowManager : OFObject
{
    OFMapTable *_managedWindows;
    GlfwEventsQueue OF_GENERIC(GlfwEvent *) *_eventsQueue;
#if defined(OF_HAVE_THREADS)
    OFMutex *_lock;
#endif
}
#ifdef OF_HAVE_CLASS_PROPERTIES
@property (class, nonatomic, readonly, copy) GlfwWindowManager *defaultManager;
#endif

- (instancetype)init OF_UNAVAILABLE;

+ (instancetype)defaultManager;

- (void)attachWindow:(OF_KINDOF(GlfwRawWindow) *)window;
- (void)detachWindow:(OF_KINDOF(GlfwRawWindow) *)window;

- (void)fetchEvent:(OF_KINDOF(GlfwEvent) *)event;
- (OF_KINDOF(GlfwRawWindow) * _Nullable)findWindow:(GLFWwindow *)windowHandle;
- (void)dispatchEvents;
- (void)drainEvents;
- (void)drawAllWindows;

@end

OF_ASSUME_NONNULL_END
