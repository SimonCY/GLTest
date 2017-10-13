//
//  ViewController.m
//  GLTest
//
//  Created by DeepAI on 2017/10/13.
//  Copyright © 2017年 chenyan. All rights reserved.
//

#import "ViewController.h"

@interface ViewController(){
    
    float _rotationX;
    float _rotationY;
}

@end

@implementation ViewController

#pragma mark - system

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //添加手势
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panEvent:)];
    [self.view addGestureRecognizer:pan];
}


#pragma mark - gesture event

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

#pragma mark - update

- (void)update {
    [super update];
    
    /* 1.模型矩阵：旋转、平移
     注意： 3d变换的顺序必须是先旋转再平移，最后执行透视或正交投影
     GLKMatrix4Multiply(translateMatrix, rotateMatrix)函数中translateMatrix在前代表先旋转  后平移
     */
    GLKMatrix4 modelMatrix = GLKMatrix4Identity;
    //旋转变换
    GLKMatrix4 rotateXMatrix = GLKMatrix4MakeRotation(GLKMathDegreesToRadians(_rotationX), 1, 0, 0);
    GLKMatrix4 rotateYMatrix = GLKMatrix4MakeRotation(GLKMathDegreesToRadians(_rotationY), 0, 1, 0);
    //合并旋转变换
    GLKMatrix4 rotateMatrix = GLKMatrix4Multiply(rotateXMatrix, rotateYMatrix);
    //平移变换
    GLKMatrix4 translateMatrix = GLKMatrix4MakeTranslation( 0.0, 0.0, -1.0);
    //合并平移、旋转变换
    modelMatrix = GLKMatrix4Multiply(translateMatrix, rotateMatrix);
    //将旋转、平移matrix传递给shader
    GLuint modelViewMatrixUniformLocation = glGetUniformLocation(self.shaderProgram, "modelMatrix");
    glUniformMatrix4fv(modelViewMatrixUniformLocation, 1, 0, modelMatrix.m);
    
    
    // 2.投影：投影常见的类型有透视投影和正交投影
    /* 2.1 透视投影
     第一个参数是镜头视角
     第二个参数是方向比例
     第三、四个参数代表可见范围，设置近平面距离眼睛4单位，远平面10单位  超过这个范围的图像将不显示
     */
    float aspect =  self.view.frame.size.width / self.view.frame.size.height;
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(90.0f), aspect, 0.1f, 100.f);
    //将透视投影matrix传递给shader
    GLuint projectionMatrixUniformLocation = glGetUniformLocation(self.shaderProgram, "projectionMatrix");
    glUniformMatrix4fv(projectionMatrixUniformLocation, 1, 0, projectionMatrix.m);
    
    
    /* 2.2.正交投影
     属于平行投影的一种   在正交投影范围内，人眼看到的物体不随着距离的远近生大小的改变
     */
    //    GLKMatrix4 rotateMatrix = GLKMatrix4MakeRotation(self.elapsedTime, 0, 1, 0);
    //    float viewWidth = self.glkView.frame.size.width;
    //    float viewHeight = self.glkView.frame.size.height;
    //    GLKMatrix4 orthMatrix = GLKMatrix4MakeOrtho(-viewWidth/2, viewWidth/2, -viewHeight / 2, viewHeight/2, -10, 10);
    //    //正交投影下我们的模型只有1像素  所以这里为了查看将其放大200倍
    //    GLKMatrix4 scaleMatrix = GLKMatrix4MakeScale(200, 200, 200);
    //    GLKMatrix4 scaleAndRotateMatrix = GLKMatrix4Multiply(scaleMatrix, rotateMatrix);
    //    orthMatrix = GLKMatrix4Multiply(orthMatrix, scaleAndRotateMatrix);
    //    GLuint orthMatrixUniformLocation = glGetUniformLocation(self.shaderProgram, "orthMatrix");
    //    glUniformMatrix4fv(orthMatrixUniformLocation, 1, 0, orthMatrix.m);
    
    
    /* 3.摄像机
     前三个参数代表眼睛坐标
     中间三个参数代表注视点坐标
     后三个参数代表正方向坐标
     */
    float varyingFactor = sin(self.elapsedTime);
    GLKMatrix4 cameraMatrix = GLKMatrix4MakeLookAt(0, varyingFactor,0.1,0 ,0,  -1, 0, 1, 0);
    GLuint cameraMatrixUniformLocation = glGetUniformLocation(self.shaderProgram, "cameraMatrix");
    glUniformMatrix4fv(cameraMatrixUniformLocation, 1, 0, cameraMatrix.m);
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    [super glkView:view drawInRect:rect];
    
    [self drawTriangle];
}

