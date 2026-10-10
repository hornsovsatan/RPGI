

#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


/* RENDERTARGETS: 6 */
layout(location = 0) out vec4 framebuffer_mainOutput;


ivec2 texelCoord = ivec2(gl_FragCoord.xy);
vec2 texCoord = gl_FragCoord.xy * pixelSize;


#include "/Lib/GbufferData.glsl"
#include "/Lib/Uniform/GbufferTransforms.glsl"
#include "/Lib/BasicFunctions/TemporalNoise.glsl"
#ifdef DIMENSION_NETHER
	#include "/Lib/BasicFunctions/NetherColor.glsl"
#endif

#if defined VS_VELOCITY && defined SR_IRIS_EXT_VELOCITY
	vec2 ScreenVelocity(vec2 coord, float depth){
		vec3 projection = vec3(coord, depth) * 2.0 - 1.0;
		projection = (vec3(vec2(gbufferProjectionInverse0.x, gbufferProjectionInverse0.y) * projection.xy, 0.0) + gbufferProjectionInverse1) / (gbufferProjectionInverse0.z * projection.z + gbufferProjectionInverse0.w);
		projection = mat3(gbufferModelViewInverse) * projection + gbufferModelViewInverse[3].xyz;
		projection = mat3(gbufferPreviousModelView) * projection + gbufferPreviousModelView[3].xyz;	
		projection = (vec3(gbufferPreviousProjection0.x, gbufferPreviousProjection0.y, gbufferPreviousProjection0.z) * projection + gbufferPreviousProjection1) / -projection.z * 0.5 + 0.5;
		return coord - projection.xy;
	}
#else
	vec2 ScreenVelocity(vec2 coord, float depth){
		vec3 projection = vec3(coord, depth) * 2.0 - 1.0;
		projection = (vec3(vec2(gbufferProjectionInverse0.x, gbufferProjectionInverse0.y) * projection.xy, 0.0) + gbufferProjectionInverse1) / (gbufferProjectionInverse0.z * projection.z + gbufferProjectionInverse0.w);
		projection = mat3(gbufferModelViewInverse) * projection + gbufferModelViewInverse[3].xyz;
		if (depth < 1.0) projection += cameraPositionToPrevious;
		projection = mat3(gbufferPreviousModelView) * projection + gbufferPreviousModelView[3].xyz;		
		projection = (vec3(gbufferPreviousProjection0.x, gbufferPreviousProjection0.y, gbufferPreviousProjection0.z) * projection + gbufferPreviousProjection1) / -projection.z * 0.5 + 0.5;
		return coord - projection.xy;
	}
#endif


float SampleDepthFetch(sampler2D depthSampler, ivec2 coord){
	return texelFetch(depthSampler, coord, 0).x;
}

float SampleDepthFetchClosest3x3(sampler2D depthSampler, vec2 coord){
	ivec2 nearestTexel = ivec2(coord * screenSize);
	float depth0 = SampleDepthFetch(depthSampler, nearestTexel + ivec2(-1, -1));
	float depth1 = SampleDepthFetch(depthSampler, nearestTexel + ivec2( 0, -1));
	float depth2 = SampleDepthFetch(depthSampler, nearestTexel + ivec2( 1, -1));
	float depth3 = SampleDepthFetch(depthSampler, nearestTexel + ivec2(-1,  0));
	float depth4 = SampleDepthFetch(depthSampler, nearestTexel + ivec2( 0,  0));
	float depth5 = SampleDepthFetch(depthSampler, nearestTexel + ivec2( 1,  0));
	float depth6 = SampleDepthFetch(depthSampler, nearestTexel + ivec2(-1,  1));
	float depth7 = SampleDepthFetch(depthSampler, nearestTexel + ivec2( 0,  1));
	float depth8 = SampleDepthFetch(depthSampler, nearestTexel + ivec2( 1,  1));

	return min9(depth0, depth1, depth2, depth3, depth4, depth5, depth6, depth7, depth8);
}

