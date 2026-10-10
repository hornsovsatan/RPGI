

#define PROGRAM_UPDATE_SSBO


#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


#ifndef PT_DIFFUSE_TEMPORAL_HISTORY_FIX
	const ivec3 workGroups = ivec3(1, 1, 1);
#else
	const vec2 workGroupsRender = vec2(0.25, 0.25);
#endif
layout (local_size_x = 16, local_size_y = 16) in;
 

layout (rgba16f) uniform image2D FBIMG_ALT_OUTPUT;


vec4 SpdLoadSourceImage(ivec2 p, uint slice){
	ivec4 mipmapMapping = ssb_mipmapMappingSpaced[0u];
	ivec2 readTexel = clamp(p, ivec2(0), mipmapMapping.zw - 1);
	return texelFetch(FBTEX_MAIN_OUTPUT, readTexel, 0);
}

vec4 SpdLoad(ivec2 p, uint slice){
	ivec4 mipmapMapping = ssb_mipmapMappingSpaced[6u];
	ivec2 readTexel = clamp(p, ivec2(0), mipmapMapping.zw - 1) + mipmapMapping.xy;
	return texelFetch(FBTEX_ALT_OUTPUT, readTexel, 0);
}

void SpdStore(ivec2 p, vec4 value, uint mip, uint slice){
	ivec4 mipmapMapping = ssb_mipmapMappingSpaced[mip];
	ivec2 drawTexel = clamp(p, ivec2(0), mipmapMapping.zw - 1) + mipmapMapping.xy;
	imageStore(FBIMG_ALT_OUTPUT, drawTexel, value);
}

vec4 SpdReduce4(vec4 v0, vec4 v1, vec4 v2, vec4 v3){
	return v0 * 0.25 + v1 * 0.25 + v2 * 0.25 + v3 * 0.25;
}


#include "/Lib/FidelityFX/SPD/SPD.glsl"

void main(){
	#ifdef PT_DIFFUSE_TEMPORAL_HISTORY_FIX
		uint totalNumWorkGroups = gl_NumWorkGroups.x * gl_NumWorkGroups.y;
		SpdDownsample(gl_WorkGroupID.xy, gl_LocalInvocationIndex, ssb_mipmapMaxLevel, totalNumWorkGroups, gl_WorkGroupID.z);
	#endif
}
