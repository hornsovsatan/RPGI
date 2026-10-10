

#if VFOG_NOISE_TYPE == 0

float FogDensity(vec3 fogPos, float baseDensity, float fogTimeFactor){
	const float maxHeight = max(VFOG_HEIGHT, VFOG_HEIGHT_2);
	const float minHeight = min(VFOG_HEIGHT, VFOG_HEIGHT_2);

	float dh = max(fogPos.y - maxHeight, 0.0) + max(minHeight - fogPos.y, 0.0);
	dh *= (2.0 / VFOG_FALLOFF) * (1.0 - fogTime.y * 0.5);
	float density = exp2(-dh);

	density = (density * (VFOG_DENSITY * 0.15) + baseDensity) * fogTimeFactor;

	return density;
}

#else


float Get3DNoise(vec3 pos){
	vec3 p = floor(pos);
	vec3 f = pos - p;

	vec2 uv = vec2(55.0, 0.0) * p.y + p.zx + f.zx;
	vec2 noise = textureLod(noisetex, uv / 128.0, 0.0).zw;

	return mix(noise.x, noise.y, f.y);
}


float FogDensity(vec3 fogPos, float baseDensity, float fogTimeFactor, vec3 wind){
	const float maxHeight = max(VFOG_HEIGHT, VFOG_HEIGHT_2);

	float dh = abs(fogPos.y - maxHeight);
	dh *= (2.5 / VFOG_FALLOFF) * (1.0 - fogTime.y * 0.5);
	float falloff = exp2(-dh);
 
	
	fogPos = fogPos * vec3(0.2, 0.05, 0.2) + wind;


	#if VFOG_NOISE_OCTAVE == 1
		float density = Get3DNoise(fogPos);	
	#else
		float density = 0.0;
		const float minAlpha = exp2(float(-VFOG_NOISE_OCTAVE));
		const float totalAlpha =  1.0 / (1.0 - minAlpha);
		for (float stepAlpha = 0.5; stepAlpha >= minAlpha; stepAlpha *= 0.5) {
			density += stepAlpha * Get3DNoise(fogPos);
			fogPos = (fogPos + wind) * vec3(3.3, 2.7, 3.3);
		}

		density *= totalAlpha;
	#endif

	density = saturate(density * (1.2 / VFOG_NOISE_COVERAGE) - (1.0 / VFOG_NOISE_COVERAGE - 1.0));

	density  = density * density;
	//density  = density * density;
	density *= density * falloff;

	density = (density * VFOG_DENSITY + baseDensity) * fogTimeFactor;

	return density;
}

#endif

