

#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


/* RENDERTARGETS: 6 */
layout(location = 0) out vec4 framebuffer_mainOutput;


ivec2 texelCoord = ivec2(gl_FragCoord.xy);
vec2 texCoord = gl_FragCoord.xy * UNIFORM_PIXEL_SIZE;


#include "/Lib/GbufferData.glsl"
#include "/Lib/Uniform/GbufferTransforms.glsl"
#include "/Lib/BasicFunctions/TemporalNoise.glsl"

#define SPATIAL_FILTER_ORDER 5
#include "/Lib/PathTracing/Denoiser/DiffuseSpatialFilter.glsl"


void main(){
	#ifdef RENDERING_MODE
		if(rtwDiscardRefresh) discard;
	#endif

	float depth = uintBitsToFloat(texelFetch(depthtexS, texelCoord, 0).x);

	#ifdef LOD_RENDERING
		if (depth == 1.0) depth = -texelFetch(LOD_DEPTH_TEX_1, texelCoord, 0).x;
	#endif

    if (abs(depth) == 1.0) discard;
		
	framebuffer_mainOutput = DiffuseSpatialFilter(depth);
}
