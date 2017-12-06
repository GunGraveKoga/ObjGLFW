//
//  GFEventHandler.h
//  ObjGLFW
//
//  Created by Юрий Вовк on 06.12.2017.
//  Copyright © 2017 GunGraveKoga. All rights reserved.
//

#import <ObjFW/ObjFW.h>

@class GFWindow;
@class GFEvent;

@interface GFEventHandler : OFObject
{
    OFSortedList OF_GENERIC(GFEvent *) *_eventsQueue;
    OFMutableSet OF_GENERIC(GFWindow *) *_windowsList;
}

- (OFArray OF_GENERIC(GFWindow *) *)handledWindows;
- (void)attachWindow:(GFWindow *)window;
- (void)detachWindow:(GFWindow *)window;
- (OFSortedList OF_GENERIC(GFEvent *) *)pollEvents;
- (void)drainEvents;

@end
