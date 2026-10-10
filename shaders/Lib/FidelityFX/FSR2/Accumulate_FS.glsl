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


/* RENDERTARGETS: 7,15 */
layout(location = 0) out vec4 framebuffer_mainTemporal;
//layout(location = 1) out vec4 framebuffer_gwater;
layout(location = 1) out vec4 framebuffer_fsrLuma;


//layout(r32f) writeonly uniform image2D img_fsrReconstructDepth2D;


//uniform sampler2D FBTEX_GWATER;
//uniform sampler2D FBTEX_GWATER;
uniform sampler2D colortex15;


#if FSR2_SCALE >= 0

#include "/Lib/Uniform/GbufferTransforms.glsl"

#define LOCK_LIFETIME_REMAINING 0
#define LOCK_TEMPORAL_LUMA 1


#include "/Lib/FidelityFX/FSR2/Common.glsl"


vec4 SampleHistory(ivec2 texel){
	return texelFetch(FBTEX_MAIN_TEMPORAL, texel, 0);
}

//float SampleLuminance(ivec2 texel){
//	return texelFetch(FBTEX_MAIN_OUTPUT, texel, 0).a;
//}

vec3 SamplePreparedColor(ivec2 texel){
	return texelFetch(FBTEX_ALT_OUTPUT, texel, 0).rgb;   
}

vec4 SampleLumaHistory(vec2 coord){
	return textureLod(FBTEX_FSR_LUMA, coord, 0.0);   
}


#include "/Lib/FidelityFX/FSR2/Accumulate_UpdateckStatus.glsl"
#include "/Lib/FidelityFX/FSR2/Accumulate_Reproject.glsl"
#include "/Lib/FidelityFX/FSR2/Accumulate_Upsample.glsl"




vec2 FinalizeLockStatus(AccumulationPassCommonParams params, vec2 lockStatus, float fUpsampledWeight){
	// we expect similar motion for next frame
	// kill lock if that location is outside screen, avoid locks to be clamped to screen borders
	vec2 fEstimatedUvNextFrame = params.presentCoord - params.velocity;
	if (saturate(fEstimatedUvNextFrame) == fEstimatedUvNextFrame) {
		#if FSR2_SCALE == 0
			const float jitterSequenceLength = 16.0;
		#elif FSR2_SCALE == 1
			const float jitterSequenceLength = 18.0;
		#elif FSR2_SCALE == 2
			const float jitterSequenceLength = 23.0;
		#elif FSR2_SCALE == 3
			const float jitterSequenceLength = 32.0;
		#elif FSR2_SCALE == 4
			const float jitterSequenceLength = 72.0;
		#endif
		const float fLifetimeDecreaseLanczosMax = jitterSequenceLength * (0.74 / 12.0);
		float fLifetimeDecrease = fUpsampledWeight / fLifetimeDecreaseLanczosMax;
		lockStatus[LOCK_LIFETIME_REMAINING] = max(float(0), lockStatus[LOCK_LIFETIME_REMAINING] - fLifetimeDecrease);
	}else{
		lockStatus[LOCK_LIFETIME_REMAINING] = 0.0;
	}

	return lockStatus;
}




float ComputeTemporalReactiveFactor(AccumulationPassCommonParams params, float temporalReactiveFactor){
	float fNewFactor = min(0.99f, temporalReactiveFactor);

	fNewFactor = max(fNewFactor, mix(fNewFactor, 0.4f, saturate(params.texelMotion)));

	fNewFactor = max(fNewFactor * fNewFactor, max(params.depthClipFactor * 0.1f, params.dilatedReactiveFactor));

	fNewFactor = params.isNewSample ? 1.0f : fNewFactor;

	if (saturate(params.texelMotion * 10.0f) >= 1.0f) {
		fNewFactor = max(1e-3, fNewFactor) * -1.0f;
	}
	
	return fNewFactor;
}

void Accumulate(AccumulationPassCommonParams params, inout vec3 historyColor, vec3 accumulation, vec4 upsampledColorAndWeight){
	accumulation = max(accumulation + upsampledColorAndWeight.www, 1e-3);

	upsampledColorAndWeight.xyz = RGB_To_YCoCg(FsrTonemap(YCoCg_To_RGB(upsampledColorAndWeight.xyz)));
	historyColor = RGB_To_YCoCg(FsrTonemap(YCoCg_To_RGB(historyColor)));


	vec3 fAlpha = upsampledColorAndWeight.www / accumulation;
	historyColor = mix(historyColor, upsampledColorAndWeight.xyz, fAlpha);

	historyColor = YCoCg_To_RGB(historyColor);

	historyColor = FsrTonemapInverse(historyColor);

}

