

float spotShape(float r){
	float shape = curve(saturate(r * 2.0 - (2.0 - FLASHLIGHT_FOV)));
	shape += curve(saturate(r * 1.25 - (1.0 - FLASHLIGHT_FOV))) * 0.01;

	const float ringSize = 8.0 / FLASHLIGHT_FOV;
	shape *= 1.0 - curve(saturate(1.0 - abs(r * ringSize - ringSize + 1.0))) * 0.25;

	return shape;
}


float TorchScreenSpaceShadow(vec3 viewPos, vec3 viewDir, vec3 normal, vec3 shadowDir){
	shadowDir.z = max(shadowDir.z, 1e-5);

	float rayLength = -0.04 * viewPos.z / shadowDir.z;
	vec3 viewRayDir = shadowDir * rayLength;

	vec3 start = viewPos;

	float pixelScale = max(UNIFORM_PIXEL_SIZE.x, UNIFORM_PIXEL_SIZE.y);
	float NdotL = saturate(dot(shadowDir, normal));

	float fov = atan(1.0 / gbufferProjection0.y) * 360.0 * rPI;
	start += viewRayDir * (pixelScale * max(0.04 / max(dot(normal, -viewDir), 0.1), 1e3));
	start += normal * (8e-3 * fov * -viewPos.z * pixelScale / max(NdotL, 0.01));

	vec3 end = start + viewRayDir;

	start = vec3(vec2(gbufferProjection0.x, gbufferProjection0.y) * start.xy, -start.z);
	end   = vec3(vec2(gbufferProjection0.x, gbufferProjection0.y) * end.xy,   -end.z);

	vec3 screenRayDir = (end - start);
	screenRayDir.xy *= 0.5;

	start.xy += gbufferProjection1.xy;
	start.xy *= 0.5;

	#if defined TAA || defined SUPER_RESOLUTION
		float noise = BlueNoiseTemporal().x;
		vec2 offsetCoord = 0.5 + UNIFORM_TAA_JITTER * 0.5;
	#else
		float noise = BlueNoise().x;
		vec2 offsetCoord = vec2(0.5);
	#endif

	float minDist = LinearDepth_From_ScreenDepth(0.7);

	float shadow = 1.0;
	float stepLength = 1.0;

	for (int i = 0; i < 8; i++, start += screenRayDir * stepLength, stepLength += 0.3){
		vec3 samplePos = start + screenRayDir * noise * stepLength;

		if (samplePos.z < minDist) break;

		samplePos.xy = samplePos.xy / samplePos.z + offsetCoord;
		
		if (saturate(samplePos.xy) != samplePos.xy) break;

		#if defined SUPER_RESOLUTION || defined CUSTOM_RENDER_RESOLUTION
			float sampleDepth = uintBitsToFloat(textureLod(depthtexS, samplePos.xy * fsrRenderScale, 0.0).x);
		#else
			float sampleDepth = uintBitsToFloat(textureLod(depthtexS, samplePos.xy, 0.0).x);
		#endif

		if (sampleDepth < 0.7) break;

		float sampleDist = LinearDepth_From_ScreenDepth(sampleDepth);

		if (samplePos.z - sampleDist > 0.0){
			shadow = 0.0;
			break;
		}
	}

	return shadow * 0.85 + 0.15;
}

