

#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


/* RENDERTARGETS: 8 */
layout(location = 0) out vec4 framebuffer_altOutput;


ivec2 texelCoord = ivec2(gl_FragCoord.xy);
vec2 texCoord = gl_FragCoord.xy * UNIFORM_PIXEL_SIZE;


#include "/Lib/GbufferData.glsl"
#include "/Lib/Uniform/GbufferTransforms.glsl"
#include "/Lib/BasicFunctions/TemporalNoise.glsl"

#define SPATIAL_FILTER_ORDER 2
#include "/Lib/PathTracing/Denoiser/SpecularSpatialFilter.glsl"


void main(){
	#ifdef RENDERING_MODE
		if(rtwDiscardRefresh) discard;
	#endif

	vec4 reflection = texelFetch(FBTEX_ALT_OUTPUT, texelCoord, 0);
    if (reflection.a < -6e4) discard;

	float depth = texelFetch(depthtex0, texelCoord, 0).x;
	framebuffer_altOutput = SpecularSpatialFilter(reflection, depth);
}