void RectifyHistory(
	AccumulationPassCommonParams params,
	RectificationBox clippingBox,
	inout vec3 historyColor,
	inout vec3 accumulation,
	float lockContributionThisFrame,
	float temporalReactiveFactor,
	float lumaInstabilityFactor
){
	float fScaleFactorInfluence = min(20.0, pow(1.0 / abs(fsrRenderScale.x * fsrRenderScale.y), 3.0));

	float fHrVelocityFactor = saturate(params.texelMotion / 20.0);
	float fBoxScaleT = max(params.depthClipFactor, max(params.accumulationMask, fHrVelocityFactor));
	float fBoxScale = mix(fScaleFactorInfluence, 1.0, fBoxScaleT);

	vec3 fScaledBoxVec = clippingBox.boxVec * fBoxScale;
	vec3 boxMin = clippingBox.boxCenter - fScaledBoxVec;
	vec3 boxMax = clippingBox.boxCenter + fScaledBoxVec;
	vec3 boxCenter = clippingBox.boxCenter;
	float boxVecSize = length(clippingBox.boxVec);

	boxMin = max(clippingBox.aabbMin, boxMin);
	boxMax = min(clippingBox.aabbMax, boxMax);

	if (any(greaterThan(boxMin, historyColor)) || any(greaterThan(historyColor, boxMax))) {

		vec3 fClampedHistoryColor = clamp(historyColor, boxMin, boxMax);

		vec3 fHistoryContribution = max(lumaInstabilityFactor, lockContributionThisFrame).xxx;
		
		float fReactiveFactor = params.dilatedReactiveFactor;
		float fReactiveContribution = 1.0f - pow(fReactiveFactor, 1.0f / 2.0f);
		fHistoryContribution *= fReactiveContribution;

		historyColor = mix(fClampedHistoryColor, historyColor, saturate(fHistoryContribution));

		vec3 fAccumulationMin = min(accumulation, 0.1);
		accumulation = mix(fAccumulationMin, accumulation, saturate(fHistoryContribution));
	}
}

vec3 ComputeBaseAccumulationWeight(AccumulationPassCommonParams params, float thisFrameReactiveFactor, bool inMotionLastFrame, float fUpsampledWeight, LockState lockState){
	float baseAccumulation = float(params.isExistingSample) * (1.0 - thisFrameReactiveFactor) * (1.0 - params.depthClipFactor);
	baseAccumulation = min(baseAccumulation, mix(baseAccumulation, fUpsampledWeight * 10.0, max(float(inMotionLastFrame), saturate(params.texelMotion * 10.0))));
	baseAccumulation = min(baseAccumulation, mix(baseAccumulation, fUpsampledWeight, saturate(params.texelMotion / 20.0)));
	return vec3(baseAccumulation);
}

float ComputeLumaInstabilityFactor(AccumulationPassCommonParams params, RectificationBox clippingBox, float thisFrameReactiveFactor, float luminanceDiff){
	const float unormThreshold = 1.0f / 255.0f;
	const int N_MINUS_1 = 0;
	const int N_MINUS_2 = 1;
	const int N_MINUS_3 = 2;
	const int N_MINUS_4 = 3;

	float currentFrameLuma = clippingBox.boxCenter.x;
	currentFrameLuma = currentFrameLuma / (1.0 + max(0.0, currentFrameLuma));
	currentFrameLuma = round(currentFrameLuma * 255.0) / 255.0;

	bool doSampleLumaHistory = (max(max(params.depthClipFactor, params.accumulationMask), luminanceDiff) < 0.1f) && (params.isNewSample == false);
	vec4 currentFrameLumaHistory = doSampleLumaHistory ? SampleLumaHistory(params.reprojectedCoord) : vec4(0.0);

	float lumaInstability = 0.0f;
	float fDiffs0 = (currentFrameLuma - currentFrameLumaHistory[N_MINUS_1]);

	float fMin = abs(fDiffs0);

	if (fMin >= unormThreshold) {
		for (int i = N_MINUS_2; i <= N_MINUS_4; i++) {
			float fDiffs1 = (currentFrameLuma - currentFrameLumaHistory[i]);

			if (sign(fDiffs0) == sign(fDiffs1)) {
				
				// Scale difference to protect historically similar values
				float fMinBias = 1.0f;
				fMin = min(fMin, abs(fDiffs1) * fMinBias);
			}
		}

		float boxSizeFactor = pow(saturate(clippingBox.boxVec.x / 0.1), 6.0);

		lumaInstability = float(fMin != abs(fDiffs0)) * boxSizeFactor;
		lumaInstability = float(lumaInstability > unormThreshold);

		lumaInstability *= 1.0f - max(params.accumulationMask, pow(thisFrameReactiveFactor, 1.0f / 6.0f));
	}

	//shift history
	currentFrameLumaHistory[N_MINUS_4] = currentFrameLumaHistory[N_MINUS_3];
	currentFrameLumaHistory[N_MINUS_3] = currentFrameLumaHistory[N_MINUS_2];
	currentFrameLumaHistory[N_MINUS_2] = currentFrameLumaHistory[N_MINUS_1];
	currentFrameLumaHistory[N_MINUS_1] = currentFrameLuma;

	framebuffer_fsrLuma = currentFrameLumaHistory;

	return lumaInstability * float(currentFrameLumaHistory[N_MINUS_4] != 0);
}

