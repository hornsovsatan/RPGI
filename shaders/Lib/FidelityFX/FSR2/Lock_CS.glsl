// This file is part of the FidelityFX SDK.
//
// Copyright (c) 2022-2023 Advanced Micro Devices, Inc. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


const vec2 workGroupsRender = vec2(FSR2_RENDER_SCALE_FACTOR, FSR2_RENDER_SCALE_FACTOR);
layout (local_size_x = 16, local_size_y = 8) in;

layout(rgba8) writeonly uniform image2D colorimg0;
layout(r32f) writeonly uniform image2D img_fsrReconstructDepth2D;


#if FSR2_SCALE >= 0

#include "/Lib/FidelityFX/FSR2/Common.glsl"


bool ComputeThinFeatureConfidence(ivec2 texel){
	float nucleus = texelFetch(FBTEX_MAIN_OUTPUT, texel, 0).a;

	float similarThreshold = 1.1;
	float dissimilarLumaMin = 1e20;
	float dissimilarLumaMax = 0;

	uint mask = (1u << 4);

	const uint rejectionMasks[4] = uint[4](
		(1u << 0) | (1u << 1) | (1u << 3) | (1u << 4),
		(1u << 1) | (1u << 2) | (1u << 4) | (1u << 5),
		(1u << 3) | (1u << 4) | (1u << 6) | (1u << 7),
		(1u << 4) | (1u << 5) | (1u << 7) | (1u << 8)
	);

	int idx = 0;

	for (int y = -1; y <= 1; y++){
	for (int x = -1; x <= 1; x++, idx++){
		if (x == 0 && y == 0) continue;

		ivec2 sampleTexel = clamp(texel + ivec2(x, y), ivec2(0), ivec2(fsrScreenSize - 1.0));

		float sampleLuma = texelFetch(FBTEX_MAIN_OUTPUT, sampleTexel, 0).a;
		float difference = max(sampleLuma, nucleus) / min(sampleLuma, nucleus);

		if (difference > 0.0 && (difference < similarThreshold)){
			mask |= (1u << idx);
		}else{
			dissimilarLumaMin = min(dissimilarLumaMin, sampleLuma);
			dissimilarLumaMax = max(dissimilarLumaMax, sampleLuma);
		}
	}}

	bool lock = true;

	if (nucleus > dissimilarLumaMax || nucleus < dissimilarLumaMin) {
		for (int i = 0; i < 4; i++) {
			if ((mask & rejectionMasks[i]) == rejectionMasks[i]) {
				lock = false;
				break;
			}
		}
	}else{
		lock = false;
	}

	return lock;
}


void main(){
	ivec2 renderTexel = ivec2(gl_GlobalInvocationID.xy);

	//if (any(greaterThanEqual(renderTexel, ivec2(fsrScreenSize)))) return;

	if (ComputeThinFeatureConfidence(renderTexel)){
		vec2 renderCoord = vec2(renderTexel) + 0.5 - jitterRaw * 0.5;
    	ivec2 presentTexel = ivec2(floor(renderCoord / fsrRenderScale));

		imageStore(colorimg0, presentTexel, vec4(1.0, 0.0, 0.0, 0.0));
	}

	imageStore(img_fsrReconstructDepth2D, renderTexel, vec4(1.0, 0.0, 0.0, 0.0));
}

#endif