vec3 HeldLighting(inout vec3 textureLighting, vec3 viewPos, vec3 viewDir, vec3 normal, vec3 albedo, float roughness, bool isHand){
	vec3 HeldLight = vec3(0.0);
	float heldLightFalloff = 0.0;

	#ifdef HELDLIGHT_CUSTOM_COLOR
		const vec3 handEmission = pow(vec3(HELDLIGHT_COLOR_R, HELDLIGHT_COLOR_G, HELDLIGHT_COLOR_B), vec3(2.2)) * HELDLIGHT_COLOR_BRIGHTNESS;
	#else
		vec3 handEmission = vec3(
			texelFetch(pixelData2D, ivec2(PIXELDATA_HANDEMISSION_RG, 0), 0).xy, 
			texelFetch(pixelData2D, ivec2(PIXELDATA_HANDEMISSION_BA, 0), 0).x
		);
	#endif

	#if HELDLIGHT_MODE > 0
		const float sideLuminance = 0.08;
	#else
		const float sideLuminance = 0.16;
	#endif

	if (isHand){
		float albedoWeight = Radiance(albedo);

		float side = saturate(texCoord.x * 4.0 - 1.5);
		heldLightFalloff = mix(
			float(heldBlockLightValue) * (saturate(normal.x) * 0.9 + 0.1) * sideLuminance, 
			float(heldBlockLightValue) * albedoWeight, 
			curve(side * side)
		);

		side = 1.0 - side;
		heldLightFalloff = max(heldLightFalloff, mix(
			float(heldBlockLightValue2) * (saturate(-normal.x) * 0.9 + 0.1) * sideLuminance, 
			float(heldBlockLightValue2) * albedoWeight, 
			curve(side * side)
		));

		heldLightFalloff *= HELDLIGHT_BRIGHTNESS * HELDLIGHT_BRIGHTNESS_RATIO * 0.014;
		textureLighting = max(textureLighting, handEmission * heldLightFalloff);
	}else

	#if HELDLIGHT_MODE > 0
		
		{
			#ifdef FLASHLIGHT_CAMERA_SMOOTH
				float angleRx = eyeRxSmooth * -FLASHLIGHT_CAMERA_SMOOTH_TIME;
				mat3 Rx = mat3(1.0,  0.0,          0.0,
							   0.0,  cos(angleRx), sin(angleRx),
							   0.0, -sin(angleRx), cos(angleRx));

				float angleRy = eyeRySmooth * -FLASHLIGHT_CAMERA_SMOOTH_TIME;
				mat3 Ry = mat3(cos(angleRy), 0.0, -sin(angleRy),
							   0.0,          1.0,  0.0,
							   sin(angleRy), 0.0,  cos(angleRy));

				vec3 aimDir = Ry * Rx * vec3(0.0, 0.0, -1.0);
			#else
				vec3 aimDir = vec3(0.0, 0.0, -1.0);
			#endif

			if (heldBlockLightValue > 0){
				vec3 spotPosR = viewPos - vec3(FLASHLIGHT_POS_R_X, FLASHLIGHT_POS_R_Y, 0.0);
				float spotDistR = length(spotPosR);
				vec3 shadowDirR = spotPosR / spotDistR;

				float spotR = pow(max(spotDistR, 0.6), -FLASHLIGHT_FALLOFF);
				spotR *= spotShape(dot(shadowDirR, aimDir));

				#ifdef HELDLIGHT_SHADOW
					spotR *= TorchScreenSpaceShadow(viewPos, viewDir, normal, -shadowDirR);
				#endif
				spotR *= Fd_Burley(normal, -viewDir, -shadowDirR, roughness) * 1.7 + 0.05;
				
				heldLightFalloff += float(heldBlockLightValue) * spotR;
			}

			if (heldBlockLightValue2 > 0){
				vec3 spotPosL = viewPos - vec3(FLASHLIGHT_POS_L_X, FLASHLIGHT_POS_L_Y, 0.0);
				float spotDistL = length(spotPosL);
				vec3 shadowDirL = spotPosL / spotDistL;

				float spotL = pow(max(spotDistL, 0.6), -FLASHLIGHT_FALLOFF);
				spotL *= spotShape(dot(shadowDirL, aimDir));

				#ifdef HELDLIGHT_SHADOW
					spotL *= TorchScreenSpaceShadow(viewPos, viewDir, normal, -shadowDirL);
				#endif
				spotL *= Fd_Burley(normal, -viewDir, -shadowDirL, roughness) * 1.7 + 0.05;

				heldLightFalloff += float(heldBlockLightValue2) * spotL;
			}

			heldLightFalloff *= HELDLIGHT_BRIGHTNESS * 0.1;
			HeldLight = handEmission * heldLightFalloff;
		}
		
	#else
	
		{
			#ifdef HELDLIGHT_SHADOW

				if (heldBlockLightValue > 0){
					vec3 torchPosR = viewPos - vec3(FLASHLIGHT_POS_R_X, FLASHLIGHT_POS_R_Y, 0.0);
					float torchR = length(torchPosR) + 1.0;
					torchR = 1.0 / (torchR * torchR);

					vec3 shadowDirR = -normalize(viewPos - vec3(FLASHLIGHT_POS_R_X, FLASHLIGHT_POS_R_Y, 0.0));
					torchR *= TorchScreenSpaceShadow(viewPos, viewDir, normal, shadowDirR);
					torchR *= Fd_Burley(normal, -viewDir, shadowDirR, roughness) * 1.7 + 0.05;

					heldLightFalloff += float(heldBlockLightValue) * torchR;
				}

				if (heldBlockLightValue2 > 0){
					vec3 torchPosL = viewPos - vec3(FLASHLIGHT_POS_L_X, FLASHLIGHT_POS_L_Y, 0.0);
					float torchL = length(torchPosL) + 1.0;
					torchL = 1.0 / (torchL * torchL);

					vec3 shadowDirL = -normalize(viewPos - vec3(FLASHLIGHT_POS_L_X, FLASHLIGHT_POS_L_Y, 0.0));
					torchL *= TorchScreenSpaceShadow(viewPos, viewDir, normal, shadowDirL);
					torchL *= Fd_Burley(normal, -viewDir, shadowDirL, roughness) * 1.7 + 0.05;

					heldLightFalloff += float(heldBlockLightValue2) * torchL;
				}

			#else

				float torchDist = length(viewPos) + 1.0;
				heldLightFalloff = 1.0 / (torchDist * torchDist);
				heldLightFalloff *= Fd_Burley(normal, -viewDir, -viewDir, roughness) * 1.7 + 0.05;

				heldLightFalloff *= float(heldBlockLightValue + heldBlockLightValue2);

			#endif

			heldLightFalloff *= HELDLIGHT_BRIGHTNESS * 0.018;
			HeldLight = handEmission * heldLightFalloff;
		}
		
	#endif

	return HeldLight;
}


