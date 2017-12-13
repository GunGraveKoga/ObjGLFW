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

#define WINDOW_WIDTH 1200
#define WINDOW_HEIGHT 800

#define MAX_VERTEX_BUFFER 512 * 1024
#define MAX_ELEMENT_BUFFER 128 * 1024

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
    struct nk_font_atlas _atlas;
    sg_shader _shader;
    struct nk_color _background;
    sg_draw_state _draw_state;
    sg_pass_action _pass_action;
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
    
    struct nk_glfw_vertex _vertexData[64 * 1024];
    nk_draw_index _indexData[128 * 1024];
    struct nk_buffer _vbuf;
    struct nk_buffer _ibuf;
}

@end

GLFW_APPLICATION_DELEGATE(AppDelegate)

@implementation AppDelegate

- (void)applicationDidFinishLaunching {
    GlfwWindow *window = [GlfwWindow windowWithRect:GlfwRectNew(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT) title:@"Demo" hints:
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
    
    nk_init_default(&_ctx, 0);
    nk_buffer_init_default(&_cmds);
    nk_buffer_init_fixed(&_vbuf, _vertexData, sizeof(_vertexData));
    nk_buffer_init_fixed(&_ibuf, _indexData, sizeof(_indexData));
    sg_setup(&_desc);
    OF_ENSURE(sg_isvalid());
    
    sg_buffer_desc vb_desc = {};
    vb_desc.type = SG_BUFFERTYPE_VERTEXBUFFER;
    vb_desc.usage = SG_USAGE_STREAM;
    vb_desc.size = sizeof(_vertexData);
    _draw_state.vertex_buffers[0] = sg_make_buffer(&vb_desc);
    
    sg_buffer_desc eb_desc = {};
    eb_desc.type = SG_BUFFERTYPE_INDEXBUFFER;
    eb_desc.usage = SG_USAGE_STREAM;
    eb_desc.size = sizeof(_indexData);
    _draw_state.index_buffer = sg_make_buffer(&eb_desc);
    
    nk_font_atlas_init_default(&_atlas);
    nk_font_atlas_begin(&_atlas);
    /*fonts*/
    const void *image; int img_width, img_height;
    image = nk_font_atlas_bake(&_atlas, &img_width, &img_height, NK_FONT_ATLAS_RGBA32);
    sg_image_desc atlas_desc = {};
    atlas_desc.width = img_width;
    atlas_desc.height = img_height;
    atlas_desc.pixel_format = SG_PIXELFORMAT_RGBA8;
    atlas_desc.wrap_u = SG_WRAP_REPEAT;
    atlas_desc.wrap_v = SG_WRAP_REPEAT;
    atlas_desc.content.subimage[0][0].ptr = image;
    atlas_desc.content.subimage[0][0].size = img_width * img_height * 4;
    _draw_state.fs_images[0] = sg_make_image(&atlas_desc);
    nk_font_atlas_end(&_atlas, nk_handle_id((int)_draw_state.fs_images[0].id), &_null);
    if (_atlas.default_font)
        nk_style_set_font(&_ctx, &(_atlas.default_font->handle));
    
    
    sg_shader_desc shader_desc = {};
    shader_desc.vs.uniform_blocks[0].size = (sizeof(GLfloat) * (4 * 4));
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
    pip_desc.depth_stencil.depth_write_enabled = false;
    pip_desc.depth_stencil.depth_compare_func = SG_COMPAREFUNC_ALWAYS;
    _draw_state.pipeline = sg_make_pipeline(&pip_desc);
    
    _background = nk_rgb(28,48,62);
    _pass_action.colors[0].action = SG_ACTION_CLEAR;
    nk_color_fv(&(_pass_action.colors[0].val[0]), _background);
    
    [window doneContext];
    
    [[GlfwWindowManager defaultManager] attachWindow:window];
}

- (id)copy {
    return self;
}

- (void)drawInWindow:(__kindof GlfwWindow *)window {
    
    [window makeContextCurrent];
    
    if (nk_begin(&_ctx, "Demo", nk_rect(50, 50, 230, 250),
                 NK_WINDOW_BORDER|NK_WINDOW_MOVABLE|NK_WINDOW_SCALABLE|
                 NK_WINDOW_MINIMIZABLE|NK_WINDOW_TITLE))
    {
        enum {EASY, HARD};
        static int op = EASY;
        static int property = 20;
        nk_layout_row_static(&_ctx, 30, 80, 1);
        if (nk_button_label(&_ctx, "button"))
            fprintf(stdout, "button pressed\n");
        
        nk_layout_row_dynamic(&_ctx, 30, 2);
        if (nk_option_label(&_ctx, "easy", op == EASY)) op = EASY;
        if (nk_option_label(&_ctx, "hard", op == HARD)) op = HARD;
        
        nk_layout_row_dynamic(&_ctx, 25, 1);
        nk_property_int(&_ctx, "Compression:", 0, &property, 100, 10, 1);
        
        nk_layout_row_dynamic(&_ctx, 20, 1);
        nk_label(&_ctx, "background:", NK_TEXT_LEFT);
        nk_layout_row_dynamic(&_ctx, 25, 1);
        if (nk_combo_begin_color(&_ctx, _background, nk_vec2(nk_widget_width(&_ctx),400))) {
            nk_layout_row_dynamic(&_ctx, 120, 1);
            _background = nk_color_picker(&_ctx, _background, NK_RGBA);
            nk_layout_row_dynamic(&_ctx, 25, 1);
            _background.r = (nk_byte)nk_propertyi(&_ctx, "#R:", 0, _background.r, 255, 1,1);
            _background.g = (nk_byte)nk_propertyi(&_ctx, "#G:", 0, _background.g, 255, 1,1);
            _background.b = (nk_byte)nk_propertyi(&_ctx, "#B:", 0, _background.b, 255, 1,1);
            _background.a = (nk_byte)nk_propertyi(&_ctx, "#A:", 0, _background.a, 255, 1,1);
            nk_combo_end(&_ctx);
        }
    }
    nk_end(&_ctx);
    
    [self renderInWindow:window];
    
    [window swapBuffers];
    
    [window doneContext];
}

- (void)renderInWindow:(OF_KINDOF(GlfwWindow) *)window {
    GlfwSize framebufferSize = [window contentSize];
    GlfwSize windowSize = [window size];
    
    struct nk_vec2 fb_scale;
    fb_scale.x = (float)framebufferSize.width / (float)windowSize.width;
    fb_scale.y = (float)framebufferSize.height / (float)windowSize.height;
    
    const struct nk_draw_command *cmd;
    const nk_draw_index *offset = NULL;
    GLfloat ortho[4][4] = {
        {2.0f, 0.0f, 0.0f, 0.0f},
        {0.0f,-2.0f, 0.0f, 0.0f},
        {0.0f, 0.0f,-1.0f, 0.0f},
        {-1.0f,1.0f, 0.0f, 1.0f},
    };
    ortho[0][0] /= (GLfloat)windowSize.width;
    ortho[1][1] /= (GLfloat)windowSize.height;
    
    sg_begin_default_pass(&_pass_action, framebufferSize.width, framebufferSize.height);
    
    struct nk_convert_config config;
    static const struct nk_draw_vertex_layout_element vertex_layout[] = {
        {NK_VERTEX_POSITION, NK_FORMAT_FLOAT, NK_OFFSETOF(struct nk_glfw_vertex, position)},
        {NK_VERTEX_TEXCOORD, NK_FORMAT_FLOAT, NK_OFFSETOF(struct nk_glfw_vertex, uv)},
        {NK_VERTEX_COLOR, NK_FORMAT_R8G8B8A8, NK_OFFSETOF(struct nk_glfw_vertex, col)},
        {NK_VERTEX_LAYOUT_END}
    };
    NK_MEMSET(&config, 0, sizeof(config));
    config.vertex_layout = vertex_layout;
    config.vertex_size = sizeof(struct nk_glfw_vertex);
    config.vertex_alignment = NK_ALIGNOF(struct nk_glfw_vertex);
    config.null = _null;
    config.circle_segment_count = 22;
    config.curve_segment_count = 22;
    config.arc_segment_count = 22;
    config.global_alpha = 1.0f;
    config.shape_AA = NK_ANTI_ALIASING_ON;
    config.line_AA = NK_ANTI_ALIASING_ON;
    
    /* setup buffers to load vertices and elements */
    nk_buffer_clear(&_ibuf);
    nk_buffer_clear(&_vbuf);
    nk_convert(&_ctx, &_cmds, &_vbuf, &_ibuf, &config);
    
    sg_update_buffer(_draw_state.vertex_buffers[0], _vertexData, (int)_vbuf.needed);
    sg_update_buffer(_draw_state.index_buffer, _indexData, (int)_ibuf.needed);
    
    sg_apply_draw_state(&_draw_state);
    sg_apply_uniform_block(SG_SHADERSTAGE_VS, 0, &(ortho[0][0]), sizeof(ortho));
    
    int base_ement = 0;
    nk_draw_foreach(cmd, &_ctx, &_cmds)
    {
        if (!cmd->elem_count) continue;
        
        sg_apply_scissor_rect((GLint)(cmd->clip_rect.x * fb_scale.x),
                              (GLint)((windowSize.height - (GLint)(cmd->clip_rect.y + cmd->clip_rect.h)) * fb_scale.y),
                              (GLint)(cmd->clip_rect.w * fb_scale.x),
                              (GLint)(cmd->clip_rect.h * fb_scale.y), true);
        
        sg_draw(base_ement, cmd->elem_count, 1);
        base_ement += cmd->elem_count;
    }
    nk_clear(&_ctx);
    
    sg_end_pass();
    sg_commit();
}

- (GlfwEventMask)handledEventsMask {
    return GlfwAnyEventMask;
}

- (void)handleEvent:(__kindof GlfwEvent *)event fromWindow:(__kindof GlfwWindow *)window {
    
}

@end

#include "flextGL.c"
