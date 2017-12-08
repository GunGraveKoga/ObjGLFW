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

OF_INLINE GlfwPoint GlfwPointZero(void) {
    return GlfwPointNew(0, 0);
}

OF_INLINE GlfwPoint GlfwPointNull(void) {
    return (GlfwPoint){NAN,NAN};
}

OF_INLINE bool GlfwPointIsNull(GlfwPoint point) {
    return (isnan(point.x) || isnan(point.y));
}

OF_INLINE GlfwSize GlfwSizeNew(int width, int height) {
    GlfwSize size = {width, height};
    
    return size;
}

OF_INLINE GlfwSize GlfwSizeZero(void) {
    return GlfwSizeNew(0, 0);
}

OF_INLINE GlfwSize GlfwSizeNull(void) {
    return (GlfwSize){NAN, NAN};
}

OF_INLINE bool GlfwSizeIsNull(GlfwSize size) {
    return (isnan(size.width) || isnan(size.height));
}

OF_INLINE GlfwRect GlfwRectNew(int x, int y, int width, int height) {
    GlfwRect rect;
    rect.origin = GlfwPointNew(x, y);
    rect.size = GlfwSizeNew(width, height);
    
    return rect;
}

OF_INLINE GlfwRect GlfwRectZero(void) {
    return GlfwRectNew(0, 0, 0, 0);
}

OF_INLINE GlfwRect GlfwNullRect(void) {
    return (GlfwRect){{NAN,NAN},{NAN,NAN}};
}

OF_INLINE bool GlfwrectIsNull(GlfwRect rect) {
    return (GlfwPointIsNull(rect.origin) || GlfwSizeIsNull(rect.size));
}

OF_INLINE of_point_t of_point_zero(void) {
    return of_point(0, 0);
}

OF_INLINE of_point_t of_point_null(void) {
    return (of_point_t){NAN,NAN};
}

OF_INLINE bool of_point_is_null(of_point_t point) {
    return (isnan(point.x) || isnan(point.y));
}

OF_INLINE of_dimension_t of_dimension_zero(void) {
    return of_dimension(0.0, 0.0);
}

OF_INLINE of_dimension_t of_dimension_null(void) {
    return (of_dimension_t){NAN,NAN};
}

OF_INLINE bool of_dimension_is_null(of_dimension_t dimension) {
    return (isnan(dimension.width) || isnan(dimension.width));
}

OF_INLINE of_rectangle_t of_rectangle_zero(void) {
    return of_rectangle(0.0, 0.0, 0.0, 0.0);
}

OF_INLINE bool of_rectangle_is_null(of_rectangle_t rect) {
    return (of_point_is_null(rect.origin) || of_dimension_is_null(rect.size));
}
