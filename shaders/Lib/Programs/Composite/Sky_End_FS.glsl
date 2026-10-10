

#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


/* RENDERTARGETS: 8 */
layout(location = 0) out vec4 framebuffer_altOutput;

#if SR_ENABLE == 1 && SR_USING_ALGO == SR_ALGO_DLSSRR
	layout (rgba16f) uniform image2D colorimg20;
#endif

ivec2 texelCoord = ivec2(gl_FragCoord.xy);
vec2 texCoord = gl_FragCoord.xy * UNIFORM_PIXEL_SIZE;



#include "/Lib/Uniform/GbufferTransforms.glsl"

#include "/Lib/BasicFunctions/TemporalNoise.glsl"

#include "/Lib/IndividualFunctions/EndSky.glsl"


////////////////////////////// Main //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////// Main //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////// Main //////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void main(){
	float depth 					= uintBitsToFloat(texelFetch(depthtexS, texelCoord, 0).x);
	#ifdef LOD_RENDERING
		if (depth == 1.0) depth 	= texelFetch(LOD_DEPTH_TEX_1, texelCoord, 0).x;
	#endif

	if (depth < 1.0) discard;

	vec3 viewPos 					= ViewPos_From_ScreenPos(texCoord, depth);

	vec3 worldPos					= mat3(gbufferModelViewInverse) * viewPos;

	vec3 viewDir 					= normalize(viewPos);
	vec3 worldDir 					= normalize(worldPos);


//////////////////// Sky ///////////////////////////////////////////////////////////////////////////
//////////////////// Sky ///////////////////////////////////////////////////////////////////////////

	vec3 color = vec3(0.0);

	BlackHole_AccretionDisc_Stars(color, worldDir, shadowModelViewInverseEnd[2]);

	PlanetEnd2(color, vec3(0.0), worldDir);

	framebuffer_altOutput = vec4(max(color, vec3(0.0)), 0.0);

	#if SR_ENABLE == 1 && SR_USING_ALGO == SR_ALGO_DLSSRR
		imageStore(colorimg20, texelCoord, vec4(max(color, vec3(0.0)), 0.0));
	#endif
}
