


void DiffuseReturnHit(
	inout vec3 diffuse,
	bool exitTracing,
	Ray ray,
	float rayLength,
	vec3 hitVoxelPos,
	vec3 hitNormal,
	vec3 hitSurface,
	#if defined DIMENSION_OVERWORLD && defined SUNLIGHT_LEAK_FIX
		float hitSkylight,
	#endif
	float pdf,
	#ifdef DIFFUSE_TRACING_IRC
		ivec3 cameraPositionIntToPrevious,
		bool sampleHemisphere,
	#endif
	vec4 voxelColor,
	vec3 voxelCoord,
	#ifdef PT_LOWRES_ATLAS
		vec3 atlasCoord
	#else
		vec2 atlasCoord
	#endif
	#ifndef DIMENSION_NETHER
		,vec3 sunLight
		#ifdef DIMENSION_OVERWORLD
			,float waterFogLight
		#else
			,vec3 blackbody
		#endif
	#endif
){
#if defined DIMENSION_OVERWORLD || defined DIMENSION_END

	if (exitTracing){
		rayLength = PT_DIFFUSE_TRACING_DISTANCE;
		vec2 skyCoord = CubemapProjection(ray.dir);
		vec3 skyColor = textureLod(skyBox2D, skyCoord, 0.0).rgb;			
		#ifdef DIMENSION_OVERWORLD
			skyColor *= saturate(ray.dir.y * 25.0 + 0.5);
			#ifdef SUNLIGHT_LEAK_FIX
				skyColor *= isEyeInWater == 1 ? saturate(hitSkylight + 0.05) : saturate(hitSkylight * 4.44);
			#endif
		#endif
		diffuse += skyColor * hitSurface;
	}else{

#else

	if (!exitTracing){

#endif

		voxelColor = unpackUnorm4x8(texelFetch(voxelColor3D, ivec3(voxelCoord), 0).x) * vec4(voxelColor.rgb, 1.0);

		#ifdef LABPBR_EMISSIVENESS
			#ifdef PT_LOWRES_ATLAS
				#if TEXTURE_PBR_FORMAT < 2
					float emissiveness = textureLod(atlasSpecular2D, atlasCoord.xy, atlasCoord.z).a;
					emissiveness -= step(1.0, emissiveness);
				#else
					float emissiveness = textureLod(atlasSpecular2D, atlasCoord.xy, atlasCoord.z).b * 0.996;
				#endif
			#else
				#if TEXTURE_PBR_FORMAT < 2
					float emissiveness = textureLod(atlasSpecular2D, atlasCoord.xy, 0.0).a;
					emissiveness -= step(1.0, emissiveness);
				#else
					float emissiveness = textureLod(atlasSpecular2D, atlasCoord.xy, 0.0).b * 0.996;
				#endif
			#endif

			#if HARDCODED_EMISSIVENESS_MODE == 0
				if (voxelColor.a == 1.0){
					voxelColor = vec4(COLOR_ENDROD_R, COLOR_ENDROD_G, COLOR_ENDROD_B, BRIGHTNESS_ENDROD);
				}else{
					voxelColor.a = emissiveness;
				}
			#else
				voxelColor.a = max(voxelColor.a, emissiveness);

				if (voxelColor.a == 1.0) voxelColor = vec4(COLOR_ENDROD_R, COLOR_ENDROD_G, COLOR_ENDROD_B, BRIGHTNESS_ENDROD);
			#endif		

		#elif HARDCODED_EMISSIVENESS_MODE > 0
			if (voxelColor.a == 1.0) voxelColor = vec4(COLOR_ENDROD_R, COLOR_ENDROD_G, COLOR_ENDROD_B, BRIGHTNESS_ENDROD);

		#else
			voxelColor.a = 0.0;
			
		#endif

		#if WHITE_DEBUG_WORLD > 0
			voxelColor.rgb = vec3(WHITE_DEBUG_WORLD * 0.1);
		#endif
		voxelColor.rgb = GammaToLinear(voxelColor.rgb);


		hitSurface *= voxelColor.rgb;


		diffuse += (BLOCKLIGHT_BRIGHTNESS * voxelColor.a * Radiance(voxelColor.rgb)) * hitSurface;

		#ifdef PT_IRC
			#ifdef DIFFUSE_TRACING_IRC
				ivec3 prevIrcTexel = ivec3(hitVoxelPos) + ((ircResolutionInt - voxelResolutionInt) >> 1) + cameraPositionIntToPrevious;
				vec3 prevIrcColor = vec3(0.0);
				if ((frameCounter & 1) == 0){
					prevIrcColor = texelFetch(irradianceCache3D_Alt, prevIrcTexel, 0).rgb;
				}else{
					prevIrcColor = texelFetch(irradianceCache3D, prevIrcTexel, 0).rgb;
				}
				float weight = 0.01 - PT_IRC_SELFBOUNCE_ATTENUATION * 0.01;
				if (!sampleHemisphere) weight *= 0.625;
				diffuse += prevIrcColor * weight * hitSurface;

			#else
				diffuse += SampleIrradianceCache(hitVoxelPos) * hitSurface;

			#endif	
		#endif

		#ifndef DIMENSION_NETHER
			#ifdef DIMENSION_END
				float sunLighting = saturate(dot(shadowModelViewInverseEnd[2], hitNormal)) * rPI;
			#else
				float sunLighting = saturate(dot(shadowModelViewInverse2, hitNormal)) * rPI;
			#endif
			#ifdef DIMENSION_OVERWORLD
			#ifdef SUNLIGHT_LEAK_FIX
				sunLighting *= saturate(hitSkylight * 444.0 + float(isEyeInWater == 1));
			#endif
			#endif
			/*
			#ifdef PT_SHADOW
				#ifdef SUNLIGHT_LEAK_FIX
					if (isEyeInWater == 1)
				#endif
					{
						if (sunLighting > 0.0) sunLighting *= SimpleShadowTracing(hitVoxelPos, worldShadowVector);
					}
			#endif
			*/		
			if (sunLighting > 0.0){
				vec3 hitWorldPos = hitVoxelPos - cameraPositionFract - (voxelResolution * 0.5);
				vec3 sunColor = sunLight * SimpleShadow(hitWorldPos, hitNormal) * sunLighting;
				diffuse += sunColor * hitSurface;
			}
		#endif
	}
	

	#if defined DIMENSION_OVERWORLD
		diffuse += vec3(WATER_SCATTERING_R, WATER_SCATTERING_G, WATER_SCATTERING_B) * (saturate(rayLength * 0.05) * waterFogLight * pdf);
		diffuse += (vec3(0.97, 0.99, 1.18) * NOLIGHT_BRIGHTNESS) * (saturate(rayLength * 0.15) * pdf);
	#endif

	#ifdef DIMENSION_END
		diffuse += (blackbody * NOLIGHT_BRIGHTNESS * 10.0) * (saturate(rayLength * 0.15 - 0.15) * pdf);
	#endif

	#ifdef DIMENSION_NETHER
		diffuse += NetherLighting() * (saturate(rayLength * 0.1 - 0.1) * pdf);
	#endif
}