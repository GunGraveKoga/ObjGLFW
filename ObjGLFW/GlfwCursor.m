//
//  GlfwCursor.m
//  ObjGLFW
//
//  Created by Yury Vovk on 12.12.2017.
//  Copyright © 2017 GunGraveKoga. All rights reserved.
//

#import "GlfwCursor.h"

@implementation GlfwCursor

@synthesize cursorHandle = _cursorHandle;

- (instancetype)initWithImage:(GLFWimage)image hotspot:(GlfwPoint)hotspotPoint {
    self = [super init];
    
    @try {
        _cursorHandle = glfwCreateCursor(&image, hotspotPoint.x, hotspotPoint.y);
        
        if (_cursorHandle == NULL)
            @throw [OFInitializationFailedException exceptionWithClass:[self class]];
    }
    @catch (id e) {
        [self release];
        
        @throw e;
    }
    
    return self;
}

- (id)copy {
    return [self retain];
}

- (void)dealloc {
    if (_cursorHandle) {
        glfwDestroyCursor(_cursorHandle);
    }
    
    [super dealloc];
}

@end
