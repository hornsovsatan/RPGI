

#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


uniform sampler2D prevDepth2D;


/* RENDERTARGETS: 11 */
layout(location = 0) out vec4 framebuffer_specularTemporal;


ivec2 texelCoord = ivec2(gl_FragCoord.xy);
vec2 texCoord = gl_FragCoord.xy * UNIFORM_PIXEL_SIZE;


#include "/Lib/GbufferData.glsl"
#include "/Lib/Uniform/GbufferTransforms.glsl"
#include "/Lib/BasicFunctions/TemporalNoise.glsl"

#include "/Lib/PathTracing/Denoiser/SpecularTemporalFilter.glsl"


void main(){
	#ifdef RENDERING_MODE
		if(rtwDiscardRefresh) discard;
	#endif

	float depth = texelFetch(depthtex0, texelCoord, 0).x;

	#ifdef LOD_RENDERING
		if (depth == 1.0) depth = -texelFetch(LOD_DEPTH_TEX_0, texelCoord, 0).x;
	#endif

	if (abs(depth) == 1.0) discard;

	vec4 currData = texelFetch(FBTEX_ALT_OUTPUT, texelCoord, 0);
	if (currData.a <= 0.0){
		framebuffer_specularTemporal = currData;
	}else{
		framebuffer_specularTemporal = SpecularTemporalFilter(currData);
	}
}
