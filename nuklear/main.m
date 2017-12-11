//
//  main.m
//  ObjGLFW
//
//  Created by Yury Vovk on 05.12.2017.
//  Copyright © 2017 GunGraveKoga. All rights reserved.
//

#include <GL/glew.h>
#import <ObjFW/ObjFW.h>
#import "GlfwGeometry.h"
#import "GlfwApplication.h"
#import "GlfwWindowManager.h"
#import "GlfwEventHandling.h"
#import "GlfwDrawing.h"
#import "GlfwWindow.h"
#import "GlfwEvent.h"

#include "sokol_time.h"

#define NK_INCLUDE_FIXED_TYPES
#define NK_INCLUDE_STANDARD_IO
#define NK_INCLUDE_STANDARD_VARARGS
#define NK_INCLUDE_DEFAULT_ALLOCATOR
#define NK_INCLUDE_VERTEX_BUFFER_OUTPUT
#define NK_INCLUDE_FONT_BAKING
#define NK_INCLUDE_DEFAULT_FONT
#define NK_IMPLEMENTATION

#include "nuklear.h"

#ifndef NK_GLFW_TEXT_MAX
#define NK_GLFW_TEXT_MAX 256
#endif
#ifndef NK_GLFW_DOUBLE_CLICK_LO
#define NK_GLFW_DOUBLE_CLICK_LO 0.02
#endif
#ifndef NK_GLFW_DOUBLE_CLICK_HI
#define NK_GLFW_DOUBLE_CLICK_HI 0.2
#endif

#define MAX_VERTEX_BUFFER 512 * 1024
#define MAX_ELEMENT_BUFFER 128 * 1024

struct nk_glfw_device {
    struct nk_buffer cmds;
    struct nk_draw_null_texture null;
    GLuint vbo, vao, ebo;
    GLuint prog;
    GLuint vert_shdr;
    GLuint frag_shdr;
    GLint attrib_pos;
    GLint attrib_uv;
    GLint attrib_col;
    GLint uniform_tex;
    GLint uniform_proj;
    GLuint font_tex;
};

struct nk_glfw_vertex {
    float position[2];
    float uv[2];
    nk_byte col[4];
};


@interface AppDelegate: OFObject <OFApplicationDelegate, GlfwDrawing, GlfwEventHandling>
{
    struct nk_glfw_device ogl;
    struct nk_context ctx;
    struct nk_font_atlas atlas;
    struct nk_vec2 fb_scale;
    unsigned int text[NK_GLFW_TEXT_MAX];
    int text_len;
    struct nk_vec2 scroll;
    double last_button_click;
    int is_double_click_down;
    struct nk_vec2 double_click_pos;
    
    struct nk_color _background;
}

- (void)fontStashBegin;
- (void)fontStashEnd;
- (void)renderAA:(enum nk_anti_aliasing)AA maxVertexBuffer:(int)maxVB maxElementBuffer:(int)maxEB size:(GlfwSize)size viewportSize:(GlfwSize)viewport;

@end

GLFW_APPLICATION_DELEGATE(AppDelegate);

#ifdef __APPLE__
#define NK_SHADER_VERSION "#version 150\n"
#else
#define NK_SHADER_VERSION "#version 300 es\n"
#endif

@implementation AppDelegate

- (instancetype)init {
    self = [super init];
    
    _background = nk_rgb(28,48,62);
    last_button_click = 0;
    double_click_pos = nk_vec2(0, 0);
    is_double_click_down = nk_false;
    
    return self;
}

