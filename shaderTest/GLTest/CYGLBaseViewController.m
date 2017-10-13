//
//  CYGLViewController.m
//  GLTest
//
//  Created by RRTY on 17/1/11.
//  Copyright © 2017年 chenyan. All rights reserved.
//

#import "CYGLBaseViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <GLKit/GLKit.h>
#import <OpenGLES/ES2/glext.h>
#import "staticShip.h"



@interface CYGLBaseViewController () {
    GLuint _vertexBuffer;
    GLuint _indexBuffer;

    
    //背景颜色的rgb值
    float _bgR;
    float _bgG;
    float _bgB;
}

@property (nonatomic,strong) EAGLContext* context;

@end

@implementation CYGLBaseViewController

#pragma mark - system

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self setupContext];
    [self setupShader];
 
}

- (void)dealloc {
    [self tearDownGL];
}


#pragma mark - glkViewControllerDelegate

- (void)update {
 
    glUseProgram(self.shaderProgram);
    
    
    /* 0.刷新时间
     距离上一次调用update过了多长时间，比如一个游戏物体速度是3m/s,那么每一次调用update，
     他就会行走3m/s * deltaTime，这样做就可以让游戏物体的行走实际速度与update调用频次无关
     */
    NSTimeInterval deltaTime = self.timeSinceLastUpdate;
    self.elapsedTime += deltaTime;
    //将elapsedTime 的值传递给shader
    GLuint elapsedTimeUniformLocation = glGetUniformLocation(self.shaderProgram, "elapsedTime");
    glUniform1f(elapsedTimeUniformLocation, (GLfloat)self.elapsedTime);
}


#pragma mark - glkViewDelegate

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    
    //清空和渲染背景 
    glClearColor(_bgR, _bgG, _bgB, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    glClear(GL_DEPTH_BUFFER_BIT);
    glClear(GL_STENCIL_BUFFER_BIT);

    //激活“深度检测”。
    glEnable(GL_DEPTH_TEST);
    //颜色混合，用于混合处理透明或半透明的物体，启用时关闭深度检测
    /*
    glEnable(GL_BLEND);
    glBlendFunc( GL_ONE , GL_ZERO );        // 源色将覆盖目标色
    glBlendFunc( GL_ZERO , GL_ONE );        // 目标色将覆盖源色
    glBlendFunc( GL_SRC_ALPHA , GL_ONE_MINUS_SRC_ALPHA ); // 是最常使用的
     */
    //剔除背面显示（当三角形的背面朝向观察者时显示透明）
//    glEnable(GL_CULL_FACE);
    
    glUseProgram(self.shaderProgram);
}


#pragma mark - public

/* 为shader中的position和color赋值 */
- (void)bindAttribs:(GLfloat *)triangleData {
    // 启用Shader中的两个属性
    // attribute vec4 position;
    // attribute vec4 color;
    GLuint positionAttribLocation = glGetAttribLocation(self.shaderProgram, "position");
    glEnableVertexAttribArray(positionAttribLocation);
    GLuint colorAttribLocation = glGetAttribLocation(self.shaderProgram, "color");
    glEnableVertexAttribArray(colorAttribLocation);
    
    // 为shader中的position和color赋值
    // glVertexAttribPointer (GLuint indx, GLint size, GLenum type, GLboolean normalized, GLsizei stride, const GLvoid* ptr)
    // indx: 上面Get到的Location
    // size: 有几个类型为type的数据，比如位置有x,y,z三个GLfloat元素，值就为3
    // type: 一般就是数组里元素数据的类型
    // normalized: 暂时用不上
    // stride: 每一个点包含几个byte，本例中就是6个GLfloat，x,y,z,r,g,b
    // ptr: 数据开始的指针，位置就是从头开始，颜色则跳过3个GLFloat的大小
    glVertexAttribPointer(positionAttribLocation, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(GLfloat), (char *)triangleData);
    glVertexAttribPointer(colorAttribLocation, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(GLfloat), (char *)triangleData + 3 * sizeof(GLfloat));
}


#pragma mark - GL load & setting & teardown

