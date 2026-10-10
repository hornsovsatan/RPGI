

#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


/* RENDERTARGETS: 6 */
layout(location = 0) out vec4 framebuffer_mainOutput;

layout(rgba8) writeonly uniform image2D colorimg0;

ivec2 texelCoord = ivec2(gl_FragCoord.xy);


#include "/Lib/GbufferData.glsl"
#include "/Lib/Uniform/GbufferTransforms.glsl"
#include "/Lib/BasicFunctions/TemporalNoise.glsl"

#include "/Lib/PathTracing/Denoiser/DiffuseVarianceEstimation.glsl"


void main(){
	framebuffer_mainOutput = vec4(0.0);

	float depth = uintBitsToFloat(texelFetch(depthtexS, texelCoord, 0).x);

	#ifdef LOD_RENDERING
		if (depth == 1.0) depth = texelFetch(LOD_DEPTH_TEX_1, texelCoord, 0).x;
	#endif

	if (depth < 1.0) {
		vec2 frameWeights = vec2(0.0);

		#ifdef RENDERING_MODE
			if(rtwDiscardRefresh){
				framebuffer_mainOutput = texelFetch(FBTEX_MAIN_OUTPUT, texelCoord, 0);
			}else{
				framebuffer_mainOutput = DiffuseVarianceEstimation(frameWeights);
			}
		#else
			framebuffer_mainOutput = DiffuseVarianceEstimation(frameWeights);
		#endif

		imageStore(colorimg0, texelCoord, vec4(frameWeights, 0.0, 0.0));
	}

}
