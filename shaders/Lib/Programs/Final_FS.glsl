

#define PROGRAM_UPDATE_SSBO


#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"

//#undef HDR_ENABLED

////////////////////PROGRAM_FINAL_0/////////////////////////////////////////////////////////////////
////////////////////PROGRAM_FINAL_0/////////////////////////////////////////////////////////////////
#ifdef PROGRAM_FINAL_0


ivec2 texelCoord = ivec2(gl_FragCoord.xy);
vec2 texCoord = gl_FragCoord.xy * pixelSize;


/* RENDERTARGETS: 6 */
layout(location = 0) out vec4 framebuffer_mainOutput;


#include "/Lib/GbufferData.glsl"
#include "/Lib/Uniform/GbufferTransforms.glsl"

#ifdef DIMENSION_NETHER
	#include "/Lib/BasicFunctions/NetherColor.glsl"
#endif


vec3 RRTAndODTFit(vec3 v){
	vec3 a = v * (v + 0.0245786) - 0.000090537;
	vec3 b = v * (v + 0.4329510) + 0.238081;
	return a / b;
}

vec3 ACES(vec3 color){
	color *= 1.4;

	#ifdef ABNEY_EFFECT_CORRECTION
		color *= mat3(0.99999976, -1.26657e-7, -1.29064e-9, 1.67316e-8, 0.99999976, -5.32026e-9, -0.00725587, 6.47740e-9, 1.00725580);
	#endif

	color *= mat3(0.59719, 0.35458, 0.04823, 0.07600, 0.90834, 0.01566, 0.02840, 0.13383, 0.83777);

	color = RRTAndODTFit(color);

	color *= mat3(1.60475, -0.53108, -0.07367, -0.10208, 1.10813, -0.00605, -0.00327, -0.07276, 1.07602);

	return LinearToSrgb(color);
}

// https://iolite-engine.com/blog_posts/minimal_agx_implementation
// MIT License
//
// Copyright (c) 2024 Missing Deadlines (Benjamin Wrensch)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

// All values used to derive this implementation are sourced from Troy’s initial AgX implementation/OCIO config file available here:
//   https://github.com/sobotka/AgX

vec3 AgxDefaultContrastApprox(vec3 x){
	return (((((15.5 * x - 40.14) * x + 31.96) * x - 6.868) * x + 0.4298) * x + 0.1191) * x - 0.00232;		
}

vec3 AgxCurve(vec3 color){
	const float hev = AGX_EV * 0.5;
	const float midGrey = 0.18;
	color = clamp(log2(color / midGrey), -hev, hev);
	color = (color + hev) / AGX_EV;

	return AgxDefaultContrastApprox(color);			 
}

