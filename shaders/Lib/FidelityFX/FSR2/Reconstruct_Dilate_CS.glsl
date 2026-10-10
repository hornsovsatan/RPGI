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

layout(rgba16f) writeonly uniform image2D FBIMG_SPECULAR_TEMPORAL;
//layout(r32ui) uniform uimage2D img_fsrReconstructDepth2D;


//uniform sampler2D FBTEX_GWATER;


#if FSR2_SCALE >= 0

#include "/Lib/FidelityFX/FSR2/Common.glsl"


float GetTransMaterialID(ivec2 coord){
	return Unpack2xU8_ID_Y_from_U16(texelFetch(FBTEX_GTRANS_DATA, coord, 0).z);
}

void FindNearestDepth(ivec2 texel, out float nearestDepth, out ivec2 nearestDepthTexel){
	const ivec2 sampleOffsets[8] = ivec2[8](
		ivec2(-1, -1),
		ivec2( 0, -1),
		ivec2( 1, -1),
		ivec2(-1,  0),
		ivec2( 1,  0),
		ivec2(-1,  1),
		ivec2( 0,  1),
		ivec2( 1,  1)
	);

	nearestDepth = texelFetch(depthtex0, texel, 0).x;
	nearestDepthTexel = texel;

	for (int i = 0; i < 8; i++) {
		ivec2 sampleTexel = texel + sampleOffsets[i];
		sampleTexel = clamp(sampleTexel, ivec2(0), ivec2(fsrScreenSize - 1.0));
		float sampleDepth = texelFetch(depthtex0, sampleTexel, 0).x;
		if (sampleDepth < nearestDepth) {
			nearestDepth = sampleDepth;
			nearestDepthTexel = sampleTexel;
		}
	}

	nearestDepthTexel = clamp(nearestDepthTexel, ivec2(0), ivec2(fsrScreenSize - 1.0));
}


vec2 ScreenVelocity(ivec2 texel, vec2 renderCoord, float depth){
	vec2 velocity = vec2(0.0);

	float materialIDs = GetTransMaterialID(texel);

	if (materialIDs != MATID_END_PORTAL){
		vec3 screenPos = vec3(renderCoord, depth);
		vec3 projection = screenPos * 2.0 - 1.0;

		projection = (vec3(vec2(gbufferProjectionInverse0.x, gbufferProjectionInverse0.y) * projection.xy, 0.0) + gbufferProjectionInverse1) / (gbufferProjectionInverse0.z * projection.z + gbufferProjectionInverse0.w);

		if (materialIDs == MATID_HAND){
			projection += (gbufferPreviousModelView[3].xyz - gbufferModelView[3].xyz) * MC_HAND_DEPTH;
		}else{
			projection = mat3(gbufferModelViewInverse) * projection + gbufferModelViewInverse[3].xyz;
			if (depth < 1.0) projection += cameraPositionToPrevious;
			projection = mat3(gbufferPreviousModelView) * projection + gbufferPreviousModelView[3].xyz;
		}
		
		projection = (vec3(gbufferPreviousProjection0.x, gbufferPreviousProjection0.y, gbufferPreviousProjection0.z) * projection + gbufferPreviousProjection1) / -projection.z * 0.5 + 0.5;

		velocity = screenPos.xy - projection.xy;
	}

	return velocity;
}
/*
void ReconstructPrevDepth(vec2 renderCoord, float depth, vec2 velocity){
	velocity *= float(length(velocity * screenSize) > 0.1f);

	vec2 reprojectedCoord = renderCoord + velocity;
	vec2 texelCoord = reprojectedCoord * fsrScreenSize - 0.5;
	vec2 baseTexel = floor(texelCoord);
 
	for (int i = 0; i < 4; i++){
		vec2 drawTexelcoord = baseTexel + vec2(i & 1, i >> 1);
		
		float bilinearWeight = (1.0 - abs(texelCoord.x - drawTexelcoord.x)) * (1.0 - abs(texelCoord.y - drawTexelcoord.y));

		if (bilinearWeight > 0.01){
			if (clamp(drawTexelcoord, vec2(0.0), fsrScreenSize - 1.0) == drawTexelcoord) {
				imageAtomicMin(img_fsrReconstructDepth2D, ivec2(drawTexelcoord), floatBitsToUint(depth));
			}
		}
	}
}
*/

void main(){
	ivec2 renderTexel = ivec2(gl_GlobalInvocationID.xy);

	//if (any(greaterThanEqual(renderTexel, ivec2(fsrScreenSize)))) return;
	
	float dilatedDepth;
	ivec2 nearestDepthTexel;
	FindNearestDepth(renderTexel, dilatedDepth, nearestDepthTexel);

	vec2 nearestDepthCoord = (vec2(nearestDepthTexel) + 0.5) * fsrPixelSize;
	//vec2 dilatedVelocity = ScreenVelocity(nearestDepthTexel, nearestDepthCoord, dilatedDepth);
	vec2 dilatedVelocity = texelFetch(FBTEX_DIFFUSE_TEMPORAL, nearestDepthTexel, 0).xy;

	imageStore(FBIMG_SPECULAR_TEMPORAL, renderTexel, vec4(dilatedVelocity, 1.0 - dilatedDepth, 0.0));

	vec2 renderCoord = (vec2(renderTexel) + 0.5) * fsrPixelSize;
	//ReconstructPrevDepth(renderCoord, dilatedDepth, dilatedVelocity);
}

#endif