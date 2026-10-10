

vec4 SpecularSpatialFilter(vec4 currData, float depth){
	vec4 normalData = texelFetch(FBTEX_GTRANS_NORMAL, texelCoord, 0);

	//vec3 worldNormal = DecodeNormal(normalData.xy);
	vec3 viewVertexNormal = mat3(gbufferModelView) * DecodeNormal(normalData.zw);
	
	vec3 viewPos = ViewPos_From_ScreenPos_Raw(texCoord, depth);
	vec3 viewDir = normalize(viewPos);

/*
	vec2 gbuffer5 = texelFetch(FBTEX_GTRANS_DATA, texelCoord, 0).xz;
	vec2 gbuffer5z = Unpack2xU8_ID_from_U16(gbuffer5.y);
	float smoothness = 1.0;
	if (gbuffer5z.y == MATID_STAINEDGLASS){
		smoothness = gbuffer5z.x;
	}else{
		vec2 specularTex = Unpack2xU8_from_U16(gbuffer5.x);
		smoothness = specularTex.y > 229.5 / 255.0 ? -specularTex.x : specularTex.x;
	}

	float roughness = 1.0 - abs(smoothness.x);
	roughness = roughness * roughness;
*/
	vec4 currData1 = texelFetch(FBTEX_DIFFUSE_TEMPORAL, texelCoord, 0);
	vec3 worldNormal = currData1.xyz;
	float roughness = currData1.w;

	vec2 normalTrans = saturate(dot(mat3(gbufferModelView) * worldNormal, -viewDir) * 2.0) * vec2(0.6, -0.2) + vec2(0.4, 1.2);

	vec2 axis = normalize(vec2(cross(viewVertexNormal, viewDir)));

	#if PT_SPECULAR_DENOISE_STYLE == 0
		axis *= saturate(abs(roughness) * 14.0) * 14.0;
		axis *= saturate(abs(currData.w) * 0.25 + 0.35);
		float normalThreshold = 666.6 / (abs(roughness) + 0.06);
		float roughnessThreshold = 300.0 / (1.0 + saturate(-viewPos.z * 0.1));

	#else
		axis *= saturate(abs(roughness) * 17.5) * 17.5;
		axis *= saturate(abs(currData.w) * 0.25 + 0.25);
		float normalThreshold = mix(3000.0, 75.0, saturate(abs(roughness) * 5.0 - 0.25));
		float roughnessThreshold = 100.0 / (1.0 + saturate(-viewPos.z * 0.1));

	#endif

	float luminanceThreshold = saturate(abs(currData.w) * 0.25) * 0.45 + 0.05;
	float distThreshold = abs(currData.w) * 20.0 + 6.0;
	
	#if SPATIAL_FILTER_ORDER == 0
		vec2 noise = vec2(0.0);
		axis *= 2.0;
	#elif SPATIAL_FILTER_ORDER == 1
		vec2 noise = vec2(0.0);
	#elif SPATIAL_FILTER_ORDER == 2
		vec2 noise = BlueNoiseTemporal().yx - 0.5;
		#if defined DECREASE_HAND_GHOSTING && !defined DISABLE_HAND_SPECULAR
			if (GetTransMaterialID(texelCoord) == MATID_HAND) noise = BlueNoise() - 0.5;
		#endif
		axis *= 0.5;
	#endif

	#if SPATIAL_FILTER_ORDER < 2
		vec4 filteredData = currData;
		filteredData.rgb *= pow(length(currData.rgb + 1e-13), luminanceThreshold - 1.0);
		float weights = 1.0;

		const vec2 offset[8] = vec2[8](
			vec2(-1.0, -1.0), vec2(0.0, -1.0), vec2(1.0, -1.0), 
			vec2(-1.0,  0.0),                  vec2(1.0,  0.0), 
			vec2(-1.0,  1.0), vec2(0.0,  1.0), vec2(1.0,  1.0)
		);

		for (int i = 0; i < 8; i++){
		
	#else
		vec4 filteredData = vec4(0.0);
		float weights = 0.0;

		const vec2 offset[9] = vec2[9](
			vec2(-1.0, -1.0), vec2(0.0, -1.0), vec2(1.0, -1.0), 
			vec2(-1.0,  0.0), vec2(0.0,  0.0), vec2(1.0,  0.0), 
			vec2(-1.0,  1.0), vec2(0.0,  1.0), vec2(1.0,  1.0)
		);

		for (int i = 0; i < 9; i++){
		
	#endif

	
		vec2 sampleOffset = (offset[i] + noise) * normalTrans;
		sampleOffset = axis * sampleOffset.x + vec2(axis.y, -axis.x) * sampleOffset.y;

		if (length(sampleOffset) <= distThreshold){
			vec2 sampleCoord = (vec2(texelCoord) + 0.5) + sampleOffset;
			ivec2 sampleTexel = ivec2(floor(sampleCoord));
			sampleCoord *= UNIFORM_PIXEL_SIZE;
	
			if (sampleTexel == clamp(sampleTexel, ivec2(2), ivec2(UNIFORM_SCREEN_SIZE - 3.0))){
				#if SPATIAL_FILTER_ORDER == 0
					vec4 sampleData = textureLod(FBTEX_SPECULAR_TEMPORAL, sampleCoord, 0.0);
				#else
					#ifdef SUPER_RESOLUTION
						vec4 sampleData = textureLod(FBTEX_ALT_OUTPUT, sampleCoord * fsrRenderScale, 0.0);
					#else
						vec4 sampleData = textureLod(FBTEX_ALT_OUTPUT, sampleCoord, 0.0);
					#endif
				#endif
				sampleData.rgb *= pow(length(sampleData.rgb + 1e-13), luminanceThreshold - 1.0);

				float sampleWeight = float(sampleData.a > -6e4);

				vec4 sampleData1 = texelFetch(FBTEX_DIFFUSE_TEMPORAL, sampleTexel, 0);

				sampleWeight *= pow(saturate(dot(sampleData1.xyz, worldNormal)), normalThreshold);
				sampleWeight *= exp2(-roughnessThreshold * abs(sampleData1.w - roughness));

				float sampleDepth = texelFetch(depthtex0, sampleTexel, 0).x;
				vec3 sampleViewPos = ViewPos_From_ScreenPos_Raw(sampleCoord, sampleDepth);			
				float depthGradient = abs(dot(sampleViewPos - viewPos, viewVertexNormal));
				sampleWeight *= step(depthGradient, -viewPos.z * 0.05);

				filteredData += sampleData * sampleWeight;
				weights += sampleWeight;		
			}
		}
	}

	if (weights < 1e-5){
		filteredData = currData;
		
	}else{
		filteredData /= weights;

		filteredData.rgb *= pow(length(filteredData.rgb + 1e-13), 1.0 / luminanceThreshold - 1.0);
	}

	//filteredData = currData;

	return filteredData;
}