/*
https://allenwp.com/blog/2025/05/29/allenwp-tonemapping-curve/

Copyright (c) 2025 Allen Pestaluky

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

// allenwp tonemapping curve; developed for use in the Godot game engine
// Source and details: https://allenwp.com/blog/2025/05/29/allenwp-tonemapping-curve/
// Input must be a linear scene value

vec3 AgxHdrCurve(vec3 color, float output_max_value) {
	const float hev = AGX_HDR_EV * 0.5;
	color = max(log2(color / AGX_HDR_MIDGREY), -hev);
	color = (color + hev) / AGX_HDR_EV;

	vec3 colorCurved = mix(
		AgxDefaultContrastApprox(color),
		color * 2.063794 - 0.7540885,
		saturate(color * 20.0 - 11.9481)
	);

	output_max_value -= 1.0;

	#if 1
	colorCurved = mix(
		colorCurved,
		AgxDefaultContrastApprox(color - 0.484544 * output_max_value) + output_max_value,
		saturate(color * 20.0 - 11.9481 - 20.0 * 0.484544 * output_max_value)
	);
	#endif

	return colorCurved;
}


vec3 AgX(vec3 color) {
	color *= 2.3;


	#ifdef ABNEY_EFFECT_CORRECTION
		color *= mat3(0.99999976, -1.26657e-7, -1.29064e-9, 1.67316e-8, 0.99999976, -5.32026e-9, -0.00725587, 6.47740e-9, 1.00725580);
	#endif

	color *= mat3(0.842479062253094, 0.0784335999999992, 0.0792237451477643, 0.0423282422610123, 0.878468636469772, 0.0791661274605434, 0.0423756549057051, 0.0784336, 0.879142973793104);

	#ifdef HDR_ENABLED
		float output_max_value = HdrGamePeakBrightness / HdrGamePaperWhiteBrightness;
		color = AgxHdrCurve(color, output_max_value);
	#else
		color = AgxCurve(color);
	#endif

	color *= mat3(1.19687900512017, -0.0980208811401368, -0.0990297440797205, -0.0528968517574562, 1.15190312990417, -0.0989611768448433, -0.0529716355144438, -0.0980434501171241, 1.15107367264116);

	#ifdef HDR_ENABLED
		color /= output_max_value;
	#endif

	return color;
}



//https://www.desmos.com/calculator/gslcdxvipg
vec3 GT(vec3 color) {
	color = pow(color * 0.6, vec3(0.9));

	const float P = 1.0;
	const float a = 1.0;
	const float m = 0.22;
	const float l = 0.4;
	const float c = 1.33;
	const float b = 0.0;

	const float l0 = ((P - m) * l) / a;
	const float L0 = m - m / a;
	const float L1 = m + (1.0 - m) / a;
	vec3 L = (m - a * m) + a * color;

	const float T0 = 1.0 / pow(m, c - 1.0) + b;
	vec3 T = pow(color, vec3(c)) * T0;

	const float S0 = m + l0;
	const float S1 = m + a * l0;
	const float C2 = (a * P) / (P - S1);
	const float CP = -1.44269502 * C2 / P;
	vec3 S = P - ((P - S1) / exp2(CP * S0)) * exp2(CP * color);

	vec3 w0 = 1.0 - smoothstep(0.0, m, color);
	vec3 w2 = step(vec3(S0), color);
	vec3 w1 = 1.0 - w0 - w2;
	 
	return LinearToSrgb(T * w0 + L * w1 + S * w2);
}


vec3 None(vec3 color){
	return pow(color, vec3(1.0 / 2.2));
}

float GetExposureValue(){
	return texelFetch(pixelData2D, ivec2(PIXELDATA_EXPOSURE, 0), 0).y;
}

float Vignette(vec2 coord, const float falloff, const float roundness){
	vec2 aCoord = coord * 2.0 - 1.0;
	aCoord.x *= mix(1.0, aspectRatio, roundness);
	float rf = dot(aCoord, aCoord) * falloff * falloff + 1.0;
	return 1.0 / (rf * rf);
}



#ifdef PT_TRACING_EYE

uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;

uniform usampler3D voxelColor3D;
uniform sampler3D voxelData3D;

#ifdef PT_IRC
	uniform sampler3D irradianceCache3D;
	uniform sampler3D irradianceCache3D_Alt;
#endif

#include "/Lib/PathTracing/Voxelizer/VoxelProfile.glsl"
#include "/Lib/Uniform/ShadowTransforms.glsl"
#include "/Lib/BasicFunctions/TemporalNoise.glsl"


vec3 colorTorchlight = vec3(1.0);
uint randSeed = 0u;

#include "/Lib/PathTracing/Tracer/TracingUtilities.glsl"
#include "/Lib/PathTracing/Voxelizer/BlockShape.glsl"
#include "/Lib/PathTracing/Tracer/ShadowTracing.glsl"
#include "/Lib/PathTracing/Tracer/SampleIRC.glsl"
struct TracingData
{
	Ray ray;
	vec3 result;
	vec3 surface;
	vec3 hitVoxelPos;
	vec3 hitNormal;
	float hitSkylight;
	bool traceTranslucent;
};

vec3 PathTracingEye(vec3 worldDir){
	vec3 voxelPos = gbufferModelViewInverse[3].xyz + cameraPositionFract + (voxelResolution * 0.5);
	//voxelPos += gbufferModelViewInverse[2].xyz * 40.0;

	vec3 result = vec3(0.0);

	vec2 atlasPixelSize = 1.0 / vec2(textureSize(atlas2D, 0));

 

	TracingData pt;

	float hitSkylight = 1.0;
		

	pt.surface = vec3(1.0);
	pt.result = vec3(0.0);
	vec3 hitVoxelPos = voxelPos;

	pt.ray = PackRay(voxelPos, worldDir);

	bool exitTracing = true;

	vec3 voxelCoord = floor(pt.ray.ori);
	vec3 totalStep = (pt.ray.sdir * (voxelCoord - pt.ray.ori + 0.5) + 0.5) * abs(pt.ray.rdir);
	float rayLength = 0.0;
	vec3 tracingNext = step(totalStep, vec3(minVec3(totalStep)));
	vec3 hitNormal = vec3(0.0);

	vec4 texColor;

	vec4 voxelData;
	float voxelID;

	bool eliminated = false;


	for (int i = 0; i < 300; i++){
		if (rayLength > 300.0 || clamp(voxelCoord, vec3(0.0), vec3(voxelResolution - 0.5)) != voxelCoord){
			exitTracing = true;
			break;
		} 

		voxelData = texelFetch(voxelData3D, ivec3(voxelCoord), 0);
		voxelID = floor(voxelData.z * 65535.0 - 999.9);


		if (abs(voxelID) < 240.0){


			bool hit = IsHitBlock(pt.ray, totalStep, tracingNext, voxelCoord, abs(voxelID), rayLength, hitNormal);

			//bool hit = IsHitBlock_FromOrigin_WithInternalIntersection(pt.ray, totalStep, tracingNext, voxelCoord, abs(voxelID), rayLength, hitNormal, eliminated);

			if (hit){

				hitVoxelPos = pt.ray.ori + pt.ray.dir * rayLength + hitNormal * (rayLength * 1e-6 + 1e-5);

				vec2 voxelDataW = Unpack2xU8_from_U16(voxelData.w);

				vec3 dataCoord = GetAtlasCoordWithLod(voxelCoord, voxelData.xy, voxelDataW.x, hitVoxelPos, hitNormal, atlasPixelSize);
				texColor = textureLod(atlas2D, dataCoord.xy, dataCoord.z);

				bool isTranslucent = voxelID == 3.0 || abs(voxelID - 16.5) < 8.0;

				if (isTranslucent){
					vec3 stainedGlassColor = normalize(texColor.rgb + 0.0001) * pow(dot(texColor.rgb, texColor.rgb), 0.25);
					pt.surface *= GammaToLinear(mix(vec3(0.96), texColor.rgb * 0.96, pow(texColor.a, 0.25)));
				}else 

				if (voxelID >= 0.0 || (texColor.a >= 0.1 && rayLength > 0.0)){
					exitTracing = false;
					#ifdef DIMENSION_OVERWORLD
					#ifdef SUNLIGHT_LEAK_FIX
						hitSkylight = voxelDataW.y;
					#endif
					#endif
					break;
					break;
				}

			}

		} //hit voxel ?

		#ifdef PT_SPARE_TRACING
			if (abs(voxelData.z - 0.76) < 0.16){
				float spareSize = floor(voxelData.z * 20.0 - 10.0);

				vec3 spareOrigin = floor(voxelCoord / spareSize) * spareSize;

				vec3 boxMin = spareOrigin - pt.ray.ori;
				vec3 boxMax = boxMin + spareSize;

				vec3 t1 = pt.ray.rdir * boxMin;
				vec3 t2 = pt.ray.rdir * boxMax;

				vec3 tMax = max(t1, t2);
				rayLength = minVec3(tMax);

				tracingNext = step(tMax, vec3(rayLength));

				vec3 exitVoxelCoord = floor(pt.ray.ori + rayLength * pt.ray.dir + tracingNext * pt.ray.sdir * 0.5);

				totalStep += (exitVoxelCoord - voxelCoord) * pt.ray.sdir * abs(pt.ray.rdir);
				voxelCoord = exitVoxelCoord;
			}else{
				rayLength = minVec3(totalStep);
				tracingNext = step(totalStep, vec3(rayLength));
				voxelCoord += tracingNext * pt.ray.sdir;
				totalStep += tracingNext * abs(pt.ray.rdir);
			}
		#else
			rayLength = minVec3(totalStep);
			tracingNext = step(totalStep, vec3(rayLength));
			voxelCoord += tracingNext * pt.ray.sdir;
			totalStep += tracingNext * abs(pt.ray.rdir);
		#endif	
	} //stepping loop

	if (!exitTracing && !eliminated){

		//ivec2 voxelTexel = ivec2(VoxelTexel_From_VoxelCoord(voxelCoord));
		//vec4 hitAlbedo = texelFetch(shadowcolor0, voxelTexel, 0);
		vec4 hitAlbedo = unpackUnorm4x8(texelFetch(voxelColor3D, ivec3(voxelCoord), 0).x);

		hitAlbedo.rgb *= texColor.rgb;
		#ifdef DP_plain_world
			hitAlbedo.rgb = vec3(DP_plain_world_color);
		#endif

		result = hitAlbedo.rgb * pt.surface;


		#ifdef PT_TRACING_EYE_SHADOW
			#ifndef DIMENSION_NETHER
				#ifdef DIMENSION_OVERWORLD
					vec3 worldShadowVector = shadowModelViewInverse2;
				#else
					vec3 worldShadowVector = shadowModelViewInverseEnd[2];
				#endif

				float sunLighting = saturate(dot(worldShadowVector, hitNormal)) * 0.5;

				#ifdef DIMENSION_OVERWORLD
				#ifdef SUNLIGHT_LEAK_FIX
					sunLighting *= saturate(hitSkylight * 444.0 + float(isEyeInWater == 1));
				#endif
				#endif

				//if (sunLighting > 0.0) sunLighting *= SimpleShadowTracing(hitVoxelPos, worldShadowVector);

				if (sunLighting > 0.0) {
					vec3 hitWorldPos = hitVoxelPos - cameraPositionFract - (voxelResolution * 0.5);
					result += SimpleShadow(hitWorldPos, hitNormal) * sunLighting * pt.surface;
				}
			#endif
		#endif

		#ifdef DEBUG_IRC
		#ifdef PT_IRC
			result = SampleIrradianceCache(hitVoxelPos);
		#endif
		#endif

		//result = hitAlbedo.aaa;
	}

	//result = vec3(Unpack2xU8_Y_from_U16(voxelData.w));

	return result;
}

#endif





vec3 ColorGrading(vec3 color){
	color = SrgbToLinear(color);

	{	
		vec3 highlight = color * (5.0 / 3.0) - (2.0 / 3.0);
		highlight = saturate(highlight * highlight * (0.6 - highlight * 0.6));
		highlight *= saturate(color * 1e10 - 4e9);

		vec3 shadow = 1.0 - color * (5.0 / 3.0);
		shadow = saturate(shadow * shadow * (0.6 - shadow * 0.6));
		shadow *= saturate(6e9 - color * 1e10);

		color = saturate(color + highlight * HIGHLIGHT_CURVE + shadow * SHADOW_CURVE);
	}

	color = saturate(color * (WHITE_POINT - BLACK_POINT) + BLACK_POINT);

	{
		color += 1e-20;
		float luminance = Luminance(color);

		float gammaLuminance = pow(luminance, 1.0 / 2.2);
		float highlightWeight = curve(saturate(gammaLuminance * 2.5 - 1.5));
		float shadowWeight = curve(saturate(1.0 - gammaLuminance * 2.5));

		vec3 highlight = normalize(color + HSV_to_RGB_Smooth(HIGHLIGHT_HUE / 360.0, 1.0, HIGHLIGHT_STRENGTH));
		vec3 shadow    = normalize(color + HSV_to_RGB_Smooth(SHADOW_HUE    / 360.0, 1.0, SHADOW_STRENGTH));
		vec3 midtone   = normalize(color + HSV_to_RGB_Smooth(MIDTONE_HUE   / 360.0, 1.0, MIDTONE_STRENGTH));

		float colorLength = length(color);
		color /= colorLength;
		color = highlight * highlightWeight + shadow * shadowWeight + midtone * (1.0 - highlightWeight - shadowWeight);
		color *= colorLength;

		#ifdef KEEP_LUMINANCE
			color *= luminance / Luminance(color);
		#endif

		color = saturate(color);
	}

	color = saturate(mix(color, vec3(Luminance(color)), 1.0 - SATURATION));

	color = saturate(pow(color, vec3(1.0 / GAMMA)));

	return LinearToSrgb(color);
}

/*
#define NORM2SNORM(value) (value * 2.0 - 1.0)
#define SNORM2NORM(value) (value * 0.5 + 0.5)

vec3 EquirectToDirection(vec2 uv) {

	uv = NORM2SNORM(uv);
	uv.x *= PI;  // phi
	uv.y *= hPI; // theta
		
	return vec3(cos(uv.x)*cos(uv.y)
			  , sin(uv.y)
			  , sin(uv.x)*cos(uv.y));
}

uniform sampler2D pixelData2D;
//*/
/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void main(){
	ivec2 texelCoord = ivec2(gl_FragCoord.xy);
	vec4 data1 = texelFetch(FBTEX_MAIN_OUTPUT, texelCoord, 0);
	//data1 = texelFetch(FBTEX_ALT_OUTPUT, texelCoord, 0);
	vec3 color = data1.rgb;

	//color = UnpackLogluvU32(packHalf2x16(unpackHalf2x16(PackLogluvU32(color))));


	#ifdef PT_TRACING_EYE

		float depth = texelFetch(depthtex0, texelCoord, 0).x;
		vec3 viewPos = ViewPos_From_ScreenPos_Raw(texCoord, depth);
		vec3 worldDir = normalize(mat3(gbufferModelViewInverse) * viewPos);

		color = PathTracingEye(worldDir);

		#ifdef DEBUG_IRC
			color *= GetExposureValue();

			color = TONEMAP_OPERATOR(color);
		#endif

		if (hideGUI == 0) color = color * 0.5 + texelFetch(FBTEX_ALBEDO, texelCoord, 0).rgb * 0.5;

	#else

		#ifdef BLOOM
			color = mix(color, textureLod(FBTEX_ALT_OUTPUT, texCoord * 0.5, 0.0).rgb, data1.a);
		#endif

		#ifdef VIGNETTE
			color *= Vignette(texCoord, VIGNETTE_FALLOFF, VIGNETTE_ROUNDNESS);
		#endif

		color *= GetExposureValue();

		color = TONEMAP_OPERATOR(color);

		color = saturate(color);

		#ifdef ADVANCED_COLOR
			color = ColorGrading(color);
		#endif
/*
		#ifdef HAS_COLORWHEEL
			#ifdef SUPER_RESOLUTION
				ivec2 tcoord = ivec2(texCoord * UNIFORM_SCREEN_SIZE);
				if (GetTransMaterialID(tcoord) == MATID_OVERLAY){
					color = textureLod(FBTEX_ALBEDO, texCoord * fsrRenderScale, 0.0).rgb;
				}
			#else
				if (GetTransMaterialID(texelCoord) == MATID_OVERLAY){
					color = texelFetch(FBTEX_ALBEDO, texelCoord, 0).rgb;
				}
			#endif
		#endif
*/
		#ifdef SNEAKING_VIGNETTE
			color *= mix(1.0, Vignette(vec2(0.5, texCoord.y), 0.7, 0.0), isSneakingSmooth);
		#endif


	#endif

	framebuffer_mainOutput = vec4(color, 0.0);
}