- (void)applicationDidFinishLaunching {
    
    GlfwWindow *newWindow = [[[GlfwWindow alloc] initWithRect:GlfwRectNew(0, 0, 640, 480) title:@"Test" hints:@{
        @(GLFW_CONTEXT_VERSION_MAJOR): @(3),
        @(GLFW_CONTEXT_VERSION_MINOR): @(2),
        @(GLFW_OPENGL_PROFILE): @(GLFW_OPENGL_CORE_PROFILE),
#ifdef __APPLE__
        @(GLFW_OPENGL_FORWARD_COMPAT): @(GL_TRUE),
#endif
    }] autorelease];
    
    [newWindow bindDrawble:self];
    [newWindow bindEventHandler:self];
    
    [newWindow makeContextCurrent];
    
    glViewport(0, 0, 640, 480);
    glewExperimental = 1;
    if (glewInit() != GLEW_OK)
        @throw [OFInitializationFailedException exceptionWithClass:[self class]];
    
    nk_init_default(&ctx, 0);
    
    GLint status;
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
    
    struct nk_glfw_device *dev = &ogl;
    nk_buffer_init_default(&dev->cmds);
    dev->prog = glCreateProgram();
    dev->vert_shdr = glCreateShader(GL_VERTEX_SHADER);
    dev->frag_shdr = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(dev->vert_shdr, 1, &vertex_shader, 0);
    glShaderSource(dev->frag_shdr, 1, &fragment_shader, 0);
    glCompileShader(dev->vert_shdr);
    glCompileShader(dev->frag_shdr);
    glGetShaderiv(dev->vert_shdr, GL_COMPILE_STATUS, &status);
    assert(status == GL_TRUE);
    glGetShaderiv(dev->frag_shdr, GL_COMPILE_STATUS, &status);
    assert(status == GL_TRUE);
    glAttachShader(dev->prog, dev->vert_shdr);
    glAttachShader(dev->prog, dev->frag_shdr);
    glLinkProgram(dev->prog);
    glGetProgramiv(dev->prog, GL_LINK_STATUS, &status);
    assert(status == GL_TRUE);
    
    dev->uniform_tex = glGetUniformLocation(dev->prog, "Texture");
    dev->uniform_proj = glGetUniformLocation(dev->prog, "ProjMtx");
    dev->attrib_pos = glGetAttribLocation(dev->prog, "Position");
    dev->attrib_uv = glGetAttribLocation(dev->prog, "TexCoord");
    dev->attrib_col = glGetAttribLocation(dev->prog, "Color");
    
    {
        /* buffer setup */
        GLsizei vs = sizeof(struct nk_glfw_vertex);
        size_t vp = offsetof(struct nk_glfw_vertex, position);
        size_t vt = offsetof(struct nk_glfw_vertex, uv);
        size_t vc = offsetof(struct nk_glfw_vertex, col);
        
        glGenBuffers(1, &dev->vbo);
        glGenBuffers(1, &dev->ebo);
        glGenVertexArrays(1, &dev->vao);
        
        glBindVertexArray(dev->vao);
        glBindBuffer(GL_ARRAY_BUFFER, dev->vbo);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, dev->ebo);
        
        glEnableVertexAttribArray((GLuint)dev->attrib_pos);
        glEnableVertexAttribArray((GLuint)dev->attrib_uv);
        glEnableVertexAttribArray((GLuint)dev->attrib_col);
        
        glVertexAttribPointer((GLuint)dev->attrib_pos, 2, GL_FLOAT, GL_FALSE, vs, (void*)vp);
        glVertexAttribPointer((GLuint)dev->attrib_uv, 2, GL_FLOAT, GL_FALSE, vs, (void*)vt);
        glVertexAttribPointer((GLuint)dev->attrib_col, 4, GL_UNSIGNED_BYTE, GL_TRUE, vs, (void*)vc);
    }
    
    glBindTexture(GL_TEXTURE_2D, 0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    glBindVertexArray(0);
    
    [self fontStashBegin];
    
    [self fontStashEnd];
    
    [newWindow doneContext];
    
    [[GlfwWindowManager defaultManager] attachWindow:newWindow];
}

