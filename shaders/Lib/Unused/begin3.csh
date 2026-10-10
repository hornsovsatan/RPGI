#version 430


#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"

#include "/Lib/Unused/wssCommon.glsl"


const ivec3 workGroups = ivec3(128, 256, 1);
layout (local_size_x = 16, local_size_y = 8) in;

layout (rg32f) writeonly uniform image2D img_rippleXY2D;

uniform sampler2D rippleX2D;
uniform sampler2D rippleY2D;
uniform sampler2D rippleXY2D;

#define FETCH(uv) texelFetch(rippleX2D, clamp(uv, ivec2(0), ivec2(GridSize-1.0)), 0).r

void main(){
    ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
    vec2 uv0 = vec2(uv) + 0.5;

    if(uv0.x > GridSize || uv0.y > GridSize) return;

    if(uv0.x > GridSize || uv0.y > GridSize) return;
    
    vec4 col = vec4(0.0);
    
    // ======================================================= GENERALIZED CUBIC BSPLINE =======================================================
    
    float kernD0[3];
    float kernD1[3];
    
    kernD0[0] = 2.0/3.0; kernD0[1] = 1.0/6.0; kernD0[2] = 0.0;
    kernD1[0] =     0.0; kernD1[1] =    -0.5; kernD1[2] = 0.0;
    
    float sw;// side lobes weight

    sw = 0.0;// cubic BSpline
    
   #if 0
   
    sw = 0.25;// similar to 1/3 but less ringing
    
   #elif 0
   
    sw = 1.0/3.0;// kernD0[0] == 1
    
   #elif 0
    
    sw = 0.186605;// max abs derivative == 1
    
   #elif 0
    
    sw = 1.0/6.0;// maximaly flat pass band
    
   #elif 1
    
    sw = -0.25;// spectrum falls off to 0 at Nyquist frequency
    
   #endif
    
    // add a pair of side lobes:
    kernD0[0] += 1.0 * sw; kernD0[1] += -1.0/3.0 * sw; kernD0[2] += -1.0/6.0 * sw;
    	                   kernD1[1] += -1.0     * sw; kernD1[2] +=  0.5     * sw;
    
    int r = sw == 0.0 ? 1 : 2;
    for(int j = -r; j <= r; ++j)
    for(int i = -r; i <= r; ++i)
    {
    	float f = FETCH(uv + ivec2(i, j));
        
        int x = abs(i);
        int y = abs(j);
        
        float kAx = kernD0[x];
        float kAy = kernD0[y];
        
        float kBx = kernD1[x] * (i > 0 ? -1.0 : 1.0);
        float kBy = kernD1[y] * (j > 0 ? -1.0 : 1.0);
        
        col += f * vec4(kBx * kAy, 
                        kAx * kBy, 
                        kBx * kBy,
                        kAx * kAy);
    }


	imageStore(img_rippleXY2D, uv, col);
}