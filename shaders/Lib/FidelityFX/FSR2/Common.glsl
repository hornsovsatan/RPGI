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


float MinDividedByMax(float v0, float v1)
{
	float m = max(v0, v1);
	return m != 0.0 ? min(v0, v1) / m : 0.0;
}

vec3 RGB_To_YCoCg(vec3 color) {
	return vec3(color.r * 0.25 + color.g * 0.5 + color.b * 0.25, color.r * 0.5 - color.b * 0.5, color.r * -0.25 + color.g * 0.5 + color.b * -0.25);
}

vec3 YCoCg_To_RGB(vec3 color) {
	float temp = color.r - color.b;
	return vec3(temp + color.g, color.r + color.b, temp - color.g);
}


vec3 FsrTonemap(vec3 color){
	return color /= (max(maxVec3(color), 0.0) + 1.0);
}

vec3 FsrTonemapInverse(inout vec3 color){
	return color /= max(1e-5, 1.0 - maxVec3(color));
}

float LockPerceivedLuminance(vec3 color, float exposure){
	color *= exposure;
	color = FsrTonemap(color);

	float luminance = Luminance(color);

	float percievedLuminance = 0.0;
	if (luminance <= 216.0 / 24389.0) {
		percievedLuminance = luminance * (24389.0 / 27.0);
	}
	else {
		percievedLuminance = pow(luminance, 1.0 / 3.0) * 116.0 - 16.0;
	}

	return saturate(pow(percievedLuminance * 0.01, 1.0 / 6.0));
}

ivec2 ClampTexel(ivec2 texel, const ivec2 offset, ivec2 texSize){
	texel += offset;
	texel.x = (offset.x < 0) ? max(texel.x, 0        ) : texel.x;
	texel.x = (offset.x > 0) ? min(texel.x, texSize.x) : texel.x;
	texel.y = (offset.y < 0) ? max(texel.y, 0        ) : texel.y;
	texel.y = (offset.y > 0) ? min(texel.y, texSize.y) : texel.y;
	return texel;
}

float Exposure(){
	return texelFetch(pixelData2D, ivec2(PIXELDATA_EXPOSURE, 0), 0).y;
}


struct FetchedBilinearSamples{
	vec4 fColor00;
	vec4 fColor10;

	vec4 fColor01;
	vec4 fColor11;
};

struct FetchedBicubicSamples{
	vec4 fColor00;
	vec4 fColor10;
	vec4 fColor20;
	vec4 fColor30;

	vec4 fColor01;
	vec4 fColor11;
	vec4 fColor21;
	vec4 fColor31;

	vec4 fColor02;
	vec4 fColor12;
	vec4 fColor22;
	vec4 fColor32;

	vec4 fColor03;
	vec4 fColor13;
	vec4 fColor23;
	vec4 fColor33;
};

struct RectificationBox{
	vec3 boxCenter;
	vec3 boxVec;
	vec3 aabbMin;
	vec3 aabbMax;
	float boxCenterWeight;
};

struct AccumulationPassCommonParams{
	ivec2 presentTexel;
	vec2 presentCoord;
	vec2 renderSampleCoord;
	vec2 velocity;
	vec2 reprojectedCoord;
	float texelMotion;
	float depthClipFactor;
	float dilatedReactiveFactor;
	float accumulationMask;

	bool isResetFrame;
	bool isExistingSample;
	bool isNewSample;
};

struct LockState{
	bool newLock;
	bool wasLockedPrevFrame;
};