- (void)drawInWindow:(GlfwWindow *)window {
    
    [window makeContextCurrent];
    
    GlfwSize viewport = [window contentSize];
    GlfwSize winsize = [window size];
    
    fb_scale.x = viewport.width / winsize.width;
    fb_scale.y = viewport.height / winsize.height;
    
    if (nk_begin(&ctx, "Demo", nk_rect(50, 50, 230, 250), NK_WINDOW_BORDER|NK_WINDOW_MOVABLE|NK_WINDOW_SCALABLE| NK_WINDOW_MINIMIZABLE|NK_WINDOW_TITLE)) {
        
        enum {EASY, HARD};
        static int op = EASY;
        static int property = 20;
        nk_layout_row_static(&ctx, 30, 80, 1);
        if (nk_button_label(&ctx, "button"))
            fprintf(stdout, "button pressed\n");
        
        nk_layout_row_dynamic(&ctx, 30, 2);
        if (nk_option_label(&ctx, "easy", op == EASY)) op = EASY;
        if (nk_option_label(&ctx, "hard", op == HARD)) op = HARD;
        
        nk_layout_row_dynamic(&ctx, 25, 1);
        nk_property_int(&ctx, "Compression:", 0, &property, 100, 10, 1);
        
        nk_layout_row_dynamic(&ctx, 20, 1);
        nk_label(&ctx, "background:", NK_TEXT_LEFT);
        nk_layout_row_dynamic(&ctx, 25, 1);
        if (nk_combo_begin_color(&ctx, _background, nk_vec2(nk_widget_width(&ctx),400))) {
            nk_layout_row_dynamic(&ctx, 120, 1);
            _background = nk_color_picker(&ctx, _background, NK_RGBA);
            nk_layout_row_dynamic(&ctx, 25, 1);
            _background.r = (nk_byte)nk_propertyi(&ctx, "#R:", 0, _background.r, 255, 1,1);
            _background.g = (nk_byte)nk_propertyi(&ctx, "#G:", 0, _background.g, 255, 1,1);
            _background.b = (nk_byte)nk_propertyi(&ctx, "#B:", 0, _background.b, 255, 1,1);
            _background.a = (nk_byte)nk_propertyi(&ctx, "#A:", 0, _background.a, 255, 1,1);
            nk_combo_end(&ctx);
        }
        
    }
    nk_end(&ctx);
    
    float bg[4];
    nk_color_fv(bg, _background);
    glViewport(0, 0, viewport.width, viewport.height);
    glClear(GL_COLOR_BUFFER_BIT);
    glClearColor(bg[0], bg[1], bg[2], bg[3]);
    /* IMPORTANT: `nk_glfw_render` modifies some global OpenGL state
     * with blending, scissor, face culling, depth test and viewport and
     * defaults everything back into a default state.
     * Make sure to either a.) save and restore or b.) reset your own state after
     * rendering the UI. */
    [self renderAA:NK_ANTI_ALIASING_ON maxVertexBuffer:MAX_VERTEX_BUFFER maxElementBuffer:MAX_ELEMENT_BUFFER size:winsize viewportSize:viewport];
    
    [window swapBuffers];
    
    [window doneContext];
}

- (void)renderAA:(enum nk_anti_aliasing)AA maxVertexBuffer:(int)maxVB maxElementBuffer:(int)maxEB size:(GlfwSize)size viewportSize:(GlfwSize)viewport {
    struct nk_glfw_device *dev = &ogl;
    struct nk_buffer vbuf, ebuf;
    GLfloat ortho[4][4] = {
        {2.0f, 0.0f, 0.0f, 0.0f},
        {0.0f,-2.0f, 0.0f, 0.0f},
        {0.0f, 0.0f,-1.0f, 0.0f},
        {-1.0f,1.0f, 0.0f, 1.0f},
    };
    ortho[0][0] /= (GLfloat)size.width;
    ortho[1][1] /= (GLfloat)size.height;
    
    /* setup global state */
    glEnable(GL_BLEND);
    glBlendEquation(GL_FUNC_ADD);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glDisable(GL_CULL_FACE);
    glDisable(GL_DEPTH_TEST);
    glEnable(GL_SCISSOR_TEST);
    glActiveTexture(GL_TEXTURE0);
    
    /* setup program */
    glUseProgram(dev->prog);
    glUniform1i(dev->uniform_tex, 0);
    glUniformMatrix4fv(dev->uniform_proj, 1, GL_FALSE, &ortho[0][0]);
    glViewport(0,0,(GLsizei)viewport.width,(GLsizei)viewport.height);
    {
        /* convert from command queue into draw list and draw to screen */
        const struct nk_draw_command *cmd;
        void *vertices, *elements;
        const nk_draw_index *offset = NULL;
        
        /* allocate vertex and element buffer */
        glBindVertexArray(dev->vao);
        glBindBuffer(GL_ARRAY_BUFFER, dev->vbo);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, dev->ebo);
        
        glBufferData(GL_ARRAY_BUFFER, maxVB, NULL, GL_STREAM_DRAW);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, maxEB, NULL, GL_STREAM_DRAW);
        
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
            config.null = dev->null;
            config.circle_segment_count = 22;
            config.curve_segment_count = 22;
            config.arc_segment_count = 22;
            config.global_alpha = 1.0f;
            config.shape_AA = AA;
            config.line_AA = AA;
            
            /* setup buffers to load vertices and elements */
            nk_buffer_init_fixed(&vbuf, vertices, (size_t)maxVB);
            nk_buffer_init_fixed(&ebuf, elements, (size_t)maxEB);
            nk_convert(&ctx, &dev->cmds, &vbuf, &ebuf, &config);
        }
        glUnmapBuffer(GL_ARRAY_BUFFER);
        glUnmapBuffer(GL_ELEMENT_ARRAY_BUFFER);
        
        /* iterate over and execute each draw command */
        nk_draw_foreach(cmd, &ctx, &dev->cmds)
        {
            if (!cmd->elem_count) continue;
            glBindTexture(GL_TEXTURE_2D, (GLuint)cmd->texture.id);
            glScissor(
                      (GLint)(cmd->clip_rect.x * fb_scale.x),
                      (GLint)((size.height - (GLint)(cmd->clip_rect.y + cmd->clip_rect.h)) * fb_scale.y),
                      (GLint)(cmd->clip_rect.w * fb_scale.x),
                      (GLint)(cmd->clip_rect.h * fb_scale.y));
            glDrawElements(GL_TRIANGLES, (GLsizei)cmd->elem_count, GL_UNSIGNED_SHORT, offset);
            offset += cmd->elem_count;
        }
        nk_clear(&ctx);
    }
    
    /* default OpenGL state */
    glUseProgram(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    glBindVertexArray(0);
    glDisable(GL_BLEND);
    glDisable(GL_SCISSOR_TEST);
}

