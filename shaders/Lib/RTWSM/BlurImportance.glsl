

#include "/Lib/Utilities.glsl"
#include "/Lib/UniformDeclare.glsl"

#if RTW_RESOLUTION == 256
	const ivec3 workGroups = ivec3(2, 2, 1);
	layout (local_size_x = 128) in;
#elif RTW_RESOLUTION == 512
	const ivec3 workGroups = ivec3(4, 2, 1);
	layout (local_size_x = 128) in;
#elif RTW_RESOLUTION == 1024
	const ivec3 workGroups = ivec3(8, 2, 1);
	layout (local_size_x = 128) in;
#endif

layout (r32ui) uniform uimage2D img_rtwImportance2D;

shared float sampleData[160];

uniform usampler2D rtwImportance2D;


void main(){
	#ifdef RENDERING_MODE
		vec2 currFramesData = texelFetch(pixelData2D, ivec2(PIXELDATA_RENDER_FRAMES, 0), 0).xy;
		float renderFrames = currFramesData.x * 1000.0 + currFramesData.y - 10.0;
		if (renderFrames > 0.5) return;
	#else
		if (rtwDiscardRefresh) return;
	#endif

	ivec2 groupTexelOrigin = ivec2(gl_WorkGroupID.xy);
	groupTexelOrigin.y += RTW_RESOLUTION;
	groupTexelOrigin.x = groupTexelOrigin.x * 128 - 16;
	int id = int(gl_LocalInvocationIndex);

	sampleData[id] = uintBitsToFloat(texelFetch(rtwImportance2D, ivec2(groupTexelOrigin.x + id, groupTexelOrigin.y), 0).x);
	id += 128;

	if (id < 160)
	sampleData[id] = uintBitsToFloat(texelFetch(rtwImportance2D, ivec2(groupTexelOrigin.x + id, groupTexelOrigin.y), 0).x);

	barrier();

	int wid = int(gl_LocalInvocationIndex) + 16;
	
	vec2 
	blur  = vec2(sampleData[wid - 16], 1.0) * exp2(-RTW_BLUR_FACTOR * 256.0);
	blur += vec2(sampleData[wid - 15], 1.0) * exp2(-RTW_BLUR_FACTOR * 225.0);
	blur += vec2(sampleData[wid - 14], 1.0) * exp2(-RTW_BLUR_FACTOR * 196.0);
	blur += vec2(sampleData[wid - 13], 1.0) * exp2(-RTW_BLUR_FACTOR * 169.0);
	blur += vec2(sampleData[wid - 12], 1.0) * exp2(-RTW_BLUR_FACTOR * 144.0);
	blur += vec2(sampleData[wid - 11], 1.0) * exp2(-RTW_BLUR_FACTOR * 121.0);
	blur += vec2(sampleData[wid - 10], 1.0) * exp2(-RTW_BLUR_FACTOR * 100.0);
	blur += vec2(sampleData[wid - 9 ], 1.0) * exp2(-RTW_BLUR_FACTOR * 81.0 );
	blur += vec2(sampleData[wid - 8 ], 1.0) * exp2(-RTW_BLUR_FACTOR * 64.0 );
	blur += vec2(sampleData[wid - 7 ], 1.0) * exp2(-RTW_BLUR_FACTOR * 49.0 );
	blur += vec2(sampleData[wid - 6 ], 1.0) * exp2(-RTW_BLUR_FACTOR * 36.0 );
	blur += vec2(sampleData[wid - 5 ], 1.0) * exp2(-RTW_BLUR_FACTOR * 25.0 );
	blur += vec2(sampleData[wid - 4 ], 1.0) * exp2(-RTW_BLUR_FACTOR * 16.0 );
	blur += vec2(sampleData[wid - 3 ], 1.0) * exp2(-RTW_BLUR_FACTOR * 9.0  );
	blur += vec2(sampleData[wid - 2 ], 1.0) * exp2(-RTW_BLUR_FACTOR * 4.0  );
	blur += vec2(sampleData[wid - 1 ], 1.0) * exp2(-RTW_BLUR_FACTOR * 1.0  );
	blur += vec2(sampleData[wid     ], 1.0) * exp2(-RTW_BLUR_FACTOR * 0.0  );
	blur += vec2(sampleData[wid + 1 ], 1.0) * exp2(-RTW_BLUR_FACTOR * 1.0  );
	blur += vec2(sampleData[wid + 2 ], 1.0) * exp2(-RTW_BLUR_FACTOR * 4.0  );
	blur += vec2(sampleData[wid + 3 ], 1.0) * exp2(-RTW_BLUR_FACTOR * 9.0  );
	blur += vec2(sampleData[wid + 4 ], 1.0) * exp2(-RTW_BLUR_FACTOR * 16.0 );
	blur += vec2(sampleData[wid + 5 ], 1.0) * exp2(-RTW_BLUR_FACTOR * 25.0 );
	blur += vec2(sampleData[wid + 6 ], 1.0) * exp2(-RTW_BLUR_FACTOR * 36.0 );
	blur += vec2(sampleData[wid + 7 ], 1.0) * exp2(-RTW_BLUR_FACTOR * 49.0 );
	blur += vec2(sampleData[wid + 8 ], 1.0) * exp2(-RTW_BLUR_FACTOR * 64.0 );
	blur += vec2(sampleData[wid + 9 ], 1.0) * exp2(-RTW_BLUR_FACTOR * 81.0 );
	blur += vec2(sampleData[wid + 10], 1.0) * exp2(-RTW_BLUR_FACTOR * 100.0);
	blur += vec2(sampleData[wid + 11], 1.0) * exp2(-RTW_BLUR_FACTOR * 121.0);
	blur += vec2(sampleData[wid + 12], 1.0) * exp2(-RTW_BLUR_FACTOR * 144.0);
	blur += vec2(sampleData[wid + 13], 1.0) * exp2(-RTW_BLUR_FACTOR * 169.0);
	blur += vec2(sampleData[wid + 14], 1.0) * exp2(-RTW_BLUR_FACTOR * 196.0);
	blur += vec2(sampleData[wid + 15], 1.0) * exp2(-RTW_BLUR_FACTOR * 225.0);
	blur += vec2(sampleData[wid + 16], 1.0) * exp2(-RTW_BLUR_FACTOR * 256.0);


	ivec2 drawTexel = ivec2(gl_GlobalInvocationID.xy);

	imageStore(img_rtwImportance2D, drawTexel, uvec4(floatBitsToUint(blur.x / blur.y), 0u, 0u, 0u));
}