//
//  main.m
//  nuklear
//
//  Created by Yury Vovk on 13.12.2017.
//  Copyright © 2017 GunGraveKoga. All rights reserved.
//

#import <ObjFW/ObjFW.h>
#define GLFW_INCLUDE_NONE
#import "ObjGLFW.h"
#include "flextGL.h"

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

#ifndef NK_GLFW_TEXT_MAX
#define NK_GLFW_TEXT_MAX 256
#endif
#ifndef NK_GLFW_DOUBLE_CLICK_LO
#define NK_GLFW_DOUBLE_CLICK_LO 0.02
#endif
#ifndef NK_GLFW_DOUBLE_CLICK_HI
#define NK_GLFW_DOUBLE_CLICK_HI 0.2
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
    struct nk_buffer _cmds;
    struct nk_font_atlas _atlas;
    struct nk_vec2 _fb_scale;
    struct nk_draw_null_texture _null;
    struct nk_color _background;
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
    double _last_MB_click;
}

@end

GLFW_APPLICATION_DELEGATE(AppDelegate)

NK_INTERN void
nk_glfw3_clipbard_paste(nk_handle usr, struct nk_text_edit *edit)
{
    GlfwWindow *window = (__bridge GlfwWindow *)(usr.ptr);
    OFString *text = [window clipboardString];
    if (text != nil) {
        nk_textedit_paste(edit, [text UTF8String], [text UTF8StringLength]);
    }
}

NK_INTERN void
nk_glfw3_clipbard_copy(nk_handle usr, const char *text, int len)
{
    GlfwWindow *window = (__bridge GlfwWindow *)(usr.ptr);
    [window setClipboardString:[OFString stringWithUTF8StringNoCopy:(char *)text length:len freeWhenDone:false]];
}

@implementation AppDelegate

- (void)applicationDidFinishLaunching {
    
    GlfwWindow *window = [GlfwWindow windowWithRect:GlfwRectNew(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT) title:@"Demo" hints:
                          @{
                            @(GLFW_CONTEXT_VERSION_MAJOR): @(3),
                            @(GLFW_CONTEXT_VERSION_MINOR): @(3),
                            @(GLFW_OPENGL_PROFILE): @(GLFW_OPENGL_CORE_PROFILE),
#ifdef __APPLE__
                            @(GLFW_OPENGL_FORWARD_COMPAT): @(GL_TRUE)
#endif
                            }];
    
    [window bindDrawble:self];
    [window bindEventHandler:self];
    
    [window makeContextCurrent];
    glViewport(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT);
    
    flextInit([window windowHandle]);
    
    nk_init_default(&_ctx, 0);
    _ctx.clip.copy = &nk_glfw3_clipbard_copy;
    _ctx.clip.paste = &nk_glfw3_clipbard_copy;
    _ctx.clip.userdata = nk_handle_ptr((__bridge void *)window);
    
    [self initializeDevice];
    
    [self beginFontStash];
    
    [self endFontStash];
    
    _background = nk_rgb(28,48,62);
    
    [window doneContext];
    
    [[GlfwWindowManager defaultManager] attachWindow:window];
}

- (GlfwEventMask)handledEventsMask {
    return GlfwAnyEventMask;
}

