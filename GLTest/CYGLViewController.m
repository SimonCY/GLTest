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

    _increasing = YES;
    _curR = 1.0;
    _curG = 1.0;
    _curB = 1.0;
    

    [self setupGL];
    
    
}

- (void)dealloc {
    [self tearDownGL];
}
/**
 初始化
 */
- (void)setupGL {
    
    
    //1.设置的当前上下文（防止在实际操作中上下文切换带来的错误）
    [EAGLContext setCurrentContext:self.context];
    
    //发送第一个“GL”指令：激活“深度检测”。
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_BLEND);
    //剔除背面显示（当三角形的背面朝向观察者时显示透明）
//    glEnable(GL_CULL_FACE);
    
    //------OpenGL的缓冲由一些标准的函数（glGenBuffers, glBindBuffer, glBufferData, glVertexAttribPointer）来创建、绑定、填充和配置；
    
    // 申请一个标识符Generate 1 buffer, put the resulting identifier in vertexbuffer
    glGenBuffers(1, &_vertexBuffer);
    // 把标识符绑定到GL_ARRAY_BUFFER上  The following commands will talk about our 'vertexbuffer' buffer
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    // 把顶点数据从cpu内存复制到gpu内存  Give our vertices to OpenGL.
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices), Vertices, GL_STATIC_DRAW);
    
    glGenBuffers(1, &_indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);
    
    
    //  1rst attribute buffer : vertices
    /*    glVertexAttribPointer
     第一个参数定义要设置的属性名。我们就使用预定义的GLKit常量。
     第二个参数定义了每个顶点有多少个值。如果你往回看看顶点的结构，你会看到对于位置，有3个浮点值(x, y, z)，对于颜色有4个浮点值(r, g, b, a)。
     第三个参数定义了每个值的类型-对于位置和颜色都是浮点型。
     第四个参数通常都是false。
     第五个参数是跨度（stride）的大小，简单点说就是包含每个顶点的数据结构的大小。所以我们可以简单地传进sizeof(Vertex)，让编译器帮助我们计算它。
     最后一个参数是在数据结构中要获得此数据的偏移量。我们使用方便的offsetof操作来找到结构体中一个具体属性（就是从Vertex数据结构中，找到“位置”信息的偏移量）。
     所以现在我们为GLKBaseEffect传递了位置和颜色数据，还剩下一步了：
     */
    
    //开启对应的顶点属性
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    //设置合适的格式从buffer里面读取数据
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, Position));
    
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, Normal));
    
    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, Color));
    
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, texture));
    
    
    //2.创建着色器
    self.effect = [[GLKBaseEffect alloc] init];
    //设置模型中的颜色缓存可用
//    self.effect.colorMaterialEnabled = GL_TRUE;
    
    
    //2.1创建光源并设置属性
    self.effect.lightingType = GLKLightingTypePerVertex;
    
    self.effect.light0.enabled = GL_TRUE;
    //光源位置向量
    self.effect.light0.position = GLKVector4Make(0, 2, 0, 1);
    //设置环境光线（多个光源的光是叠加的）比较耗费资源  一般做法是直接让物体直接发光
//    self.effect.light0.ambientColor = GLKVector4Make(0.7, 0.7, 0.7, 1);
    //漫反射光的颜色
    self.effect.light0.diffuseColor = GLKVector4Make(0.75f, 0.75f, 0.75f, 1.0f);

    
    
    self.effect.light1.enabled = GL_TRUE;
    //光源位置向量
    self.effect.light1.position = GLKVector4Make(0, -3, -7, 1);
    //漫反射光的颜色
    self.effect.light1.diffuseColor = GLKVector4Make(0.75f, 0.75f, 0.75f, 1.0f);

    
    
    
    //2.2设置材料属性
    //材料反光度
//    self.effect.material.shininess = 0.5;
    //漫反射光颜色
//    self.effect.material.diffuseColor = GLKVector4Make(0.8, 0.8, 0.8, 1);
    //镜面高光