#endif
////////////////////END_IF//////////////////////////////////////////////////////////////////////////





////////////////////PROGRAM_FINAL_1/////////////////////////////////////////////////////////////////
////////////////////PROGRAM_FINAL_1/////////////////////////////////////////////////////////////////
#ifdef PROGRAM_FINAL_1


ivec2 texelCoord = ivec2(gl_FragCoord.xy);


#include "/Lib/GbufferData.glsl"

#include "/Lib/IndividualFunctions/PrintFloat.glsl"


vec3 FidelityFX_CAS(sampler2D originSampler, vec3 sampleE, ivec2 texel){
	//      +---+
	//    g | h | i
	//  +---+---+---+
	//  | d | e | f |
	//  +---+---+---+
	//    a | b | c
	//      +---+

	vec3 sampleB = texelFetch(originSampler, ivec2(texel.x, texel.y - 1), 0).rgb;
	vec3 sampleD = texelFetch(originSampler, ivec2(texel.x - 1, texel.y), 0).rgb;
	vec3 sampleF = texelFetch(originSampler, ivec2(texel.x + 1, texel.y), 0).rgb;
	vec3 sampleH = texelFetch(originSampler, ivec2(texel.x, texel.y + 1), 0).rgb;
	float luminanceB = Luminance(sampleB);
	float luminanceD = Luminance(sampleD);
	float luminanceE = Luminance(sampleE);
	float luminanceF = Luminance(sampleF);
	float luminanceH = Luminance(sampleH);

	float minCross = min5(luminanceB, luminanceD, luminanceE, luminanceF, luminanceH);
	float maxCross = max5(luminanceB, luminanceD, luminanceE, luminanceF, luminanceH);

	#if FSR2_SCALE >= 0 || (defined CUSTOM_RENDER_RESOLUTION && defined FSR1)
		const float sharpness = FSR2_RCAS_SHARPNESS;
	#else
		const float sharpness = CAS_SHARPNESS;
	#endif

	float weight = sqrt(saturate(min(minCross, 2.0 - maxCross) / maxCross)) * (-0.1 - sharpness * 0.01);

	#ifdef CAS_DENOISE
		float noise = luminanceB * 0.25 + luminanceD * 0.25 + luminanceF * 0.25 + luminanceH * 0.25 - luminanceE;
		noise = saturate(abs(noise) / (maxCross - minCross));
		weight *= 1.0 - 0.5 * noise;
	#endif

	vec3 sharpen = (sampleB * weight + sampleD * weight + sampleF * weight + sampleH * weight + sampleE) / (1.0 + 4.0 * weight);

	return max(sharpen, vec3(0.0));
}
/*
float BlackBar(float newRatio){
	if (newRatio == 0.0) return 1.0;
	vec2 aCoord = abs(texCoord - 0.5) * 2.0;
	float width = min(newRatio / aspectRatio, 1.0);
	float height = min(aspectRatio / newRatio, 1.0);

	return step(aCoord.x, width) * step(aCoord.y, height);
}
*/
vec3 Fxaa(vec3 rgbM, vec2 coord){

	#define FXAA_REDUCE_MIN   (1.0/64.0)
	#define FXAA_REDUCE_MUL   (1.0/8.0)
	#define FXAA_SPAN_MAX     16.0
	
	vec3 rgbNW = textureLod(FBTEX_MAIN_OUTPUT, coord + pixelSize * vec2(-0.5, -0.5), 0.0).xyz;
	vec3 rgbNE = textureLod(FBTEX_MAIN_OUTPUT, coord + pixelSize * vec2( 0.5, -0.5), 0.0).xyz;
	vec3 rgbSW = textureLod(FBTEX_MAIN_OUTPUT, coord + pixelSize * vec2(-0.5,  0.5), 0.0).xyz;
	vec3 rgbSE = textureLod(FBTEX_MAIN_OUTPUT, coord + pixelSize * vec2( 0.5,  0.5), 0.0).xyz;

	vec3 luma = vec3(0.299, 0.587, 0.114);
	float lumaNW = dot(rgbNW, luma);
	float lumaNE = dot(rgbNE, luma);
	float lumaSW = dot(rgbSW, luma);
	float lumaSE = dot(rgbSE, luma);
	float lumaM  = dot(rgbM,  luma);

	float lumaMin = min(lumaM, min(min(lumaNW, lumaNE), min(lumaSW, lumaSE)));
	float lumaMax = max(lumaM, max(max(lumaNW, lumaNE), max(lumaSW, lumaSE)));

	vec2 dir;
	dir.x = -((lumaNW + lumaNE) - (lumaSW + lumaSE));
	dir.y =  ((lumaNW + lumaSW) - (lumaNE + lumaSE));

	float dirReduce = max(
		(lumaNW + lumaNE + lumaSW + lumaSE) * (0.25 * FXAA_REDUCE_MUL),
		FXAA_REDUCE_MIN);
	float rcpDirMin = 1.0/(min(abs(dir.x), abs(dir.y)) + dirReduce);
	dir = min(vec2( FXAA_SPAN_MAX,  FXAA_SPAN_MAX),
		  max(vec2(-FXAA_SPAN_MAX, -FXAA_SPAN_MAX),
		  dir * rcpDirMin)) * pixelSize;

	vec3 rgbA = (1.0/2.0) * (
	textureLod(FBTEX_MAIN_OUTPUT, coord + dir * vec2(1.0/3.0 - 0.5), 0.0).xyz +
	textureLod(FBTEX_MAIN_OUTPUT, coord + dir * vec2(2.0/3.0 - 0.5), 0.0).xyz);
	vec3 rgbB = rgbA * (1.0/2.0) + (1.0/4.0) * (
	textureLod(FBTEX_MAIN_OUTPUT, coord + dir * vec2(0.0/3.0 - 0.5), 0.0).xyz +
	textureLod(FBTEX_MAIN_OUTPUT, coord + dir * vec2(3.0/3.0 - 0.5), 0.0).xyz);

	float lumaB = dot(rgbB, luma);

	if ((lumaB < lumaMin) || (lumaB > lumaMax)) {
		return rgbA;
	} else {
		return rgbB;
	}
}


