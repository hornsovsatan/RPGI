

vec3 BlockLighting(float lightmap){
	float lightSourceMask = float(lightmap == 1.0);
	float blockLight = min(lightmap, 1.0 - 0.2 * lightSourceMask);

	float dist = 16.0 - blockLight * 15.0;
	#if TORCHLIGHT_FALLOFF_MODE > 0
		float boost = saturate(blockLight * 2.0 - 1.0);
		blockLight = blockLight * 0.5 + boost * boost * 0.5;
	#endif
	blockLight *= 1.0 / (dist * dist);

	blockLight *= BLOCKLIGHT_BRIGHTNESS * 0.5;

	const float temperature = BLOCKLIGHT_TEMPERATURE;
	const mat2x4 splineX = mat2x4(-0.2661293e9, -0.2343589e6, 0.8776956e3, 0.179910,
								-3.0258469e9,  2.1070479e6, 0.2226347e3, 0.240390);

	const mat3x4 splineY = mat3x4(-1.1063814, -1.34811020, 2.18555832, -0.20219683,
								-0.9549476, -1.37418593, 2.09137015, -0.16748867,
								3.0817580, -5.87338670, 3.75112997, -0.37001483);

	const float rt = 1.0 / temperature;
	const float rt2 = rt * rt;
	const vec4 coeffX = vec4(rt2 * rt, rt2, rt, 1.0);
	
	const float xSp0 = dot(coeffX, splineX[0]) + saturate((temperature - 4000.0) * 1e10) * 1e10;
	const float xSp1 = dot(coeffX, splineX[0]) + saturate((3999.9 - temperature) * 1e10) * 1e10;

	const float x = min(xSp0, xSp1);
	const float x2 = x * x;
	const vec4 coeffY = vec4(x2 * x, x2, x, 1.0);

	const float zSp0 = dot(coeffY, splineY[0]) + saturate((0.504166 - x) * 1e10) * 1e10;
	const float zSp1 = dot(coeffY, splineY[1]) + saturate((x - 0.504167) * 1e10) * 1e10 + saturate((0.380007 - x) * 1e10) * 1e10;
	const float zSp2 = dot(coeffY, splineY[2]) + saturate((x - 0.380008) * 1e10) * 1e10;

	const float z = 1.0 / min3(zSp0, zSp1, zSp2);

	const float xyzX = x * z;
	const float xyzZ = z - xyzX - 1.0;


	const mat3 xyzToSrgb = mat3( 3.24097, -0.96924,  0.05563,
								-1.53738,  1.87597, -0.20398,
								-0.49861,  0.04156,  1.05697);

	const vec3 blackbody = max(xyzToSrgb * vec3(xyzX, 1.0, xyzZ), vec3(0.0));

	return blackbody * blockLight;
}

