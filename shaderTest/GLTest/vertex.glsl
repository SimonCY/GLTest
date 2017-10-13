attribute vec4 position;
attribute vec4 color;

varying vec4 fragColor;

uniform float elapsedTime;

//投影矩阵
uniform mat4 projectionMatrix;
//观察矩阵
uniform mat4 cameraMatrix;
//模型矩阵
uniform mat4 modelMatrix;

//正交投影矩阵
uniform mat4 orthMatrix;

void main(void) {
    
    fragColor = color;
    
//    float angle = elapsedTime * 1.0;
//    float xPos = position.x * cos(angle) - position.y * sin(angle);
//    float yPos = position.x * sin(angle) + position.y * cos(angle);
//    gl_Position = vec4(xPos,yPos,position.z,1);
    
    //3D变换的顺序必须是先旋转再平移再透视或者正交投影 即： projectionMatrix * cameraMatrix * modelMatrix  否则得到的结果是错误的
    mat4 mvp = projectionMatrix * cameraMatrix * modelMatrix;
    gl_Position = mvp * position;
    
    gl_PointSize = 25.0;
}




