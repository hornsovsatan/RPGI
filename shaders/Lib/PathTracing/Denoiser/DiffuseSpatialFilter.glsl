

vec4 DiffuseSpatialFilter(float depth){
	vec4 normalData = texelFetch(FBTEX_GSOLID_NORMAL, texelCoord, 0);

	vec3 worldNormal = DecodeNormal(normalData.xy);
	vec3 viewVertexNormal = mat3(gbufferModelView) * DecodeNormal(normalData.zw);

	vec4 currData = texelFetch(FBTEX_MAIN_OUTPUT, texelCoord, 0);
	float currLuminance = Luminance(currData.xyz);

	vec2 accumFramesWeights = texelFetch(FBTEX_ALBEDO, texelCoord, 0).xy;
	//accumFramesWeights.x = accumFramesWeights.x * saturate(currData.w * 1e4 - 1.0) * 0.999 + 0.001;
	accumFramesWeights.x *= 1.0 - exp2(-currLuminance * 8.0) * 0.9;
	bool isUnderSample = accumFramesWeights.y > 0.5;

	vec3 viewPos = ViewPos_From_ScreenPos_Raw(texCoord, depth);
	#ifdef LOD_RENDERING
		if (depth < 0.0){
			viewPos = ViewPos_From_ScreenPos_Raw_LOD(texCoord, -depth);
			depth = 1.0;
		}
	#endif
	vec3 viewDir = normalize(viewPos);

	// The kernel is inspired from Sundial by GeForceLegend.
	#if   SPATIAL_FILTER_ORDER == 0
		vec2 axis = vec2(3.0, 3.0);

	#elif SPATIAL_FILTER_ORDER == 1
		vec2 axis = vec2(3.0, -3.0);

	#elif SPATIAL_FILTER_ORDER == 2
		vec2 axis = vec2(36.0, 0.0);

	#elif SPATIAL_FILTER_ORDER == 3
		vec2 axis = vec2(0.0, 36.0);

	#elif SPATIAL_FILTER_ORDER == 4
		vec2 axis = vec2(16.0, 16.0);

	#elif SPATIAL_FILTER_ORDER == 5
		vec2 axis = vec2(16.0, -16.0);

	#elif SPATIAL_FILTER_ORDER == 6
		vec2 axis = vec2(9.0, 0.0);

	#elif SPATIAL_FILTER_ORDER == 7
		vec2 axis = vec2(0.0, 9.0);

	#endif

	
	//#if SPATIAL_FILTER_ORDER >= 2 && SPATIAL_FILTER_ORDER <= 5
		//float ra = BlueNoise(texelCoord + (SPATIAL_FILTER_ORDER / 2) * ivec2(7, 9)).x * TAU;
		//vec2 rotMat = vec2(cos(ra), sin(ra));
		//axis *= mat2(rotMat.x, rotMat.y, -rotMat.y, rotMat.x);
	//#endif


	#if SPATIAL_FILTER_ORDER >= 2
		float varianceWeight = length(axis) * 0.22 / abs(currData.w);
		varianceWeight *= step(0.7, depth);
	#else
		float varianceWeight = 0.0;
	#endif

	float VdotN = saturate(dot(viewVertexNormal, -viewDir));

	vec2 normalTransDir = normalize(viewVertexNormal.xy + 1e-10);
	float normalTransWeight = -dot(axis, normalTransDir) * saturate(0.8 - VdotN * 1.25);
	axis += normalTransDir * normalTransWeight;


	float depthWeight = -PT_DIFFUSE_SPATIAL_FILTER_DEPTH_WEIGHT;
	float normalWeight = mix(PT_DIFFUSE_SPATIAL_FILTER_NORMAL_WEIGHT, PT_DIFFUSE_SPATIAL_FILTER_NORMAL_WEIGHT * 0.3, saturate(-viewPos.z * 0.01 / (VdotN + 0.1)));
	//normalWeight = 60.0;
	if	(isUnderSample){
		depthWeight = 50.0 / (viewPos.z - 1.0);
		normalWeight = 10.0;
	}


	//#if PT_DIFFUSE_SPATIAL_FILTER_STYLE == 0
	//	vec4 filteredData = currData * accumFramesWeights.x;
	//	float weights = accumFramesWeights.x;
	//#else
		vec4 filteredData = vec4(0.0);
		float weights = 0.0;
	//#endif

#if SPATIAL_FILTER_ORDER >= 2 && SPATIAL_FILTER_ORDER <= 3

	vec2 offset = -axis;
	for (int i = 0; i < 2; i++, offset += axis * 2.0){

#else
		
	float noise = BlueNoiseTemporal(SPATIAL_FILTER_ORDER).x;
	
	vec2 offset = -axis * (noise + 0.5);
	for (int i = 0; i < 3; i++, offset += axis){

#endif

		ivec2 sampleTexel = texelCoord + ivec2(round(offset));
 
		if (sampleTexel == clamp(sampleTexel, ivec2(2), ivec2(UNIFORM_SCREEN_SIZE - 3.0))){
			vec4 sampleData = texelFetch(FBTEX_MAIN_OUTPUT, sampleTexel, 0);
			sampleData.w = abs(sampleData.w);
			float luminanceDiff = Luminance(sampleData.rgb) - currLuminance;
			
			vec4 sampleNormalData = texelFetch(FBTEX_GSOLID_NORMAL, sampleTexel, 0);
			vec3 sampleNormal = DecodeNormal(sampleNormalData.xy);
			vec3 sampleVertexNormal = mat3(gbufferModelView) * DecodeNormal(sampleNormalData.zw);

			float sampleDepth = uintBitsToFloat(texelFetch(depthtexS, sampleTexel, 0).x);
			vec3 sampleViewPos = vec3((vec2(sampleTexel) + 0.5) * UNIFORM_PIXEL_SIZE, sampleDepth);
			#ifdef LOD_RENDERING
				if (sampleDepth == 1.0){
					sampleDepth = texelFetch(LOD_DEPTH_TEX_1, sampleTexel, 0).x;
					sampleViewPos = ViewPos_From_ScreenPos_Raw_LOD(sampleViewPos.xy, sampleDepth);
				}else{
					sampleViewPos = ViewPos_From_ScreenPos_Raw(sampleViewPos.xy, sampleViewPos.z);
				}
			#else
				sampleViewPos = ViewPos_From_ScreenPos_Raw(sampleViewPos.xy, sampleViewPos.z);
			#endif
			
			vec3 posDiff = sampleViewPos - viewPos;
			float posDiffLength = length(posDiff);
			float depthGradient = dot(posDiff, viewVertexNormal);

			float sampleWeight = step(abs(sampleDepth), 0.999999);
			sampleWeight *= exp2(-abs(luminanceDiff) * varianceWeight);

			float geometryWeight = exp2(
				normalWeight * log2(saturate(dot(sampleNormal, worldNormal))) +
				depthWeight * abs(depthGradient)
			);

			float edgeWeight = step(luminanceDiff, 0.0) * step(0.0, dot(-posDiff, sampleVertexNormal));
			edgeWeight *= saturate(2.0 - posDiffLength * 2.0);
			edgeWeight *= saturate(depthGradient * 25.0 - 1.0);

			geometryWeight = geometryWeight * (1.0 - edgeWeight) + edgeWeight;

			sampleWeight = sampleWeight * geometryWeight;

			filteredData += sampleData * sampleWeight;
			weights += sampleWeight;
		}
	}

	//#if PT_DIFFUSE_SPATIAL_FILTER_STYLE == 0
		const float xf = pow(max(PT_DIFFUSE_SPATIAL_FILTER_DETAIL * 0.2 + 0.3, 0.0), 4.0) * 3.0 - 0.03;
		#if SPATIAL_FILTER_ORDER >= 2 && SPATIAL_FILTER_ORDER <= 3
			float centerWeight = min(weights * xf + accumFramesWeights.x * 0.2, accumFramesWeights.x);
		#else
			float centerWeight = min(weights * xf + 1e-5, accumFramesWeights.x);
		#endif

		filteredData += currData * centerWeight;
		filteredData /= weights + centerWeight;
	//#else
	//	#if SPATIAL_FILTER_ORDER >= 2 && SPATIAL_FILTER_ORDER <= 3
	//		filteredData = (filteredData + currData) / (weights + 1.0);
	//	#else
	//		if (weights < 1e-5){
	//			filteredData = currData;
	//		}else{
	//			filteredData /= weights;
	//		}
	//	#endif
	//#endif

	if (isUnderSample) filteredData.w = -filteredData.w;

	#if defined DECREASE_HAND_GHOSTING && SPATIAL_FILTER_ORDER == 7
		if (GetSolidMaterialID(texelCoord) == MATID_HAND){
			vec4 shR = vec4(texelFetch(pixelData2D, ivec2(PIXELDATA_SHR_XY, 0), 0).xy, texelFetch(pixelData2D, ivec2(PIXELDATA_SHR_ZW, 0), 0).xy);
			vec4 shG = vec4(texelFetch(pixelData2D, ivec2(PIXELDATA_SHG_XY, 0), 0).xy, texelFetch(pixelData2D, ivec2(PIXELDATA_SHG_ZW, 0), 0).xy);
			vec4 shB = vec4(texelFetch(pixelData2D, ivec2(PIXELDATA_SHB_XY, 0), 0).xy, texelFetch(pixelData2D, ivec2(PIXELDATA_SHB_ZW, 0), 0).xy);

			filteredData.rgb = DecodeHallucinatedZH3(shR, shG, shB, worldNormal);
			filteredData.rgb = max(filteredData.rgb * 100.0, 0.0);
		}
	#endif

	return filteredData;
}