- (GlfwEventMask)handledEventsMask {
    return GlfwAnyEventMask;
}

- (void)handleEvent:(GlfwEvent *)event fromWindow:(GlfwWindow *)window {
    nk_input_begin(&ctx);
    
    of_log(@"%@", event);
    
    if ([event isMatchEventMask:GlfwCharacterEventMask]) {
        nk_input_unicode(&ctx, ((GlfwCharacterEvent *)event).character);
    }
    
    if ([event isMatchEventMask:GlfwKeyEventMask]) {
        GlfwKeyEvent *keyEvent = (GlfwKeyEvent *)event;
        
        if ((keyEvent.modifiersFlags & GLFW_MOD_CONTROL) == GLFW_MOD_CONTROL) {
            if (keyEvent.type == GlfwKeyUp || keyEvent.currentType == GlfwKeyUp) {
                switch (keyEvent.glfwKey) {
                    case GLFW_KEY_C:
                        nk_input_key(&ctx, NK_KEY_COPY, 1);
                        break;
                    case GLFW_KEY_V:
                        nk_input_key(&ctx, NK_KEY_PASTE, 1);
                        break;
                    case GLFW_KEY_X:
                        nk_input_key(&ctx, NK_KEY_CUT, 1);
                        break;
                    case GLFW_KEY_Z:
                        nk_input_key(&ctx, NK_KEY_TEXT_UNDO, 1);
                        break;
                    case GLFW_KEY_R:
                        nk_input_key(&ctx, NK_KEY_TEXT_REDO, 1);
                        break;
                    case GLFW_KEY_LEFT:
                        nk_input_key(&ctx, NK_KEY_TEXT_WORD_LEFT, 1);
                        break;
                    case GLFW_KEY_RIGHT:
                        nk_input_key(&ctx, NK_KEY_TEXT_WORD_RIGHT, 1);
                        break;
                    case GLFW_KEY_B:
                        nk_input_key(&ctx, NK_KEY_TEXT_LINE_START, 1);
                        break;
                    case GLFW_KEY_E:
                        nk_input_key(&ctx, NK_KEY_TEXT_LINE_END, 1);
                        break;
                    default:
                        break;
                }
            }
            else {
                nk_input_key(&ctx, NK_KEY_LEFT, 0);
                nk_input_key(&ctx, NK_KEY_RIGHT, 0);
                nk_input_key(&ctx, NK_KEY_COPY, 0);
                nk_input_key(&ctx, NK_KEY_PASTE, 0);
                nk_input_key(&ctx, NK_KEY_CUT, 0);
                nk_input_key(&ctx, NK_KEY_SHIFT, 0);
            }
        }
        
    }
    
    if ([event isMatchEventMask:GlfwMouseMovedMask]) {
        of_point_t mouseLocation = event.locationInWindow;
        if (!of_point_is_null(mouseLocation))
            nk_input_motion(&ctx, mouseLocation.x, mouseLocation.y);
    }
    
    if ([event isMatchEventMask:(GlfwLeftMouseDownMask | GlfwLeftMouseUpMask)]) {
        
        if (event.type == GlfwLeftMouseDown) {
            double dt = (event.timestamp - last_button_click) / 1000;
            
            if (dt > NK_GLFW_DOUBLE_CLICK_LO && dt < NK_GLFW_DOUBLE_CLICK_HI) {
                of_point_t location = event.locationInWindow;
                
                if (!of_point_is_null(location))
                    nk_input_button(&ctx, NK_BUTTON_DOUBLE, location.x, location.y, nk_true);
                
            }
            last_button_click = event.timestamp;
            
        }
    }
    
    if ([event isMatchEventMask:(GlfwRightMouseDownMask | GlfwLeftMouseDownMask | GlfwMouseMiddleDownMask)]) {
        of_point_t mouseLocation = event.currentLocationInWindow;
        if (!of_point_is_null(mouseLocation)) {
            switch (event.glfwMouseButton) {
                case GLFW_MOUSE_BUTTON_LEFT:
                    nk_input_button(&ctx, NK_BUTTON_LEFT, mouseLocation.x, mouseLocation.y, nk_true);
                    break;
                case GLFW_MOUSE_BUTTON_RIGHT:
                    nk_input_button(&ctx, NK_BUTTON_RIGHT, mouseLocation.x, mouseLocation.y, nk_true);
                    break;
                case GLFW_MOUSE_BUTTON_MIDDLE:
                    nk_input_button(&ctx, NK_BUTTON_MIDDLE, mouseLocation.x, mouseLocation.y, nk_true);
                    break;
                default:
                    break;
            }
        }
    }
    
    if ([event isMatchEventMask:(GlfwRightMouseUpMask | GlfwLeftMouseUpMask | GlfwMouseMiddleUpMask)]) {
        of_point_t mouseLocation = event.currentLocationInWindow;
        if (!of_point_is_null(mouseLocation)) {
            switch (event.glfwMouseButton) {
                case GLFW_MOUSE_BUTTON_LEFT:
                    nk_input_button(&ctx, NK_BUTTON_LEFT, mouseLocation.x, mouseLocation.y, nk_false);
                    break;
                case GLFW_MOUSE_BUTTON_RIGHT:
                    nk_input_button(&ctx, NK_BUTTON_RIGHT, mouseLocation.x, mouseLocation.y, nk_false);
                    break;
                case GLFW_MOUSE_BUTTON_MIDDLE:
                    nk_input_button(&ctx, NK_BUTTON_MIDDLE, mouseLocation.x, mouseLocation.y, nk_false);
                    break;
                default:
                    break;
            }
        }
    }
    
    if ([event isMatchEventMask:GlfwScrollWheelMask]) {
        nk_input_scroll(&ctx, nk_vec2(event.deltaX, event.deltaY));
    }
    
    nk_input_end(&ctx);
}

