

#if PARALLAX_MODE > 1

#include "/Lib/BasicFunctions/TemporalNoise.glsl"


float BilinearHeightSample(vec2 quadCoord, vec2 atlasSizeF, vec2 quadPixelSize){
	#if PARALLAX_MODE == 2
		vec2 atlasCoord00 = (fract(quadCoord                       ) * v_quadCoordMapping.xy + v_quadCoordMapping.zw) * atlasSizeF;
		vec2 atlasCoord11 = (fract(quadCoord + quadPixelSize * 0.99) * v_quadCoordMapping.xy + v_quadCoordMapping.zw) * atlasSizeF;
		vec2 f = fract(atlasCoord00);
		//f = curve(f);

		ivec2 atlasTexel00 = ivec2(atlasCoord00);
		ivec2 atlasTexel11 = ivec2(atlasCoord11);

		vec4 sh = vec4(
			fetchNormals(      atlasTexel00                   ).a,
			fetchNormals(ivec2(atlasTexel11.x, atlasTexel00.y)).a,
			fetchNormals(ivec2(atlasTexel00.x, atlasTexel11.y)).a,
			fetchNormals(      atlasTexel11                   ).a
		);

	#else
		vec2 atlasCoord00 = (fract(quadCoord - quadPixelSize * 0.49) * v_quadCoordMapping.xy + v_quadCoordMapping.zw) * atlasSizeF;
		vec2 atlasCoord11 = (fract(quadCoord + quadPixelSize * 0.5 ) * v_quadCoordMapping.xy + v_quadCoordMapping.zw) * atlasSizeF;
		vec2 atlasCoord22 = (fract(quadCoord + quadPixelSize * 1.49) * v_quadCoordMapping.xy + v_quadCoordMapping.zw) * atlasSizeF;
		vec2 f = fract(atlasCoord11);

		ivec2 atlasTexel00 = ivec2(atlasCoord00);
		ivec2 atlasTexel11 = ivec2(atlasCoord11);
		ivec2 atlasTexel22 = ivec2(atlasCoord22);

		vec4 sh;

		float sampleHeight00 = fetchNormals(      atlasTexel00                   ).a;
		float sampleHeight01 = fetchNormals(ivec2(atlasTexel00.x, atlasTexel11.y)).a;
		float sampleHeight02 = fetchNormals(ivec2(atlasTexel00.x, atlasTexel22.y)).a;
		float sampleHeight10 = fetchNormals(ivec2(atlasTexel11.x, atlasTexel00.y)).a;
		float sampleHeight11 = fetchNormals(      atlasTexel11                   ).a;
		float sampleHeight12 = fetchNormals(ivec2(atlasTexel11.x, atlasTexel22.y)).a;
		float sampleHeight20 = fetchNormals(ivec2(atlasTexel22.x, atlasTexel00.y)).a;
		float sampleHeight21 = fetchNormals(ivec2(atlasTexel22.x, atlasTexel11.y)).a;
		float sampleHeight22 = fetchNormals(      atlasTexel22                   ).a;

		sh.x = sampleHeight11 * 0.25;
		sh.z = sh.x + sampleHeight12 * 0.25;
		sh.x = sh.x + sampleHeight10 * 0.25;
		sh.y = sh.x + sampleHeight20 * 0.25 + sampleHeight21 * 0.25;
		sh.x = sh.x + sampleHeight00 * 0.25 + sampleHeight01 * 0.25;
		sh.w = sh.z + sampleHeight21 * 0.25 + sampleHeight22 * 0.25;
		sh.z = sh.z + sampleHeight01 * 0.25 + sampleHeight02 * 0.25;

	#endif

	sh += saturate(1.0 - sh * 1e20);

	return mix(mix(sh.x, sh.y, f.x),
			   mix(sh.z, sh.w, f.x),
			   f.y);
}

