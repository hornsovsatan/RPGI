


/*
vec3 GetPreviousPos(vec3 screenPos, out vec3 prevWorldPos, out float normalWeight){
	prevWorldPos = screenPos * 2.0 - 1.0;
	#if defined TAA || defined SUPER_RESOLUTION
		prevWorldPos.xy -= UNIFORM_TAA_JITTER;
	#endif

	#ifdef LOD_RENDERING
		if (screenPos.z < 0.0){
			prevWorldPos.z = -depth * 2.0 - 1.0;
			prevWorldPos = (vec3(vec2(gbufferProjectionInverse0.x, gbufferProjectionInverse0.y) * prevWorldPos.xy, 0.0) + lodProjectionInverse1) / (lodProjectionInverse0.x * prevWorldPos.z + lodProjectionInverse0.y);
			screenPos.z = 1.0;
		}else{
			prevWorldPos = (vec3(vec2(gbufferProjectionInverse0.x, gbufferProjectionInverse0.y) * prevWorldPos.xy, 0.0) + gbufferProjectionInverse1) / (gbufferProjectionInverse0.z * prevWorldPos.z + gbufferProjectionInverse0.w);
		}
	#else
		prevWorldPos = (vec3(vec2(gbufferProjectionInverse0.x, gbufferProjectionInverse0.y) * prevWorldPos.xy, 0.0) + gbufferProjectionInverse1) / (gbufferProjectionInverse0.z * prevWorldPos.z + gbufferProjectionInverse0.w);
	#endif

	normalWeight = 30.0 / (1.0 - prevWorldPos.z);

	if (screenPos.z < 0.7){
		prevWorldPos += (gbufferPreviousModelView[3].xyz - gbufferModelView[3].xyz) * MC_HAND_DEPTH;
	}else{
		prevWorldPos = mat3(gbufferModelViewInverse) * prevWorldPos + gbufferModelViewInverse[3].xyz + cameraPositionToPrevious;
	}

	vec3 prevScreenPos = prevWorldPos;
	if (screenPos.z >= 0.7) prevScreenPos = mat3(gbufferPreviousModelView) * prevScreenPos + gbufferPreviousModelView[3].xyz;
	prevScreenPos = (vec3(gbufferPreviousProjection0.x, gbufferPreviousProjection0.y, gbufferPreviousProjection0.z) * prevScreenPos + gbufferPreviousProjection1) / -prevScreenPos.z * 0.5 + 0.5;

	#if defined TAA || defined SUPER_RESOLUTION
		prevScreenPos.xy += UNIFORM_TAA_JITTER * 0.5;
	#endif

	return prevScreenPos;
}
*/