void FinalDither(inout vec3 color){
	ivec2 tc = texelCoord;
	tc.x += 64 - int(viewWidth);

	vec2 ct = vec2(0.5, 0.0);
	if (clamp(tc, ivec2(0), ivec2(52, 6)) == tc){
		if (tc.y == 0){
			if (tc.x < 32){if (bool((0x89e81e29 >> (31 - tc.x)) & 1)) ct.y = 0.5;}
			else          {if (bool((0xc8a28000 >> (63 - tc.x)) & 1)) ct.y = 0.5;}
		}else if (tc.y == 1){
			if (tc.x < 32){if (bool((0x9208224a >> (31 - tc.x)) & 1)) ct.y = 0.5;}
			else          {if (bool((0x28a28000 >> (63 - tc.x)) & 1)) ct.y = 0.5;}
		}else if (tc.y == 2){
			if (tc.x < 32){if (bool((0x93e81e4a >> (31 - tc.x)) & 1)) ct.y = 0.5;}
			else          {if (bool((0x28a28000 >> (63 - tc.x)) & 1)) ct.y = 0.5;}
		}else if (tc.y == 3){
			if (tc.x < 32){if (bool((0x922c824a >> (31 - tc.x)) & 1)) ct.y = 0.5;}
			else          {if (bool((0x28a28000 >> (63 - tc.x)) & 1)) ct.y = 0.5;}
		}else if (tc.y == 4){
			if (tc.x < 32){if (bool((0xb9cb1ce9 >> (31 - tc.x)) & 1)) ct.y = 0.5;}
			else          {if (bool((0xcf3cf000 >> (63 - tc.x)) & 1)) ct.y = 0.5;}
		}else if (tc.y == 5){
			if (tc.x < 32){if (bool((0x10000040 >> (31 - tc.x)) & 1)) ct.y = 0.5;}
			else          {if (bool((0x00228800 >> (63 - tc.x)) & 1)) ct.y = 0.5;}
		}else{
			if (tc.x < 32){if (bool((0x90000048 >> (31 - tc.x)) & 1)) ct.y = 0.5;}
			else          {if (bool((0x003cf000 >> (63 - tc.x)) & 1)) ct.y = 0.5;}
		}
	}

	tc += ivec2(1, -1);

	if (clamp(tc, ivec2(0), ivec2(52, 6)) == tc){
		if (tc.y == 0){
			if (tc.x < 32){if (bool((0x89e81e29 >> (31 - tc.x)) & 1)) ct = vec2(1.0);}
			else          {if (bool((0xc8a28000 >> (63 - tc.x)) & 1)) ct = vec2(1.0);}
		}else if (tc.y == 1){
			if (tc.x < 32){if (bool((0x9208224a >> (31 - tc.x)) & 1)) ct = vec2(1.0);}
			else          {if (bool((0x28a28000 >> (63 - tc.x)) & 1)) ct = vec2(1.0);}
		}else if (tc.y == 2){
			if (tc.x < 32){if (bool((0x93e81e4a >> (31 - tc.x)) & 1)) ct = vec2(1.0);}
			else          {if (bool((0x28a28000 >> (63 - tc.x)) & 1)) ct = vec2(1.0);}
		}else if (tc.y == 3){
			if (tc.x < 32){if (bool((0x922c824a >> (31 - tc.x)) & 1)) ct = vec2(1.0);}
			else          {if (bool((0x28a28000 >> (63 - tc.x)) & 1)) ct = vec2(1.0);}
		}else if (tc.y == 4){
			if (tc.x < 32){if (bool((0xb9cb1ce9 >> (31 - tc.x)) & 1)) ct = vec2(1.0);}
			else          {if (bool((0xcf3cf000 >> (63 - tc.x)) & 1)) ct = vec2(1.0);}
		}else if (tc.y == 5){
			if (tc.x < 32){if (bool((0x10000040 >> (31 - tc.x)) & 1)) ct = vec2(1.0);}
			else          {if (bool((0x00228800 >> (63 - tc.x)) & 1)) ct = vec2(1.0);}
		}else{
			if (tc.x < 32){if (bool((0x90000048 >> (31 - tc.x)) & 1)) ct = vec2(1.0);}
			else          {if (bool((0x003cf000 >> (63 - tc.x)) & 1)) ct = vec2(1.0);}
		}
	}

	color += vec3(ct.x * ct.y * (-4.0 / 255.0));
	#ifdef HDR_ENABLED
		color += IGN(gl_FragCoord.xy) * (1.0 / 1023.0);
	#else
		color += IGN(gl_FragCoord.xy) * (1.0 / 255.0);
	#endif
	//color = saturate(color);
}

