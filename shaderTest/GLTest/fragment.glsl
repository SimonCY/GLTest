//片段着色器中声明变量必须声明变量的精度是 highp lowp mediup ，加上这句可以统一声明float类型变量的精度
precision highp float;

varying vec4 fragColor;

uniform highp float elapsedTime;

void main(void) {
    
    
    highp float processedElapsedTime = elapsedTime;
    highp float intensity = (sin(processedElapsedTime) + 1.0) / 2.0;
 
    gl_FragColor = vec4(fragColor.x * (0.4 * abs(sin(processedElapsedTime)) + 0.6),fragColor.y * (0.4 * abs(cos(processedElapsedTime)) + 0.6) ,fragColor.z * (0.4 * abs(sin(processedElapsedTime)) + 0.6),1.0);// fragColor * intensity;
}

