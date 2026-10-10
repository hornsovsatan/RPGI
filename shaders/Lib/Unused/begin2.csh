#version 430


#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"

#include "/Lib/Unused/wssCommon.glsl"


const ivec3 workGroups = ivec3(128, 256, 1);
layout (local_size_x = 16, local_size_y = 8) in;

layout (rgba32f) writeonly uniform image2D img_rippleY2D;

uniform sampler2D rippleX2D;
uniform sampler2D rippleY2D;
uniform sampler2D rippleXY2D;


#define FETCH(uv) texelFetch(rippleX2D, clamp(uv, ivec2(0), ivec2(GridSize-1.0)), 0).r

void main(){
    ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
    vec2 uv0 = vec2(uv) + 0.5;

    if(uv0.x > GridSize || uv0.y > GridSize) return;

    vec4 col = vec4(0.0);
    
    float lowp3[4] = float[4](5.0/16.0, 15.0/64.0, 3.0/32.0, 1.0/64.0);   
    float lowp7[8] = float[8](429.0/2048.0, 3003.0/16384.0, 1001.0/8192.0, 1001.0/16384.0, 91.0/4096.0, 91.0/16384.0, 7.0/8192.0, 1.0/16384.0);   
    float lapl7[8] = float[8](3.22, -1.9335988099476562, 0.4384577800334821, -0.1637450351359609, 0.07015324480535713, -0.02963974593026339, 0.010609595665007715, -0.0022370294899667453);   

    float lowpass3  = 0.0;
    float lowpass7  = 0.0;
    float laplacian = 0.0;
    
    for(int x = -7; x <= 7; ++x)
    {
        float f = FETCH(uv + ivec2(x, 0));
    
        int i = abs(x);

        lowpass3  += f * (i < 4 ? lowp3[i] : 0.0);
        lowpass7  += f * lowp7[i];
        laplacian += f * lapl7[i];
    }

    float f0 = FETCH(uv);
    
    col = vec4(lowpass3, lowpass7, f0, laplacian);


	imageStore(img_rippleY2D, uv, col);
}