- (of_comparison_result_t)compare:(id<OFComparing>)object {
    return OF_ORDERED_SAME;
}

- (void)fontStashBegin {
    nk_font_atlas_init_default(&atlas);
    nk_font_atlas_begin(&atlas);
}

- (void)fontStashEnd {
    const void *image; int w, h;
    image = nk_font_atlas_bake(&atlas, &w, &h, NK_FONT_ATLAS_RGBA32);
    struct nk_glfw_device *dev = &ogl;
    glGenTextures(1, &dev->font_tex);
    glBindTexture(GL_TEXTURE_2D, dev->font_tex);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)w, (GLsizei)h, 0,
                 GL_RGBA, GL_UNSIGNED_BYTE, image);
    nk_font_atlas_end(&atlas, nk_handle_id((int)ogl.font_tex), &ogl.null);
    if (atlas.default_font)
        nk_style_set_font(&ctx, &atlas.default_font->handle);
}

- (void)applicationWillTerminate {
    struct nk_glfw_device *dev = &ogl;
    glDetachShader(dev->prog, dev->vert_shdr);
    glDetachShader(dev->prog, dev->frag_shdr);
    glDeleteShader(dev->vert_shdr);
    glDeleteShader(dev->frag_shdr);
    glDeleteProgram(dev->prog);
    glDeleteTextures(1, &dev->font_tex);
    glDeleteBuffers(1, &dev->vbo);
    glDeleteBuffers(1, &dev->ebo);
    nk_buffer_free(&dev->cmds);
}

@end