vec3 TorchSpecularHighlight(vec3 viewPos, vec3 viewDir, float dist, vec3 normal, float roughness, vec3 f0){
	roughness = max(roughness, 0.002);

	#if HELDLIGHT_MODE > 0

		#ifdef FLASHLIGHT_CAMERA_SMOOTH
			float angleRx = eyeRxSmooth * -FLASHLIGHT_CAMERA_SMOOTH_TIME;
			mat3 Rx = mat3(1.0,  0.0,          0.0,
							0.0,  cos(angleRx), sin(angleRx),
							0.0, -sin(angleRx), cos(angleRx));

			float angleRy = eyeRySmooth * -FLASHLIGHT_CAMERA_SMOOTH_TIME;
			mat3 Ry = mat3(cos(angleRy), 0.0, -sin(angleRy),
							0.0,          1.0,  0.0,
							sin(angleRy), 0.0,  cos(angleRy));

			vec3 aimDir = Ry * Rx * vec3(0.0, 0.0, -1.0);
		#else
			vec3 aimDir = vec3(0.0, 0.0, -1.0);
		#endif

		vec3 heldHighlight = vec3(0.0);
		
		if (heldBlockLightValue > 0){
			vec3 spotPosR = viewPos - vec3(FLASHLIGHT_POS_R_X, FLASHLIGHT_POS_R_Y, 0.0);
			float spotDistR = length(spotPosR);
			vec3 shadowDirR = spotPosR / spotDistR;

			float spotR = pow(max(spotDistR, 0.6), -FLASHLIGHT_FALLOFF);
			spotR *= spotShape(dot(shadowDirR, aimDir));
			
			heldHighlight += SpecularGGX(normal, -viewDir, -shadowDirR, roughness, f0) * (float(heldBlockLightValue) * spotR);
		}

		if (heldBlockLightValue2 > 0){
			vec3 spotPosL = viewPos - vec3(FLASHLIGHT_POS_L_X, FLASHLIGHT_POS_L_Y, 0.0);
			float spotDistL = length(spotPosL);
			vec3 shadowDirL = spotPosL / spotDistL;

			float spotL = pow(max(spotDistL, 0.6), -FLASHLIGHT_FALLOFF);
			spotL *= spotShape(dot(shadowDirL, aimDir));

			heldHighlight += SpecularGGX(normal, -viewDir, -shadowDirL, roughness, f0) * (float(heldBlockLightValue2) * spotL);
		}

		heldHighlight *= HELDLIGHT_BRIGHTNESS * 0.1 * 0.25;


	#else

		vec3 heldHighlight = SpecularGGX(normal, -viewDir, -viewDir, roughness, f0);

		float falloffDist = dist + 1.0;			
		float heldLightFalloff = 1.0 / (falloffDist * falloffDist);

		heldLightFalloff *= float(heldBlockLightValue + heldBlockLightValue2);
		heldLightFalloff *= HELDLIGHT_BRIGHTNESS * 0.018 * 0.25;

		heldHighlight *= heldLightFalloff;

		
	#endif

	#ifdef HELDLIGHT_CUSTOM_COLOR
		const vec3 handEmission = pow(vec3(HELDLIGHT_COLOR_R, HELDLIGHT_COLOR_G, HELDLIGHT_COLOR_B), vec3(2.2)) * HELDLIGHT_COLOR_BRIGHTNESS;
	#else
		vec3 handEmission = vec3(
			texelFetch(pixelData2D, ivec2(PIXELDATA_HANDEMISSION_RG, 0), 0).xy, 
			texelFetch(pixelData2D, ivec2(PIXELDATA_HANDEMISSION_BA, 0), 0).x
		);
	#endif

	return handEmission * heldHighlight;
}
