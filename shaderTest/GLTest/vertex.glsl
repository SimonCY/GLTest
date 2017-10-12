attribute vec4 position;
attribute vec4 color;

varying vec4 fragColor;

uniform float elapsedTime;
uniform mat4 projectionMatrix;
uniform mat4 cameraMatrix;
uniform mat4 modelMatrix;

void main(void) {
    fragColor = color;
    gl_Position = position * modelMatrix;
    
}