#ifdef VFOG_TRANSMITTANCE
void VolumetricFog(inout vec3 color, vec3 startPos, vec3 endPos, vec3 worldDir, float globalCloudShadow, float fogTimeFactor, out float transmittance){
#else
void VolumetricFog(inout vec3 color, vec3 startPos, vec3 endPos, vec3 worldDir, float globalCloudShadow, float fogTimeFactor){
#endif
	#if VFOG_NOISE_TYPE == 0
		fogTimeFactor *= fogTime.y * 2.0 + 1.0;
	#endif

	float eyeBrightnessCurved = texelFetch(pixelData2D, ivec2(PIXELDATA_EYE_BRIGHTNESS, 0), 0).x;

	#if defined TAA || defined SUPER_RESOLUTION
		float noise = BlueNoiseTemporal().y;
	#else
		float noise = bayer64(gl_FragCoord.xy);
	#endif

	float VdotL = dot(worldDir, worldShadowVector);

	#ifdef VFOG_LQ
		const float steps = 3.0;
	#else
		const float steps = VFOG_QUALITY;
	#endif
	const float rSteps = 1.0 / steps;

	vec3 start = startPos + gbufferModelViewInverse[3].xyz;
	vec3 end = endPos + gbufferModelViewInverse[3].xyz;

	vec3 rayVector = end - start;
	float rayLength = length(rayVector) * rSteps * 0.23979;

	vec3 shadowStart = ShadowScreenPos_From_WorldPos(start);
	vec3 shadowEnd = ShadowScreenPos_From_WorldPos(end);

	vec3 shadowRayVector = shadowEnd - shadowStart;

	start += cameraPosition;

	#ifdef LOD_RENDERING
		float baseDensity = VFOG_DENSITY_BASE * (fogTime.y * 0.25 + 0.25) / clamp(float(LOD_RENDER_DISTANCE), 512.0, 2048.0);
	#else
		float baseDensity = VFOG_DENSITY_BASE * (fogTime.y * 0.15 + 0.08) / max(far, 100.0);
	#endif
	#if FOG_SKYLIGHT_FALLOFF > 0
		baseDensity *= eyeBrightnessCurved;
	#endif

	float phases = HenyeyGreenstein(VdotL, 0.65) * 0.7 + 0.035;

	#if VFOG_NOISE_TYPE > 0
		float windTimer = (frameTimeCounter * CLOUD_SPEED + 10.0 * FTC_OFFSET);
		vec3 wind = (vec3(0.6, -0.05, -1.0) * 0.1) * windTimer;
	#endif

	#ifdef VFOG_TRANSMITTANCE
		transmittance = 1.0;
	#else
		float transmittance = 1.0;
	#endif
	float fogDensity = 0.0;
	float rayDensity = 0.0;
	#ifdef VFOG_STAINED
		vec3 translucentColor = vec3(0.0);
	#endif

	for (int i = 0; i < steps; i++){
		float exponential = pow(11.0, (float(i) + noise) * rSteps);
		float stepLength = exponential * 0.1 - 0.1;
		float stepDensity = exponential * rayLength * 1.442695;

		vec3 fogPos = start + stepLength * rayVector;
		vec3 shadowPos = shadowStart + stepLength * shadowRayVector;

		#if VFOG_NOISE_TYPE == 0
			float density = FogDensity(fogPos, baseDensity, fogTimeFactor);
		#else
			float density = FogDensity(fogPos, baseDensity, fogTimeFactor, wind);
		#endif
		
		float absorption = exp2(-density * stepDensity);

		//#ifdef VFOG_VOLUMETRIC_LIGHTING
			float lightingDensity = 0.0;

			float lightingStepLength = VFOG_SUNLIGHT_STEPLENGTH;
			
			for (int i = 0; i < VFOG_SUNLIGHT_STEPS; i++, fogPos += worldShadowVector * lightingStepLength, lightingStepLength *= 1.5){
				#if VFOG_NOISE_TYPE == 0
					lightingDensity += FogDensity(fogPos, baseDensity, fogTimeFactor) * lightingStepLength;
				#else
					lightingDensity += FogDensity(fogPos, baseDensity, fogTimeFactor, wind) * lightingStepLength;
				#endif
			}

			float stepRayDensity = exp2(-lightingDensity * (VFOG_SUNLIGHT_ABSORPTION));
			stepRayDensity *= phases;
		//#endif


		shadowPos = DistortShadowScreenPos(shadowPos);

		float shadow = 1.0;
		#ifdef VFOG_STAINED
			vec3 shadowColorSample = vec3(0.0);
		#endif

		if (saturate(shadowPos.xy) == shadowPos.xy && shadowPos.z < 1.0){
			float solidDepth = textureLod(shadowtex1, shadowPos.xy, 0.0).x;

			if (shadowPos.z > solidDepth){
				shadow = 0.0;
			}
		#ifdef VFOG_STAINED
			else{
				float transparentDepth = textureLod(shadowtex0, shadowPos.xy, 0.0).x;
				float transparentShadow = step(transparentDepth, shadowPos.z);
				shadow -= transparentShadow;

				vec4 shadowAlbedo = textureLod(shadowcolor0, shadowPos.xy, 0.0);
				if (shadowAlbedo.a < 1.0){
					shadowColorSample = GammaToLinear(shadowAlbedo.rgb);
					shadowColorSample *= transparentShadow;
				}
			}
		#endif
		}

/*
		#ifdef VOLUMETRIC_CLOUDS
			#ifdef CLOUD_SHADOW
				#ifdef VFOG_CLOUD_SHADOW
					float cloudShadow = CloudShadowFromTex(fogPos - cameraPosition);
				#endif
			#endif
		#endif
*/
		
		float integral = transmittance - absorption * transmittance;
		stepRayDensity *= integral;

		//#if defined VOLUMETRIC_CLOUDS && defined CLOUD_SHADOW && defined VFOG_CLOUD_SHADOW
		//	stepRayDensity *= mix(cloudShadow, 1.0, wetness * 0.1 + 0.03);
		//	fogDensity += integral * mix(cloudShadow, 1.0, wetness * 0.3 + 0.7);
		//#else
			fogDensity += integral;
		//#endif

		rayDensity += stepRayDensity * shadow;

		#ifdef VFOG_STAINED
			translucentColor += stepRayDensity * shadowColorSample;
		#endif
			
		transmittance *= absorption;
	}


	vec3 skylight = colorSkylight;
	vec3 skySunLight = colorShadowlight * 0.03;
	skylight += skySunLight * (1.0 + (1.0 - globalCloudShadow) * (1.0 - wetness));

	skylight = mix(skylight, skySunLight, wetness * 0.5);

	vec3 fogColor = skylight         * fogDensity;
	vec3 rayColor = colorShadowlight * rayDensity;
	#ifdef VFOG_STAINED
		rayColor += colorShadowlight * translucentColor;
	#endif

	fogColor *= 0.3 * VFOG_FOG_DENSITY      * SKYLIGHT_INTENSITY;
	rayColor *= 1.2 * VFOG_SUNLIGHT_DENSITY * SUNLIGHT_INTENSITY;

	//#if !defined VOLUMETRIC_CLOUDS || !defined CLOUD_SHADOW || !defined VFOG_CLOUD_SHADOW
		rayColor *= mix(globalCloudShadow, 1.0, wetness * 0.025);
		//rayColor *= globalCloudShadow;
	//#endif

	#if FOG_SKYLIGHT_FALLOFF > 0
		fogColor *= eyeBrightnessCurved;
		#if defined CAVE_MODE || defined VFOG_LQ
			rayColor *= eyeBrightnessCurved;
		#endif
		transmittance = mix(1.0, transmittance, eyeBrightnessCurved);
	#endif

	color = transmittance * color;
	color += fogColor + rayColor;
}


vec3 UnderwaterVolumetricFog(vec3 startPos, vec3 endPos, vec3 worldDir, float VdotSR, float globalCloudShadow){
	const float range = 20.0;

	vec3 result = vec3(0.0);

	float rayLength = length(startPos);
	if (rayLength < range){
	
		float endLength = length(endPos);
		if (endLength > range){
			endLength = range;
			endPos = worldDir * range;
		}
		
		vec3 shadowStart = ShadowScreenPos_From_WorldPos(startPos + gbufferModelViewInverse[3].xyz);
		vec3 shadowEnd = ShadowScreenPos_From_WorldPos(endPos + gbufferModelViewInverse[3].xyz);

		const float rSteps = 1.0 / UNDERWATER_VFOG_QUALITY;

		#if defined TAA || defined SUPER_RESOLUTION
			float noise = BlueNoiseTemporal().y;
		#else
			float noise = bayer64(gl_FragCoord.xy);
		#endif

		vec3 shadowIncrement = (shadowEnd - shadowStart) * rSteps;
		vec3 shadowRayPosition = shadowIncrement * noise + shadowStart;

		float rayIncrement = (endLength - rayLength) * rSteps;
		rayLength += rayIncrement * noise;

		float causticsSum = 0.0;

		for (int i = 0; i < UNDERWATER_VFOG_QUALITY; i++, shadowRayPosition += shadowIncrement, rayLength += rayIncrement){
			vec3 shadowPos = shadowRayPosition;
			shadowPos = DistortShadowScreenPos(shadowPos);		

			vec4 shadowColorSample = textureLod(shadowcolor0, shadowPos.xy, 0.0);
			if (shadowColorSample.a > 0.003) continue;

			float caustics = shadowColorSample.r * float(shadowColorSample.a < 0.003);

			if (saturate(shadowPos) == shadowPos){
				float solidDepth = textureLod(shadowtex1, shadowPos.xy, 0.0).x;
				caustics *= step(shadowPos.z, solidDepth);
			}

			caustics /= rayLength * 0.2 + 0.1;

			causticsSum += caustics * rayIncrement;
		}
		causticsSum *= rSteps;

		result = colorShadowlight * (causticsSum * MiePhaseFunction(0.65, -VdotSR) * (UNDERWATER_VFOG_DENSITY * 0.07));

		#ifdef WATER_FOG
			const vec3 waterAttenuation = exp2(-vec3(WATER_ATTENUATION_R, WATER_ATTENUATION_G, WATER_ATTENUATION_B * 0.9) * 20.0);
			result *= waterAttenuation;
		#endif

		result *= globalCloudShadow;
	}

	return result;
}


vec3 simpleScattering(vec3 camera, vec3 worldDir, float dist, float shadowDist, vec3 lightVector){
	float ds = RaySphereIntersection(camera, lightVector, atmosphereModel_top_radius).y * 0.25;
	vec3 opticalLength = ds * lightVector;
	camera += 0.5 * opticalLength;

	vec3 opticalDepth = vec3(0.0);
	for (int i = 0; i < 4; i++, camera += opticalLength){
		float altitude = length(camera) - atmosphereModel_bottom_radius;
		opticalDepth += vec3(GetProfileDensityRayleighMie(atmosphereModel_densityProfile_rayleigh, altitude),
							 GetProfileDensityRayleighMie(atmosphereModel_densityProfile_mie, altitude),
							 GetProfileDensityAbsorption (atmosphereModel_densityProfile_absorption_width, atmosphereModel_densityProfile_absorption, altitude));
	}
	opticalDepth = opticalDepth * ds + dist;

	vec3 attenuation = exp2(-opticalDepth.x * atmosphereModel_rayleigh_scattering
		 				    -opticalDepth.y * atmosphereModel_mie_scattering
		 			   	    -opticalDepth.z * atmosphereModel_absorption_extinction);

	float nu = dot(worldDir, lightVector);
	vec3 scattering = atmosphereModel_rayleigh_scattering *  RayleighPhaseFunction(nu) * (dist * 0.15 + shadowDist * 0.85 * (1.0 - wetness))
					+ atmosphereModel_mie_scattering      * (MiePhaseFunction(0.6 - wetness * 0.2, nu) * shadowDist);

	return scattering * atmosphereModel_solar_irradiance * attenuation * LMS;
}

#ifdef SHOW_TODO
#error "Land Scattering: timeMidnight"
#endif

void LandAtmosphericScattering(inout vec3 color, float dist, vec3 startPos, vec3 endPos, vec3 worldDir, bool isSky){
	float strength = max(LANDSCATTERING_STRENGTH - float(isSky), 0.0);
	#ifdef VFOG
		strength *= 1.0 - fogTime.x;
	#endif
	#ifdef DIMENSION_OVERWORLD
	#if FOG_SKYLIGHT_FALLOFF > 0
		strength *= texelFetch(pixelData2D, ivec2(PIXELDATA_EYE_BRIGHTNESS, 0), 0).x;
	#endif
	#endif
	
	if(strength > 0.001){

		#ifdef ATMO_HORIZON
			vec3 camera = vec3(0.0, max(cameraPosition.y, ATMO_MIN_ALTITUDE) * 0.001 + atmosphereModel_bottom_radius, 0.0);
		#else
			vec3 camera = vec3(0.0, max(cameraPosition.y, 63.0) * 0.001 + atmosphereModel_bottom_radius, 0.0);
		#endif

		float shadowDist = dist;

		#ifdef LANDSCATTERING_SHADOW
			const float rSteps = 1.0 / LANDSCATTERING_SHADOW_QUALITY;

			vec3 shadowStart = ShadowScreenPos_From_WorldPos(startPos + gbufferModelViewInverse[3].xyz);
			vec3 shadowEnd = ShadowScreenPos_From_WorldPos(endPos + gbufferModelViewInverse[3].xyz);

			#if defined TAA || defined SUPER_RESOLUTION
				float noise = BayerTemporal();
			#else
				float noise = bayer64(gl_FragCoord.xy);
			#endif

			vec3 shadowIncrement = (shadowEnd - shadowStart) * rSteps;
			vec3 shadowRayPosition = shadowIncrement * noise + shadowStart;

			float shadowLength = 0.0;

			for (int i = 0; i < LANDSCATTERING_SHADOW_QUALITY; i++, shadowRayPosition += shadowIncrement){
				vec3 shadowPos = shadowRayPosition;
					
				shadowPos = DistortShadowScreenPos(shadowPos);

				if (shadowPos.z < -1e-9) continue;

				if (saturate(shadowPos.xy) == shadowPos.xy && shadowPos.z < 1.0){
					float solidDepth = textureLod(shadowtex0, shadowPos.xy, 0.0).x;
					shadowLength += step(solidDepth, shadowPos.z);
				}
			}

			shadowDist = max(shadowDist - shadowLength * length((endPos - startPos) * rSteps), 0.0);
		#endif

		dist *= LANDSCATTERING_DISTANCE;
		shadowDist *= LANDSCATTERING_DISTANCE;

		color += simpleScattering(camera, worldDir, dist, shadowDist, worldSunVector)
			   * strength;
	}
}