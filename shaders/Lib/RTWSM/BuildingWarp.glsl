

#extension GL_KHR_shader_subgroup_arithmetic : enable


#include "/Lib/Utilities.glsl"
#include "/Lib/UniformDeclare.glsl"


#if RTW_RESOLUTION == 256

	const ivec3 workGroups = ivec3(1, 2, 1);
	layout (local_size_x = 256) in;

	#if defined MC_GL_VENDOR_NVIDIA || defined MC_GL_VENDOR_AMD
		shared float prefixSumCache[8];
	#else
		shared float prefixSumCache[16];
	#endif


#elif RTW_RESOLUTION == 512

	const ivec3 workGroups = ivec3(1, 2, 1);
	layout (local_size_x = 512) in;

	#if defined MC_GL_VENDOR_NVIDIA || defined MC_GL_VENDOR_AMD
		shared float prefixSumCache[16];
	#else
		shared float prefixSumCache[32];
	#endif


#elif RTW_RESOLUTION == 1024

	const ivec3 workGroups = ivec3(1, 2, 1);
	layout (local_size_x = 1024) in;

	#if defined MC_GL_VENDOR_NVIDIA || defined MC_GL_VENDOR_AMD
		shared float prefixSumCache[32];
	#else
		shared float prefixSumCache[64];
	#endif


#endif


layout (rg16) writeonly uniform image2D img_rtwWarp1D;

uniform usampler2D rtwImportance2D;


#include "/Lib/PathTracing/Voxelizer/VoxelProfile.glsl"


void main(){
	#ifdef RENDERING_MODE
		vec2 currFramesData = texelFetch(pixelData2D, ivec2(PIXELDATA_RENDER_FRAMES, 0), 0).xy;
		float renderFrames = currFramesData.x * 1000.0 + currFramesData.y - 10.0;
		if (renderFrames > 0.5) return;
	#else
		if (rtwDiscardRefresh) return;
	#endif

	ivec2 drawTexel = ivec2(gl_GlobalInvocationID.xy);

	float importance = uintBitsToFloat(texelFetch(rtwImportance2D, drawTexel, 0).x);

	float shadowCoord = (float(drawTexel.x) + 0.5) * (2.0 / float(RTW_RESOLUTION)) - 1.0;
	float voxelWeight = step(abs(shadowCoord), voxelDistance / shadowDistance) * RTW_VOXEL_WEIGHT;
	importance = max(importance, voxelWeight);
	//if (isEyeInWater == 1){
	//	float eyeWeight = step(abs(shadowCoord), 3.0 / shadowDistance) * 0.01;
	//	importance = max(importance, eyeWeight);
	//}
	

	float prefixSum = subgroupInclusiveAdd(importance);

	if (gl_SubgroupInvocationID == gl_SubgroupSize - 1u) 
		prefixSumCache[gl_SubgroupID] = prefixSum;

	barrier();

	uint loopLength = uint(findMSB(gl_NumSubgroups));
	loopLength += uint(gl_NumSubgroups - (1u << (loopLength - 1u)) > 0u);

	for (uint i = 0; i < loopLength; i++){
		if ((gl_SubgroupID & (1u << i)) > 0u){
			prefixSum += prefixSumCache[(gl_SubgroupID >> i << i) - 1u];
		
			if (gl_SubgroupInvocationID == gl_SubgroupSize - 1u) 
				prefixSumCache[gl_SubgroupID] = prefixSum;
		}

		barrier();
	}

	if (gl_LocalInvocationID.x == uint(RTW_RESOLUTION - 1))
		prefixSumCache[0] = prefixSum;
	
	barrier();

	float sum = prefixSumCache[0];
	float warp = (prefixSum - importance) / sum - float(gl_LocalInvocationID.x + 1u) / float(RTW_RESOLUTION);
	warp = warp * 0.5 + 0.5;
	float warpPixelSize = importance / max(sum, 1.0);
	
	imageStore(img_rtwWarp1D, drawTexel, vec4(warp, warpPixelSize, 0.0, 0.0));
}