vec3 BlockLighting_Raw(float blockLight){
	float dist = 16.0 - blockLight * 15.0;
	#if TORCHLIGHT_FALLOFF_MODE > 0
		float boost = saturate(blockLight * 2.0 - 1.0);
		blockLight = blockLight * 0.5 + boost * boost * 0.5;
	#endif
	blockLight *= 1.0 / (dist * dist);

	blockLight *= BLOCKLIGHT_BRIGHTNESS * 0.4;

	const float temperature = BLOCKLIGHT_TEMPERATURE;
	const mat2x4 splineX = mat2x4(-0.2661293e9, -0.2343589e6, 0.8776956e3, 0.179910,
								-3.0258469e9,  2.1070479e6, 0.2226347e3, 0.240390);

	const mat3x4 splineY = mat3x4(-1.1063814, -1.34811020, 2.18555832, -0.20219683,
								-0.9549476, -1.37418593, 2.09137015, -0.16748867,
								3.0817580, -5.87338670, 3.75112997, -0.37001483);

	const float rt = 1.0 / temperature;
	const float rt2 = rt * rt;
	const vec4 coeffX = vec4(rt2 * rt, rt2, rt, 1.0);
	
	const float xSp0 = dot(coeffX, splineX[0]) + saturate((temperature - 4000.0) * 1e10) * 1e10;
	const float xSp1 = dot(coeffX, splineX[0]) + saturate((3999.9 - temperature) * 1e10) * 1e10;

	const float x = min(xSp0, xSp1);
	const float x2 = x * x;
	const vec4 coeffY = vec4(x2 * x, x2, x, 1.0);

	const float zSp0 = dot(coeffY, splineY[0]) + saturate((0.504166 - x) * 1e10) * 1e10;
	const float zSp1 = dot(coeffY, splineY[1]) + saturate((x - 0.504167) * 1e10) * 1e10 + saturate((0.380007 - x) * 1e10) * 1e10;
	const float zSp2 = dot(coeffY, splineY[2]) + saturate((x - 0.380008) * 1e10) * 1e10;

	const float z = 1.0 / min3(zSp0, zSp1, zSp2);

	const float xyzX = x * z;
	const float xyzZ = z - xyzX - 1.0;


	const mat3 xyzToSrgb = mat3( 3.24097, -0.96924,  0.05563,
								-1.53738,  1.87597, -0.20398,
								-0.49861,  0.04156,  1.05697);

	const vec3 blackbody = max(xyzToSrgb * vec3(xyzX, 1.0, xyzZ), vec3(0.0));

	return blackbody * blockLight;
}


vec3 TextureLighting(vec3 albedo, float emissiveness, MaterialMask mask){
	vec4 blockLighting = vec4(0.0);

	#ifdef TACZ_ADAPTIVE_EMISSIVE
		if (mask.hand > 0.5 && heldBlockLightValue + heldBlockLightValue2 <= 0){
			float exposure = texelFetch(pixelData2D, ivec2(PIXELDATA_EXPOSURE, 0), 0).x * 13.0;

			vec3 adaptiveEmissive = vec3(saturate(exposure) * emissiveness * (TACZ_ADAPTIVE_EMISSIVE_BRIGHTNESS * 0.15));

			#ifdef TACZ_MUZZLE_FLASH
				adaptiveEmissive += vec3(1.41, 0.92, 0.53) * (saturate(dot(albedo, vec3(0.33333)) * 6.0 - 4.7) * emissiveness * (TACZ_MUZZLE_FLASH_BRIGHTNESS * 2.0));
			#endif
			
			return adaptiveEmissive;
		}
	#endif

	blockLighting += vec4(mask.torch         * (pow(vec3(COLOR_TORCH_R,         COLOR_TORCH_G,         COLOR_TORCH_B        ), vec3(2.2)) * BRIGHTNESS_TORCH         * 1.6), 	mask.torch);
	blockLighting += vec4(mask.redstoneTorch * (pow(vec3(COLOR_REDSTONETORCH_R, COLOR_REDSTONETORCH_G, COLOR_REDSTONETORCH_B), vec3(2.2)) * BRIGHTNESS_REDSTONETORCH * 4.0), 	mask.redstoneTorch);
	blockLighting += vec4(mask.amethyst      * vec3(BRIGHTNESS_AMETHYST), 																										mask.amethyst);
	blockLighting += vec4(mask.soulTorch     * vec3(BRIGHTNESS_SOULTORCH * 2.0), 																								mask.soulTorch);
	blockLighting += vec4(mask.fire          * (vec3(0.88, 0.42, 0.14) * 1.5), 																									mask.fire);
	blockLighting += vec4(mask.endrod        * (vec3(COLOR_ENDROD_R, COLOR_ENDROD_G, COLOR_ENDROD_B) * BRIGHTNESS_ENDROD), 														mask.endrod);
	//blockLighting += mask.soulFire      * 0.5;

	if (blockLighting.a > 0.0){
		blockLighting.rgb *= SPHERELIGHT_BRIGHTNESS * emissiveness;
	}else{
		blockLighting.rgb = vec3(emissiveness);
	}

	return blockLighting.rgb * (BLOCKLIGHT_BRIGHTNESS * Radiance(albedo));
}