- (void)handleEvent:(__kindof GlfwEvent *)event fromWindow:(__kindof GlfwWindow *)window {
    
    if ([event isMatchEventMask:GlfwWindowResizedMask]) {
        [self drawInWindow:window];
        return;
    }
    
    if ([event isMatchEventMask:GlfwWindowShouldCloseMask]) {
        [[GlfwWindowManager defaultManager] detachWindow:window];
        return;
    }
    
    if ([event isMatchEventMask:GlfwKeyEventMask]) {
        if (([event modifiersFlags] & GLFW_MOD_CONTROL) == GLFW_MOD_CONTROL) {
            if ([event type] == GlfwKeyUp) {
                switch ([event glfwKey]) {
                    case GLFW_KEY_C:
                        nk_input_key(&_ctx, NK_KEY_COPY, nk_true);
                        return;
                    case GLFW_KEY_V:
                        nk_input_key(&_ctx, NK_KEY_PASTE, nk_true);
                        return;
                    case GLFW_KEY_X:
                        nk_input_key(&_ctx, NK_KEY_CUT, nk_true);
                        return;
                    case GLFW_KEY_Z:
                        nk_input_key(&_ctx, NK_KEY_TEXT_UNDO, nk_true);
                        return;
                    case GLFW_KEY_R:
                        nk_input_key(&_ctx, NK_KEY_TEXT_REDO, nk_true);
                        return;
                    case GLFW_KEY_LEFT:
                        nk_input_key(&_ctx, NK_KEY_TEXT_WORD_LEFT, nk_true);
                        return;
                    case GLFW_KEY_RIGHT:
                        nk_input_key(&_ctx, NK_KEY_TEXT_WORD_RIGHT, nk_true);
                        return;
                    case GLFW_KEY_B:
                        nk_input_key(&_ctx, NK_KEY_TEXT_LINE_START, nk_true);
                        return;
                    case GLFW_KEY_E:
                        nk_input_key(&_ctx, NK_KEY_TEXT_LINE_END, nk_true);
                        return;
                    default:
                        break;
                }
            }
            else {
                nk_input_key(&_ctx, NK_KEY_LEFT, 0);
                nk_input_key(&_ctx, NK_KEY_RIGHT, 0);
                nk_input_key(&_ctx, NK_KEY_COPY, 0);
                nk_input_key(&_ctx, NK_KEY_PASTE, 0);
                nk_input_key(&_ctx, NK_KEY_CUT, 0);
                nk_input_key(&_ctx, NK_KEY_SHIFT, 0);
            }
        }
        
        return;
    }
    
    if ([event isMatchEventMask:GlfwMouseMovedMask]) {
        of_point_t pos = [event locationInWindow];
        
        if (!of_point_is_null(pos))
            nk_input_motion(&_ctx, pos.x, pos.y);
        
        return;
    }
    
    if ([event isMatchEventMask:(GlfwRightMouseDownMask | GlfwLeftMouseDownMask | GlfwMouseMiddleDownMask)]) {
        of_point_t pos = [event currentLocationInWindow];
        
        if (!of_point_is_null(pos)) {
            switch ([event glfwMouseButton]) {
                case GLFW_MOUSE_BUTTON_LEFT: {
                    double eventTimestamp = [event timestamp];
                    double dt = (eventTimestamp - _last_MB_click) / 1000;
                    
                    if (dt > NK_GLFW_DOUBLE_CLICK_LO && dt < NK_GLFW_DOUBLE_CLICK_HI) {
                        of_point_t pos = [event currentLocationInWindow];
                        
                        if (!of_point_is_null(pos)) {
                            nk_input_button(&_ctx, NK_BUTTON_DOUBLE, pos.x, pos.y, nk_true);
                            of_log(@"Double click");
                        }
                    }
                    _last_MB_click = eventTimestamp;
                    nk_input_button(&_ctx, NK_BUTTON_LEFT, pos.x, pos.y, nk_true);
                }
                    return;
                case GLFW_MOUSE_BUTTON_RIGHT:
                    nk_input_button(&_ctx, NK_BUTTON_RIGHT, pos.x, pos.y, nk_true);
                    return;
                case GLFW_MOUSE_BUTTON_MIDDLE:
                    nk_input_button(&_ctx, NK_BUTTON_MIDDLE, pos.x, pos.y, nk_true);
                    return;
                default:
                    break;
            }
        }
        
        return;
    }
    
    if ([event isMatchEventMask:(GlfwRightMouseUpMask | GlfwLeftMouseUpMask | GlfwMouseMiddleUpMask)]) {
        of_point_t pos = [event currentLocationInWindow];
        
        switch ([event glfwMouseButton]) {
            case GLFW_MOUSE_BUTTON_LEFT: {
                nk_input_button(&_ctx, NK_BUTTON_DOUBLE, pos.x, pos.y, nk_false);
                nk_input_button(&_ctx, NK_BUTTON_LEFT, pos.x, pos.y, nk_false);
            }
                return;
            case GLFW_MOUSE_BUTTON_RIGHT:
                nk_input_button(&_ctx, NK_BUTTON_RIGHT, pos.x, pos.y, nk_false);
                return;
            case GLFW_MOUSE_BUTTON_MIDDLE:
                nk_input_button(&_ctx, NK_BUTTON_MIDDLE, pos.x, pos.y, nk_false);
                return;
            default:
                break;
        }
    }
}