vec3 HeightBasedNormal(vec2 quadCoord, vec2 atlasSizeF, vec2 quadPixelSize){
	#if PARALLAX_MODE == 2
		vec2 atlasCoord00 = (fract(quadCoord                ) * v_quadCoordMapping.xy + v_quadCoordMapping.zw) * atlasSizeF;
		vec2 atlasCoord11 = (fract(quadCoord + quadPixelSize) * v_quadCoordMapping.xy + v_quadCoordMapping.zw) * atlasSizeF;
		vec2 f = fract(atlasCoord00);
		//f = curve(f);

		ivec2 atlasTexel00 = ivec2(atlasCoord00);
		ivec2 atlasTexel11 = ivec2(atlasCoord11);

		vec4 sh = vec4(
			fetchNormals(      atlasTexel00                   ).a,
			fetchNormals(ivec2(atlasTexel11.x, atlasTexel00.y)).a,
			fetchNormals(ivec2(atlasTexel00.x, atlasTexel11.y)).a,
			fetchNormals(      atlasTexel11                   ).a
		);

	#else
		vec2 atlasCoord00 = (fract(quadCoord - quadPixelSize * 0.5) * v_quadCoordMapping.xy + v_quadCoordMapping.zw) * atlasSizeF;
		vec2 atlasCoord11 = (fract(quadCoord + quadPixelSize * 0.5) * v_quadCoordMapping.xy + v_quadCoordMapping.zw) * atlasSizeF;
		vec2 atlasCoord22 = (fract(quadCoord + quadPixelSize * 1.5) * v_quadCoordMapping.xy + v_quadCoordMapping.zw) * atlasSizeF;
		vec2 f = fract(atlasCoord11);

		ivec2 atlasTexel00 = ivec2(atlasCoord00);
		ivec2 atlasTexel11 = ivec2(atlasCoord11);
		ivec2 atlasTexel22 = ivec2(atlasCoord22);

		vec4 sh;

		float sampleHeight00 = fetchNormals(      atlasTexel00                   ).a;
		float sampleHeight01 = fetchNormals(ivec2(atlasTexel00.x, atlasTexel11.y)).a;
		float sampleHeight02 = fetchNormals(ivec2(atlasTexel00.x, atlasTexel22.y)).a;
		float sampleHeight10 = fetchNormals(ivec2(atlasTexel11.x, atlasTexel00.y)).a;
		float sampleHeight11 = fetchNormals(      atlasTexel11                   ).a;
		float sampleHeight12 = fetchNormals(ivec2(atlasTexel11.x, atlasTexel22.y)).a;
		float sampleHeight20 = fetchNormals(ivec2(atlasTexel22.x, atlasTexel00.y)).a;
		float sampleHeight21 = fetchNormals(ivec2(atlasTexel22.x, atlasTexel11.y)).a;
		float sampleHeight22 = fetchNormals(      atlasTexel22                   ).a;

		sh.x = sampleHeight11 * 0.25;
		sh.z = sh.x + sampleHeight12 * 0.25;
		sh.x = sh.x + sampleHeight10 * 0.25;
		sh.y = sh.x + sampleHeight20 * 0.25 + sampleHeight21 * 0.25;
		sh.x = sh.x + sampleHeight00 * 0.25 + sampleHeight01 * 0.25;
		sh.w = sh.z + sampleHeight21 * 0.25 + sampleHeight22 * 0.25;
		sh.z = sh.z + sampleHeight01 * 0.25 + sampleHeight02 * 0.25;

	#endif


	#if PARALLAX_MODE > 1
		sh.w = sh.y + sh.z -sh.x - sh.w;
		#ifndef PROGRAM_TERRAIN
			return vec3(sh.w * f.yx + (sh.x - sh.yz), (4.0 / PARALLAX_DEPTH) * quadPixelSize.x);
		#else
			return vec3(sh.w * f.yx + (sh.x - sh.yz), (4.0 / PARALLAX_DEPTH) / v_quadCoordScale * quadPixelSize.x);
		#endif
	#else
		const float eps = 0.01;
		f -= 0.5;

		float dX = mix(sh.x - sh.y, sh.z - sh.w, saturate(f.y * 1e20)) * saturate((eps - abs(f.x)) * 1e20);
		float dY = mix(sh.x - sh.z, sh.y - sh.w, saturate(f.x * 1e20)) * saturate((eps - abs(f.y)) * 1e20);
		
		return vec3(dX, dY, step(abs(dX) + abs(dY), 0.0));
	#endif
}