AccumulationPassCommonParams InitializeParams(ivec2 presentTexel){
	AccumulationPassCommonParams params;

	params.presentTexel = presentTexel;
	vec2 presentCoord = (vec2(presentTexel) + 0.5) * pixelSize;
	params.presentCoord = presentCoord;
	
	vec2 renderCoordJittered = presentCoord + fsrJitter;
	params.renderSampleCoord = clamp(renderCoordJittered, fsrPixelSize * 0.5, 1.0 - fsrPixelSize * 0.5);

	params.velocity = texelFetch(FBTEX_SPECULAR_TEMPORAL, ivec2(presentCoord * fsrScreenSize), 0).xy;
	//params.velocity = vec2(0.0);
	params.texelMotion = length(params.velocity * screenSize);

	params.reprojectedCoord = params.presentCoord - params.velocity;
	params.isExistingSample = saturate(params.reprojectedCoord) == params.reprojectedCoord;
	//params.isExistingSample = true;

	params.depthClipFactor = 0.0;
	//params.depthClipFactor = saturate(textureLod(FBTEX_ALT_OUTPUT, params.renderSampleCoord * fsrRenderScale, 0.0).a);
	
	vec2 dilatedReactiveMasks = textureLod(FBTEX_GWATER, params.renderSampleCoord * fsrRenderScale, 0.0).xy; // params.renderSampleCoord;
	params.dilatedReactiveFactor = dilatedReactiveMasks.x;
	params.accumulationMask = dilatedReactiveMasks.y;
	params.isResetFrame = frameCounter == 0;

	params.isNewSample = (params.isExistingSample == false || params.isResetFrame);

	return params;
}



void main(){
	ivec2 presentTexel = ivec2(gl_FragCoord.xy);
	AccumulationPassCommonParams params = InitializeParams(presentTexel);

	vec3 historyColor = vec3(0.0);
	vec2 lockStatus = vec2(0.0);

	float temporalReactiveFactor = 0.0;
	bool inMotionLastFrame = false;
	LockState lockState = {false, false};


	if (params.isExistingSample && !params.isResetFrame) {
		ReprojectHistoryColor(params, historyColor, temporalReactiveFactor, inMotionLastFrame);
		//lockState = ReprojectHistoryLockStatus(params, lockStatus);
	}

	//imageStore(colorimg15, params.presentTexel, vec4(historyColor, 0.0));

	float thisFrameReactiveFactor = max(params.dilatedReactiveFactor, temporalReactiveFactor);

	float luminanceDiff = 0.0;
	float lockContributionThisFrame = 0.0;
	//UpdateLockStatus(params, thisFrameReactiveFactor, lockState, lockStatus, lockContributionThisFrame, luminanceDiff);

	// Load upsampled input color
	RectificationBox clippingBox;
	vec4 upsampledColorAndWeight = ComputeUpsampledColorAndWeight(params, clippingBox, thisFrameReactiveFactor);


 
	float lumaInstabilityFactor = ComputeLumaInstabilityFactor(params, clippingBox, thisFrameReactiveFactor, luminanceDiff);

	vec3 accumulation = ComputeBaseAccumulationWeight(params, thisFrameReactiveFactor, inMotionLastFrame, upsampledColorAndWeight.w, lockState);


	if (params.isNewSample){
		historyColor = YCoCg_To_RGB(upsampledColorAndWeight.rgb);
	}else{
		RectifyHistory(params, clippingBox, historyColor, accumulation, lockContributionThisFrame, thisFrameReactiveFactor, lumaInstabilityFactor);

		Accumulate(params, historyColor, accumulation, upsampledColorAndWeight);
	}

	#ifdef FSR2_USE_CURVE
		historyColor = CurveToLinear(historyColor);
	#endif
	historyColor /= Exposure();

	//framebuffer_gwater = vec4(FinalizeLockStatus(params, lockStatus, upsampledColorAndWeight.w), 0.0, 0.0);

	temporalReactiveFactor = ComputeTemporalReactiveFactor(params, thisFrameReactiveFactor);

	framebuffer_mainTemporal = vec4(historyColor, temporalReactiveFactor);

	//if (all(lessThan(params.presentTexel, ivec2(fsrScreenSize))))
	//	imageStore(img_fsrReconstructDepth2D, params.presentTexel, vec4(1.0, 0.0, 0.0, 0.0));

}

#endif