#pragma mark - draw triangle

- (void)drawTriangle {
    
    static GLfloat triangleData[18] = {
        0,      0.5f,  0,  1,  0,  0, // x, y, z, r, g, b,每一行存储一个点的信息，位置和颜色
        -0.5f, -0.5f,  0,  0,  1,  0,
        0.5f,  -0.5f,  0,  0,  0,  1,
    };
    
    [self bindAttribs:triangleData];
    
    //画线时可以设置线宽
    glLineWidth(10);
    
    /*  draw
     第一个参数定义了绘制定点的方法，GL_TRIANGLES是最通用的
     第二个参数是要渲染的顶点的数量
     第三个参数是所以数组中每个索引的数据类型。
     最后一个参数应该是一个指向索引的指针。
     */
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 3);
    //    glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);
}

#pragma mark - draw cube

- (void)drawCube {
    [self drawXPlanes];
    [self drawYPlanes];
    [self drawZPlanes];
}

- (void)drawXPlanes {
    static GLfloat triangleData[] = {
        // X轴0.5处的平面
        0.5,  -0.5,    0.5f, 1,  0,  0,
        0.5,  -0.5f,  -0.5f, 1,  0,  0,
        0.5,  0.5f,   -0.5f, 1,  0,  0,
        0.5,  0.5,    -0.5f, 1,  0,  0,
        0.5,  0.5f,    0.5f, 1,  0,  0,
        0.5,  -0.5f,   0.5f, 1,  0,  0,
        // X轴-0.5处的平面
        -0.5,  -0.5,    0.5f, 1,  0,  0,
        -0.5,  -0.5f,  -0.5f, 1,  0,  0,
        -0.5,  0.5f,   -0.5f, 1,  0,  0,
        -0.5,  0.5,    -0.5f, 1,  0,  0,
        -0.5,  0.5f,    0.5f, 1,  0,  0,
        -0.5,  -0.5f,   0.5f, 1,  0,  0,
    };
    [self bindAttribs:triangleData];
    glDrawArrays(GL_TRIANGLES, 0, 12);
}

- (void)drawYPlanes {
    static GLfloat triangleData[] = {
        -0.5,  0.5,  0.5f, 0,  1,  0,
        -0.5f, 0.5, -0.5f, 0,  1,  0,
        0.5f, 0.5,  -0.5f, 0,  1,  0,
        0.5,  0.5,  -0.5f, 0,  1,  0,
        0.5f, 0.5,   0.5f, 0,  1,  0,
        -0.5f, 0.5,  0.5f, 0,  1,  0,
        -0.5, -0.5,   0.5f, 0,  1,  0,
        -0.5f, -0.5, -0.5f, 0,  1,  0,
        0.5f, -0.5,  -0.5f, 0,  1,  0,
        0.5,  -0.5,  -0.5f, 0,  1,  0,
        0.5f, -0.5,   0.5f, 0,  1,  0,
        -0.5f, -0.5,  0.5f, 0,  1,  0,
    };
    [self bindAttribs:triangleData];
    glDrawArrays(GL_TRIANGLES, 0, 12);
}

- (void)drawZPlanes {
    static GLfloat triangleData[] = {
        -0.5,   0.5f,  0.5,   0,  0,  1,
        -0.5f,  -0.5f,  0.5,  0,  0,  1,
        0.5f,   -0.5f,  0.5,  0,  0,  1,
        0.5,    -0.5f, 0.5,   0,  0,  1,
        0.5f,  0.5f,  0.5,    0,  0,  1,
        -0.5f,   0.5f,  0.5,  0,  0,  1,
        -0.5,   0.5f,  -0.5,   0,  0,  1,
        -0.5f,  -0.5f,  -0.5,  0,  0,  1,
        0.5f,   -0.5f,  -0.5,  0,  0,  1,
        0.5,    -0.5f, -0.5,   0,  0,  1,
        0.5f,  0.5f,  -0.5,    0,  0,  1,
        -0.5f,   0.5f,  -0.5,  0,  0,  1,
    };
    [self bindAttribs:triangleData];
    glDrawArrays(GL_TRIANGLES, 0, 12);
}

@end
