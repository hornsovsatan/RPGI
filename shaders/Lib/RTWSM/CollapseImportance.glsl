

#include "/Lib/Utilities.glsl"
#include "/Lib/UniformDeclare.glsl"

#if RTW_RESOLUTION == 256
	const ivec3 workGroups = ivec3(256, 2, 1);
	layout (local_size_x = 64) in;
#elif RTW_RESOLUTION == 512
	const ivec3 workGroups = ivec3(512, 2, 1);
	layout (local_size_x = 128) in;
#elif RTW_RESOLUTION == 1024
	const ivec3 workGroups = ivec3(1024, 2, 1);
	layout (local_size_x = 256) in;
#endif

layout (r32ui) uniform uimage2D img_rtwImportance2D;

shared uint importanceMax;

uniform usampler2D rtwImportance2D;


void main(){
	#ifdef RENDERING_MODE
		vec2 currFramesData = texelFetch(pixelData2D, ivec2(PIXELDATA_RENDER_FRAMES, 0), 0).xy;
		float renderFrames = currFramesData.x * 1000.0 + currFramesData.y - 10.0;
		if (renderFrames > 0.5) return;
	#else
		if (rtwDiscardRefresh) return;
	#endif

	importanceMax = 0u;
	barrier();

	ivec2 sampleTexel = ivec2(0);
	ivec2 sampleDir = ivec2(0);
	ivec2 drawTexel = ivec2(gl_WorkGroupID.xy);
	drawTexel.y += RTW_RESOLUTION;

	if (gl_WorkGroupID.y == 0u){
		sampleTexel.x = drawTexel.x;
		sampleTexel.y = int(gl_LocalInvocationID.x) * 4;
		sampleDir.y = 1;
	}else{
		sampleTexel.x = int(gl_LocalInvocationID.x) * 4;
		sampleTexel.y = drawTexel.x;
		sampleDir.x = 1;
	}

	uint findMax = texelFetch(rtwImportance2D, sampleTexel, 0).x;
	findMax = max(findMax, texelFetch(rtwImportance2D, sampleTexel + sampleDir, 0).x);
	findMax = max(findMax, texelFetch(rtwImportance2D, sampleTexel + sampleDir * 2, 0).x);
	findMax = max(findMax, texelFetch(rtwImportance2D, sampleTexel + sampleDir * 3, 0).x);
	findMax = atomicMax(importanceMax, findMax);

	barrier();

	float currImportance = uintBitsToFloat(importanceMax);

	//float prevImportance = imageLoad(img_rtwImportance1D, drawTexel).x;
	//currImportance = mix(currImportance, prevImportance, 0.8);

	imageStore(img_rtwImportance2D, drawTexel, uvec4(floatBitsToUint(currImportance), 0u, 0u, 0u));
}