float SampleDepthFetch(usampler2D depthSampler, ivec2 coord){
	return uintBitsToFloat(texelFetch(depthSampler, coord, 0).x);
}

float SampleDepthFetchClosest3x3(usampler2D depthSampler, vec2 coord){
	ivec2 nearestTexel = ivec2(coord * screenSize);
	float depth0 = SampleDepthFetch(depthSampler, nearestTexel + ivec2(-1, -1));
	float depth1 = SampleDepthFetch(depthSampler, nearestTexel + ivec2( 0, -1));
	float depth2 = SampleDepthFetch(depthSampler, nearestTexel + ivec2( 1, -1));
	float depth3 = SampleDepthFetch(depthSampler, nearestTexel + ivec2(-1,  0));
	float depth4 = SampleDepthFetch(depthSampler, nearestTexel + ivec2( 0,  0));
	float depth5 = SampleDepthFetch(depthSampler, nearestTexel + ivec2( 1,  0));
	float depth6 = SampleDepthFetch(depthSampler, nearestTexel + ivec2(-1,  1));
	float depth7 = SampleDepthFetch(depthSampler, nearestTexel + ivec2( 0,  1));
	float depth8 = SampleDepthFetch(depthSampler, nearestTexel + ivec2( 1,  1));

	return min9(depth0, depth1, depth2, depth3, depth4, depth5, depth6, depth7, depth8);
}