- (void)drawInWindow:(__kindof GlfwWindow *)window {
    nk_input_end(&_ctx);
    
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
    
    nk_input_begin(&_ctx);
}

- (void)renderInWindow:(OF_KINDOF(GlfwWindow) *)window {
    GlfwSize fbSize = [window contentSize];
    GlfwSize wSize = [window size];
    
    float bg[4];
    nk_color_fv(bg, _background);
    glViewport(0, 0, wSize.width, wSize.height);
    glClear(GL_COLOR_BUFFER_BIT);
    glClearColor(bg[0], bg[1], bg[2], bg[3]);
    
    struct nk_buffer vbuf, ebuf;
    GLfloat ortho[4][4] = {
        {2.0f, 0.0f, 0.0f, 0.0f},
        {0.0f,-2.0f, 0.0f, 0.0f},
        {0.0f, 0.0f,-1.0f, 0.0f},
        {-1.0f,1.0f, 0.0f, 1.0f},
    };
    ortho[0][0] /= (GLfloat)wSize.width;
    ortho[1][1] /= (GLfloat)wSize.height;
    
    _fb_scale.x = (float)fbSize.width / (float)wSize.width;
    _fb_scale.y = (float)fbSize.height / (float)wSize.height;
    
    /* setup global state */
    glEnable(GL_BLEND);
    glBlendEquation(GL_FUNC_ADD);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glDisable(GL_CULL_FACE);
    glDisable(GL_DEPTH_TEST);
    glEnable(GL_SCISSOR_TEST);
    glActiveTexture(GL_TEXTURE0);
    
    /* setup program */
    glUseProgram(_prog);
    glUniform1i(_uniform_tex, 0);
    glUniformMatrix4fv(_uniform_proj, 1, GL_FALSE, &ortho[0][0]);
    glViewport(0,0,(GLsizei)fbSize.width,(GLsizei)fbSize.height);
    {
        /* convert from command queue into draw list and draw to screen */
        const struct nk_draw_command *cmd;
        void *vertices, *elements;
        const nk_draw_index *offset = NULL;
        
        /* allocate vertex and element buffer */
        glBindVertexArray(_vao);
        glBindBuffer(GL_ARRAY_BUFFER, _vbo);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _ebo);
        
        glBufferData(GL_ARRAY_BUFFER, MAX_VERTEX_BUFFER, NULL, GL_STREAM_DRAW);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, MAX_ELEMENT_BUFFER, NULL, GL_STREAM_DRAW);
        
        /* load draw vertices & elements directly into vertex + element buffer */
        vertices = glMapBuffer(GL_ARRAY_BUFFER, GL_WRITE_ONLY);
        elements = glMapBuffer(GL_ELEMENT_ARRAY_BUFFER, GL_WRITE_ONLY);
        {
            /* fill convert configuration */
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
            nk_buffer_init_fixed(&vbuf, vertices, (size_t)MAX_VERTEX_BUFFER);
            nk_buffer_init_fixed(&ebuf, elements, (size_t)MAX_ELEMENT_BUFFER);
            nk_convert(&_ctx, &_cmds, &vbuf, &ebuf, &config);
        }
        glUnmapBuffer(GL_ARRAY_BUFFER);
        glUnmapBuffer(GL_ELEMENT_ARRAY_BUFFER);
        
        /* iterate over and execute each draw command */
        nk_draw_foreach(cmd, &_ctx, &_cmds)
        {
            if (!cmd->elem_count) continue;
            glBindTexture(GL_TEXTURE_2D, (GLuint)cmd->texture.id);
            glScissor(
                      (GLint)(cmd->clip_rect.x * _fb_scale.x),
                      (GLint)((wSize.height - (GLint)(cmd->clip_rect.y + cmd->clip_rect.h)) * _fb_scale.y),
                      (GLint)(cmd->clip_rect.w * _fb_scale.x),
                      (GLint)(cmd->clip_rect.h * _fb_scale.y));
            glDrawElements(GL_TRIANGLES, (GLsizei)cmd->elem_count, GL_UNSIGNED_SHORT, offset);
            offset += cmd->elem_count;
        }
        nk_clear(&_ctx);
    }
    
    /* default OpenGL state */
    glUseProgram(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    glBindVertexArray(0);
    glDisable(GL_BLEND);
    glDisable(GL_SCISSOR_TEST);
}

