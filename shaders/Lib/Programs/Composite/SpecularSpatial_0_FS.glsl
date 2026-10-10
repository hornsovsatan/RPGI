

#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


/* RENDERTARGETS: 8 */
layout(location = 0) out vec4 framebuffer_altOutput;

//layout(r32f) uniform image2D img_prevDepth2D;


ivec2 texelCoord = ivec2(gl_FragCoord.xy);
vec2 texCoord = gl_FragCoord.xy * UNIFORM_PIXEL_SIZE;


#include "/Lib/GbufferData.glsl"
#include "/Lib/Uniform/GbufferTransforms.glsl"
#include "/Lib/BasicFunctions/TemporalNoise.glsl"

#define SPATIAL_FILTER_ORDER 0
#include "/Lib/PathTracing/Denoiser/SpecularSpatialFilter.glsl"


void main(){
	#ifdef RENDERING_MODE
		if(rtwDiscardRefresh){
			framebuffer_altOutput = texelFetch(FBTEX_ALT_OUTPUT, texelCoord, 0);
			return;
		}
	#endif

	float depth = texelFetch(depthtex0, texelCoord, 0).x;

	#ifdef LOD_RENDERING
		if (depth == 1.0) depth = -texelFetch(LOD_DEPTH_TEX_0, texelCoord, 0).x;
	#endif

	//imageStore(img_prevDepth2D, texelCoord, vec4(depth, 0.0, 0.0, 0.0));

	//if (abs(depth) == 1.0) discard;

	vec4 reflection = texelFetch(FBTEX_SPECULAR_TEMPORAL, texelCoord, 0);
    if (reflection.a == 0.0){
		framebuffer_altOutput = vec4(0.0);
	}else if (reflection.a < -6e4){
		framebuffer_altOutput = reflection;
	}else{
		framebuffer_altOutput = SpecularSpatialFilter(reflection, depth);
	}
}
