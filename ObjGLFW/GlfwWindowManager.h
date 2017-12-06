//
//  GlfwWindowManager.h
//  ObjGLFW
//
//  Created by Yury Vovk on 06.12.2017.
//  Copyright © 2017 GunGraveKoga. All rights reserved.
//

#import <ObjFW/ObjFW.h>

@class GlfwWindow;
@class GlfwEvent;

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

- (void)attachWindow:(GlfwWindow *)window;
- (void)detachWindow:(GlfwWindow *)window;

@end