- (void)initializeDevice {
    GLint status;
    
    nk_buffer_init_default(&_cmds);
    _prog = glCreateProgram();
    _vert_shdr = glCreateShader(GL_VERTEX_SHADER);
    _frag_shdr = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(_vert_shdr, 1, &vertex_shader, 0);
    glShaderSource(_frag_shdr, 1, &fragment_shader, 0);
    glCompileShader(_vert_shdr);
    glCompileShader(_frag_shdr);
    glGetShaderiv(_vert_shdr, GL_COMPILE_STATUS, &status);
    OF_ENSURE(status == GL_TRUE);
    glGetShaderiv(_frag_shdr, GL_COMPILE_STATUS, &status);
    OF_ENSURE(status == GL_TRUE);
    glAttachShader(_prog, _vert_shdr);
    glAttachShader(_prog, _frag_shdr);
    glLinkProgram(_prog);
    glGetProgramiv(_prog, GL_LINK_STATUS, &status);
    OF_ENSURE(status == GL_TRUE);
    
    _uniform_tex = glGetUniformLocation(_prog, "Texture");
    _uniform_proj = glGetUniformLocation(_prog, "ProjMtx");
    _attrib_pos = glGetAttribLocation(_prog, "Position");
    _attrib_uv = glGetAttribLocation(_prog, "TexCoord");
    _attrib_col = glGetAttribLocation(_prog, "Color");
    
    GLsizei vs = sizeof(struct nk_glfw_vertex);
    size_t vp = offsetof(struct nk_glfw_vertex, position);
    size_t vt = offsetof(struct nk_glfw_vertex, uv);
    size_t vc = offsetof(struct nk_glfw_vertex, col);
    
    glGenBuffers(1, &_vbo);
    glGenBuffers(1, &_ebo);
    glGenVertexArrays(1, &_vao);
    
    glBindVertexArray(_vao);
    glBindBuffer(GL_ARRAY_BUFFER, _vbo);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _ebo);
    
    glEnableVertexAttribArray((GLuint)_attrib_pos);
    glEnableVertexAttribArray((GLuint)_attrib_uv);
    glEnableVertexAttribArray((GLuint)_attrib_col);
    
    glVertexAttribPointer((GLuint)_attrib_pos, 2, GL_FLOAT, GL_FALSE, vs, (void*)vp);
    glVertexAttribPointer((GLuint)_attrib_uv, 2, GL_FLOAT, GL_FALSE, vs, (void*)vt);
    glVertexAttribPointer((GLuint)_attrib_col, 4, GL_UNSIGNED_BYTE, GL_TRUE, vs, (void*)vc);
    
    glBindTexture(GL_TEXTURE_2D, 0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    glBindVertexArray(0);
}

- (void)beginFontStash {
    nk_font_atlas_init_default(&_atlas);
    nk_font_atlas_begin(&_atlas);
}

- (void)endFontStash {
    const void *image; int w, h;
    image = nk_font_atlas_bake(&_atlas, &w, &h, NK_FONT_ATLAS_RGBA32);
    glGenTextures(1, &_font_tex);
    glBindTexture(GL_TEXTURE_2D, _font_tex);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)w, (GLsizei)h, 0,
                 GL_RGBA, GL_UNSIGNED_BYTE, image);
    nk_font_atlas_end(&_atlas, nk_handle_id((int)_font_tex), &_null);
    if (_atlas.default_font)
        nk_style_set_font(&_ctx, &_atlas.default_font->handle);
}

- (id)copy {
    return self;
}

@end

#include "flextGL.c"
