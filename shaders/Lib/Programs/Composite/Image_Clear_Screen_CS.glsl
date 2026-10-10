

#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


#if SR_SHOULD_APPLY_SCALE == 1
	const vec2 workGroupsRender = vec2(SR_RENDER_SCALE_FACTOR, SR_RENDER_SCALE_FACTOR);
#else
	const vec2 workGroupsRender = vec2(FSR2_RENDER_SCALE_FACTOR, FSR2_RENDER_SCALE_FACTOR);
#endif

layout (local_size_x = 16, local_size_y = 8) in;


layout (r32ui) writeonly uniform uimage2D img_depthtexS;
#ifdef DIMENSION_OVERWORLD
	layout(r32ui) writeonly uniform uimage2D img_waterDepth2D;
#endif


void main(){
	ivec2 drawTexel = ivec2(gl_GlobalInvocationID.xy);

	imageStore(img_depthtexS, drawTexel, uvec4(floatBitsToUint(1.0), 0u, 0u, 0u));
	#ifdef DIMENSION_OVERWORLD
		imageStore(img_waterDepth2D, drawTexel, uvec4(floatBitsToUint(1e20), 0u, 0u, 0u));
		#ifdef PT_OCCLUDED_WATER_SPECULAR
			drawTexel.y += int(screenSize.y);
			imageStore(img_waterDepth2D, drawTexel, uvec4(floatBitsToUint(1e20), 0u, 0u, 0u));
		#endif
	#endif
}