vec2 ParallaxOcclusionMapping(
	vec2 coord,
	mat3 tbnMat,
	vec3 shadowVector,
	float lod,
	vec2 duv1,
	vec2 duv2,
	inout vec3 normalTex
	#ifdef PARALLAX_SHADOW
		,inout float parallaxShadow
	#endif
	#ifdef PT_DIFFUSE_SST_PARALLAX
		,inout float parallaxDist
	#endif
){
	vec3 worldDir = normalize(v_worldPos - gbufferModelViewInverse[3].xyz);

	#ifdef PROGRAM_TERRAIN
		vec2 atlasSizeF = vec2(atlasSize);
	#else
		vec2 atlasSizeF = vec2(textureSize(tex, 0));
	#endif

	if (v_quadCoordMapping.x > 0.0){
		vec2 quadPixelSize = 1.0 / (v_quadCoordMapping.xy * atlasSizeF);
		vec3 parallaxQuadCoord = vec3((coord - v_quadCoordMapping.zw) / v_quadCoordMapping.xy, 1.0);

		parallaxQuadCoord.xy -= quadPixelSize * 0.5;

		float sampleHeight = BilinearHeightSample(parallaxQuadCoord.xy, atlasSizeF, quadPixelSize);

		if (sampleHeight > 0.0 && sampleHeight < 1.0){
			#ifdef PARALLAX_FADE
				vec2 duvMax = max(abs(duv1), abs(duv2)) / v_quadCoordMapping.xy;
				float fade = saturate(pow(max(duvMax.x, duvMax.y) * 0.3, -0.4) * 1.5);
			#endif

			vec3 viewVector = worldDir * tbnMat;
			viewVector /= -viewVector.z;
			
			vec3 stepDir = viewVector / PARALLAX_QUALITY;
			stepDir.y *= quadPixelSize.y / quadPixelSize.x;
			#ifndef PROGRAM_TERRAIN
				stepDir.xy *= PARALLAX_DEPTH * 0.125;
			#else
				stepDir.xy *= v_quadCoordScale * (PARALLAX_DEPTH * 0.25);
			#endif

			float stepLength = 2.0 / PARALLAX_QUALITY;

			for (int i = 0; i < PARALLAX_QUALITY; i++, stepLength += 2.0 / PARALLAX_QUALITY){
				parallaxQuadCoord += stepDir * stepLength;

				sampleHeight = BilinearHeightSample(parallaxQuadCoord.xy, atlasSizeF, quadPixelSize);

				if (sampleHeight > parallaxQuadCoord.z) break;
			}

			for (int i = 0; i < PARALLAX_MAX_REFINEMENTS; i++){
				stepLength *= 0.5;
				parallaxQuadCoord += stepDir * (stepLength * fsign(parallaxQuadCoord.z - sampleHeight));

				sampleHeight = BilinearHeightSample(parallaxQuadCoord.xy, atlasSizeF, quadPixelSize);
			}
			parallaxQuadCoord += stepDir * (stepLength * 0.5 * fsign(parallaxQuadCoord.z - sampleHeight));


			#ifdef PT_DIFFUSE_SST_PARALLAX
				parallaxDist = saturate(1.0 - parallaxQuadCoord.z) / max(dot(-worldDir, tbnMat[2]), 1e-10);
				
				#ifndef PROGRAM_TERRAIN
					parallaxDist *= PARALLAX_DEPTH * 0.125;
				#else
					parallaxDist *= PARALLAX_DEPTH * 0.25;
				#endif

				#ifdef PARALLAX_FADE
					parallaxDist *= fade;
				#endif
			#endif


			#ifndef DIMENSION_NETHER
			#ifdef PARALLAX_SHADOW
				parallaxShadow = saturate(dot(tbnMat[2], shadowVector) * 100.0 - 1.0);

				if(parallaxShadow > 0.0){
					vec3 shadowQuadCoord = parallaxQuadCoord;

					shadowVector = shadowVector * tbnMat;
					shadowVector.z = max(shadowVector.z, 0.001);
					shadowVector /= max(shadowVector.z, 0.1);		

					vec3 stepSize = shadowVector / (PARALLAX_SHADOW_QUALITY);
					stepSize.y *= quadPixelSize.y / quadPixelSize.x;
					#ifndef PROGRAM_TERRAIN
						stepSize.xy *= PARALLAX_DEPTH * 0.125;
					#else
						stepSize.xy *= v_quadCoordScale * PARALLAX_DEPTH * 0.25;
					#endif

					#if defined TAA
						shadowQuadCoord += stepSize * (BlueNoiseTemporal().x + 0.25);
					#else
						shadowQuadCoord += stepSize * (BlueNoise().x + 0.25);
					#endif

					for (int i = 0; i < PARALLAX_SHADOW_QUALITY; i++, shadowQuadCoord += stepSize){	
						if (shadowQuadCoord.z > 1.0) break;

						sampleHeight = BilinearHeightSample(shadowQuadCoord.xy, atlasSizeF, quadPixelSize);

						float diff = shadowQuadCoord.z - sampleHeight;
						parallaxShadow *= saturate(diff * 100.0 + 0.5);

						if(parallaxShadow < 0.003) break;
					}

					#ifdef PARALLAX_FADE
						parallaxShadow *= mix(1.0, parallaxShadow, fade);
					#endif
				}
			#endif
			#endif

			coord = fract(parallaxQuadCoord.xy + quadPixelSize * 0.5) * v_quadCoordMapping.xy + v_quadCoordMapping.zw;


			#if PARALLAX_BASED_NORMAL == 2
				#ifdef PARALLAX_FADE
					normalTex = mix(DecodeNormalTex(sampleNormals(coord, lod).rgb), HeightBasedNormal(parallaxQuadCoord.xy, atlasSizeF, quadPixelSize), fade);
				#else
					normalTex = HeightBasedNormal(parallaxQuadCoord.xy, atlasSizeF, quadPixelSize);
				#endif
			#endif

			
		}
	}

	#if PARALLAX_BASED_NORMAL < 2
		normalTex = DecodeNormalTex(sampleNormals(coord, lod).rgb);
	#endif

	return coord;
}


