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

layout(rgba16f) writeonly uniform image2D FBIMG_ALT_OUTPUT;
layout(rgba8) writeonly uniform image2D FBIMG_GWATER;

//uniform sampler2D FBTEX_GWATER;

#if FSR2_SCALE >= 0

#include "/Lib/Uniform/GbufferTransforms.glsl"

#include "/Lib/FidelityFX/FSR2/Common.glsl"


float ComputeDepthClip(vec2 renderCoord, vec2 dilatedVelocity, float dilatedDepth){
	float currDist = LinearDepth_From_ScreenDepth(dilatedDepth);

	vec2 reprojectedCoord = renderCoord + dilatedVelocity;
	vec2 texelCoord = reprojectedCoord * fsrScreenSize - 0.5;
	vec2 baseTexel = floor(texelCoord);


	float dilatedSum = 0.0;
	float depth = 0.0;
	float weights = 0.0;
	for (int i = 0; i < 4; i++){
		vec2 sampleTexelCoord = baseTexel + vec2(i & 1, i >> 1);

		if (clamp(sampleTexelCoord, vec2(0.0), fsrScreenSize - 1.0) == sampleTexelCoord){
			float bilinearWeight = (1.0 - abs(texelCoord.x - sampleTexelCoord.x)) * (1.0 - abs(texelCoord.y - sampleTexelCoord.y));

			if (bilinearWeight > 0.01){
				ivec2 sampleTexel = ivec2(sampleTexelCoord);

				float prevDepth = texelFetch(fsrReconstructDepth2D, sampleTexel, 0).x;
				float prevDist = LinearDepth_From_ScreenDepth(prevDepth);

				float distDiff = currDist - prevDist;

				if (distDiff > 0.0) {
					float planeDepth = max(prevDepth, dilatedDepth);
	  
					vec3 center = ViewPos_From_ScreenPos_Raw(vec2(0.5), planeDepth);
					vec3 corner = ViewPos_From_ScreenPos_Raw(vec2(0.0), planeDepth);

					float halfViewportWidth = length(fsrScreenSize);
					float depthThreshold = max(currDist, prevDist);

					const float sepFactor = 1.37e-05f;
					float fovFactor = length(center) / length(corner);
					float requiredDepthSeparation = sepFactor * fovFactor * halfViewportWidth * depthThreshold;

					const float fhdViewportWidth = 1.0 / length(vec2(1920.0, 1080.0));
					float power = mix(1.0, 3.0, saturate(halfViewportWidth * fhdViewportWidth));

					depth += pow(saturate(requiredDepthSeparation / distDiff), power) * bilinearWeight;
					weights += bilinearWeight;
				}
			}
		}
	}

	return (weights > 0.0) ? saturate(1.0 - depth / weights) : 0.0;
}


float ComputeMotionDivergence(ivec2 texel)
{
	float minconvergence = 1.0f;

	vec2 fMotionVectorNucleus = texelFetch(FBTEX_DIFFUSE_TEMPORAL, texel, 0).xy;
	float fNucleusVelocityLr = length(fMotionVectorNucleus * fsrScreenSize);
	float fMaxVelocityUv = length(fMotionVectorNucleus);

	const float MotionVectorVelocityEpsilon = 1e-02f;

	if (fNucleusVelocityLr > MotionVectorVelocityEpsilon) {
		for (int y = -1; y <= 1; ++y) {
			for (int x = -1; x <= 1; ++x) {

				ivec2 sp = texel + ivec2(x, y);

				sp = clamp(sp, ivec2(0), ivec2(fsrScreenSize - 1.0));

				vec2 velocity = texelFetch(FBTEX_DIFFUSE_TEMPORAL, sp, 0).xy;
				float fVelocityUv = length(velocity);

				fMaxVelocityUv = max(fVelocityUv, fMaxVelocityUv);
				fVelocityUv = max(fVelocityUv, fMaxVelocityUv);
				minconvergence = min(minconvergence, dot(velocity / fVelocityUv, fMotionVectorNucleus / fVelocityUv));
			}
		}
	}

	return saturate(1.0 - minconvergence) * saturate(fMaxVelocityUv / 0.01);
}

float ComputeDepthDivergence(ivec2 texel)
{
	float fMaxDistInMeters = LinearDepth_From_ScreenDepth(1.0);
	float fDepthMax = 0.0;
	float fDepthMin = fMaxDistInMeters;

	int iMaxDistFound = 0;

	for (int y = -1; y < 2; y++) {
		for (int x = -1; x < 2; x++) {

			ivec2 iOffset = ivec2(x, y);
			ivec2 iSamplePos = texel + iOffset;

			const float fOnScreenFactor = float(clamp(iSamplePos, ivec2(0), ivec2(fsrScreenSize - 1.0)) == iSamplePos);
			float fDepth = LinearDepth_From_ScreenDepth(1.0 - texelFetch(FBTEX_SPECULAR_TEMPORAL, iSamplePos, 0).z) * fOnScreenFactor;

			iMaxDistFound |= int(fMaxDistInMeters == fDepth);

			fDepthMin = min(fDepthMin, fDepth);
			fDepthMax = max(fDepthMax, fDepth);
		}
	}

	return (1.0f - fDepthMin / fDepthMax) * (bool(iMaxDistFound) ? 0.0f : 1.0f); // todo
}

