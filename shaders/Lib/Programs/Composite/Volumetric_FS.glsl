

#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;


/* RENDERTARGETS: 6 */
layout(location = 0) out vec4 framebuffer_mainOutput;


//#if SR_ENABLE == 1
//	layout(r32f) writeonly uniform image2D colorimg16;
//#endif

ivec2 texelCoord = ivec2(gl_FragCoord.xy);
vec2 texCoord = gl_FragCoord.xy * UNIFORM_PIXEL_SIZE;


#ifdef DIMENSION_OVERWORLD
	in vec3 worldShadowVector;
	in vec3 shadowVector;
	in vec3 worldSunVector;

	in vec3 colorShadowlight;
	in vec3 colorSunlight;
	in vec3 colorMoonlight;

	in vec3 colorSkylight;

	in vec2 fogTime;
#endif

#include "/Lib/GbufferData.glsl"
#include "/Lib/Uniform/GbufferTransforms.glsl"
#include "/Lib/PathTracing/Voxelizer/VoxelProfile.glsl"
#include "/Lib/Uniform/ShadowTransforms.glsl"

#include "/Lib/BasicFunctions/TemporalNoise.glsl"
#ifdef DIMENSION_OVERWORLD
#include "/Lib/BasicFunctions/PrecomputedAtmosphere.glsl"
#endif
#include "/Lib/BasicFunctions/Blocklight.glsl"
#include "/Lib/BasicFunctions/HeldLight.glsl"
#include "/Lib/BasicFunctions/VanillaComposite.glsl"
#ifdef DIMENSION_NETHER
	#include "/Lib/BasicFunctions/NetherColor.glsl"
#endif

#ifdef DIMENSION_OVERWORLD
	#define VFOG_TRANSMITTANCE
	#include "/Lib/IndividualFunctions/VolumetricFog.glsl"
	#define FULL_WATERFOG
	#include "/Lib/IndividualFunctions/WaterFog.glsl"
#endif
#ifdef DIMENSION_END
	#include "/Lib/IndividualFunctions/EndSky.glsl"
#endif

#include "/Lib/IndividualFunctions/DOF.glsl"


void CaveFog(inout vec3 color, float worldDirY, float dist){
	if (eyeBrightnessZeroSmooth > 0.0 && isEyeInWater == 0){
		float fogDensity = 0.011 - worldDirY * 0.003;
		float fogFactor = 1.0 - exp2(-dist * fogDensity);
		fogFactor *= fogFactor;

		vec3 fogColor = mix(vec3(0.9, 1.0, 1.2), vec3(0.75, 1.0, 1.45), 0.5 - worldDirY * 0.5);

		color += fogColor * (fogFactor * eyeBrightnessZeroSmooth * (CAVE_FOG_BRIGHTNESS * 3e-5));
	}
}

#ifdef DIMENSION_OVERWORLD
	void Rain(inout vec3 color, float rainMask){
		vec3 rainSunlight = colorShadowlight * (5.0 - RAIN_SHADOW * 4.0);
		vec3 rainColor = colorSkylight + rainSunlight * 0.1;

		#ifndef DISABLE_LOCAL_PRECIPITATION
			color = mix(
				color,
				rainColor * (eyeSnowySmooth * 0.07 + 0.01),
				saturate(rainMask * (0.2 * eyeSnowySmooth + 0.15) * wetness * RAIN_VISIBILITY)
			);
		#else
			color = mix(color, rainColor * 0.01, saturate(rainMask * wetness * (RAIN_VISIBILITY * 0.15)));
		#endif
	}
#endif


