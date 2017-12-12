#!/bin/sh

#  gen_flextgl.sh
#  ObjGLFW
#
#  Created by Yury Vovk on 12.12.2017.
#  Copyright © 2017 GunGraveKoga. All rights reserved.

python3 ${SOURCE_ROOT}/flextgl/flextGLgen.py -T glfw3 -D ${SOURCE_ROOT}/ObjGLFW ${SOURCE_ROOT}/ObjGLFW/flextgl_profile.txt
