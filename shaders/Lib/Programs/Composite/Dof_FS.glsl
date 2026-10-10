

#include "/Lib/Utilities.glsl"
#include "/Lib/UniformDeclare.glsl"


/* DRAWBUFFERS:6 */
layout(location = 0) out vec4 framebuffer_mainOutput;

#if SR_ENABLE == 1 && SR_USING_ALGO == SR_ALGO_DLSSRR
	#define PROGRAM_DOF
	layout (rgba16f) writeonly uniform image2D colorimg22;
#endif


ivec2 texelCoord = ivec2(gl_FragCoord.xy);
vec2 texCoord = gl_FragCoord.xy * UNIFORM_PIXEL_SIZE;


#include "/Lib/Uniform/GbufferTransforms.glsl"
#include "/Lib/BasicFunctions/TemporalNoise.glsl"

#include "/Lib/IndividualFunctions/DOF.glsl"


void main(){
	#ifdef DOF
		framebuffer_mainOutput = DepthOfField();
	#endif
}