#elif PARALLAX_MODE == 1


vec2 ParallaxOcclusionMapping(
	vec2 coord,
	mat3 tbnMat,
	vec3 shadowVector,
	float lod,
	vec2 duv1,
	vec2 duv2,
	inout vec3 hitNormal
	#ifdef PARALLAX_SHADOW
		,inout float parallaxShadow
	#endif
	#ifdef PT_DIFFUSE_SST_PARALLAX
		,inout float parallaxDist
	#endif
){
	vec3 worldDir = normalize(v_worldPos - gbufferModelViewInverse[3].xyz);

	#ifdef PROGRAM_TERRAIN
		vec2 atlasSizeF = vec2(atlasSize);
	#else
		vec2 atlasSizeF = vec2(textureSize(tex, 0));
	#endif

	vec2 atlasTexel = coord * atlasSizeF;
	ivec2 parallaxTexel = ivec2(floor(atlasTexel));

	float sampleHeight = fetchNormals(parallaxTexel).a;
	sampleHeight += saturate(1.0 - sampleHeight * 1e20);

	bool exit = false;

	if (sampleHeight > 0.0 && sampleHeight < 1.0){
		#ifdef PARALLAX_FADE
			vec2 duvMax = max(abs(duv1), abs(duv2)) / v_quadCoordMapping.xy;
			float fade = saturate(pow(max(duvMax.x, duvMax.y) * 0.3, -0.4) * 1.5);
		#endif

		ivec4 tileBase = ivec4(
			floor(v_quadCoordMapping.zw * atlasSizeF + 1e-7),
			ceil((v_quadCoordMapping.xy + v_quadCoordMapping.zw) * atlasSizeF - 1e-7)		
		);
		tileBase.zw -= tileBase.xy;

		vec3 viewVector = worldDir * tbnMat;
		vec3 stepDir = vec3(viewVector.xy, -viewVector.z);
		float quadSize = v_quadCoordMapping.x * atlasSizeF.x;
		#ifndef PROGRAM_TERRAIN
			stepDir.xy *= quadSize * PARALLAX_DEPTH * 0.125;
		#else
			stepDir.xy *= v_quadCoordScale * quadSize * PARALLAX_DEPTH * 0.25;
		#endif
		stepDir = normalize(stepDir);

		vec2 ardir = abs(1.0 / stepDir.xy);
		ivec2 sdir = (floatBitsToInt(stepDir.xy) >> 31) * 2 + 1;

		vec2 totalStep = (vec2(sdir) * (0.5 - (atlasTexel - vec2(parallaxTexel))) + 0.5) * ardir;

		float stepLength = 0.0;
		float stepHeight = 1.0;
		float prevStepHeight = 1.0;
		ivec2 stepNext = ivec2(0);

		for (int i = 0; i < PARALLAX_QUALITY; i++){
			stepLength = min(totalStep.x, totalStep.y);
			stepHeight = 1.0 - stepLength * stepDir.z;
			if (sampleHeight > stepHeight){
				if (sampleHeight > prevStepHeight){
					hitNormal = vec3(-stepNext * sdir, 0.0);
					sampleHeight = prevStepHeight;
				}
				exit = true;
				break;
			}

			stepNext = (floatBitsToInt(vec2(stepLength) - totalStep) >> 31) + 1;
			parallaxTexel += stepNext * sdir;
			totalStep += vec2(stepNext) * ardir;
			prevStepHeight = stepHeight;

			parallaxTexel = tileBase.xy + ((parallaxTexel - tileBase.xy) % tileBase.zw);
			sampleHeight = fetchNormals(parallaxTexel).a;
			sampleHeight += saturate(1.0 - sampleHeight * 1e20);
		}


		#ifdef PT_DIFFUSE_SST_PARALLAX
			parallaxDist = saturate(1.0 - sampleHeight) / max(dot(-worldDir, tbnMat[2]), 1e-10);

			#ifndef PROGRAM_TERRAIN
				parallaxDist *= PARALLAX_DEPTH * 0.125;
			#else
				parallaxDist *= PARALLAX_DEPTH * 0.25;
			#endif

			#ifdef PARALLAX_FADE
				parallaxDist *= fade;
			#endif
		#endif




		#ifndef DIMENSION_NETHER
		#ifdef PARALLAX_SHADOW
			parallaxShadow = saturate(dot(tbnMat[2], shadowVector) * 200.0 - 0.5);
			shadowVector = shadowVector * tbnMat;

			if(dot(shadowVector, hitNormal) * parallaxShadow > 0.0 && exit){
				float shadowStepLength = (1.0 - sampleHeight) / stepDir.z;

				vec2 shadowTexel = atlasTexel + shadowStepLength * stepDir.xy;
				ivec2 shadowParallaxTexel = ivec2(floor(shadowTexel));

				#ifndef PROGRAM_TERRAIN
					shadowVector.xy *= quadSize * PARALLAX_DEPTH * 0.125;
				#else
					shadowVector.xy *= v_quadCoordScale * quadSize * PARALLAX_DEPTH * 0.25;
				#endif
				vec3 shadowStepDir = normalize(shadowVector);

				vec2 ardir = abs(1.0 / shadowStepDir.xy);
				ivec2 sdir = (floatBitsToInt(shadowStepDir.xy) >> 31) * 2 + 1;

				totalStep = (vec2(sdir) * (0.5 - (shadowTexel - shadowParallaxTexel)) + 0.5) * ardir;
				stepNext = ivec2(0);

				for (int i = 0; i < PARALLAX_SHADOW_QUALITY; i++){
					shadowStepLength = min(totalStep.x, totalStep.y);
					float shadowHeight = sampleHeight + shadowStepLength * shadowStepDir.z;

					stepNext = (floatBitsToInt(vec2(shadowStepLength) - totalStep) >> 31) + 1;
					shadowParallaxTexel += stepNext * sdir;
					totalStep += vec2(stepNext) * ardir;

					shadowParallaxTexel = tileBase.xy + ((shadowParallaxTexel - tileBase.xy) % tileBase.zw);
					float shadowSampleHeight = fetchNormals(shadowParallaxTexel).a;
					shadowSampleHeight += saturate(1.0 - shadowSampleHeight * 1e20);

					if (shadowSampleHeight > shadowHeight){
						parallaxShadow = 0.0;
						break;
					}
				}
		
				#ifdef PARALLAX_FADE
					parallaxShadow = mix(1.0, parallaxShadow, fade);
				#endif
			}
		#endif
		#endif


		coord = (vec2(parallaxTexel) + 0.5) / atlasSizeF;

#if PARALLAX_BASED_NORMAL == 1

		#ifdef PARALLAX_FADE
			hitNormal = mix(DecodeNormalTex(sampleNormals(coord, lod).rgb), hitNormal, fade * (1.0 - hitNormal.z));
		#else
			if(hitNormal.z == 1.0) hitNormal = DecodeNormalTex(sampleNormals(coord, lod).rgb);
		#endif
		
	}else{
		hitNormal = DecodeNormalTex(sampleNormals(coord, lod).rgb);

#elif PARALLAX_BASED_NORMAL == 2 && defined PARALLAX_FADE

		hitNormal = mix(vec3(0.0, 0.0, 1.0), hitNormal, fade);

#endif
	}

	#if PARALLAX_BASED_NORMAL == 0
		hitNormal = DecodeNormalTex(sampleNormals(coord, lod).rgb);
	#endif

	return coord;
}

#endif