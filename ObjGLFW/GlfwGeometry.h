//
//  GlfwGeometry.h
//  ObjGLFW
//
//  Created by Юрий Вовк on 06.12.2017.
//  Copyright © 2017 GunGraveKoga. All rights reserved.
//

#import <ObjFW/OFObject.h>

typedef struct _GlfwPoint {
    int x;
    int y;
} GlfwPoint;

typedef struct _GlfwSize {
    int width;
    int height;
} GlfwSize;

typedef struct _GlfwRect {
    GlfwPoint origin;
    GlfwSize size;
} GlfwRect;

OF_INLINE GlfwPoint GlfwPointNew(int x, int y) {
    GlfwPoint point = {x, y};
    
    return point;
}

OF_INLINE GlfwSize GlfwSizeNew(int width, int height) {
    GlfwSize size = {width, height};
    
    return size;
}

OF_INLINE GlfwRect GlfwRectNew(int x, int y, int width, int height) {
    GlfwRect rect;
    rect.origin = GlfwPointNew(x, y);
    rect.size = GlfwSizeNew(width, height);
    
    return rect;
}
