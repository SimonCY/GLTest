//
//  CYGLViewController.h
//  GLTest
//
//  Created by RRTY on 17/1/11.
//  Copyright © 2017年 chenyan. All rights reserved.
//

#import <GLKit/GLKit.h>

@interface CYGLBaseViewController : GLKViewController

/* 着色器program */
@property (assign, nonatomic) GLuint shaderProgram;

/* 当前总时长 */
@property (assign, nonatomic) GLfloat elapsedTime;

/* 投影矩阵 */
@property (assign, nonatomic) GLKMatrix4 projectionMatrix;
/* 观察矩阵 */
@property (assign, nonatomic) GLKMatrix4 cameraMatrix;
/* 模型矩阵 */
@property (assign, nonatomic) GLKMatrix4 modelMatrix;

/* 重写此方法以更新矩阵操作   重写glkView:drawInRect 来进行绘制 */
- (void)update;

/* 为shader中的postition和color属性赋值 */
- (void)bindAttribs:(GLfloat *)ptr;

/* 在update中调用以更新三种矩阵数据到shader */
- (void)setNeedsUpdateMatrixInShaders;

@end