vec3 MotionBlur(){
	#if defined MOTION_BLUR && !defined RENDERING_MODE
		vec2 velocity = vec2(0.0);

		#ifdef SUPER_RESOLUTION
			ivec2 sampleTexel = ivec2(texCoord * fsrScreenSize);
		#else
			ivec2 sampleTexel = texelCoord;
		#endif

		#if defined VS_VELOCITY && defined SR_IRIS_EXT_VELOCITY
			float depth = texelFetch(depthtex0, sampleTexel, 0).x;
			if (depth < 1.0){
				velocity = texelFetch(colortex16, sampleTexel, 0).xy;
			}else{
				velocity = ScreenVelocity(texCoord, depth);
			}
		#else

			float materialIDs = GetTransMaterialID(sampleTexel);

			float depth = 0.0;
			if (materialIDs == MATID_WATER){
				depth = texelFetch(depthtex0, sampleTexel, 0).x;
			}else{
				depth = uintBitsToFloat(texelFetch(depthtexS, sampleTexel, 0).x);
			}

			#ifdef DISABLE_PLAYER_TAA_MOTION_BLUR
				if (depth > 0.7 && materialIDs != MATID_END_PORTAL && materialIDs != MATID_ENTITIES_PLAYER) 
			#else
				if (depth > 0.7 && materialIDs != MATID_END_PORTAL)
			#endif
				velocity = ScreenVelocity(texCoord, depth);
		#endif



		vec3 color = vec3(0.0);

		float stability = inversesqrt(dot(velocity, velocity));

		ivec2 clampedTexel = clamp(texelCoord, ivec2(2), ivec2(screenSize - 3.0));

		if (stability > 1e5){
			color = texelFetch(FBTEX_MAIN_TEMPORAL, clampedTexel, 0).rgb;

		}else{
			velocity *= saturate(stability);
			#if MOTION_BLUR_SUTTER_MODE == 0
				const float sutter = MOTION_BLUR_SUTTER_ANGLE / 360.0;
			#else
				const float sutter = 1.0 / MOTION_BLUR_SUTTER_SPEED / frameTime;
			#endif
			velocity *= sutter * 0.5;


			vec2 stepDir = velocity * (1.0 / MOTION_BLUR_QUALITY);

			float noise = 0.5;
			#ifdef MOTION_BLUR_DITHER
				noise = BlueNoiseTemporal().x;
			#endif		

			vec2 coord = texCoord - velocity * 0.5 + noise * stepDir;

			const float steps = MOTION_BLUR_QUALITY;
			#if defined DECREASE_HAND_GHOSTING && !defined SUPER_RESOLUTION
				float samples = 0.0;
			#endif

			for (int i = 0; i < MOTION_BLUR_QUALITY; i++){
				vec2 sampleCoord = clamp(coord, 2.5 * pixelSize , 1.0 - 2.5 * pixelSize);

				#if defined DECREASE_HAND_GHOSTING && !defined SUPER_RESOLUTION
					if (SampleDepthFetchClosest3x3(depthtexS, sampleCoord) < 0.7) continue;
					samples++;
				#endif
				color += textureLod(FBTEX_MAIN_TEMPORAL, sampleCoord, 0.0).rgb;
				
				coord += stepDir;
			}

			#if defined DECREASE_HAND_GHOSTING && !defined SUPER_RESOLUTION
				if (samples == 0.0){
					color = texelFetch(FBTEX_MAIN_TEMPORAL, clampedTexel, 0).rgb;
				}else{
					color.rgb /= samples;
				}
			#else
				color.rgb /= MOTION_BLUR_QUALITY;
			#endif

			//color.rgb = vec3(abs(velocity.xy), 0.0);
		}

		color = max(color, vec3(0.0));

	#else
		ivec2 clampedTexel = clamp(texelCoord, ivec2(2), ivec2(screenSize - 3.0));
		vec3 color = texelFetch(FBTEX_MAIN_TEMPORAL, clampedTexel, 0).rgb;
	#endif

	float alpha = abs(saturate(frameTimeCounter * 0.1 - 100.0) - 0.5);
	alpha = curve(remapSaturate(alpha, 0.5, 0.4));
	if (alpha > 0.0){
		ivec2 tc = texelCoord / max(int(screenSize.x * 0.005), 1) - ivec2(2, 1);

		vec2 ct = vec2(0.5, 0.0);
		if (clamp(tc, ivec2(0), ivec2(52, 6)) == tc){
			if (tc.y == 0){
				if (tc.x < 32){if (bool((0x89e81e29 >> (31 - tc.x)) & 1)) ct = vec2(0.3, 1.0);}
				else          {if (bool((0xc8a28000 >> (63 - tc.x)) & 1)) ct = vec2(0.3, 1.0);}
			}else if (tc.y == 1){
				if (tc.x < 32){if (bool((0x9208224a >> (31 - tc.x)) & 1)) ct = vec2(0.3, 1.0);}
				else          {if (bool((0x28a28000 >> (63 - tc.x)) & 1)) ct = vec2(0.3, 1.0);}
			}else if (tc.y == 2){
				if (tc.x < 32){if (bool((0x93e81e4a >> (31 - tc.x)) & 1)) ct = vec2(0.3, 1.0);}
				else          {if (bool((0x28a28000 >> (63 - tc.x)) & 1)) ct = vec2(0.3, 1.0);}
			}else if (tc.y == 3){
				if (tc.x < 32){if (bool((0x922c824a >> (31 - tc.x)) & 1)) ct = vec2(0.3, 1.0);}
				else          {if (bool((0x28a28000 >> (63 - tc.x)) & 1)) ct = vec2(0.3, 1.0);}
			}else if (tc.y == 4){
				if (tc.x < 32){if (bool((0xb9cb1ce9 >> (31 - tc.x)) & 1)) ct = vec2(0.3, 1.0);}
				else          {if (bool((0xcf3cf000 >> (63 - tc.x)) & 1)) ct = vec2(0.3, 1.0);}
			}else if (tc.y == 5){
				if (tc.x < 32){if (bool((0x10000040 >> (31 - tc.x)) & 1)) ct = vec2(0.3, 1.0);}
				else          {if (bool((0x00228800 >> (63 - tc.x)) & 1)) ct = vec2(0.3, 1.0);}
			}else{
				if (tc.x < 32){if (bool((0x90000048 >> (31 - tc.x)) & 1)) ct = vec2(0.3, 1.0);}
				else          {if (bool((0x003cf000 >> (63 - tc.x)) & 1)) ct = vec2(0.3, 1.0);}
			}
		}

		tc += ivec2(1, -1);

		if (clamp(tc, ivec2(0), ivec2(52, 6)) == tc){
			if (tc.y == 0){
				if (tc.x < 32){if (bool((0x89e81e29 >> (31 - tc.x)) & 1)) ct = vec2(3.0, 1.0);}
				else          {if (bool((0xc8a28000 >> (63 - tc.x)) & 1)) ct = vec2(3.0, 1.0);}
			}else if (tc.y == 1){
				if (tc.x < 32){if (bool((0x9208224a >> (31 - tc.x)) & 1)) ct = vec2(3.0, 1.0);}
				else          {if (bool((0x28a28000 >> (63 - tc.x)) & 1)) ct = vec2(3.0, 1.0);}
			}else if (tc.y == 2){
				if (tc.x < 32){if (bool((0x93e81e4a >> (31 - tc.x)) & 1)) ct = vec2(3.0, 1.0);}
				else          {if (bool((0x28a28000 >> (63 - tc.x)) & 1)) ct = vec2(3.0, 1.0);}
			}else if (tc.y == 3){
				if (tc.x < 32){if (bool((0x922c824a >> (31 - tc.x)) & 1)) ct = vec2(3.0, 1.0);}
				else          {if (bool((0x28a28000 >> (63 - tc.x)) & 1)) ct = vec2(3.0, 1.0);}
			}else if (tc.y == 4){
				if (tc.x < 32){if (bool((0xb9cb1ce9 >> (31 - tc.x)) & 1)) ct = vec2(3.0, 1.0);}
				else          {if (bool((0xcf3cf000 >> (63 - tc.x)) & 1)) ct = vec2(3.0, 1.0);}
			}else if (tc.y == 5){
				if (tc.x < 32){if (bool((0x10000040 >> (31 - tc.x)) & 1)) ct = vec2(3.0, 1.0);}
				else          {if (bool((0x00228800 >> (63 - tc.x)) & 1)) ct = vec2(3.0, 1.0);}
			}else{
				if (tc.x < 32){if (bool((0x90000048 >> (31 - tc.x)) & 1)) ct = vec2(3.0, 1.0);}
				else          {if (bool((0x003cf000 >> (63 - tc.x)) & 1)) ct = vec2(3.0, 1.0);}
			}
		}

		color = mix(color, color * ct.x, ct.y * alpha);
	}

	#if SR_ENABLE == 1 && SR_USING_ALGO == SR_ALGO_DLSSRR
		color /= 16.0;
	#endif

	return color;
}

