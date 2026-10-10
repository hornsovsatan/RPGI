

#extension GL_KHR_shader_subgroup_arithmetic : enable


#define PROGRAM_UPDATE_SSBO

#include "/Lib/Utilities.glsl"
#include "/Lib/UniformDeclare.glsl"


const ivec3 workGroups = ivec3(1, 1, 1);
layout (local_size_x = 32, local_size_y = 16) in;


layout (rg16f) uniform image2D img_pixelData2D;
#if SR_ENABLE == 1
	layout(r32f) writeonly uniform image2D colorimg17;
#endif


#if defined MC_GL_VENDOR_NVIDIA || defined MC_GL_VENDOR_AMD
	shared vec2 prefixSumCache[16];
#else
	shared vec2 prefixSumCache[32];
#endif

float GetExposureValue(float luminance){
	#ifdef MANUAL_EXPOSURE
		return 1.5e5 * exp2(-EV_VALUE);
	#else
		float aeCurve = AE_CURVE;
		#ifndef DISABLE_NIGHTVISION
			aeCurve = mix(aeCurve, saturate(aeCurve * 1.2), nightVision);
		#endif
		#ifdef AE_CLAMP
		#ifndef DIMENSION_NETHER
			aeCurve *= remapSaturate(luminance, 2.0, 1.0) * 0.6 + 0.4;
		#endif
		#endif
		#ifdef DIMENSION_END
			aeCurve = aeCurve * 0.9;
		#endif
		#ifdef DIMENSION_NETHER
			aeCurve = aeCurve * 0.9 + 0.1;
		#endif
		float ae = pow(luminance, -aeCurve);

		ae *= exp2(AE_OFFSET);

		#ifndef DISABLE_BLINDNESS_DARKNESS
			ae *= 1.0 - min(darknessLightFactor * 2.0, 0.9);
		#endif
		
		#ifdef DIMENSION_END
			ae *= 7.0;
		#else
			ae *= 7.8;
		#endif

		return ae;
	#endif
}

