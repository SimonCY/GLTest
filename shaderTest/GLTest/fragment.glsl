

precision highp float;

varying lowp vec4 fragColor;

uniform highp float elapsedTime;

void main(void) {
    
    
    highp float processedElapsedTime = elapsedTime;
    highp float intensity = (sin(processedElapsedTime) + 1.0) / 2.0;
 
    gl_FragColor = vec4(fragColor.x * (0.4 * abs(sin(processedElapsedTime)) + 0.6),fragColor.y * (0.4 * abs(cos(processedElapsedTime)) + 0.6) ,fragColor.z * (0.4 * abs(sin(processedElapsedTime)) + 0.6),1.0);// fragColor * intensity;
}

