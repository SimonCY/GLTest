//
//  CYGLViewController.m
//  GLTest
//
//  Created by RRTY on 17/1/11.
//  Copyright © 2017年 chenyan. All rights reserved.
//

#import "CYGLViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <GLKit/GLKit.h>
#import <OpenGLES/ES2/glext.h>
#import "staticShip.h"



@interface CYGLViewController () <GLKViewControllerDelegate,GLKViewDelegate>{
    GLuint _vertexBuffer;
    GLuint _indexBuffer;
    float _rotationX;
    float _rotationY;
    
    float _curR;
    float _curG;
    float _curB;
    BOOL _increasing;
}

@property (nonatomic,strong) EAGLContext* context;
@property (nonatomic,strong) GLKBaseEffect* effect;
@property (nonatomic,strong) GLKView* glkView;

@property (assign, nonatomic) GLuint shaderProgram;

@end

@implementation CYGLViewController



- (void)loadView {
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    self.glkView = [[GLKView alloc] initWithFrame:[[UIScreen mainScreen]bounds]];
    self.glkView.context = self.context;
    self.view = self.glkView;
    self.glkView.delegate = self;
    self.delegate = self;
//        self.glkView.enableSetNeedsDisplay = NO;
    
    //-------------------相关设置-----------------
    /*GLKViewController在1秒内会多次调用你的draw方法，设置调用的次数来让GLKViewController知道你期待被调用的频率。当然，如果你的游戏花了很多时间对帧进行渲染，实际的调用次数将你设置的值。
     缺省值是30FPS。苹果的指导意见是把这个值设置成你的app能够稳定支持的帧率，以保持一致，看起来不卡。这个app非常简单，可以按照60FPS运行，所以我们设置成60FPS。
     和FYI一样（FYI是神马啊？），如果你想知道OS实际尝试调用你的update/draw方法的次数，可以检查只读属性framesPerSecond。
     */
    self.preferredFramesPerSecond = 30;
    
    //颜色格式
    self.glkView.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    //深度缓冲
    self.glkView.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    self.glkView.drawableStencilFormat = GLKViewDrawableStencilFormat8;
    
    //抗锯齿   以前对于每个像素，都会调用一次fragment shader（片段着色器），开启后会将像素区分成更小的单元，并在更细微的层面上多次调用fragment shader。之后它将返回的颜色合并，生成更光滑的几何边缘效果。(慎用，耗资源严重)
//    self.glkView.drawableMultisample = GLKViewDrawableMultisample4X;
    
    //添加手势
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panEvent:)];
    [self.view addGestureRecognizer:pan];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.title = @"openGLTest";

    [self setupShader];
 
}

- (void)dealloc {
    [self tearDownGL];
}

/**
 清除OpenGL缓存
 */
- (void)tearDownGL {
    
    [EAGLContext setCurrentContext:self.context];
    
 
    
    self.context = nil;
}

#pragma mark - touch
- (void)panEvent:(UIPanGestureRecognizer *)gesture {
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan: {
            
            break;
        }
        case UIGestureRecognizerStateChanged: {
            
            CGPoint velocity = [gesture velocityInView:gesture.view];
            _rotationX += velocity.y / 100.0;
            _rotationY += velocity.x / 100.0;
            
//            if (_rotationX >= 90) {
//                _rotationX = 90;
//            }
//            if (_rotationX <= 0) {
//                _rotationX = 0;
//            }
            
            NSLog(@"rotaX:%f \n rotaY:%f",_rotationX,_rotationY);
            
            break;
        }
        case UIGestureRecognizerStateCancelled:
            
            break;
        case UIGestureRecognizerStateEnded:
            
            break;
            
        default:
            break;
    }
}

