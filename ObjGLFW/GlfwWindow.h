//
//  GlfwWindow.h
//  ObjGLFW
//
//  Created by Yury Vovk on 07.12.2017.
//  Copyright © 2017 GunGraveKoga. All rights reserved.
//

#import "GlfwRawWindow.h"
#import "GlfwEventHandling.h"
#import "GlfwDrawing.h"

OF_ASSUME_NONNULL_BEGIN

@interface GlfwWindow : GlfwRawWindow
{
    OFSortedList OF_GENERIC(id<GlfwEventHandling>) *_eventHandlers;
    OFSortedList OF_GENERIC(id<GlfwDrawing>) *_drawables;
}

- (void)bindEventHandler:(id<GlfwEventHandling>)eventHndler;
- (void)unbindEventHandler:(id<GlfwEventHandling>)eventHndler;
- (void)bindDrawble:(id<GlfwDrawing>)drawble;
- (void)unbindDrawble:(id<GlfwDrawing>)drawble;

@end

OF_ASSUME_NONNULL_END