void main(){
	vec2 texCoord = (vec2(gl_GlobalInvocationID.xy) + 0.5) * vec2(1.0 / 32.0, 1.0 / 16.0);

	vec2 sampleCoord = texCoord * (1.0 / 64.0);
	sampleCoord.x += (15.0 / 32.0) + pixelSize.x * 12.0;

	float tileExposure = Luminance(textureLod(FBTEX_ALT_OUTPUT, sampleCoord, 0.0).rgb);


	vec2 sampleLuminance = vec2(tileExposure, 0.0);
	sampleLuminance = subgroupInclusiveAdd(sampleLuminance);

	if (gl_SubgroupInvocationID == gl_SubgroupSize - 1u) 
		prefixSumCache[gl_SubgroupID] = sampleLuminance;

	barrier();

	uint loopLength = uint(findMSB(gl_NumSubgroups));
	loopLength += uint(gl_NumSubgroups - (1u << (loopLength - 1u)) > 0u);

	for (uint i = 0; i < loopLength; i++){
		if ((gl_SubgroupID & (1u << i)) > 0u){
			sampleLuminance += prefixSumCache[(gl_SubgroupID >> i << i) - 1u];
		
			if (gl_SubgroupInvocationID == gl_SubgroupSize - 1u) 
				prefixSumCache[gl_SubgroupID] = sampleLuminance;
		}

		barrier();
	}

	if (gl_LocalInvocationIndex == 511u)
		prefixSumCache[0] = sampleLuminance / 512.0;;

	barrier();


	float avg = prefixSumCache[0].x;

	vec2 tileDistance = texCoord * 2.0 - 1.0;
	tileDistance.y /= aspectRatio;
		float centerDistance = length(tileDistance);
	
	#if AE_MODE == 0
		#ifdef DIMENSION_END
			float tileWeight = 1.0;
		#else
			float tileWeight = remapSaturate(centerDistance, 0.6, 0.4);
		#endif
	#elif AE_MODE == 1
		float tileWeight = remapSaturate(centerDistance, 0.7, 0.0);
		tileWeight *= tileWeight;
	#elif AE_MODE == 2
		float tileWeight = remapSaturate(centerDistance, 0.6, 0.4);
	#elif AE_MODE == 3
		float tileWeight = 1.0;
	#endif

	#ifdef AE_CLAMP
		tileExposure = max(7e-7, tileExposure);
	#endif

	#if defined CAVE_MODE && defined DIMENSION_OVERWORLD
		float lumaWeight = avg / tileExposure;
		tileWeight *= pow(lumaWeight, 0.7);
	#else
		#if LUMINANCE_WEIGHT_MODE > 0 
			#if LUMINANCE_WEIGHT_MODE == 1
				#ifdef DIMENSION_NETHER
					float lumaWeight = avg / tileExposure;
					lumaWeight = pow(lumaWeight, 0.4);
				#else
					float lumaWeight = avg / tileExposure;
					#ifdef DIMENSION_OVERWORLD
						lumaWeight = pow(lumaWeight, remapSaturate(avg, 0.02, 0.001) * 0.6);
					#else
						lumaWeight = pow(lumaWeight, remapSaturate(avg, 0.02, 0.001) * 0.4 + 0.2);
					#endif
				#endif
			#elif LUMINANCE_WEIGHT_MODE == 2
				#ifdef DIMENSION_NETHER
					float lumaWeight = avg / tileExposure;
					lumaWeight = pow(lumaWeight, 0.4);
				#else
					float lumaWeight = avg / tileExposure;
					lumaWeight = pow(lumaWeight, remapSaturate(avg, 0.02, 0.001) * 0.4 + 0.2);
				#endif				
			#elif LUMINANCE_WEIGHT_MODE == 3
				float lumaWeight = avg / tileExposure;
				lumaWeight = pow(lumaWeight, LUMINANCE_WEIGHT_STRENGTH);
			#elif LUMINANCE_WEIGHT_MODE == 4
				float lumaWeight = tileExposure / avg;
				lumaWeight = pow(lumaWeight, LUMINANCE_WEIGHT_STRENGTH);
			#endif
			tileWeight *= lumaWeight;
		#endif
	#endif


	vec2 sampleExposure = vec2(tileExposure * tileWeight, tileWeight);
	sampleExposure = subgroupInclusiveAdd(sampleExposure);

	if (gl_SubgroupInvocationID == gl_SubgroupSize - 1u) 
		prefixSumCache[gl_SubgroupID] = sampleExposure;

	barrier();

	for (uint i = 0; i < loopLength; i++){
		if ((gl_SubgroupID & (1u << i)) > 0u){
			sampleExposure += prefixSumCache[(gl_SubgroupID >> i << i) - 1u];
		
			if (gl_SubgroupInvocationID == gl_SubgroupSize - 1u) 
				prefixSumCache[gl_SubgroupID] = sampleExposure;
		}

		barrier();
	}


	if (gl_LocalInvocationIndex == 511u){
		float avgExposure = max(sampleExposure.x / sampleExposure.y * 29.3, 1e-10);
		//avgExposure = max(avgExposure * 29.3, 1e-5);

		#ifdef SMOOTH_EXPOSURE
			avgExposure = log2(avgExposure);
			float prevAvgExposure = log2(texelFetch(pixelData2D, ivec2(PIXELDATA_EXPOSURE, 0), 0).x);
			#ifdef IS_IRIS
				float frameTimeFixed = frameTime + step(frameCounter, 20) * 100.0;
				float exposureTime = saturate(frameTimeFixed * (2.0 / EXPOSURE_TIME));
			#else
				float exposureTime = saturate(frameTime * (2.0 / EXPOSURE_TIME));
			#endif
			avgExposure = mix(prevAvgExposure, avgExposure, exposureTime);
			avgExposure = max(exp2(avgExposure), 1e-5);
		#endif

    	float exposure = GetExposureValue(avgExposure);
		//exposure = 1000.0;

		//data.a = 100000000000.0;

		imageStore(img_pixelData2D, ivec2(PIXELDATA_EXPOSURE, 0), vec4(avgExposure, exposure, 0.0, 0.0));
		#if SR_ENABLE == 1
			#if SR_ALGO_DLSS_RENDERPRESET == SR_ALGO_DLSS_RENDERPRESET_L || SR_ALGO_DLSS_RENDERPRESET == SR_ALGO_DLSS_RENDERPRESET_M
				float preExposure = saturate(exposure * 0.0005 - 0.5) * 25.0 + 1.0;
				imageStore(colorimg17, ivec2(0, 0), vec4(exposure, preExposure, 0.0, 0.0));
			#else
				imageStore(colorimg17, ivec2(0, 0), vec4(exposure, 0.0, 0.0, 0.0));
			#endif
		#endif
	}
}