#pragma mark - glkViewControllerDelegate
- (void)glkViewControllerUpdate:(GLKViewController *)controller {
    /*  
     
     GLKMatrix4MakePerspective是透视投影变换
     GLKMatrix4Translate是平移变换
     GLKMatrix4Rotate是旋转变换
     
     modelViewMatrix = GLKMatrix4RotateX(modelViewMatrix, self.mDegreeX);
     modelViewMatrix = GLKMatrix4RotateY(modelViewMatrix, self.mDegreeY);
     modelViewMatrix = GLKMatrix4RotateZ(modelViewMatrix, self.mDegreeZ);
     以上三者分别是绕x y z 三轴变换
     
     */
//    if (_increasing) {
//        _curRed += 1.0 * controller.timeSinceLastUpdate;
//    } else {
//        _curRed -= 1.0 * controller.timeSinceLastUpdate;
//    }
//    if (_curRed >= 1.0) {
//        _curRed = 1.0;
//        _increasing = NO;
//    }
//    if (_curRed <= 0.0) {
//        _curRed = 0.0;
//        _increasing = YES;
//    }
    
    glUseProgram(self.shaderProgram);
    //计算glkView的方向比例
    float aspect = fabs(self.view.bounds.size.width / self.view.bounds.size.height);
    //第一个参数是镜头视角  第二个参数是方向比例  第三四个参数代表可见范围，设置近平面距离眼睛4单位，远平面10单位  超过这个范围的图像将不显示
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(90.0f), aspect, 0.1f, 15.0f);
    //设置效果转化属性的投影矩阵
    GLuint projectionMatrixUniformLocation = glGetUniformLocation(self.shaderProgram, "projectionMatrix");
    glUniformMatrix4fv(projectionMatrixUniformLocation, 1, 0, projectionMatrix.m);
    
    //创建沿z轴后移6个单位的矩阵   默认是0  也就是默认的（0，0，0）点是在当前屏幕中心
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -6.0f);
    //        _rotation += 90 * self.timeSinceLastUpdate;
    //进行旋转
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, GLKMathDegreesToRadians(_rotationX), 1, 0, 0);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, GLKMathDegreesToRadians(_rotationY), 0, 1, 0);
    GLuint modelViewMatrixUniformLocation = glGetUniformLocation(self.shaderProgram, "modelMatrix");
    glUniformMatrix4fv(modelViewMatrixUniformLocation, 1, 0, modelViewMatrix.m);
    
    //前三个参数代表眼睛坐标   中间三个参数代表注视点坐标   后三个参数代表正方向坐标
    self.effect.transform.modelviewMatrix = GLKMatrix4MakeLookAt(6, 6, 6, 0, 0, 0, 0, 1, 0);

    
}

#pragma mark - glkViewDelegate
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    
    //清空和渲染背景 
    glClearColor(1, 1, 1, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    glClear(GL_DEPTH_BUFFER_BIT);
    glClear(GL_STENCIL_BUFFER_BIT);

    glUseProgram(self.shaderProgram);
    
    [self drawSthWithOpenGLES];
}


/** 初始化  */
- (void)drawSthWithOpenGLES {
    //发送第一个“GL”指令：激活“深度检测”。
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_BLEND);
    //剔除背面显示（当三角形的背面朝向观察者时显示透明）
    //    glEnable(GL_CULL_FACE);
    
    static GLfloat triangleData[18] = {
        0,      0.5f,  0,  1,  0,  0, // x, y, z, r, g, b,每一行存储一个点的信息，位置和颜色
        -0.5f, -0.5f,  0,  0,  1,  0,
        0.5f,  -0.5f,  0,  0,  0,  1,
    };
    
 
    GLuint positionAttribLocation = glGetAttribLocation(self.shaderProgram, "position");
    glEnableVertexAttribArray(positionAttribLocation);
    GLuint colorAttribLocation =glGetAttribLocation(self.shaderProgram, "color");
    glEnableVertexAttribArray(colorAttribLocation);
    
    glVertexAttribPointer(positionAttribLocation, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(GLfloat), (const GLvoid *) triangleData);
    glVertexAttribPointer(colorAttribLocation, 4, GL_FLOAT, GL_FALSE, 6 * sizeof(GLfloat), (const GLvoid *) triangleData + 3 * sizeof(GLfloat));
    
    /*  draw
     第一个参数定义了绘制定点的方法，GL_TRIANGLES是最通用的
     第二个参数是要渲染的顶点的数量
     第三个参数是所以数组中每个索引的数据类型。
     最后一个参数应该是一个指向索引的指针。
     */
    glDrawArrays(GL_TRIANGLES, 0, 3);
//    glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);
}

#pragma mark - loadShader

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

#pragma mark - Prepare Shaders
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
