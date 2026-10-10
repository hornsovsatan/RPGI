#version 430


#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"

#include "/Lib/Unused/wssCommon.glsl"


const ivec3 workGroups = ivec3(8, 960, 1);
layout (local_size_x = 16, local_size_y = 8) in;

layout (rgba8) writeonly uniform image2D img_ripple2D;

uniform sampler2D rippleX2D;
uniform sampler2D rippleY2D;
uniform sampler2D rippleXY2D;


void main(){
    ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
    uv.y = 7679 - uv.y;

    int fc = frameCounter % afi;
    if ((uv.y >> 7) * fi != fc) return;   

    ivec2 ruv = ivec2(uv.x + 508, (uv.y & 127) + 508);

    vec2 n = texelFetch(rippleXY2D, ruv, 0).xy;

	imageStore(img_ripple2D, ivec2(gl_GlobalInvocationID.xy), vec4(normalize(n) * 0.5 + 0.5, length(n) * 5.0, 0.0));
}