//    self.effect.material.specularColor = GLKVector4Make(0.8, 0.8, 0.8, 1.0f);
    //材料发射光
    self.effect.material.emissiveColor = GLKVector4Make(0.35, 0.35, 0.35, 1);

    //设置光源颜色
    self.effect.useConstantColor = GL_TRUE;
    self.effect.constantColor = GLKVector4Make(1, 1, 1, 1);
    
    //3.纹理贴图
    
    NSString* filePath0 = [[NSBundle mainBundle] pathForResource:@"texture03.jpg" ofType:nil];
    NSDictionary* options0 = [NSDictionary dictionaryWithObjectsAndKeys:@(1), GLKTextureLoaderOriginBottomLeft, nil];//GLKTextureLoaderOriginBottomLeft 纹理坐标系是相反的   避免渲染出的纹理上下颠倒
    GLKTextureInfo* textureInfo0 = [GLKTextureLoader textureWithContentsOfFile:filePath0 options:options0 error:nil];
    self.effect.texture2d0.enabled = GL_TRUE;
    self.effect.texture2d0.name = textureInfo0.name;
    self.effect.texture2d0.target = GLKTextureTarget2D;
    self.effect.texture2d0.envMode = GLKTextureEnvModeModulate;

//mipmap技术：线性过滤和各向异性过滤都存在一个共同的问题。那就是如果从远处观察纹理，只对4个纹素作混合显得不够。实际上，如果3D模型位于很远的地方，屏幕上只看得见一个像素，那计算平均值得出最终颜色值时，图像所有的纹素都应该考虑在内。可以选用nearest、linear、anisotropic等任意一种滤波方式来对mipmap采样。
//    // When MAGnifying the image (no bigger mipmap available), use LINEAR filtering
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);




}

/**
 清除OpenGL缓存
 */
- (void)tearDownGL {
    
    [EAGLContext setCurrentContext:self.context];
    
    self.effect = nil;
    
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteBuffers(1, &_indexBuffer);
    
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
    //计算glkView的方向比例
    float aspect = fabs(self.view.bounds.size.width / self.view.bounds.size.height);
    //第一个参数是镜头视角  第二个参数是方向比例  第三四个参数代表可见范围，设置近平面距离眼睛4单位，远平面10单位  超过这个范围的图像将不显示
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(90.0f), aspect, 0.1f, 15.0f);
    //设置效果转化属性的投影矩阵
    self.effect.transform.projectionMatrix = projectionMatrix;
    
    
    //创建沿z轴后移6个单位的矩阵   默认是0  也就是默认的（0，0，0）点是在当前屏幕中心
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -6.0f);
    //        _rotation += 90 * self.timeSinceLastUpdate;
    //进行旋转
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, GLKMathDegreesToRadians(_rotationX), 1, 0, 0);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, GLKMathDegreesToRadians(_rotationY), 0, 1, 0);
    self.effect.transform.modelviewMatrix = modelViewMatrix;
    
    
    //前三个参数代表眼睛坐标   中间三个参数代表注视点坐标   后三个参数代表正方向坐标
//    self.effect.transform.modelviewMatrix = GLKMatrix4MakeLookAt(6, 6, 6, 0, 0, 0, 0, 1, 0);

    
}

#pragma mark - glkViewDelegate
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    
    //清空和渲染背景 
    glClearColor(_curR, _curG, _curB, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    glClear(GL_DEPTH_BUFFER_BIT);
    glClear(GL_STENCIL_BUFFER_BIT);

    //该操作是同步的 必须在drawRect方法中进行
    [self.effect prepareToDraw];
    


    /*  draw
        第一个参数定义了绘制定点的方法，GL_TRIANGLES是最通用的
        第二个参数是要渲染的顶点的数量
        第三个参数是所以数组中每个索引的数据类型。
        最后一个参数应该是一个指向索引的指针。
     */
    glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);
    
    
    
}