float ComputeTemporalMotionDivergence(ivec2 texel, vec2 velocity)
{
	vec2 fUv = (vec2(texel) + 0.5f) * fsrPixelSize;

	vec2 fReprojectedUv = fUv + velocity;
	fReprojectedUv = clamp(fReprojectedUv, fsrPixelSize * 0.5, 1.0 - fsrPixelSize * 0.5);
	vec2 fPrevMotionVector = textureLod(FBTEX_SPECULAR_TEMPORAL, fReprojectedUv * fsrRenderScale, 0.0).xy;

	float fPxDistance = length(velocity * screenSize);
	return fPxDistance > 1.0f ? mix(0.0f, 1.0f - saturate(length(fPrevMotionVector) / length(velocity)), saturate(pow(fPxDistance / 20.0f, 3.0f))) : 0;
}

void PreProcessReactiveMasks(ivec2 texel, float fMotionDivergence){
	vec2 fReactiveFactor = vec2(0.0f, fMotionDivergence);
/*
	vec3 fReferenceColor = texelFetch(FBTEX_MAIN_OUTPUT, texel, 0).rgb;
	float fMasksSum = 0.0f;

	vec3 fColorSamples[9];
	float fReactiveSamples[9];
	float fTransparencyAndCompositionSamples[9];


	for (int y = -1; y < 2; y++){
	for (int x = -1; x < 2; x++){
		ivec2 sampleTexel = texel + ivec2(x, y);
		sampleTexel = clamp(sampleTexel, ivec2(0), ivec2(fsrScreenSize - 1.0));

			int sampleIdx = (y + 1) * 3 + x + 1;

			float fReactiveSample = 1.0;
			float fTransparencyAndCompositionSample = 0.0;

			fColorSamples[sampleIdx] = texelFetch(FBTEX_MAIN_OUTPUT, sampleTexel, 0).rgb;
			fReactiveSamples[sampleIdx] = fReactiveSample;
			fTransparencyAndCompositionSamples[sampleIdx] = fTransparencyAndCompositionSample;

			fMasksSum += (fReactiveSample + fTransparencyAndCompositionSample);
	}}

	if (fMasksSum > 0)
	{
		for (int sampleIdx = 0; sampleIdx < 9; sampleIdx++)
		{
			vec3 fColorSample = fColorSamples[sampleIdx];
			float fReactiveSample = fReactiveSamples[sampleIdx];
			float fTransparencyAndCompositionSample = fTransparencyAndCompositionSamples[sampleIdx];

			float fMaxLenSq = max(dot(fReferenceColor, fReferenceColor), dot(fColorSample, fColorSample));
			float fSimilarity = dot(fReferenceColor, fColorSample) / fMaxLenSq;

			// Increase power for non-similar samples
			const float fPowerBiasMax = 6.0f;
			float fSimilarityPower = 1.0f + (fPowerBiasMax - fSimilarity * fPowerBiasMax);
			float fWeightedReactiveSample = pow(fReactiveSample, fSimilarityPower);
			float fWeightedTransparencyAndCompositionSample = pow(fTransparencyAndCompositionSample, fSimilarityPower);

			fReactiveFactor = max(fReactiveFactor, vec2(fWeightedReactiveSample, fWeightedTransparencyAndCompositionSample));
		}
	}
*/
	imageStore(FBIMG_GWATER, texel, vec4(fReactiveFactor, 0.0, 0.0));
}



vec3 ComputePreparedInputColor(ivec2 texel){
	vec3 color = texelFetch(FBTEX_MAIN_OUTPUT, texel, 0).rgb;

	color *= Exposure();
	#ifdef FSR2_USE_CURVE
		color = LinearToCurve(color);
	#endif

	return RGB_To_YCoCg(color);
}

float EvaluateSurface(ivec2 texel){
	float d0 = LinearDepth_From_ScreenDepth(texelFetch(fsrReconstructDepth2D, texel + ivec2(0, -1), 0).x);
	float d1 = LinearDepth_From_ScreenDepth(texelFetch(fsrReconstructDepth2D, texel + ivec2(0,  0), 0).x);
	float d2 = LinearDepth_From_ScreenDepth(texelFetch(fsrReconstructDepth2D, texel + ivec2(0,  1), 0).x);

	return 1.0 - float(((d0 - d1) > (d1 * 0.01)) && ((d1 - d2) > (d2 * 0.01)));
}

void main(){
	ivec2 renderTexel = ivec2(gl_GlobalInvocationID.xy);
	vec2 renderCoord = (vec2(renderTexel) + 0.5) * fsrPixelSize;

	vec3 dilatedData = texelFetch(FBTEX_SPECULAR_TEMPORAL, renderTexel, 0).xyz; // XY:dilatedVelocity Z:dilatedDepth
	dilatedData.xy *= float(length(dilatedData.xy * screenSize) > 0.1);
	dilatedData.z = 1.0 - dilatedData.z;

	//float depthClip = ComputeDepthClip(renderCoord, dilatedData.xy, dilatedData.z) * EvaluateSurface(renderTexel);
	vec3 preparedYCoCg = ComputePreparedInputColor(renderTexel);
	imageStore(FBIMG_ALT_OUTPUT, renderTexel, vec4(preparedYCoCg, 0.0));

	float fMotionDivergence = ComputeMotionDivergence(renderTexel);

	float fTemporalMotionDifference = saturate(ComputeTemporalMotionDivergence(renderTexel, dilatedData.xy) - ComputeDepthDivergence(renderTexel));

	PreProcessReactiveMasks(renderTexel, max(fTemporalMotionDifference, fMotionDivergence));
}

#endif