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


float Lanczos2ApproxNoClamp(float x){
	float x2 = x * x;
    float a = (2.0 / 5.0) * x2 - 1.0;
    float b = (1.0 / 4.0) * x2 - 1.0;
    return ((25.0 / 16.0) * a * a - (25.0 / 16.0 - 1.0)) * (b * b);
}

vec4 Lanczos2Approx(vec4 color0, vec4 color1, vec4 color2, vec4 color3, float f)
{
    float weight0 = Lanczos2ApproxNoClamp(-1.0 - f);
    float weight1 = Lanczos2ApproxNoClamp( 0.0 - f);
    float weight2 = Lanczos2ApproxNoClamp( 1.0 - f);
    float weight3 = Lanczos2ApproxNoClamp( 2.0 - f);
    return (weight0 * color0 + weight1 * color1 + weight2 * color2 + weight3 * color3) / (weight0 + weight1 + weight2 + weight3);
}

vec4 InterpolateHistory(vec4[4][4] colors, vec2 f){
    vec4 colorX0 = Lanczos2Approx(colors[0][0], colors[1][0], colors[2][0], colors[3][0], f.x);
    vec4 colorX1 = Lanczos2Approx(colors[0][1], colors[1][1], colors[2][1], colors[3][1], f.x);
    vec4 colorX2 = Lanczos2Approx(colors[0][2], colors[1][2], colors[2][2], colors[3][2], f.x);
    vec4 colorX3 = Lanczos2Approx(colors[0][3], colors[1][3], colors[2][3], colors[3][3], f.x);
    vec4 colorXY = Lanczos2Approx(colorX0, colorX1, colorX2, colorX3, f.y);

    vec4 deringingSamples[4] = vec4[4](
        colors[1][1],
        colors[2][1],
        colors[1][2],
        colors[2][2]
	);

    vec4 deringingMin = deringingSamples[0];
    vec4 deringingMax = deringingSamples[0];

    for (int iSampleIndex = 1; iSampleIndex < 4; iSampleIndex++){
        deringingMin = min(deringingMin, deringingSamples[iSampleIndex]);
        deringingMax = max(deringingMax, deringingSamples[iSampleIndex]);
    }

    return clamp(colorXY, deringingMin, deringingMax);
}

vec4[4][4] FetchHistorySamples(ivec2 texel){
	ivec2 texSize = ivec2(screenSize - 1.0);

	vec4 colors[4][4];

	colors[0][0]  = SampleHistory(ClampTexel(texel, ivec2(-1, -1), texSize));
	colors[1][0]  = SampleHistory(ClampTexel(texel, ivec2( 0, -1), texSize));
	colors[2][0]  = SampleHistory(ClampTexel(texel, ivec2( 1, -1), texSize));
	colors[3][0]  = SampleHistory(ClampTexel(texel, ivec2( 2, -1), texSize));

	colors[0][1]  = SampleHistory(ClampTexel(texel, ivec2(-1,  0), texSize));
	colors[1][1]  = SampleHistory(ClampTexel(texel, ivec2( 0,  0), texSize));
	colors[2][1]  = SampleHistory(ClampTexel(texel, ivec2( 1,  0), texSize));
	colors[3][1]  = SampleHistory(ClampTexel(texel, ivec2( 2,  0), texSize));

	colors[0][2]  = SampleHistory(ClampTexel(texel, ivec2(-1,  1), texSize));
	colors[1][2]  = SampleHistory(ClampTexel(texel, ivec2( 0,  1), texSize));
	colors[2][2]  = SampleHistory(ClampTexel(texel, ivec2( 1,  1), texSize));
	colors[3][2]  = SampleHistory(ClampTexel(texel, ivec2( 2,  1), texSize));

	colors[0][3]  = SampleHistory(ClampTexel(texel, ivec2(-1,  2), texSize));
	colors[1][3]  = SampleHistory(ClampTexel(texel, ivec2( 0,  2), texSize));
	colors[2][3]  = SampleHistory(ClampTexel(texel, ivec2( 1,  2), texSize));
	colors[3][3]  = SampleHistory(ClampTexel(texel, ivec2( 2,  2), texSize));

	return colors;
}


vec4 HistoryBicubic(vec2 coord){
	vec2 texelCoord = coord * screenSize - 0.5;
	vec2 p = floor(texelCoord);
	vec2 f = texelCoord - p;

	ivec2 texel = ivec2(p);

	return InterpolateHistory(FetchHistorySamples(texel), f);
}


void ReprojectHistoryColor(AccumulationPassCommonParams params, out vec3 historyColor, out float temporalReactiveFactor, out bool inMotionLastFrame){
	vec4 history = HistoryBicubic(params.reprojectedCoord);

	historyColor = history.xyz * Exposure();
    #ifdef FSR2_USE_CURVE
        historyColor = LinearToCurve(historyColor);
    #endif
	historyColor = min(historyColor, 1e20);

	historyColor = RGB_To_YCoCg(historyColor);

	temporalReactiveFactor = saturate(abs(history.w));
	inMotionLastFrame = (history.w < 0.0f);
}
/*
LockState ReprojectHistoryLockStatus(AccumulationPassCommonParams params, out vec2 reprojectedLockStatus){
    LockState state = {false, false};
    float newLockIntensity = texelFetch(FBTEX_ALBEDO, params.presentTexel, 0).r;
    state.newLock = newLockIntensity > 0.5;

   // float fInPlaceLockLifetime = state.newLock ? newLockIntensity : 0;

    reprojectedLockStatus = textureLod(FBTEX_GWATER, params.reprojectedCoord, 0.0).rg;

    if (reprojectedLockStatus[LOCK_LIFETIME_REMAINING] != 0.0) {
        state.wasLockedPrevFrame = true;
    }

    return state;
}
*/