vec3 sRGB_EncodeSafe(vec3 c) {
   // 为宽色域保存符号
   vec3 s = sign(c);
   c = abs(c);
    
   // sRGB 编码
   c = mix(
		c * 12.92, 
		pow(c, vec3(1.0 / 2.4)) * 1.055 - 0.055,
		step(vec3(0.0031308), c)
	);

   // 恢复符号
   return c * s;
}

uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;

#include "/Lib/Uniform/GbufferTransforms.glsl"
#include "/Lib/PathTracing/Voxelizer/VoxelProfile.glsl"
#include "/Lib/Uniform/ShadowTransforms.glsl"

uniform usampler2D rtwImportance2D;

uniform usampler3D voxelID3D;
uniform sampler3D voxelData3D;
uniform sampler3D voxelColor3D;

//uniform sampler2D rippleX2D;
//uniform sampler2D ripple2D;

//uniform sampler2D colortex15;
//uniform sampler2D colortex17;

//uniform sampler2D prevDepth2D;

//uniform sampler2D debugtex;

//uniform mat4 gbufferPreviousProjection;

/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void main(){
	vec3 color = vec3(BACKGROUND_COLOR_R, BACKGROUND_COLOR_G, BACKGROUND_COLOR_B);

	ivec2 texel = ivec2(gl_FragCoord.xy);

	#if defined CUSTOM_RENDER_RESOLUTION && CUSTOM_SCALE_MODE == 1
		const float customAspectRatio = float(CUSTOM_RENDER_RESOLUTION_X) / float(CUSTOM_RENDER_RESOLUTION_Y);
		texel += customAspectRatio >= aspectRatio ? ivec2(0, (viewWidth / customAspectRatio - viewHeight) * 0.5) : ivec2((viewHeight * customAspectRatio - viewWidth) * 0.5, 0);

		color = texelFetch(FBTEX_GSOLID_NORMAL, texel, 0).rgb;
		#ifndef RENDERING_MODE
			color = FidelityFX_CAS(FBTEX_GSOLID_NORMAL, color, texel);
		#endif
	#else
		#ifdef CUSTOM_RENDER_RESOLUTION
			texel /= INTEGER_SCALING;
			texel += ivec2((vec2(CUSTOM_RENDER_RESOLUTION_X, CUSTOM_RENDER_RESOLUTION_Y) - vec2(viewWidth, viewHeight) / INTEGER_SCALING) * 0.5);
			if (clamp(texel, ivec2(0), ivec2(CUSTOM_RENDER_RESOLUTION_X - 1, CUSTOM_RENDER_RESOLUTION_Y - 1)) == texel)
		#endif
			{
			
				color = texelFetch(FBTEX_MAIN_OUTPUT, texel, 0).rgb;
				#ifndef RENDERING_MODE
					#if !defined SUPER_RESOLUTION && defined DECREASE_HAND_GHOSTING && defined DISABLE_PLAYER_TAA_MOTION_BLUR	
						float materialIDs = GetTransMaterialID(texel);
						if (materialIDs == MATID_HAND || materialIDs == MATID_ENTITIES_PLAYER){
							vec2 texCoord = (vec2(texel) + 0.5) * pixelSize;
							color = Fxaa(color, texCoord);
						}else

					#elif !defined SUPER_RESOLUTION && defined DECREASE_HAND_GHOSTING
						float materialIDs = GetTransMaterialID(texel);
						if (materialIDs == MATID_HAND){
							vec2 texCoord = (vec2(texel) + 0.5) * pixelSize;
							color = Fxaa(color, texCoord);
						}else

					#elif !defined SUPER_RESOLUTION && defined DISABLE_PLAYER_TAA_MOTION_BLUR
						float materialIDs = GetTransMaterialID(texel);
						if (materialIDs == MATID_ENTITIES_PLAYER){
							vec2 texCoord = (vec2(texel) + 0.5) * pixelSize;
							color = Fxaa(color, texCoord);
						}else

					#endif
						{
							#if (CAS_SHARPNESS > 0 && defined TAA && !defined SUPER_RESOLUTION) || (FSR2_RCAS_SHARPNESS > 0 && FSR2_SCALE >= 0)
								color = FidelityFX_CAS(FBTEX_MAIN_OUTPUT, color, texel);
							#endif
						}
				#endif
			}

	#endif

	FinalDither(color);

	#ifdef HDR_ENABLED
		color *= HdrGamePeakBrightness / HdrGamePaperWhiteBrightness;
		color = SrgbToLinear(color);
		color *= HdrGamePaperWhiteBrightness / HdrUIBrightness;
		color = sRGB_EncodeSafe(color);
	#endif


#if 0
	const vec2 size = vec2(900, 512);

	const int hres = 512;
	const float intensity = 0.05;
	const float thres = 0.001;

	//if (all(lessThan(texelCoord, ivec2(size + 3.0)))) color = vec3(0.5);
	if (all(lessThan(texelCoord, ivec2(size)))) {

		vec2 uv = texelCoord / size;
		vec3 col = vec3(0);

		//if (texelCoord.y == ivec2(ceil(size.y * 0.75))) col = vec3(0.5);
		//if (texelCoord.y == ivec2(floor(size.y * 0.125))) col = vec3(0.5);

		float s = uv.y * 1.6 - 0.2;
		float maxb = s+thres;
		float minb = s-thres;

		#if 0
			uv.x *= 3.0;

			if (texelCoord.x < int(size.x / 3.0)){   
			for (int i = 0; i <= hres; i++){
				float x = texture(FBTEX_MAIN_OUTPUT, vec2(uv.x, float(i)/float(hres))).r;
				col.r += intensity * step(x, maxb)*step(minb, x);
			}}

			uv.x -= 1.0;

			if (texelCoord.x >= int(size.x / 3.0) && texelCoord.x < int(size.x * 2.0 / 3.0)){
			for (int i = 0; i <= hres; i++) {
				float x = texture(FBTEX_MAIN_OUTPUT, vec2(uv.x, float(i)/float(hres))).g;
				col.g += intensity * step(x, maxb)*step(minb, x);
			}}

			uv.x -= 1.0;

			if (texelCoord.x >= int(size.x * 2.0 / 3.0)){
			for (int i = 0; i <= hres; i++) {
				float x = texture(FBTEX_MAIN_OUTPUT, vec2(uv.x, float(i)/float(hres))).b;
				col.b += intensity * step(x, maxb)*step(minb, x);
			}}
		#else
			for (int i = 0; i <= hres; i++){
				vec3 x = texture(FBTEX_MAIN_OUTPUT, vec2(uv.x, float(i)/float(hres))).rgb;
				col += intensity * step(x, vec3(maxb))*step(vec3(minb), x);
			}

		#endif

		color = col;
	}
#endif
	//color *= BlackBar(SEREEN_RATIO);


	//uint p0 = texelFetch(voxelID3D, ivec3(texelCoord.x, 0, texelCoord.y), 0).x;

	//color = vec3(p0);


	//color = vec3(pow(texelFetch(depthtexS, texelCoord, 0).x, 100.0));
	//color = texelFetch(debugtex, texelCoord, 0).xxx;
	//color = vec3(pow(uintBitsToFloat(texelFetch(depthtexS, texelCoord, 0).x), 100.0));
	
	//color = vec3(pow(0.9992 - texelFetch(FBTEX_MAIN_TEMPORAL, texelCoord, 0).w, 2000.0));
	//color = vec3(abs(texelFetch(FBTEX_MAIN_TEMPORAL, texelCoord, 0).w) * 1000.0);
	//color = vec3(pow(texelFetch(prevDepth2D, texelCoord, 0).x, 100.0));
	//color = vec3(pow(texelFetch(fsrReconstructDepth2D, texelCoord, 0).x, 100.0));
	//color = vec3(pow(texelFetch(waterDepth2D, texelCoord, 0).x, 10000.0));
	//color = texelFetch(vxDepthTexOpaque, texelCoord, 0).xxx;

	//color = pow(color, vec3(1000.0));

	//color = vec3(texelFetch(ripple2D, texelCoord / 5 + ivec2(0, (frameCounter % 60) * 128), 0).z >= 1.0);

	//vec3 rp = texelFetch(ripple2D, texelCoord / 5, 0).xyz;
	//rp.xy = (rp.xy * 2.0 - 1.0) * rp.z;
	//color = vec3(rp.x * 3.0);
	

	//if (texelCoord.x > 1280) color = pow(texelFetch(FBTEX_ALBEDO, texelCoord / 2 - ivec2(150, 0), 0).rgb, vec3(1.0));
	//color = texelFetch(FBTEX_ALBEDO, texelCoord, 0).rgb;
	//color = texelFetch(FBTEX_MAIN_OUTPUT, texelCoord / 50, 0).rgb;
	//color = texelFetch(FBTEX_ALT_OUTPUT, texelCoord, 0).rgb * 10.0;
	//color = texelFetch(FBTEX_MAIN_TEMPORAL, texelCoord, 0).rgb;
	//color = texelFetch(FBTEX_SST_TEMPORAL, texelCoord, 0).rgb * 100.0;
	//color = texelFetch(FBTEX_GWATER, texelCoord, 0).rrr * 10.0;
	//color = texelFetch(FBTEX_GWATER, texelCoord, 0).ggg;
	//color = pow(texelFetch(FBTEX_DIFFUSE_TEMPORAL, texelCoord, 0).rgb * 0.1, vec3(1.0/2.2));
	//color = texelFetch(colortex12, texelCoord, 0).rgb;
	//color = texelFetch(colortex15, texelCoord, 0).rgb;
	#if defined VS_VELOCITY && defined SR_IRIS_EXT_VELOCITY
		//color = pow(abs(texelFetch(colortex16, texelCoord, 0).rgb), vec3(0.2));
	#endif
	//color = pow(texelFetch(skyBox2D, texelCoord >> 3, 0).rgb * 3.0, vec3(1.0 / 2.2));
	//color = texelFetch(LOD_DEPTH_TEX_0, texelCoord, 0).rrr;
	//color = texelFetch(noisetex, texelCoord / 10, 0).ggg;
	//if(hideGUI == 1) color = texelFetch(shadowcolor0, texelCoord, 0).rgb;
	//if(hideGUI == 1) color = vec3(pow(texelFetch(shadowtex0, texelCoord, 0).x * 2.0, 3.0));


	//color = vec3(Unpack2xU8_from_U16(texelFetch(FBTEX_GSOLID_DATA, texelCoord, 0).r), Unpack2xU8_X_from_U16(texelFetch(FBTEX_GSOLID_DATA, texelCoord, 0).b));
	//color = Unpack2xU8_from_U16(texelFetch(FBTEX_GSOLID_DATA, texelCoord, 0).b).y * 255.0 == MATID_WATER ? vec3(1.0, 1.0, 0.0) : color;
	//color = Unpack2xU8_from_U16(texelFetch(FBTEX_GSOLID_DATA, texelCoord, 0).b).xxx;
	//color = texelFetch(colortex12, texelCoord, 0).aaa;

	//color = vec3(uint(texelFetch(FBTEX_GSOLID_DATA, texelCoord, 0).b * 65535.0) & 128u);


	//color = texelFetch(colortex15, texelCoord, 0).rgb;
	//color = YCoCg_To_RGB(texelFetch(colortex15, texelCoord, 0).rgb);
	//color = vec3(pow(texelFetch(colortex15, texelCoord, 0).x, 1000.0));

	//color = vec3(abs(texelFetch(colortex15, texelCoord, 0).xy) * 100.0, 0.0);

	//color = texelFetch(FBTEX_MAIN_TEMPORAL, texelCoord, 0).rgb * 10.0;


	//color = LinearToGamma(texelFetch(FBTEX_SPECULAR_TEMPORAL, texelCoord, 0).rgb * 100.0);

	//color = mix(color, texelFetch(shadowcolor1, texelCoord * 5, 0).bbb, 0.5);


	//color = texelFetch(shadowcolor1, texelCoord * 4, 0).rrr;
	//float sd = texelFetch(shadowtex0, texelCoord * 4, 0).r;
	//color = sd < 1.0 && sd > 0.0 ? vec3(sd) : color;

	//color = texelFetch(FBTEX_GSOLID_TEMPORAL, texelCoord, 0).aaa * 4.0;
	//color = texelFetch(FBTEX_ALT_OUTPUT, texelCoord, 0).aaa * 1.0;

	//color = DecodeNormal(texelFetch(FBTEX_GSOLID_NORMAL, texelCoord, 0).ba);
	//color = DecodeNormal(texelFetch(FBTEX_GTRANS_NORMAL, texelCoord, 0).rg);
	//color = DecodeNormal(texelFetch(FBTEX_GWATER, texelCoord, 0).rg);
	//color = texelFetch(FBTEX_GWATER, texelCoord, 0).bbb;
	//color = Unpack2xU8_from_U16(texelFetch(FBTEX_GWATER, texelCoord, 0).b).xxx;


	

	//uvec4 data9 = texelFetch(FBTEX_GSOLID_TEMPORAL, texelCoord, 0);
	//vec2 packX = unpackUnorm2x16(data9.x);
	//vec2 packY = unpackUnorm2x16(data9.y);

	//color = vec3(packY.y * 256.0 < 3.0);

	//color = texelFetch(voxelData3D, ivec3(texelCoord / 4, 95), 0).zzz;
	//color = texelFetch(voxelColor3D, ivec3(texelCoord / 4 , 95), 0).rgb;

	//vec4 gbuffer5 = texelFetch(FBTEX_GSOLID_DATA, texelCoord, 0);
	//vec4 specTex = vec4(Unpack2xU8_from_U16(gbuffer5.x), Unpack2xU8_from_U16(gbuffer5.y));
	//color = vec3(specTex.xy, 0.0);

	//color = vec3(texelFetch(FBTEX_SPECULAR_TEMPORAL, texelCoord, 0).a);

	//color = vec3(texelFetch(FBTEX_SST_TEMPORAL, texelCoord, 0).a);

	//color = vec3(Unpack2xU16_from_F32(texelFetch(FBTEX_MAIN_TEMPORAL, texelCoord, 0).a).x * 10.0);
	//color = HSV_to_RGB_Smooth(vec3(texCoord.x, 1.0, 1.0));

	//float materialIDs 				= GetTransMaterialID(texelCoord);
	//color = vec3(materialIDs * 0.1);


//#define DEBUG_RTW

#ifdef DEBUG_RTW
	if (all(lessThan(texelCoord, ivec2(512.0)))){

		float importance = uintBitsToFloat(texelFetch(rtwImportance2D, texelCoord * 2, 0).x);

		color = vec3(importance);
	}

	if (clamp(texelCoord.y, 512, 599) == texelCoord.y && texelCoord.x < 512){

		float importance = uintBitsToFloat(texelFetch(rtwImportance2D, ivec2(texelCoord.x * 2, 0), 0).x);

		color = vec3(importance);

		if (texelCoord.y >= 555){
			color = vec3(0.0);
			importance = texelFetch(rtwWarp1D, ivec2(texelCoord.x * 2, 0), 0).x * 4.0 - 2.0;
			color.r +=  importance * float(importance > 0);
			color.b += -importance * float(importance < 0);
		}
	}

	if (clamp(texelCoord.x, 512, 599) == texelCoord.x && texelCoord.y < 512){

		float importance = uintBitsToFloat(texelFetch(rtwImportance2D, ivec2(texelCoord.y * 2, 1), 0).x);

		color = vec3(importance);

		if (texelCoord.x >= 555){
			color = vec3(0.0);
			importance = texelFetch(rtwWarp1D, ivec2(texelCoord.y * 2, 1), 0).x * 4.0 - 2.0;
			color.r +=  importance * float(importance > 0);
			color.b += -importance * float(importance < 0);
		}
	}

	if (clamp(texelCoord, ivec2(0, 600), ivec2(511, 1111)) == texelCoord){
		color = vec3(0.0);
		vec2 sst = (vec2(texelCoord - ivec2(0, 600)) + 0.5) / 512.0;

		color = textureLod(shadowcolor0, sst, 0.0).rgb;

	}
#endif

	#ifdef DEBUG_COUNTER
		color = saturate(color);
		vec2 tCoord = gl_FragCoord.xy;
		float scale = 4.0;

		//mat4 tmat = gbufferPreviousProjection;

		if (clamp(tCoord, vec2(0.0), vec2(300.0, 50.0) * scale) == tCoord){
			color = clamp(color.rgb * 0.5, vec3(0.0), vec3(0.8));

			//color += PrintFloat(ssb_gbufferPreviousProjectionInverse0.z, vec2(50.0, 35.0) * scale, scale);

			//color += PrintFloat(texelFetch(pixelData2D, ivec2(7, 0), 0).x, vec2(50.0, 25.0) * scale, scale);
			//color += PrintFloat(texelFetch(pixelData2D, ivec2(9, 0), 0).x / 32768.0, vec2(50.0,  5.0) * scale, scale);
			//color += PrintFloat(eyeBrightnessSmoothCurved, vec2(50.0, 15.0) * scale, scale);
			//
			

			//color += PrintFloat(texelFetch(pixelData2D, ivec2(PIXELDATA_EXPOSURE, 0), 0).x, vec2(50.0, 35.0) * scale, scale);
			//color += PrintFloat(float(ssb_mipmapMappingSpaced[3].x), vec2(50.0, 35.0) * scale, scale);

			//color += PrintFloat(float(frameCounter), vec2(50.0, 35.0) * scale, scale);
			//color += PrintFloat(frameTimeCounter, vec2(50.0, 25.0) * scale, scale);


/*
			const int nc = 100;
			const float onc = float(nc / 2) - 0.5;
			float np = 0.0;
			for (int x = 0; x < nc; x++){
			for (int y = 0; y < nc; y++){
				vec2 p = (vec2(x, y) - onc) / float(nc);

				float r = p.x * p.x + p.y * p.y + 0.25;

				np += pow(r, -3.0 / 2.0) * (0.75 / PI);
			}}

			color += PrintFloat(np / (float(nc) * float(nc)), vec2(50.0, 35.0) * scale, scale);
*/

			//color += PrintFloat(dgc.x, vec2(300.0, 235.0) * scale, scale);
			//color += PrintFloat(SRJitterOffset.y, vec2(300.0, 225.0) * scale, scale);
			//color += PrintFloat(SRPreviousJitterOffset.x, vec2(300.0, 215.0) * scale, scale);
			//color += PrintFloat(SRPreviousJitterOffset.y, vec2(300.0, 205.0) * scale, scale);
			//color += PrintFloat(fsqrt(length(cameraPositionToPrevious)) * 5.0, vec2(150.0, 25.0) * scale, scale);

/*

			vec3 t = Blackbody(8000.0);
			color += PrintFloat(t.x, vec2(50.0, 35.0) * scale, scale);
			color += PrintFloat(t.y, vec2(50.0, 25.0) * scale, scale);
			color += PrintFloat(t.z, vec2(50.0, 15.0) * scale, scale);
		

			//const float vx = 21;

			//const vec2 vwh = vec2(512, 512);

			//const float vy = ceil(vwh.y / vx);

			//color += PrintFloat(vx * vwh.x + 2048.0, vec2(50.0, 35.0) * scale, scale);
			//color += PrintFloat(vy * vwh.x, vec2(50.0, 25.0) * scale, scale);
			//color += PrintFloat(vx * vwh.x, vec2(50.0, 5.0) * scale, scale);
//*/


			//color += PrintFloat(LinearDepth_From_ScreenDepth(ScreenDepth_From_LODScreenDepth(texelFetch(LOD_DEPTH_TEX_0, ivec2(screenSize * 0.5), 0).x)), vec2(50.0, 35.0) * scale, scale);
			//color += PrintFloat(texelFetch(FBTEX_MAIN_TEMPORAL, ivec2(2, 0), 0).a, vec2(50.0, 25.0) * scale, scale);



			//vec2 r2 = Sequences_R2(16.0) * 2.0 - 1.0;


			//color += PrintFloat(r2.x, vec2(50.0, 35.0) * scale, scale);
			//color += PrintFloat(r2.y, vec2(50.0, 25.0) * scale, scale);
			

/*
			color += PrintFloat(tmat[0][0], vec2(50.0, 35.0) * scale, scale);
			color += PrintFloat(tmat[1][0], vec2(100.0, 35.0) * scale, scale);
			color += PrintFloat(tmat[2][0], vec2(150.0, 35.0) * scale, scale);
			color += PrintFloat(tmat[3][0], vec2(200.0, 35.0) * scale, scale);

			color += PrintFloat(tmat[0][1], vec2(50.0, 25.0) * scale, scale);
			color += PrintFloat(tmat[1][1], vec2(100.0, 25.0) * scale, scale);
			color += PrintFloat(tmat[2][1], vec2(150.0, 25.0) * scale, scale);
			color += PrintFloat(tmat[3][1], vec2(200.0, 25.0) * scale, scale);

			color += PrintFloat(tmat[0][2], vec2(50.0, 15.0) * scale, scale);
			color += PrintFloat(tmat[1][2], vec2(100.0, 15.0) * scale, scale);
			color += PrintFloat(tmat[2][2], vec2(150.0, 15.0) * scale, scale);
			color += PrintFloat(tmat[3][2], vec2(200.0, 15.0) * scale, scale);

			color += PrintFloat(tmat[0][3], vec2(50.0, 5.0) * scale, scale);
			color += PrintFloat(tmat[1][3], vec2(100.0, 5.0) * scale, scale);
			color += PrintFloat(tmat[2][3], vec2(150.0, 5.0) * scale, scale);
			color += PrintFloat(tmat[3][3], vec2(200.0, 5.0) * scale, scale);
//*/		
		}
	#endif


/*
color = vec3(0.0);

const float cellSize = 15.0;
const float cellNum = 45.0;
const float maxAngle = 90.0;
const float ringInterval = 5.0;

vec2 fragCoord = floor(gl_FragCoord.xy);
fragCoord -= floor(screenSize * 0.5 - cellSize * 0.5);

vec2 cellPos = (floor(fragCoord / cellSize) * cellSize) / (cellSize * cellNum);
float angle = maxVec2(abs(cellPos));

if (angle <= 1.0){
	float z = cos(angle * (maxAngle / 180.0) * PI);
	vec2 dir = normalize(cellPos);
	vec2 xy = dir * sqrt((1.0 - z * z) / dot(dir, dir));

	vec3 normal = normalize(vec3(xy, z));
	if (angle == 0.0) normal = vec3(0.0, 0.0, 1.0);

	color = normal * 0.5 + 0.5;

	vec2 checkCoord = abs(fragCoord - cellSize * 0.5 + 0.5);
	vec2 grid = checkCoord - cellSize * 0.5 - 0.5;
	float ring = maxVec2(grid);

	if (mod(ring, cellSize) == 0.0){
		color = mix(
			color, 
			vec3(1.0), 
			float(mod(ring, cellSize * ringInterval) == 0.0) * 0.5 + 0.3
		);
	}else if (any(equal(mod(grid, cellSize), vec2(0.0)))){
		color = mix(color, vec3(0.0), 0.1);
	}
}

//*/
	


	//if (texelCoord.x < 400) color = vec3(1.3);


	gl_FragData[0] = vec4(color, 0.0);

}


#endif
////////////////////END_IF//////////////////////////////////////////////////////////////////////////
