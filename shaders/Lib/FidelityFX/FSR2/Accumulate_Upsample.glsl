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


float Lanczos2ApproxSq(float x2){
    x2 = min(x2, 4.0);
    float a = (2.0 / 5.0) * x2 - 1.0;
    float b = (1.0 / 4.0) * x2 - 1.0;
    return ((25.0 / 16.0) * a * a - (25.0 / 16.0 - 1.0)) * (b * b);
}

float Lanczos2(float x){
    x = min(abs(x), 2.0);
    return abs(x) < 1e-3 ? 1.0 : (sin(PI * x) / (PI * x)) * (sin(0.5 * PI * x) / (0.5 * PI * x));
}

void Deringing(RectificationBox clippingBox, inout vec3 color){
    color = clamp(color, clippingBox.aabbMin, clippingBox.aabbMax);
}

float GetUpsampleLanczosWeight(vec2 sampleOffset, float kernelWeight){
    vec2 sampleOffsetBiased = sampleOffset * kernelWeight;
    float sampleWeight = Lanczos2ApproxSq(dot(sampleOffsetBiased, sampleOffsetBiased));
    //float sampleWeight = Lanczos2(length(sampleOffsetBiased));
    return sampleWeight;
}

float ComputeMaxKernelWeight(){
    const float kernelSizeBias = 1.0;
    float kernelWeight = (1.0 / fsrRenderScale.x - 1.0) * kernelSizeBias + 1.0;
    return min(1.99, kernelWeight);
}

void RectificationBoxAddInitialSample(inout RectificationBox rectificationBox, vec3 colorSample, float sampleWeight){
    rectificationBox.aabbMin = colorSample;
    rectificationBox.aabbMax = colorSample;

    vec3 weightedSample = colorSample * sampleWeight;
    rectificationBox.boxCenter = weightedSample;
    rectificationBox.boxVec = colorSample * weightedSample;
    rectificationBox.boxCenterWeight = sampleWeight;
}

void RectificationBoxAddSample(bool isInitialSample, inout RectificationBox rectificationBox, vec3 colorSample, float sampleWeight){
    if (isInitialSample) {
        RectificationBoxAddInitialSample(rectificationBox, colorSample, sampleWeight);
    } else {
        rectificationBox.aabbMin = min(rectificationBox.aabbMin, colorSample);
        rectificationBox.aabbMax = max(rectificationBox.aabbMax, colorSample);

        vec3 weightedSample = colorSample * sampleWeight;
        rectificationBox.boxCenter += weightedSample;
        rectificationBox.boxVec += colorSample * weightedSample;
        rectificationBox.boxCenterWeight += sampleWeight;
    }
}

void RectificationBoxComputeVarianceBoxData(inout RectificationBox rectificationBox){
    rectificationBox.boxCenterWeight = abs(rectificationBox.boxCenterWeight) > 1e-3 ? rectificationBox.boxCenterWeight : 1.0;
    rectificationBox.boxCenter /= rectificationBox.boxCenterWeight;
    rectificationBox.boxVec /= rectificationBox.boxCenterWeight;
    vec3 stdDev = sqrt(abs(rectificationBox.boxVec - rectificationBox.boxCenter * rectificationBox.boxCenter));
    rectificationBox.boxVec = stdDev;
}

vec4 ComputeUpsampledColorAndWeight(AccumulationPassCommonParams params, inout RectificationBox clippingBox, float reactiveFactor){
    vec2 renderCenterTexelCoord = (vec2(params.presentTexel) + 0.5) * fsrRenderScale;
    ivec2 renderTexel = ivec2(floor(renderCenterTexelCoord));

    vec3 samples[9];

    vec2 unjitteredTexelCoord = (vec2(renderTexel) + 0.5) - jitterRaw * 0.5;
 
    bool flipCol = unjitteredTexelCoord.x > renderCenterTexelCoord.x;
	bool flipRow = unjitteredTexelCoord.y > renderCenterTexelCoord.y;
    

    ivec2 offsetTL = ivec2(
        flipCol ? -2 : -1,
        flipRow ? -2 : -1
    );

    for (int row = 0; row < 3; row++){
    for (int col = 0; col < 3; col++){
        int iSampleIndex = col + row * 3;

        ivec2 sampleColRow = ivec2(flipCol ? (3 - col) : col, flipRow ? (3 - row) : row);
        ivec2 sampleTexel = renderTexel + offsetTL + sampleColRow;

        sampleTexel = clamp(sampleTexel, ivec2(0), ivec2(fsrScreenSize - 1.0));

        samples[iSampleIndex] = SamplePreparedColor(sampleTexel);
    }}

    vec4 colorAndWeight = vec4(0.0);

    vec2 baseSampleOffset = unjitteredTexelCoord - renderCenterTexelCoord;

    float kernelReactiveFactor = max(reactiveFactor, float(params.isNewSample));
    float kernelBiasMax = ComputeMaxKernelWeight() * (1.0 - kernelReactiveFactor);

    float fKernelBiasMin = max(1.0, kernelBiasMax * 0.3 + 0.3);
    float fKernelBiasFactor = max(0.0, max(0.25 * params.depthClipFactor, kernelReactiveFactor));
    float fKernelBias = mix(kernelBiasMax, fKernelBiasMin, fKernelBiasFactor);

    float rectificationCurveBias = mix(-2.0, -3.0, saturate(params.texelMotion / 50.0));


    for (int row = 0; row < 3; row++){
    for (int col = 0; col < 3; col++){
        int iSampleIndex = col + row * 3;

        ivec2 sampleColRow = ivec2(flipCol ? (3 - col) : col, flipRow ? (3 - row) : row);
        ivec2 offset = offsetTL + sampleColRow;
        vec2 sampleOffset = baseSampleOffset + vec2(offset);

        ivec2 sampleTexel = renderTexel + offset;

        float fOnScreenFactor = float(clamp(sampleTexel, ivec2(0), ivec2(fsrScreenSize - 1.0)) == sampleTexel);
        float sampleWeight = fOnScreenFactor * GetUpsampleLanczosWeight(sampleOffset, fKernelBias);

        colorAndWeight += vec4(samples[iSampleIndex] * sampleWeight, sampleWeight);

        {
            float sampleOffsetSq = dot(sampleOffset, sampleOffset);
            float boxSampleWeight = exp(rectificationCurveBias * sampleOffsetSq);

            bool isInitialSample = (row == 0) && (col == 0);
            RectificationBoxAddSample(isInitialSample, clippingBox, samples[iSampleIndex], boxSampleWeight);
        }
    }}

    RectificationBoxComputeVarianceBoxData(clippingBox);



    if (colorAndWeight.w > 1e-3) {
        colorAndWeight.xyz = colorAndWeight.xyz / colorAndWeight.w;
        colorAndWeight.w *= 1.0 / 12.0;

        Deringing(clippingBox, colorAndWeight.xyz);
    }else{
        colorAndWeight.w = 0.0;
    }


    return colorAndWeight;
}
