//
//  GFGeometry.h
//  ObjGLFW
//
//  Created by Юрий Вовк on 06.12.2017.
//  Copyright © 2017 GunGraveKoga. All rights reserved.
//

#import <ObjFW/OFObject.h>

typedef struct _GFPoint {
    int x;
    int y;
} GFPoint;

typedef struct _GFSize {
    int width;
    int height;
} GFSize;

typedef struct _GFRect {
    GFPoint origin;
    GFSize size;
} GFRect;

OF_INLINE GFPoint GFPointNew(int x, int y) {
    GFPoint point = {x, y};
    
    return point;
}

OF_INLINE GFSize GFSizeNew(int width, int height) {
    GFSize size = {width, height};
    
    return size;
}

OF_INLINE GFRect GFRectNew(int x, int y, int width, int height) {
    GFRect rect;
    rect.origin = GFPointNew(x, y);
    rect.size = GFSizeNew(width, height);
    
    return rect;
}
