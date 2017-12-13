//
//  main.m
//  nuklear
//
//  Created by Yury Vovk on 12.12.2017.
//  Copyright © 2017 GunGraveKoga. All rights reserved.
//

#define GLFW_INCLUDE_NONE
#import "ObjGLFW.h"
#include "flextGL.h"
#define SOKOL_IMPL
#define SOKOL_GLCORE33
#include "sokol_gfx.h"

#import <ObjFW/ObjFW.h>

#define NK_INCLUDE_FIXED_TYPES
#define NK_INCLUDE_STANDARD_IO
#define NK_INCLUDE_STANDARD_VARARGS
#define NK_INCLUDE_DEFAULT_ALLOCATOR
#define NK_INCLUDE_VERTEX_BUFFER_OUTPUT
#define NK_INCLUDE_FONT_BAKING
#define NK_INCLUDE_DEFAULT_FONT
#define NK_IMPLEMENTATION
#include "nuklear.h"

#ifdef __APPLE__
#define NK_SHADER_VERSION "#version 150\n"
#else
#define NK_SHADER_VERSION "#version 300 es\n"
#endif

static const GLchar *vertex_shader =
NK_SHADER_VERSION
"uniform mat4 ProjMtx;\n"
"in vec2 Position;\n"
"in vec2 TexCoord;\n"
"in vec4 Color;\n"
"out vec2 Frag_UV;\n"
"out vec4 Frag_Color;\n"
"void main() {\n"
"   Frag_UV = TexCoord;\n"
"   Frag_Color = Color;\n"
"   gl_Position = ProjMtx * vec4(Position.xy, 0, 1);\n"
"}\n";
static const GLchar *fragment_shader =
NK_SHADER_VERSION
"precision mediump float;\n"
"uniform sampler2D Texture;\n"
"in vec2 Frag_UV;\n"
"in vec4 Frag_Color;\n"
"out vec4 Out_Color;\n"
"void main(){\n"
"   Out_Color = Frag_Color * texture(Texture, Frag_UV.st);\n"
"}\n";

struct nk_glfw_vertex {
    float position[2];
    float uv[2];
    nk_byte col[4];
};

@interface AppDelegate : OFObject <OFApplicationDelegate, OFCopying, GlfwDrawing, GlfwEventHandling>
{
    struct nk_context _ctx;
    sg_desc _desc;
    struct nk_buffer _cmds;
    struct nk_draw_null_texture _null;
    sg_shader _shader;
    sg_draw_state _draw_state;
    sg_pass _pass_action;
    GLuint _vbo, _vao, _ebo;
    GLuint _prog;
    GLuint _vert_shdr;
    GLuint _frag_shdr;
    GLint _attrib_pos;
    GLint _attrib_uv;
    GLint _attrib_col;
    GLint _uniform_tex;
    GLint _uniform_proj;
    GLuint _font_tex;
}

@end

GLFW_APPLICATION_DELEGATE(AppDelegate)

@implementation AppDelegate

- (void)applicationDidFinishLaunching {
    GlfwWindow *window = [GlfwWindow windowWithRect:GlfwRectNew(0, 0, 640, 480) title:@"Demo" hints:
  @{
    @(GLFW_CONTEXT_VERSION_MAJOR): @(3),
    @(GLFW_CONTEXT_VERSION_MINOR): @(3),
    @(GLFW_OPENGL_PROFILE): @(GLFW_OPENGL_CORE_PROFILE)
#ifdef __APPLE__
    , @(GLFW_OPENGL_FORWARD_COMPAT): @(GL_TRUE)
#endif
    }];
    
    [window bindDrawble:self];
    [window bindEventHandler:self];
    
    [window makeContextCurrent];
    
    flextInit([window windowHandle]);
    
    GLint status;
    
    nk_init_default(&ctx, 0);
    nk_buffer_init_default(&_cmds);
    sg_setup(&_desc);
    OF_ENSURE(sg_isvalid());
    sg_shader_desc shader_desc = {};
    shader_desc.vs.uniform_blocks[0].size = sizeof(GLfloat[4][4]);
    shader_desc.vs.uniform_blocks[0].uniforms[0] = sg_named_uniform("ProjMtx", SG_UNIFORMTYPE_MAT4, 1);
    shader_desc.vs.source = vertex_shader;
    shader_desc.fs.images[0] = sg_named_image("Texture", SG_IMAGETYPE_2D);
    shader_desc.fs.source = fragment_shader;
    _shader = sg_make_shader(&shader_desc);
    
    sg_pipeline_desc pip_desc = {};
    pip_desc.vertex_layouts[0].stride = sizeof(struct nk_glfw_vertex);
    pip_desc.vertex_layouts[0].attrs[0] = sg_named_attr("Position", offsetof(struct nk_glfw_vertex, position), SG_VERTEXFORMAT_FLOAT2);
    pip_desc.vertex_layouts[0].attrs[1] = sg_named_attr("TexCoord", offsetof(struct nk_glfw_vertex, uv), SG_VERTEXFORMAT_FLOAT2);
    pip_desc.vertex_layouts[0].attrs[2] = sg_named_attr("Color", offsetof(struct nk_glfw_vertex, col), SG_VERTEXFORMAT_UBYTE4);
    pip_desc.shader = _shader;
    pip_desc.index_type = SG_INDEXTYPE_UINT16;
    pip_desc.blend.enabled = true;
    pip_desc.blend.src_factor_rgb = SG_BLENDFACTOR_SRC_ALPHA;
    pip_desc.blend.dst_factor_rgb = SG_BLENDFACTOR_ONE_MINUS_SRC_ALPHA;
    pip_desc.blend.color_write_mask = SG_COLORMASK_RGB;
    _draw_state.pipeline = sg_make_pipeline(&pip_desc);
    
    
    
    [window doneContext];
    
    [[GlfwWindowManager defaultManager] attachWindow:window];
}

- (id)copy {
    return self;
}

- (void)drawInWindow:(__kindof GlfwWindow *)window {
    
}

- (GlfwEventMask)handledEventsMask {
    return GlfwAnyEventMask;
}

- (void)handleEvent:(__kindof GlfwEvent *)event fromWindow:(__kindof GlfwWindow *)window {
    
}

@end

#include "flextGL.c"
