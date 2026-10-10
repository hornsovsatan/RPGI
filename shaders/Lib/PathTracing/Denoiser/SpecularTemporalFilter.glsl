

vec4 SpecularTemporalFilter(vec4 currData){
	vec4 integratedData = currData;

	float depth = texelFetch(depthtex0, texelCoord, 0).x;

	// reprojection
	vec3 prevWorldPos = vec3(texCoord, depth) * 2.0 - 1.0;
	#if defined TAA || defined SUPER_RESOLUTION
		prevWorldPos.xy -= UNIFORM_TAA_JITTER;
	#endif
	prevWorldPos = (vec3(vec2(gbufferProjectionInverse0.x, gbufferProjectionInverse0.y) * prevWorldPos.xy, 0.0) + gbufferProjectionInverse1) / (gbufferProjectionInverse0.z * prevWorldPos.z + gbufferProjectionInverse0.w);

	float dist = -prevWorldPos.z;
	if (depth < 0.7){
		#ifndef DECREASE_HAND_GHOSTING
			prevWorldPos += (gbufferPreviousModelView[3].xyz - gbufferModelView[3].xyz) * MC_HAND_DEPTH;
		#endif
	}else{
		prevWorldPos = mat3(gbufferModelViewInverse) * prevWorldPos + gbufferModelViewInverse[3].xyz + cameraPositionToPrevious;
	}

	vec3 prevScreenPos = prevWorldPos;
	if (depth >= 0.7) prevScreenPos = mat3(gbufferPreviousModelView) * prevScreenPos + gbufferPreviousModelView[3].xyz;
	prevScreenPos = (vec3(gbufferPreviousProjection0.x, gbufferPreviousProjection0.y, gbufferPreviousProjection0.z) * prevScreenPos + gbufferPreviousProjection1) / -prevScreenPos.z * 0.5 + 0.5;

	#if defined TAA || defined SUPER_RESOLUTION
		prevScreenPos.xy += UNIFORM_TAA_JITTER * 0.5;
	#endif
	prevScreenPos.xy += taaJitterToPrevious * 0.05;

	if (saturate(prevScreenPos.xy) == prevScreenPos.xy){
		vec2 prevTexelcoord = prevScreenPos.xy * UNIFORM_SCREEN_SIZE - 0.5;
		vec2 prevTexel = floor(prevTexelcoord);

		vec4 normalData = texelFetch(FBTEX_GTRANS_NORMAL, texelCoord, 0);
		vec3 worldNormal = DecodeNormal(normalData.xy);
		vec3 vertexNormal = DecodeNormal(normalData.zw);

		vec4 prevData = vec4(0.0);
		float weights = 0.0;
		float maxTapWeight = 0.0;

		for (int i = 0; i < 4; i++){
			vec2 sampleTexelcoord = prevTexel + vec2(i & 1, i >> 1);
			ivec2 sampleTexel = ivec2(sampleTexelcoord);

			float bilinearWeight = (1.0 - abs(prevTexelcoord.x - sampleTexelcoord.x)) * (1.0 - abs(prevTexelcoord.y - sampleTexelcoord.y));

			vec4 sampleData = texelFetch(FBTEX_SPECULAR_TEMPORAL, sampleTexel, 0);
			float sampleWeight = saturate(sampleData.a * 1e10);

			//vec3 sampleData1 = texelFetch(FBTEX_GSOLID_TEMPORAL, sampleTexel, 0).xyz;
			float sampleDepth = texelFetch(prevDepth2D, sampleTexel, 0).x;

			// remove sky
			sampleWeight *= float(sampleDepth < 1.0);

			// reprojection
			vec3 sampleViewPos = vec3((sampleTexelcoord + 0.5) * UNIFORM_PIXEL_SIZE, sampleDepth) * 2.0 - 1.0;
			sampleViewPos.xy -= previousTaaJitter;
  			sampleViewPos.z = gbufferPreviousProjection1.z / (sampleViewPos.z + gbufferPreviousProjection0.z);
    		sampleViewPos = vec3(sampleViewPos.xy / vec2(gbufferPreviousProjection0.x, gbufferPreviousProjection0.y) * sampleViewPos.z, -sampleViewPos.z);

			vec3 sampleWorldPos = sampleViewPos;
			if (sampleDepth >= 0.7) sampleWorldPos = (sampleViewPos - gbufferPreviousModelView[3].xyz) * mat3(gbufferPreviousModelView);

			// position difference with normal gradient
			vec3 posDiff = prevWorldPos - sampleWorldPos;
			float depthGradient = dot(posDiff, vertexNormal);
			sampleWeight *= step(abs(depthGradient), sampleViewPos.z * -3e-4 + 0.01);

			// normal difference
			vec3 sampleNormal = DecodeNormal(texelFetch(FBTEX_GSOLID_TEMPORAL, sampleTexel, 0).xy);
			sampleWeight *= pow(saturate(dot(sampleNormal, worldNormal)), 1000.0);

			maxTapWeight = max(maxTapWeight, sampleWeight);
			sampleWeight = bilinearWeight * sampleWeight + 1e-10;

			prevData += sampleData * sampleWeight;
			weights += sampleWeight;
		}
		prevData /= weights;

		float smoothness = Unpack2xU8_X_from_U16(texelFetch(FBTEX_GSOLID_DATA, texelCoord, 0).x);
		float blendWeight = saturate(4.25 - smoothness * 4.5);
		#ifdef DISABLE_REFLECTION_TEMPORAL_MOTIONWEIGHT
			blendWeight += 6.0 * (1.0 - smoothness * 0.6);
		#else
			float motionWeight = fsqrt(length(cameraPositionToPrevious)) * smoothness * smoothness;
			motionWeight /= dist * 0.4 + 1.0;
			motionWeight = saturate(1.0 - smoothness * 0.6 - motionWeight * 8.0);
			blendWeight += 6.0 * motionWeight;
		#endif
		blendWeight *= saturate(25.0 - smoothness * 25.0) * max(0.01666667 / frameTime, 1.0);
		
		blendWeight = 1.0 / (maxTapWeight * blendWeight + 1.0);

		#if defined DECREASE_HAND_GHOSTING && !defined DISABLE_HAND_SPECULAR
			if (GetTransMaterialID(texelCoord) == MATID_HAND) blendWeight = 1.0;
		#endif

		integratedData.xyz = mix(prevData.xyz, integratedData.xyz, blendWeight);
	}

	return max(integratedData, 0.0);
}