/* 初始化context上下文 */
- (void)setupContext {
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    /*GLKViewController在1秒内会多次调用你的draw方法，设置调用的次数来让GLKViewController知道你期待被调用的频率。当然，如果你的游戏花了很多时间对帧进行渲染，实际的调用次数将你设置的值。
     缺省值是30FPS。苹果的指导意见是把这个值设置成你的app能够稳定支持的帧率，以保持一致，看起来不卡。这个app非常简单，可以按照60FPS运行，所以我们设置成60FPS。
     和FYI一样（FYI是神马啊？），如果你想知道OS实际尝试调用你的update/draw方法的次数，可以检查只读属性framesPerSecond。
     */
    self.preferredFramesPerSecond = 60;
    
    GLKView *glkView = (GLKView *)self.view;
    glkView.context = self.context;
    //颜色格式
    glkView.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    //深度缓冲
    glkView.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    //纹理渲染
    glkView.drawableStencilFormat = GLKViewDrawableStencilFormat8;
    
    //抗锯齿   以前对于每个像素，都会调用一次fragment shader（片段着色器），开启后会将像素区分成更小的单元，并在更细微的层面上多次调用fragment shader。之后它将返回的颜色合并，生成更光滑的几何边缘效果。(慎用，耗资源严重)
    //    glkView.drawableMultisample = GLKViewDrawableMultisample4X;
}

/* 初始化顶点着色器和片段着色器并生成program */
- (void)setupShader {
    
    [EAGLContext setCurrentContext:self.context];
    NSString *vertexShaderPath = [[NSBundle mainBundle] pathForResource:@"vertex" ofType:@"glsl"];
    NSString *fragmentShaderPath = [[NSBundle mainBundle] pathForResource:@"fragment" ofType:@"glsl"];
    NSString *vertexShaderContent = [NSString stringWithContentsOfFile:vertexShaderPath encoding:NSUTF8StringEncoding error:nil];
    NSString *fragmentShaderContent = [NSString stringWithContentsOfFile:fragmentShaderPath encoding:NSUTF8StringEncoding error:nil];
    GLuint program;
    createProgram(vertexShaderContent.UTF8String, fragmentShaderContent.UTF8String, &program);
    self.shaderProgram = program;
}

/** 清除OpenGL缓存 */
- (void)tearDownGL {
    
    [EAGLContext setCurrentContext:self.context];
    
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteBuffers(1, &_indexBuffer);
    
    self.context = nil;
}


#pragma mark - Prepare Shaders

/* program 可是看做是由顶点着色器和片段着色器编译出来的小程序 prepare shaders 中的函数是对glsl进行编译和链接形成program */
bool createProgram(const char *vertexShader, const char *fragmentShader, GLuint *pProgram) {
    GLuint program, vertShader, fragShader;
    // Create shader program.
    program = glCreateProgram();
    
    const GLchar *vssource = (GLchar *)vertexShader;
    const GLchar *fssource = (GLchar *)fragmentShader;
    
    if (!compileShader(&vertShader,GL_VERTEX_SHADER, vssource)) {
        printf("Failed to compile vertex shader");
        return false;
    }
    
    if (!compileShader(&fragShader,GL_FRAGMENT_SHADER, fssource)) {
        printf("Failed to compile fragment shader");
        return false;
    }
    
    // Attach vertex shader to program.
    glAttachShader(program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(program, fragShader);
    
    // Link program.
    if (!linkProgram(program)) {
        printf("Failed to link program: %d", program);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (program) {
            glDeleteProgram(program);
            program = 0;
        }
        return false;
    }
    
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(program, fragShader);
        glDeleteShader(fragShader);
    }
    
    *pProgram = program;
    printf("Effect build success => %d \n", program);
    return true;
}


bool compileShader(GLuint *shader, GLenum type, const GLchar *source) {
    GLint status;
    
    if (!source) {
        printf("Failed to load vertex shader");
        return false;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    
#if Debug
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        printf("Shader compile log:\n%s", log);
        printf("Shader: \n %s\n", source);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return false;
    }
    
    return true;
}

bool linkProgram(GLuint prog) {
    GLint status;
    glLinkProgram(prog);
    
#if Debug
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        printf("Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return false;
    }
    
    return true;
}

bool validateProgram(GLuint prog) {
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        printf("Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
        return false;
    }
    
    return true;
}

@end