float title(inout vec3 color){
	const float startTime = 0.35;
	float titleCounter = abs(saturate(frameTimeCounter * 0.1) - 0.5);
	float alphaCounter = curve(remapSaturate(titleCounter, startTime - 0.02, startTime - 0.09));
 
	vec4 title = vec4(0.0);

	if (alphaCounter > 0.0){

		vec3 viewDir = normalize(ViewPos_From_ScreenPos_Raw(texCoord, 1.0));
		vec3 camera = vec3(0.0, 0.0, 3.0 + pow(remapSaturate(titleCounter, startTime, startTime - 0.07), 0.1));

		float angleRx = acos(dot(gbufferModelView[1].xyz, vec3(0.0, 0.0, -1.0))) - hPI;

		angleRx = -0.5 * angleRx + 0.1;
		mat3 Rx = mat3(1.0,  0.0,          0.0,
					   0.0,  cos(angleRx), sin(angleRx),
					   0.0, -sin(angleRx), cos(angleRx));

		float angleRy = eyeRySmooth * 7.0;
		mat3 Ry = mat3(cos(angleRy), 0.0, -sin(angleRy),
					   0.0,          1.0,  0.0,
					   sin(angleRy), 0.0,  cos(angleRy));
		Rx = Ry * Rx;

		vec3 op = camera;
		op = Rx * op;
		vec3 pp = Rx * viewDir;

		#if MC_VERSION >= 11400
			op = mat3(gbufferModelViewInverse) * op + gbufferModelViewInverse[3].xyz * 0.1;
			pp = mat3(gbufferModelViewInverse) * pp + gbufferModelViewInverse[3].xyz * 0.1;
		#else
			op = mat3(gbufferModelViewInverse) * op;
			pp = mat3(gbufferModelViewInverse) * pp;
		#endif

		op = op * Ry;

		vec3 intersectionPlane = mat3(gbufferModelView) * RayPlaneIntersection(op, pp, -gbufferModelViewInverse[2].xyz);

		const float size = 0.8;
		if(clamp(intersectionPlane.xy, vec2(-3.0, -1.0) * size, vec2(3.0, 1.0) * size) == intersectionPlane.xy){
			ivec2 tcoord = ivec2(intersectionPlane.xy * (vec2(9.0 / 1.0, -9.0 / 1.0) / size) + vec2(28.0, 10.0));

			title = texelFetch(scatteringLut2D, tcoord, 0);


			#ifdef DIMENSION_NETHER
				title.rgb *= NetherLighting() * 10.0;
				title.a = 1.0 - saturate(1e10 - title.a * 1e10);
			#else
				title.rgb *= texelFetch(pixelData2D, ivec2(PIXELDATA_EXPOSURE, 0), 0).x * 0.2;
			#endif
		}

		title.a *= alphaCounter;

		color = mix(color, title.rgb, title.a);
	}

	return title.a;
}