/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void main(){
	float depth = texelFetch(depthtex0, texelCoord, 0).x;

	float materialIDs 				= GetTransMaterialID(texelCoord);
	MaterialMask materialMask 		= CalculateMasks(materialIDs);

	vec3 viewPos 					= ViewPos_From_ScreenPos(texCoord, depth);

	#ifdef LOD_RENDERING
		bool isDH = false;
		if (depth == 1.0){
			isDH = true;
			depth 					= texelFetch(LOD_DEPTH_TEX_0, texelCoord, 0).x;
			viewPos 				= ViewPos_From_ScreenPos_LOD(texCoord, depth);
		}
	#endif

	vec3 worldPos					= mat3(gbufferModelViewInverse) * viewPos;
	vec3 viewDir 					= normalize(viewPos.xyz);
	vec3 worldDir 					= normalize(worldPos.xyz);

	float waterDist 				= length(viewPos) + float(depth == 1.0) * 1e10;

	//#if SR_ENABLE == 1
	//	imageStore(colorimg16, texelCoord, vec4(depth, 0.0, 0.0, 0.0));
	//#endif

	#if SR_ENABLE == 1 && SR_USING_ALGO == SR_ALGO_DLSSRR
		vec3 color = texelFetch(FBTEX_MAIN_OUTPUT, texelCoord, 0).rgb;
	#else
		vec3 color = texelFetch(FBTEX_SST_TEMPORAL, texelCoord, 0).rgb;
	#endif

	
	#ifdef DIMENSION_OVERWORLD

		#ifdef LOD_RENDERING
			float farDist = clamp(LOD_FAR_PLANE, 1024.0, 2048.0);
		#else
			float farDist = max(far * 1.4, 1024.0);
		#endif
		waterDist = min(waterDist, farDist);

		#ifdef LOD_RENDERING
			#ifdef DH_LIMIT_VFOG_DIST
				vec3 rayWorldPos = worldDir * min(waterDist, max(float(LOD_RENDER_DISTANCE), far) * 1.4);
			#else
				vec3 rayWorldPos = worldDir * min(length(worldPos) + float(depth == 1.0) * 1e10, max(float(LOD_RENDER_DISTANCE), far) * 1.4);
			#endif
		#else
			vec3 rayWorldPos = worldDir * min(waterDist, far * 1.4);
		#endif

		#ifdef LANDSCATTERING
			if (isEyeInWater == 0) LandAtmosphericScattering(color, waterDist, vec3(0.0), rayWorldPos, worldDir, materialMask.sky > 0.5);
		#endif

		float globalCloudShadow = 1.0 - wetness * (RAIN_SHADOW * 0.985);

		#ifdef UNDERWATER_VFOG
			if (isEyeInWater == 1){
				float k = 1.0 - (1.0 / (WATER_IOR * WATER_IOR)) * (1.0 - worldShadowVector.y * worldShadowVector.y);
				vec3 shadowVectorRefracted = -worldShadowVector * (1.0 / WATER_IOR);
				shadowVectorRefracted.y -= (1.0 / WATER_IOR) * -worldShadowVector.y + sqrt(k);
				float VdotSR = dot(shadowVectorRefracted, worldDir);

				color += UnderwaterVolumetricFog(vec3(0.0), worldPos, worldDir, VdotSR, globalCloudShadow);
			}
		#endif
		
		#ifdef VFOG
			float fogTimeFactor = 1.0;
			#ifndef VFOG_IGNORE_WORLDTIME
				#ifndef DISABLE_LOCAL_PRECIPITATION
					fogTimeFactor *= mix(fogTime.x, VFOG_RAIN_DENSITY_MUL, wetness * (1.0 - eyeNoPrecipitationSmooth * 0.7));
				#else
					fogTimeFactor *= mix(fogTime.x, VFOG_RAIN_DENSITY_MUL, wetness);
				#endif
			#else
				#ifndef DISABLE_LOCAL_PRECIPITATION
					fogTimeFactor *= mix(1.0, VFOG_RAIN_DENSITY_MUL, wetness * (1.0 - eyeNoPrecipitationSmooth * 0.7));
				#else
					fogTimeFactor *= mix(1.0, VFOG_RAIN_DENSITY_MUL, wetness);
				#endif					
			#endif

			float fogTransmittance = 1.0;
			if (fogTimeFactor > 0.01 && isEyeInWater == 0) VolumetricFog(color, vec3(0.0), rayWorldPos, worldDir, globalCloudShadow, fogTimeFactor, fogTransmittance);
		#endif

		#ifdef DIMENSION_OVERWORLD
		#ifdef CAVE_FOG
			CaveFog(color, worldDir.y, waterDist);
		#endif
		#endif

		if(isEyeInWater == 0.0 && wetness > 0.0) Rain(color, 1.0 - texelFetch(FBTEX_ALBEDO, texelCoord, 0).a);

	#endif

	#ifdef DIMENSION_END
		EndFog(color, waterDist, worldDir, shadowModelViewInverseEnd[2]);
	#endif

	#ifdef DIMENSION_NETHER
		NetherFog(color, waterDist);
	#endif

	if (isEyeInWater == 2) color = mix(color, vec3(3.721, 0.775, 0.024) * BLOCKLIGHT_BRIGHTNESS, smoothstep(0.0, 1.0, waterDist));
	#if defined DIMENSION_OVERWORLD
		if (isEyeInWater == 3) color = mix(color, colorSkylight * 0.5, smoothstep(0.0, 2.0, waterDist));
	#elif defined DIMENSION_NETHER
		if (isEyeInWater == 3) color = mix(color, NetherLighting() * 0.3, smoothstep(0.0, 2.0, waterDist));
	#else
		if (isEyeInWater == 3) color = mix(color, vec3(0.02), smoothstep(0.0, 2.0, waterDist));
	#endif

	//#ifndef DISABLE_BLINDNESS_DARKNESS
	//	if (darknessFactor > 0.0) color = mix(color, vec3(NOLIGHT_BRIGHTNESS), smoothstep(5.0, mix(far, 15.0, darknessFactor), waterDist) * darknessFactor);
	//	if (blindness > 0.0) color = mix(color, vec3(NOLIGHT_BRIGHTNESS), smoothstep(1.5, mix(far, 4.5, blindness), waterDist) * blindness);
	//#endif

	if (materialMask.selection > 0.5 && isEyeInWater < 3){
		float exposure = texelFetch(pixelData2D, ivec2(PIXELDATA_EXPOSURE, 0), 0).x;
		color = GammaToLinear(texelFetch(FBTEX_ALBEDO, texelCoord, 0).rgb) * (exposure * 0.13);
	}
	
	#if SR_SHOULD_APPLY_SCALE == 1
		#if SR_ALGO_DLSS_RENDERPRESET == SR_ALGO_DLSS_RENDERPRESET_L || SR_ALGO_DLSS_RENDERPRESET == SR_ALGO_DLSS_RENDERPRESET_M
			color *= texelFetch(colortex17, ivec2(0), 0).g;
		#endif
	#endif


	#ifdef DISABLE_SKY_RENDERING
		if (depth == 1.0) color = vec3(0.0);
	#endif

	#if SR_ENABLE == 1 && SR_USING_ALGO == SR_ALGO_DLSSRR
		color *= 16.0;
	#endif

	#ifdef DOF
		framebuffer_mainOutput = vec4(max(color, 0.0), CoCSpread());
	#elif defined DIMENSION_NETHER
		framebuffer_mainOutput = vec4(max(color, 0.0), -viewPos.z);
	#elif defined VFOG && defined VFOG_BLOOM && defined BLOOM && defined DIMENSION_OVERWORLD
		framebuffer_mainOutput = vec4(max(color, 0.0), fsqrt(1.0 - fogTransmittance));
	#else
		framebuffer_mainOutput = vec4(max(color, 0.0), 0.0);
	#endif
}