

#ifdef LABPBR_SSS
vec3 VariablePenumbraShadow(vec3 worldPos, vec3 vertexNormal, float dist, float sunlight, vec3 albedo, float lightmap, float scatteringStrength, MaterialMask mask, out vec3 sss){
#else
vec3 VariablePenumbraShadow(vec3 worldPos, vec3 vertexNormal, float dist, float sunlight, vec3 albedo, float lightmap, float scatteringStrength, MaterialMask mask){
#endif

	worldPos += gbufferModelViewInverse[3].xyz;
	#ifndef REPROJECTED_HAND_SHADOW
		worldPos -= gbufferModelViewInverse[2].xyz * 0.5 * mask.hand;
	#endif

	#ifdef DIMENSION_END
		vec3 shadowNormal = shadowModelViewEnd * vertexNormal;
		shadowNormal.z = -shadowNormal.z;

		vec3 shadowScreenPos = shadowModelViewEnd * worldPos;
	#else
		vec3 shadowNormal = mat3(shadowModelView0, shadowModelView1, shadowModelView2) * vertexNormal;
		shadowNormal.z = -shadowNormal.z;

		vec3 shadowScreenPos = mat3(shadowModelView0, shadowModelView1, shadowModelView2) * worldPos;
	#endif
	shadowScreenPos *= vec3(shadowProjection[0][0], shadowProjection[0][0], -shadowProjection[0][0] * 0.5);

	float zScale = 1.0 / shadowProjection[0][0];


	#if defined TAA || defined SUPER_RESOLUTION
		vec2 noise = BlueNoiseTemporal();
		#if defined DECREASE_HAND_GHOSTING && defined DISABLE_PLAYER_TAA_MOTION_BLUR
			if (mask.hand > 0.5 || mask.entityPlayer > 0.5) noise = BlueNoise();
		#else
			#ifdef DECREASE_HAND_GHOSTING
				if (mask.hand > 0.5) noise = BlueNoise();
			#endif
			#ifdef DISABLE_PLAYER_TAA_MOTION_BLUR
				if (mask.entityPlayer > 0.5) noise = BlueNoise();
			#endif
		#endif
	#else
		vec2 noise = BlueNoise();
	#endif

	vec3 result = vec3(1.0);


	#ifdef LABPBR_SSS
		sss = vec3(0.0);

		if (scatteringStrength > 0.0){
			vec3 shadowScreenPosRaw = shadowScreenPos * 0.5 + 0.5;

			float spread = (scatteringStrength * 0.12 + 0.05) * shadowProjection[0][0];
			vec3 scatteringDensity = 20.0 / (scatteringStrength * albedo + 0.1);

			const float rSteps = 1.0 / SSS_QUALITY;

			float angle = noise.x * TAU;
			vec2 rot = vec2(cos(angle), sin(angle));

			float scatteringDepth = 0.0;

			for (int i = 0; i < SSS_QUALITY; i++){
				rot *= rotMatGR;
				float radius = (float(i) + noise.y) * rSteps;
				vec2 offset = rot * spread * radius;
		
				vec3 sampleCoord = vec3(shadowScreenPosRaw.xy + offset, shadowScreenPosRaw.z);
				sampleCoord.xy += SampleRTWWarpSmooth(sampleCoord.xy);
				//ShiftShadowScreenPos(sampleCoord.xy);

				float sampleDepth = textureLod(shadowtex0, sampleCoord.xy, 0.0).x;

				scatteringDepth += max(sampleCoord.z - sampleDepth, 1e-5);
			}
			scatteringDepth *= rSteps * zScale;

			vec3 scattering = exp2(-scatteringDepth * scatteringDensity);
			//scattering = vec3(remapSaturate(scatteringDepth, 0.15, 0.1));

			float distFalloff = saturate(((min(shadowDistance, far) - length(worldPos)) * 0.05 - 1.0));

			//#ifdef SSS_NORMAL
			//	sss = scattering * (SSS_BRIGHTNESS * distFalloff * (MiePhaseFunction(0.5, dot(worldNormal, -worldShadowVector)) * 0.5 + 0.15));
			//#else
				sss = scattering * (SSS_BRIGHTNESS * distFalloff * 0.2);
			//#endif

			scatteringStrength *= distFalloff; 
		}
	#endif

	if (sunlight > 0.0){
		float maskPlant = mask.leaves + mask.grass * 0.7;

		shadowScreenPos += shadowNormal * (max(2e-4, 1e-5 * dist) * (1.0 - maskPlant));


		vec2 shadowCoord = shadowScreenPos.xy * 0.5 + 0.5;
		vec4 warp = SampleRTWWarpSmoothWithPixelSize(shadowCoord);
		vec2 warpPixelSizeMinMax = vec2(minVec2(warp.zw), maxVec2(warp.zw)) * warpPixelScale;

		shadowCoord += warp.xy;	
		if (all(bvec2(shadowCoord == clamp(shadowCoord, vec2(shadowPixelSize), vec2(1.0 - shadowPixelSize)), shadowScreenPos.z < 1.0))){

			result = vec3(0.0);

			shadowScreenPos = shadowScreenPos * 0.5 + 0.5;

			float spread = VPS_SPREAD * shadowProjection[0][0] * 8.0;




			float avgDiff = 0.0;
			float vaildSampleCounts = 0.0;

			#ifdef VARIABLE_PENUMBRA_SHADOWS
				float lookupSpread = spread * (0.0024 * sqrt(VPS_LOOKUP_MAX_DIST));
				//float lookupLod = max(log2(lookupSpread * shadowSize * 3.0), 0.0);

				float lookupAngle = noise.y * TAU;
				vec2 lookupRot = vec2(cos(lookupAngle), sin(lookupAngle));

				const int lookupSteps = clamp(SHADOW_QUALITY, 4, 16);
		
				for (int i = 0; i < lookupSteps; i++){
					lookupRot *= rotMatGR;
					float radius = fsqrt((float(i) + noise.x) * (1.0 / lookupSteps)) * lookupSpread;
					vec2 offset = lookupRot * radius;

					vec2 lookupCoord = shadowScreenPos.xy + offset;
					lookupCoord += SampleRTWWarpSmooth(lookupCoord);
					//ShiftShadowScreenPos(lookupCoord);

					float depthDiff = shadowScreenPos.z;
					//ivec2 lookupTexel = ivec2(lookupCoord * shadowSize);
					if (isEyeInWater == 1){
						depthDiff -= textureLod(shadowtex1, lookupCoord, 0.0).x;
					}else{
						depthDiff -= textureLod(shadowtex0, lookupCoord, 0.0).x;
					}
					depthDiff *= zScale;

					float isBlocked = float(depthDiff > 0.0);
					avgDiff += depthDiff * isBlocked;
					vaildSampleCounts += isBlocked;
				}
				
				avgDiff /= max(vaildSampleCounts, 1.0);
				avgDiff = min(avgDiff, VPS_LOOKUP_MAX_DIST);
			#endif

			spread = max3(
				avgDiff * 1e-3 * spread,
				(0.1 * maskPlant) * shadowProjection[0][0],
				(SHADOW_BASIC_BLUR * 2e-6) / (warpPixelSizeMinMax.x + 2e-3)
			);

			#ifdef DECREASE_HAND_GHOSTING
				if (mask.hand > 0.5){
					spread = (SHADOW_BASIC_BLUR * 1e-6) / (warpPixelSizeMinMax.x + 2e-3);
				}
			#endif

			shadowScreenPos.z -= (1.0 + noise.y * 1.0) * (1.0 - 0.9 * maskPlant) * max(3e-5, 1e-6 / warpPixelSizeMinMax.x);

			#ifdef SHADOW_DYNAMIC_QUALITY
				float steps = round(mix(float(SHADOW_QUALITY), float(SHADOW_QUALITY) * 4.0, saturate(avgDiff / VPS_LOOKUP_MAX_DIST + maskPlant)));
				float rSteps = 1.0 / steps;
			#else
				const float steps = float(SHADOW_QUALITY) * 4.0;
				const float rSteps = 1.0 / steps;
			#endif

			vec4 caustics = vec4(0.0);

			float angle = noise.x * TAU;
			vec2 rot = vec2(cos(angle), sin(angle));

			vec3 zOffestBase = vec3(normalize(shadowNormal.xy), sqrt((1.0 - shadowNormal.z * shadowNormal.z) * 0.5) / shadowNormal.z);
			zOffestBase.z = clamp(zOffestBase.z, -4.0, 4.0) * maskPlant;
			
			for (int i = 0; i < steps; i++){
				rot *= rotMatGR;
				float radius = sqrt((float(i) + noise.y) * rSteps) * spread;
				vec2 offset = rot * radius;

				vec3 sampleCoord = vec3(shadowScreenPos.xy + offset, shadowScreenPos.z - dot(offset, zOffestBase.xy) * zOffestBase.z);

				sampleCoord.xy += SampleRTWWarpSmooth(sampleCoord.xy);
				//ShiftShadowScreenPos(sampleCoord.xy);                                                               

				#ifdef COLORED_SHADOWS
					float soildShadow = SampleShadowBilinear(shadowtex1, sampleCoord);

					if (soildShadow > 0.0){
						float translucentShadow = SampleShadowBilinear(shadowtex0, sampleCoord);
						result += vec3(translucentShadow);

						float coloredShadow = saturate(soildShadow - translucentShadow);
						
						if (coloredShadow > 1e-3){
							vec4 shadowColorSample = textureLod(shadowcolor0, sampleCoord.xy, 0.0);
							if (shadowColorSample.a < 1.0){
								if (shadowColorSample.a > 0.003){ 
									shadowColorSample.rgb = AlbedoToAbsorption(GammaToLinear(shadowColorSample.rgb), shadowColorSample.a);

									result += shadowColorSample.rgb * coloredShadow;
								}else{
									caustics += vec4(shadowColorSample.rgb, 1.0);
								}
							}
						}
					}
				#else
					float soildShadow = SampleShadowBilinear(shadowtex1, sampleCoord);
					result += vec3(soildShadow);
				#endif
			}
			result *= rSteps;

			if(caustics.a > 0.0){
				caustics.rgb /= caustics.a;

				float altitude = caustics.g * 2.0 + caustics.b * 510.0;
				altitude = max(altitude - 64.0 - cameraPosition.y - worldPos.y, 0.0);

				caustics.r = mix(0.85, caustics.r, saturate(altitude * 0.5));
				if (isEyeInWater == 0) caustics.r *= saturate(lightmap * 10.0);
				caustics.rgb = exp2(-vec3(WATER_ATTENUATION_R, WATER_ATTENUATION_G, WATER_ATTENUATION_B) * altitude) * caustics.r;
			}

			result = mix(result, caustics.rgb, caustics.a * rSteps);
		}
	}
	
	return result;
}

float ScreenSpaceShadow(vec3 viewPos, vec3 viewDir, float depth, MaterialMask mask, float shadowmapRange){
	#if defined HAND_SCREEN_SHADOW && !defined DECREASE_HAND_GHOSTING
		if (mask.hand > 0.5){
			depth = depth * (4.0 / MC_HAND_DEPTH) - (2.0 / MC_HAND_DEPTH + 1.0);
			viewPos = ViewPos_From_ScreenPos(texCoord, depth);
		}
	#endif

	bool notPlant = mask.grass + mask.leaves < 0.5;
	float sqrtDist = fsqrt(-viewPos.z);

	float sampleLength = 0.0;
	if (notPlant){
		sampleLength = max(
			sqrtDist * 2e-3, 
			(2.5 - shadowmapRange * 2.5) / gbufferProjection0.y + fsqrt(shadowDistance) * 3e-4
		);
	}else{
		sampleLength = mask.grass > 0.5 ? max(0.04, sqrtDist * 0.02) : max(0.3, sqrtDist * 0.05);  // todo: change to itt style
	}
	#if defined HAND_SCREEN_SHADOW || defined DECREASE_HAND_GHOSTING
		if (mask.hand > 0.5)
			sampleLength = 3e-4;
	#endif

	vec3 viewRayDir = worldShadowVector * mat3(gbufferModelViewInverse) * sampleLength;

	vec3 start = viewPos;
	start += notPlant ? viewDir * viewPos.z * 1e-3 : viewDir * viewPos.z * 1e-4;
	//start += mat3(gbufferModelViewInverse) * vertexNormal * 0.01;
	vec3 end = start + viewRayDir;

	start = vec3(vec2(gbufferProjection0.x, gbufferProjection0.y) * start.xy, -start.z);
	end   = vec3(vec2(gbufferProjection0.x, gbufferProjection0.y) * end.xy,   -end.z);

	vec3 screenRayDir = (end - start);
	screenRayDir.xy *= 0.5;

	start.xy += gbufferProjection1.xy;
	start.xy *= 0.5;

	start += screenRayDir * mask.grass * 0.3;

	float scatteringDensity = pow(0.7, sqrtDist * 0.5);

	#if defined TAA || defined SUPER_RESOLUTION
		float noise = IGNTemoral();
		#if defined DECREASE_HAND_GHOSTING && defined DISABLE_PLAYER_TAA_MOTION_BLUR
			if (mask.hand > 0.5 || mask.entityPlayer > 0.5){
				noise = IGN(gl_FragCoord.xy);
			}
		#elif defined DECREASE_HAND_GHOSTING
			if (mask.hand > 0.5){
				noise = IGN(gl_FragCoord.xy);
			}
		#elif defined DISABLE_PLAYER_TAA_MOTION_BLUR
			if (mask.entityPlayer > 0.5){
				noise = IGN(gl_FragCoord.xy);
			}
		#endif

		vec2 offsetCoord = 0.5 + UNIFORM_TAA_JITTER * 0.5;
	#else
		float noise = IGN(gl_FragCoord.xy);
		vec2 offsetCoord = vec2(0.5);
	#endif

	float shadow = 1.0;
	float stepLength = 1.0;
	float distThreshold = notPlant ? 0.025 + (0.015 - shadowmapRange * 0.0115) * -viewPos.z : 1.0;
	#if defined HAND_SCREEN_SHADOW || defined DECREASE_HAND_GHOSTING
		distThreshold += mask.hand * 0.015;
	#endif


	for (int i = 0; i < 12; i++, start += screenRayDir * stepLength, stepLength += 0.3){
		vec3 samplePos = start + screenRayDir * noise * stepLength;
		samplePos.xy = samplePos.xy / samplePos.z + offsetCoord;
		
		if (saturate(samplePos.xy) != samplePos.xy) break;

		#if defined SUPER_RESOLUTION || defined CUSTOM_RENDER_RESOLUTION
			float sampleDepth = uintBitsToFloat(textureLod(depthtexS, samplePos.xy * fsrRenderScale, 0.0).x);
		#else
			float sampleDepth = uintBitsToFloat(textureLod(depthtexS, samplePos.xy, 0.0).x);
		#endif

		#ifdef LOD_RENDERING		
			float sampleDist;
			bool isLod = false;
			if (sampleDepth == 1.0){
				isLod = true;
				#if defined DISTANT_HORIZONS && (defined SUPER_RESOLUTION || defined CUSTOM_RENDER_RESOLUTION)
					sampleDepth = textureLod(LOD_DEPTH_TEX_1, samplePos.xy * fsrRenderScale, 0.0).x;
				#else
					sampleDepth = textureLod(LOD_DEPTH_TEX_1, samplePos.xy, 0.0).x;
				#endif
				sampleDist = LinearDepth_From_ScreenDepth_LOD(sampleDepth);
			}else{
				#if defined HAND_SCREEN_SHADOW || defined DECREASE_HAND_GHOSTING
					if (mask.hand > 0.5) 
						sampleDepth = sampleDepth * (4.0 / MC_HAND_DEPTH) - (2.0 / MC_HAND_DEPTH + 1.0);
				#endif
				sampleDist = LinearDepth_From_ScreenDepth(sampleDepth);
			}

		#else
			#if defined HAND_SCREEN_SHADOW || defined DECREASE_HAND_GHOSTING
				if (mask.hand > 0.5) 
					sampleDepth = sampleDepth * (4.0 / MC_HAND_DEPTH) - (2.0 / MC_HAND_DEPTH + 1.0);
			#endif

			float sampleDist = LinearDepth_From_ScreenDepth(sampleDepth);
		#endif

		if (abs(samplePos.z - sampleDist - distThreshold) < distThreshold){
			if (notPlant){
				vec2 sampleTexelCoord = samplePos.xy * UNIFORM_SCREEN_SIZE + 0.5;
				vec2 sampleTexel = floor(sampleTexelCoord);
				vec2 f = sampleTexelCoord - sampleTexel;

				#if defined SUPER_RESOLUTION || defined CUSTOM_RENDER_RESOLUTION
					vec4 sh = uintBitsToFloat(textureGather(depthtexS, sampleTexel * UNIFORM_PIXEL_SIZE * fsrRenderScale, 0));
				#else
					vec4 sh = uintBitsToFloat(textureGather(depthtexS, sampleTexel * UNIFORM_PIXEL_SIZE, 0));
				#endif

				#ifdef LOD_RENDERING
					float sampleDist;
					if (any(greaterThanEqual(sh, vec4(1.0)))){
						#if defined DISTANT_HORIZONS && (defined SUPER_RESOLUTION || defined CUSTOM_RENDER_RESOLUTION)
							vec4 sh = textureGather(LOD_DEPTH_TEX_0, sampleTexel * UNIFORM_PIXEL_SIZE * fsrRenderScale, 0);
						#else
							vec4 sh = textureGather(LOD_DEPTH_TEX_0, sampleTexel * UNIFORM_PIXEL_SIZE, 0);
						#endif

						float sampleDepth = mix(
							mix(sh.x, sh.y, f.x),
							mix(sh.z, sh.w, f.x),
						f.y);

						sampleDist = LinearDepth_From_ScreenDepth_LOD(sampleDepth);
					}else{
						float sampleDepth = mix(
							mix(sh.x, sh.y, f.x),
							mix(sh.z, sh.w, f.x),
						f.y);

						if (sampleDepth < 0.7 && mask.hand > 0.5) 
							sampleDepth = sampleDepth * (4.0 / MC_HAND_DEPTH) - (2.0 / MC_HAND_DEPTH + 1.0);
					
						sampleDist = LinearDepth_From_ScreenDepth(sampleDepth);
					}

				#else

					float sampleDepth = mix(
						mix(sh.x, sh.y, f.x),
						mix(sh.z, sh.w, f.x),
					f.y);
					
					if (sampleDepth < 0.7 && mask.hand > 0.5) 
						sampleDepth = sampleDepth * (4.0 / MC_HAND_DEPTH) - (2.0 / MC_HAND_DEPTH + 1.0);
					
					float sampleDist = LinearDepth_From_ScreenDepth(sampleDepth);

				#endif
				
				if (abs(samplePos.z - sampleDist - distThreshold) < distThreshold) shadow = 0.0;

			}else{
				shadow *= scatteringDensity;

			}
		}

		if (shadow < 0.01) break;
	}

	return shadow;
}

vec2 ShadowRims(vec3 viewPos, vec3 worldDir, vec3 vertexNormal, float depth, MaterialMask mask, inout vec3 worldPos){
	float VNdotL = dot(vertexNormal, worldShadowVector);

	if (VNdotL < 0.0 && depth > 0.7){ //0.052631
		float NdotV = saturate(dot(vertexNormal, -worldDir));
		
		vec3 sampleDir = normalize((worldShadowVector - vertexNormal * VNdotL)) * mat3(gbufferModelViewInverse);
		#if RIMS_TYPE == 0
			sampleDir *= RIMS_RELATIVE_WIDTH * 0.05;
		#else
			sampleDir *= RIMS_RELATIVE_WIDTH * 0.1;
		#endif

		//VNdotL = saturate(-VNdotL * 0.95 + 0.05);
		VNdotL = saturate(-VNdotL);
		
		vec3 start = viewPos;
		vec3 end = start + sampleDir;

		start = vec3(vec2(gbufferProjection0.x, gbufferProjection0.y) * start.xy, -start.z);
		end   = vec3(vec2(gbufferProjection0.x, gbufferProjection0.y) *   end.xy,   -end.z);

		vec3 screenRayDir = (end - start);
		screenRayDir.xy *= 0.5;

		vec2 pixelWidth = screenRayDir.xy / start.z * screenSize;
		float pixelRatio = inversesqrt(dot(pixelWidth, pixelWidth));
		#ifdef SUPER_RESOLUTION
			const float minRatio = max(RIMS_MIN_WIDTH, 2.0);
		#else
			const float minRatio = RIMS_MIN_WIDTH;
		#endif
		#if RIMS_TYPE == 0
			const float maxRatio = RIMS_MAX_WIDTH;
		#else
			const float maxRatio = RIMS_MAX_WIDTH * 2.0;
		#endif
		float pixelScale = max(pixelRatio * minRatio, 1.0) * min(pixelRatio * RIMS_MAX_WIDTH, 1.0);
		screenRayDir *= pixelScale;
		sampleDir *= pixelScale;

		start.xy += gbufferProjection1.xy;
		start.xy *= 0.5;

		#if defined TAA || defined SUPER_RESOLUTION
			float noise = IGNTemoral();
			#ifdef DISABLE_PLAYER_TAA_MOTION_BLUR
				if (mask.entityPlayer > 0.5){
					noise = IGN(gl_FragCoord.xy);
				}
			#endif
			vec2 offsetCoord = 0.5 + UNIFORM_TAA_JITTER * 0.5;
		#else
			float noise = IGN(gl_FragCoord.xy);
			vec2 offsetCoord = vec2(0.5);
		#endif

		vec2 rims = vec2(0.0);

		float distThreshold = (0.05 - 0.045 * NdotV) - viewPos.z * 0.002;

		for (int i = 0; i < 6; i++){
			float stepLength = float(i) / 6.0 + noise;
			vec3 samplePos = start + screenRayDir * stepLength;
			samplePos.xy = samplePos.xy / samplePos.z + offsetCoord;

			if (saturate(samplePos.xy) != samplePos.xy) break;

			#if defined SUPER_RESOLUTION || defined CUSTOM_RENDER_RESOLUTION
				float sampleDepth = uintBitsToFloat(textureLod(depthtexS, samplePos.xy * fsrRenderScale, 0.0).x);
			#else
				float sampleDepth = uintBitsToFloat(textureLod(depthtexS, samplePos.xy, 0.0).x);
			#endif

			#ifdef LOD_RENDERING		
				float sampleDist;
				bool isLod = false;
				if (sampleDepth == 1.0){
					isLod = true;
					#if defined DISTANT_HORIZONS && (defined SUPER_RESOLUTION || defined CUSTOM_RENDER_RESOLUTION)
						sampleDepth = textureLod(LOD_DEPTH_TEX_1, samplePos.xy * fsrRenderScale, 0.0).x;
					#else
						sampleDepth = textureLod(LOD_DEPTH_TEX_1, samplePos.xy, 0.0).x;
					#endif
					sampleDist = LinearDepth_From_ScreenDepth_LOD(sampleDepth);
				}else{
					#if defined HAND_SCREEN_SHADOW || defined DECREASE_HAND_GHOSTING
						if (mask.hand > 0.5) 
							sampleDepth = sampleDepth * (4.0 / MC_HAND_DEPTH) - (2.0 / MC_HAND_DEPTH + 1.0);
					#endif
					sampleDist = LinearDepth_From_ScreenDepth(sampleDepth);
				}

			#else
				#if defined HAND_SCREEN_SHADOW || defined DECREASE_HAND_GHOSTING
					if (mask.hand > 0.5) 
						sampleDepth = sampleDepth * (4.0 / MC_HAND_DEPTH) - (2.0 / MC_HAND_DEPTH + 1.0);
				#endif

				float sampleDist = LinearDepth_From_ScreenDepth(sampleDepth);
			#endif

			if (sampleDist > samplePos.z + distThreshold){
				#if RIMS_TYPE == 0
					rims.x = saturate(3.0 - stepLength * 3.0);
				#else
					rims.x = saturate(1.2 - stepLength * 1.2);
					rims.x = rims.x * rims.x;
				#endif

				float w = 3.0 / (stepLength * stepLength + 0.01);
				rims.y = rims.x * curveTop(saturate(VNdotL * 5.0) * saturate(w - VNdotL * w));

				worldPos = mat3(gbufferModelViewInverse) * (viewPos + sampleDir * stepLength);
				break;
			}

		}

		return rims;
	}else{
		return vec2(0.0);
	}

}