vec4 DiffuseTemporalFilter(float depth, vec4 normalData){
	//vec4 integratedData = vec4(currColor, 1.0);
	float maxAccumFrames = depth < 0.7 ? 24.0 : PT_DIFFUSE_TEMPORAL_MAX_ACCUM;
	maxAccumFrames = min(maxAccumFrames * clamp(0.01666667 / frameTime, 1.0, 3.0), 256.0);

	// reprojection
	#if defined VS_VELOCITY && defined SR_IRIS_EXT_VELOCITY
		vec3 prevScreenPos = vec3(texCoord, depth);
		#if defined TAA || defined SUPER_RESOLUTION
			prevScreenPos.xy -= UNIFORM_TAA_JITTER * 0.5;
		#endif
		prevScreenPos -= texelFetch(colortex16, texelCoord, 0).xyz;

		vec3 prevWorldPos = prevScreenPos * 2.0 - 1.0;
		float viewZ;

		#ifdef LOD_RENDERING

			if (depth < 0.0){
				prevWorldPos = vec3(texCoord, -depth) * 2.0 - 1.0;
				#if defined TAA || defined SUPER_RESOLUTION
					prevWorldPos.xy -= UNIFORM_TAA_JITTER;
				#endif

				prevWorldPos = (vec3(vec2(gbufferProjectionInverse0.x, gbufferProjectionInverse0.y) * prevWorldPos.xy, 0.0) + lodProjectionInverse1) / (lodProjectionInverse0.x * prevWorldPos.z + lodProjectionInverse0.y);
				viewZ = -prevWorldPos.z;
				prevWorldPos = mat3(gbufferModelViewInverse) * prevWorldPos + gbufferModelViewInverse[3].xyz + cameraPositionToPrevious;
				
				prevScreenPos = prevWorldPos;
				prevScreenPos = mat3(gbufferPreviousModelView) * prevScreenPos + gbufferPreviousModelView[3].xyz;
				prevScreenPos = (vec3(gbufferPreviousProjection0.x, gbufferPreviousProjection0.y, gbufferPreviousProjection0.z) * prevScreenPos + gbufferPreviousProjection1) / -prevScreenPos.z * 0.5 + 0.5;

				depth = 1.0;
			}else

		#endif
		{
			prevWorldPos = (vec3(vec2(ssb_gbufferPreviousProjectionInverse0.x, ssb_gbufferPreviousProjectionInverse0.y) * prevWorldPos.xy, 0.0) + ssb_gbufferPreviousProjectionInverse1) / (ssb_gbufferPreviousProjectionInverse0.z * prevWorldPos.z + ssb_gbufferPreviousProjectionInverse0.w);
			
			viewZ = max(-prevWorldPos.z, 0.0);
			
			if (depth < 0.7){
				prevWorldPos += (gbufferModelView[3].xyz - gbufferPreviousModelView[3].xyz) * MC_HAND_DEPTH;
			}else{
				prevWorldPos = (prevWorldPos - gbufferPreviousModelView[3].xyz) * mat3(gbufferPreviousModelView);
			}
		}

		#if defined TAA || defined SUPER_RESOLUTION
			prevScreenPos.xy += UNIFORM_TAA_JITTER * 0.5;
		#endif
		
	#else
		vec3 prevWorldPos = vec3(texCoord, depth) * 2.0 - 1.0;
		#if defined TAA || defined SUPER_RESOLUTION
			prevWorldPos.xy -= UNIFORM_TAA_JITTER;
		#endif

		#ifdef LOD_RENDERING
			if (depth < 0.0){
				prevWorldPos.z = -depth * 2.0 - 1.0;
				prevWorldPos = (vec3(vec2(gbufferProjectionInverse0.x, gbufferProjectionInverse0.y) * prevWorldPos.xy, 0.0) + lodProjectionInverse1) / (lodProjectionInverse0.x * prevWorldPos.z + lodProjectionInverse0.y);
				depth = 1.0;
			}else{
				prevWorldPos = (vec3(vec2(gbufferProjectionInverse0.x, gbufferProjectionInverse0.y) * prevWorldPos.xy, 0.0) + gbufferProjectionInverse1) / (gbufferProjectionInverse0.z * prevWorldPos.z + gbufferProjectionInverse0.w);
			}
		#else
			prevWorldPos = (vec3(vec2(gbufferProjectionInverse0.x, gbufferProjectionInverse0.y) * prevWorldPos.xy, 0.0) + gbufferProjectionInverse1) / (gbufferProjectionInverse0.z * prevWorldPos.z + gbufferProjectionInverse0.w);
		#endif

		float viewZ = -prevWorldPos.z;

		if (depth < 0.7){
			prevWorldPos += (gbufferPreviousModelView[3].xyz - gbufferModelView[3].xyz) * MC_HAND_DEPTH;
		}else{
			prevWorldPos = mat3(gbufferModelViewInverse) * prevWorldPos + gbufferModelViewInverse[3].xyz + cameraPositionToPrevious;
		}

		vec3 prevScreenPos = prevWorldPos;
		if (depth >= 0.7) prevScreenPos = mat3(gbufferPreviousModelView) * prevScreenPos + gbufferPreviousModelView[3].xyz;
		prevScreenPos = (vec3(gbufferPreviousProjection0.x, gbufferPreviousProjection0.y, gbufferPreviousProjection0.z) * prevScreenPos + gbufferPreviousProjection1) / -prevScreenPos.z * 0.5 + 0.5;


		#if defined TAA || defined SUPER_RESOLUTION
			prevScreenPos.xy += UNIFORM_TAA_JITTER * 0.5;
		#endif

	#endif

	const float jitterStrength = min(13.0 / maxAccumFrames, 0.25);
	prevScreenPos.xy += taaJitterToPrevious * jitterStrength;



	float normalWeight = 30.0 / (viewZ + 1.0);


	vec4 prevData = vec4(0.0);
	float accumFrames = 1.0;


	if (saturate(prevScreenPos.xy) == prevScreenPos.xy){
		vec2 prevTexelcoord = prevScreenPos.xy * UNIFORM_SCREEN_SIZE - 0.5;
		vec2 prevTexel = floor(prevTexelcoord);

		vec3 worldNormal = DecodeNormal(normalData.xy);
		vec3 vertexNormal = DecodeNormal(normalData.zw);

		float weights = 0.0;
		float maxTapWeight = 0.0;

		for (int i = 0; i < 4; i++){
			vec2 sampleTexelcoord = prevTexel + vec2(i & 1, i >> 1);
			ivec2 sampleTexel = ivec2(sampleTexelcoord);

			float bilinearWeight = (1.0 - abs(prevTexelcoord.x - sampleTexelcoord.x)) * (1.0 - abs(prevTexelcoord.y - sampleTexelcoord.y));

			vec4 sampleData = texelFetch(FBTEX_DIFFUSE_TEMPORAL, sampleTexel, 0);
			//vec3 sampleData1 = texelFetch(FBTEX_GSOLID_TEMPORAL, sampleTexel, 0).xyz;
			float sampleDepth = texelFetch(prevDepth2D, sampleTexel, 0).x;

			

			// remove sky
			float sampleWeight = float(sampleData.a > 0 && abs(sampleDepth) < 1.0);

			// reprojection
			vec3 sampleViewPos = vec3((sampleTexelcoord + 0.5) * UNIFORM_PIXEL_SIZE, sampleDepth) * 2.0 - 1.0;
			sampleViewPos.xy -= previousTaaJitter;
			#ifdef LOD_RENDERING
				if (sampleDepth < 0.0){
					sampleViewPos.z = lodPreviousProjection0.y / (-sampleDepth * 2.0 - 1.0 + lodPreviousProjection0.x);
					sampleViewPos = vec3(sampleViewPos.xy / vec2(gbufferPreviousProjection0.x, gbufferPreviousProjection0.y) * sampleViewPos.z, -sampleViewPos.z);
					sampleDepth = 1.0;
				}else{
					sampleViewPos.z = gbufferPreviousProjection1.z / (sampleViewPos.z + gbufferPreviousProjection0.z);
					sampleViewPos = vec3(sampleViewPos.xy / vec2(gbufferPreviousProjection0.x, gbufferPreviousProjection0.y) * sampleViewPos.z, -sampleViewPos.z);
				}
			#else
				sampleViewPos.z = gbufferPreviousProjection1.z / (sampleViewPos.z + gbufferPreviousProjection0.z);
				sampleViewPos = vec3(sampleViewPos.xy / vec2(gbufferPreviousProjection0.x, gbufferPreviousProjection0.y) * sampleViewPos.z, -sampleViewPos.z);
			#endif

			vec3 sampleWorldPos = sampleViewPos;
			if (sampleDepth >= 0.7) sampleWorldPos = (sampleViewPos - gbufferPreviousModelView[3].xyz) * mat3(gbufferPreviousModelView);

			// depth gradient
			vec3 posDiff = prevWorldPos - sampleWorldPos;
			float depthGradient = dot(posDiff, vertexNormal);
			sampleWeight *= step(abs(depthGradient), sampleViewPos.z * -3e-4 + 0.01);

			// normal difference
			vec3 sampleNormal = DecodeNormal(texelFetch(FBTEX_GSOLID_TEMPORAL, sampleTexel, 0).xy);
			float sampleNormalWeight = (normalWeight * sampleData.w + normalWeight) / PT_DIFFUSE_TEMPORAL_MAX_ACCUM;
			sampleWeight *= pow(saturate(dot(sampleNormal, worldNormal)), sampleNormalWeight);

			maxTapWeight = max(maxTapWeight, sampleWeight);
			sampleWeight = bilinearWeight * sampleWeight + 1e-10;

			prevData += sampleData * sampleWeight;
			weights += sampleWeight;
		}
		prevData /= weights;

		if (depth >= 0.7) maxTapWeight *= 1.0 - saturate(exp2(log2(prevScreenPos.z - depth) * 0.7 + 4.0)) * 0.85;

		accumFrames = prevData.w * maxTapWeight + 1.0;
		accumFrames = min(accumFrames, maxAccumFrames);

		if (abs(float(worldTime + isEyeInWater * 150) - texelFetch(pixelData2D, ivec2(PIXELDATA_WORLDTIME, 0), 0).x) > 100.0) accumFrames = 1.0;

	}

	vec4 integratedData = vec4(0.0);

	#ifdef PT_DIFFUSE_TEMPORAL_HISTORY_FIX
		if (accumFrames < 3.5){
			uint lod = uint(round(4.0 - accumFrames));
			vec4 mipmapMapping = vec4(ssb_mipmapMappingSpaced[lod]) * vec4(pixelSize, pixelSize);

			#ifdef SUPER_RESOLUTION
				vec2 mipmapCoord = ldexp(texCoord * fsrRenderScale, -ivec2(lod));
			#else
				vec2 mipmapCoord = ldexp(texCoord, -ivec2(lod)) ;
			#endif			
			mipmapCoord = clamp(mipmapCoord, pixelSize * 0.5, mipmapMapping.zw - pixelSize * 0.5) + mipmapMapping.xy;

			integratedData.xyz = textureLod(FBTEX_ALT_OUTPUT, mipmapCoord, 0.0).rgb;




		}else{
			integratedData.xyz = texelFetch(FBTEX_MAIN_OUTPUT, texelCoord, 0).rgb;
		}
	#else
		integratedData.xyz = texelFetch(FBTEX_MAIN_OUTPUT, texelCoord, 0).rgb;
	#endif

	integratedData.xyz = mix(prevData.xyz, integratedData.xyz, 1.0 / accumFrames);
	integratedData.w = accumFrames;

	return integratedData;
}