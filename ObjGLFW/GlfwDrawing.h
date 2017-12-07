//
//  GlfwDrawing.h
//  ObjGLFW
//
//  Created by Юрий Вовк on 07.12.2017.
//  Copyright © 2017 GunGraveKoga. All rights reserved.
//

#import <ObjFW/OFObject.h>

@protocol GlfwDrawing <OFObject>

@required
- (void)draw;

@end