//Image和buffer互转
/*
- (CVPixelBufferRef) pixelBufferFromCGImage: (CGImageRef) image
{
    NSDictionary *options = @{
                              (NSString*)kCVPixelBufferCGImageCompatibilityKey : @YES,
                              (NSString*)kCVPixelBufferCGBitmapContextCompatibilityKey : @YES,
                              (NSString*)kCVPixelBufferIOSurfacePropertiesKey: [NSDictionary dictionary]
                              };
    CVPixelBufferRef pxbuffer = NULL;
    
    CGFloat frameWidth = CGImageGetWidth(image);
    CGFloat frameHeight = CGImageGetHeight(image);
    
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,
                                          frameWidth,
                                          frameHeight,
                                          kCVPixelFormatType_32BGRA,
                                          (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef context = CGBitmapContextCreate(pxdata,
                                                 frameWidth,
                                                 frameHeight,
                                                 8,
                                                 CVPixelBufferGetBytesPerRow(pxbuffer),
                                                 rgbColorSpace,
                                                 (CGBitmapInfo)kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    CGContextConcatCTM(context, CGAffineTransformIdentity);
    CGContextDrawImage(context, CGRectMake(0,
                                           0,
                                           frameWidth,
                                           frameHeight),
                       image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
    
    //    NSDictionary *options = @{
    //                              (NSString*)kCVPixelBufferCGImageCompatibilityKey : @YES,
    //                              (NSString*)kCVPixelBufferCGBitmapContextCompatibilityKey : @YES,
    //                              (NSString*)kCVPixelBufferIOSurfacePropertiesKey: [NSDictionary dictionary]
    //                              };
    //
    //
    //    CVPixelBufferRef pxbuffer = NULL;
    //
    //    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, CGImageGetWidth(image),
    //                                          CGImageGetHeight(image), kCVPixelFormatType_32BGRA, (__bridge CFDictionaryRef)options,
    //                                          &pxbuffer);
    //    if (status!=kCVReturnSuccess) {
    //        NSLog(@"Operation failed");
    //    }
    //
    //    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    //
    //    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    //    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    //
    //    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    //    CGContextRef context = CGBitmapContextCreate(pxdata, CGImageGetWidth(image),
    //                                                 CGImageGetHeight(image), 8, 4*CGImageGetWidth(image), rgbColorSpace,
    //                                                 kCGImageAlphaNoneSkipFirst);
    //    NSParameterAssert(context);
    //
    //    CGContextConcatCTM(context, CGAffineTransformMakeRotation(0));
    //    CGAffineTransform flipVertical = CGAffineTransformMake( 1, 0, 0, -1, 0, CGImageGetHeight(image) );
    //    CGContextConcatCTM(context, flipVertical);
    //    CGAffineTransform flipHorizontal = CGAffineTransformMake( -1.0, 0.0, 0.0, 1.0, CGImageGetWidth(image), 0.0 );
    //    CGContextConcatCTM(context, flipHorizontal);
    //
    //    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image),
    //                                           CGImageGetHeight(image)), image);
    //    CGColorSpaceRelease(rgbColorSpace);
    //    CGContextRelease(context);
    //
    //    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    //    return pxbuffer;
}

- (UIImage *)imageFromPixelBuffer:(CVPixelBufferRef)pixelBufferRef {
    CVImageBufferRef imageBuffer =  pixelBufferRef;
    
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    size_t bufferSize = CVPixelBufferGetDataSize(imageBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 0);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, baseAddress, bufferSize, NULL);
    
    CGImageRef cgImage = CGImageCreate(width, height, 8, 32, bytesPerRow, rgbColorSpace, kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrderDefault, provider, NULL, true, kCGRenderingIntentDefault);
    
    
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    
    CGImageRelease(cgImage);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(rgbColorSpace);
    
    //    NSData* imageData = UIImageJPEGRepresentation(image, 1.0);
    //    image = [UIImage imageWithData:imageData];
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    return image;
}

*/
@end