float MergeBloom(float bloomGuide){
	#ifdef DIMENSION_OVERWORLD
		#if defined SUPER_RESOLUTION || defined CUSTOM_RENDER_RESOLUTION
			float rainAlpha = saturate(1.0 - textureLod(FBTEX_ALBEDO, texCoord * fsrRenderScale, 0.0).a * RAIN_VISIBILITY);
		#else
			float rainAlpha = saturate(1.0 - texelFetch(FBTEX_ALBEDO, texelCoord, 0).a * RAIN_VISIBILITY);
		#endif
	#endif

	#ifdef DIMENSION_NETHER
		#ifdef SUPER_RESOLUTION
		// todo
			float linearDepth = 0.0;
		#else
			float linearDepth = Unpack2xU16_from_F32(texelFetch(FBTEX_MAIN_TEMPORAL, texelCoord, 0).a).x * 1024.0;
		#endif
		#ifndef LOD_RENDERING
			linearDepth = min(linearDepth, far * 0.8);
		#endif
	#else
		float depth = texelFetch(depthtex0, texelCoord, 0).x;
		float linearDepth = LinearDepth_From_ScreenDepth(depth);
		//#ifdef LOD_RENDERING
			//if (depth == 1.0) linearDepth = LinearDepth_From_ScreenDepth_LOD(texelFetch(LOD_DEPTH_TEX_0, texelCoord, 0).x);
		//#endif
	#endif

	float bloomAmount = BLOOM_AMOUNT;

	#ifdef DIMENSION_END
		bloomAmount *= 0.8 * NETHER_END_BLOOM_BOOST + 1.0;
	#endif

	#ifdef DIMENSION_NETHER
		float biomeOffset =	 BiomeNetherWastesSmooth * 1.0;
		biomeOffset +=		 BiomeCrimsonForestSmooth * 0.75;
		biomeOffset +=		 BiomeWarpedForestSmooth * 0.25;
		biomeOffset +=		 BiomeBasaltDeltasSmooth * 0.5;
	
		biomeOffset = biomeOffset * NETHER_END_BLOOM_BOOST + 1.0;
	
		float fogDensity = biomeOffset * (NETHER_END_BLOOM_BOOST * NETHERFOG_DENSITY * 0.009);
	
		if (isEyeInWater > 1) fogDensity = 0.7;
	
		float fogFactor = 1.0 - exp2(-linearDepth * fogDensity);
		fogFactor *= fogFactor * bloomGuide;
	
		bloomAmount = max(bloomAmount * biomeOffset, min(fogFactor, 0.92));
	#else
		//float fogDensity = float(isEyeInWater > 1) * 0.7;

		//#ifdef WATER_FOG
		//	fogDensity = float(isEyeInWater == 1) * 0.07 * WATERFOG_DENSITY;
		//#endif

		//float visibility = 1.0 / exp2(linearDepth * fogDensity);
		//float fogFactor = 1.1 - visibility;
		//fogFactor *= bloomGuide;

		//bloomAmount = max(bloomAmount, fogFactor);
		bloomAmount = max(bloomAmount, float(isEyeInWater >= 1) * 0.3);
	#endif


	#ifdef DIMENSION_OVERWORLD
		#if FOG_SKYLIGHT_FALLOFF > 0
			float eyeBrightnessCurved = texelFetch(pixelData2D, ivec2(PIXELDATA_EYE_BRIGHTNESS, 0), 0).x;
			float rainBloomAmount = wetness * (0.12 * eyeBrightnessCurved + 0.06);
		#else
			float rainBloomAmount = wetness * 0.18;
		#endif
		bloomAmount = max(bloomAmount, saturate(rainBloomAmount));

		#if defined VFOG && !defined DOF
			#ifdef VFOG_BLOOM
				vec2 sampleCoord = texCoord + UNIFORM_TAA_JITTER * 0.5;
				#ifdef SUPER_RESOLUTION
					sampleCoord *= fsrRenderScale;
				#endif
				float fogTransmittance = textureLod(FBTEX_MAIN_OUTPUT, sampleCoord, 0.0).a;

				bloomAmount = max(bloomAmount, fogTransmittance * bloomGuide);
			#endif
		#endif
	#endif

	#ifndef DISABLE_BLINDNESS_DARKNESS
		bloomAmount *= 1.0 - blindness - darknessFactor;
	#endif

	#if HIGHLIGHT_DIFFUSION_FILTER == 2
		bloomAmount *= 2.2;
	#elif HIGHLIGHT_DIFFUSION_FILTER == 1
		bloomAmount *= 1.55;
	#endif

	#ifdef DIMENSION_OVERWORLD
		bloomAmount = max(bloomAmount, rainAlpha * 0.75);
	#endif

	//bloomAmount = float(texCoord.x > 0.5);
	return saturate(bloomAmount);
}


/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void main(){
	vec3 color = MotionBlur();

/*
	#ifdef DIMENSION_OVERWORLD
		#if defined LENS_GLARE || defined LENS_FLARE
			color += CurveToLinear(texelFetch(FBTEX_MAIN_TEMPORAL, texelCoord, 0).rgb) * eyeBrightnessSmoothCurved;
		#endif
	#endif
*/
	float bloomGuide = 0.0;
	#if INFO_1 == 0
		bloomGuide = title(color);
	#endif

	#if SR_SHOULD_APPLY_SCALE == 1
		#if SR_ALGO_DLSS_RENDERPRESET == SR_ALGO_DLSS_RENDERPRESET_L || SR_ALGO_DLSS_RENDERPRESET == SR_ALGO_DLSS_RENDERPRESET_M
			color /= texelFetch(colortex17, ivec2(0), 0).g;
		#endif
	#endif

	#ifdef BLOOM
		bloomGuide = MergeBloom(1.0 - bloomGuide);
	#endif
	
	framebuffer_mainOutput = vec4(color, bloomGuide);
}
