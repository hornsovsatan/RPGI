

#ifdef PROGRAM_UPDATE_SSBO
	layout(std430, binding = 0) restrict buffer uniformData{
#else
	layout(std430, binding = 0) restrict readonly buffer uniformData{
#endif

	ivec4 ssb_mipmapMapping[16];
	ivec4 ssb_mipmapMappingSpaced[16];
	uint ssb_mipmapMaxLevel;
	uint ssb_spdAtomicCounter[16];
	vec4 ssb_gbufferPreviousProjectionInverse0;
	vec3 ssb_gbufferPreviousProjectionInverse1;
};