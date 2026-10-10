

#define BLACKHOLE_LQ


#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


/* RENDERTARGETS: 8 */
layout(location = 0) out vec4 framebuffer_altOutput;

layout(rgba16f) writeonly uniform image2D FBIMG_DIFFUSE_TEMPORAL;

#if SR_ENABLE == 1 && SR_USING_ALGO == SR_ALGO_DLSSRR
	layout (rgba16f) writeonly uniform image2D colorimg19;
	layout (r32f) writeonly uniform image2D colorimg21;
#endif


ivec2 texelCoord = ivec2(gl_FragCoord.xy);
vec2 texCoord = gl_FragCoord.xy * UNIFORM_PIXEL_SIZE;

#ifdef DIMENSION_OVERWORLD
	in vec3 worldShadowVector;
	in vec3 worldSunVector;

	in vec3 colorShadowlight;
	in vec3 colorSunlight;
	in vec3 colorMoonlight;

	in vec3 colorSkylight;

	in vec2 fogTime;
#endif

uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;

uniform sampler2D shadowcolor0;

uniform sampler3D voxelData3D;

#ifdef PT_IRC
	uniform sampler3D irradianceCache3D;
	uniform sampler3D irradianceCache3D_Alt;
#endif


#include "/Lib/GbufferData.glsl"
#include "/Lib/Uniform/GbufferTransforms.glsl"
#include "/Lib/BasicFunctions/TemporalNoise.glsl"
#ifdef DIMENSION_OVERWORLD
#include "/Lib/BasicFunctions/PrecomputedAtmosphere.glsl"
#endif
#ifdef DIMENSION_NETHER
	#include "/Lib/BasicFunctions/NetherColor.glsl"
#endif

#include "/Lib/PathTracing/Voxelizer/VoxelProfile.glsl"
#include "/Lib/Uniform/ShadowTransforms.glsl"

#ifdef DIMENSION_OVERWORLD
	#include "/Lib/IndividualFunctions/WaterFog.glsl"

	#define VFOG_LQ
	#include "/Lib/IndividualFunctions/VolumetricFog.glsl"
#endif
#ifdef DIMENSION_END
	#include "/Lib/IndividualFunctions/EndSky.glsl"
#endif


vec3 EnvBRDFApprox2(vec3 SpecularColor, float alpha, float NoV){
	alpha = alpha * alpha;
	NoV = abs(NoV);
	// [Ray Tracing Gems, Chapter 32]
	vec4 X;
		X.x = 1.f;
		X.y = NoV;
		X.z = NoV * NoV;
		X.w = NoV * X.z;
	vec4 Y;
		Y.x = 1.f;
		Y.y = alpha;
		Y.z = alpha * alpha;
		Y.w = alpha * Y.z;
	mat2 M1 = mat2(
		0.99044, -1.28514,
		1.29678, -0.755907
	);
	mat3 M2 = mat3(
		1.00000,  2.92338, 59.4188, 
		20.3225, -27.0302, 222.592, 
		121.563,  626.130, 316.627
	);
	mat2 M3 = mat2(
		0.0365463,  3.32707, 
		9.0632000, -9.04756
	);
	mat3 M4 = mat3(
		1.00000,  3.59685, -1.36772, 
		9.04401, -16.3174,  9.22949, 
		5.56589,  19.7886, -20.2123
	);
	float bias  = dot(M1 * X.xy, Y.xy) / (dot(M2 * X.xyw, Y.xyw));
	float scale = dot(M3 * X.xy, Y.xy) / (dot(M4 * X.xzw, Y.xyw));
	// This is a hack for specular reflectance of 0
	bias *= saturate(SpecularColor.g * 50.0);
	return SpecularColor * max(0.0, scale) + max(0.0, bias);
}


void main(){
	float depth = texelFetch(depthtex0, texelCoord, 0).x;

	#ifdef LOD_RENDERING
		if (depth == 1.0) depth = -texelFetch(LOD_DEPTH_TEX_0, texelCoord, 0).x;
	#endif

	if (abs(depth) == 1.0) discard;

	bool isSmooth = false;
	GbufferData gbuffer = GetGbufferDataTranslucent(isSmooth);
	MaterialMask materialMask = CalculateMasks(gbuffer.materialID);

	float roughness = gbuffer.material.metalness > 229.5 / 255.0 ? -gbuffer.material.roughness : gbuffer.material.roughness;
	imageStore(FBIMG_DIFFUSE_TEMPORAL, texelCoord, vec4(gbuffer.worldNormal, roughness));

	framebuffer_altOutput = vec4(0.0);

	if (gbuffer.material.reflectionStrength > 0.0){
		vec3 viewPos = ViewPos_From_ScreenPos(texCoord, depth);
		#ifdef LOD_RENDERING
			if (depth < 0.0) viewPos = ViewPos_From_ScreenPos_LOD(texCoord, -depth);
		#endif
		vec3 worldPos = mat3(gbufferModelViewInverse) * viewPos.xyz;
		vec3 worldDir = normalize(worldPos.xyz);

		vec3 hitWorldPos = texelFetch(FBTEX_SST_TEMPORAL, texelCoord, 0).xyz;

		framebuffer_altOutput = texelFetch(FBTEX_ALT_OUTPUT, texelCoord, 0);
		vec3 reflection = framebuffer_altOutput.rgb;

		vec3 rayDir = hitWorldPos.xyz - worldPos;
		float hitDist = length(rayDir);
		rayDir /= max(hitDist, 1e-20);

		float specular = 1.0;
		#if SR_ENABLE == 1 && SR_USING_ALGO == SR_ALGO_DLSSRR
			vec3 specularAlbedo = vec3(0.0);
			
			float NdotV = dot(-worldDir, gbuffer.worldNormal);

			if (isEyeInWater == 1 && materialMask.water > 0.5 && 1.0 - (WATER_IOR * WATER_IOR) * (1.0 - NdotV * NdotV) < 0.0){
				specularAlbedo = vec3(1.0);  //totalInternalReflection
			}else{
				vec3 h = normalize(rayDir - worldDir);
				float LdotH = saturate(dot(rayDir, h));
				float NdotL = saturate(dot(gbuffer.worldNormal, rayDir));
				NdotV = saturate(NdotV);

				if (materialMask.stainedGlass + materialMask.water > 0.5){
					float rrSpecular = F_Schlick(LdotH, gbuffer.material.metalness, 1.0);
					rrSpecular *= V_Schlick(NdotL, NdotV + 0.8, gbuffer.material.roughness);
					rrSpecular *= gbuffer.material.reflectionStrength;

					specularAlbedo = vec3(rrSpecular);
				}else if (gbuffer.material.metalness > 229.5 / 255.0){
					/*
					vec3 f0 = vec3(0.0);
					#if TEXTURE_PBR_FORMAT == 1 && defined LABPBR_PREDEFINED_METAL
						if(material.metalness < 237.5 / 255.0){
							f0 = PredefinedMetalF0(gbuffer.material.metalness);
						}else{
							f0 = gbuffer.albedo * (1.0 - METAL_MINIMAL_F0) + METAL_MINIMAL_F0;
						}				
					#else
						f0 = gbuffer.albedo * (1.0 - METAL_MINIMAL_F0) + METAL_MINIMAL_F0;
					#endif

					const float diffuse = clamp(METAL_ORIGIN_COLOR / (1.0 - METALMASK_STRENGTH), 0.0, 1.0);
					vec3 rrSpecular = saturate(F_Schlick_Reflection(LdotH, f0));
					*/

					specularAlbedo = vec3(1.0 - METAL_ORIGIN_COLOR);
								
				}else{
					specular *= F_Schlick(LdotH, gbuffer.material.metalness, 1.0).x;
					specular *= V_Schlick(NdotL, NdotV + 0.8, gbuffer.material.roughness);

					specularAlbedo = vec3(specular);
				}
			}
			specularAlbedo *= gbuffer.material.reflectionStrength;

			//specularAlbedo = vec3(0.0);	

			//specularAlbedo = EnvBRDFApprox2(gbuffer.albedo, gbuffer.material.roughness, NdotV);

			imageStore(colorimg19, texelCoord, vec4(specularAlbedo, 0.0));

		#else
			
			if (gbuffer.material.metalness < 229.5 / 255.0 && materialMask.stainedGlass + materialMask.water < 0.5){
				vec3 h = normalize(rayDir - worldDir);
				float LdotH = saturate(dot(rayDir, h));
				float NdotL = saturate(dot(gbuffer.worldNormal, rayDir));
				float NdotV = saturate(dot(-worldDir, gbuffer.worldNormal));

				specular *= F_Schlick(LdotH, gbuffer.material.metalness, 1.0).x;
				specular *= V_Schlick(NdotL, NdotV + 0.8, gbuffer.material.roughness);
			}
		#endif

		if (hitDist > 0.0){
			#if SR_ENABLE == 1 && SR_USING_ALGO == SR_ALGO_DLSSRR
				imageStore(colorimg21, texelCoord, vec4(hitDist, 0.0, 0.0, 0.0));
			#endif

			float dist = length(worldPos);
			#ifdef LOD_RENDERING
				float farDist = max(float(LOD_RENDER_DISTANCE), far) * 1.4;
				#ifdef DH_LIMIT_VFOG_DIST
					farDist = min(2048.0, farDist);
				#endif
			#else
				float farDist = far * 1.4;
			#endif
			
			#ifdef DIMENSION_OVERWORLD
				float rayDist = max(min(hitDist + dist, farDist) - dist, 0.0);
				vec3 endPos = worldPos + rayDir * rayDist;
				float globalCloudShadow = 1.0 - wetness * (RAIN_SHADOW * 0.985);	


				#if (defined UNDERWATER_VFOG && defined VFOG_REFLECTION) || defined WATER_FOG
					if (isEyeInWater == 1){
						float k = 1.0 - (1.0 / (WATER_IOR * WATER_IOR)) * (1.0 - worldShadowVector.y * worldShadowVector.y);
						vec3 shadowVectorRefracted = -worldShadowVector * (1.0 / WATER_IOR);
						shadowVectorRefracted.y -= (1.0 / WATER_IOR) * -worldShadowVector.y + sqrt(k);
						float VdotSR = dot(shadowVectorRefracted, rayDir);

						#ifdef WATER_FOG
							WaterFog(reflection, rayDir, hitDist, VdotSR);
						#endif

						#ifdef UNDERWATER_VFOG
						#ifdef VFOG_REFLECTION
							reflection += UnderwaterVolumetricFog(worldPos, endPos, rayDir, VdotSR, globalCloudShadow);
						#endif
						#endif
					}
				#endif

				if (isEyeInWater == 0){
					#ifdef LANDSCATTERING
						#ifdef LOD_RENDERING
							LandAtmosphericScattering(reflection, rayDist, worldPos, endPos, rayDir, hitDist > 5e4);
						#else
							#ifdef LANDSCATTERING_REFLECTION
								LandAtmosphericScattering(reflection, rayDist, worldPos, endPos, rayDir, hitDist > 5e4);
							#endif
						#endif
					#endif

					#ifdef VFOG
					#ifdef VFOG_REFLECTION
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

						if (fogTimeFactor > 0.01) VolumetricFog(reflection, worldPos, endPos, rayDir, globalCloudShadow, fogTimeFactor);
					#endif
					#endif
				}

			#endif

			#ifdef DIMENSION_NETHER
				dist = min(dist, 200.0);
				float rayDist = min(hitDist + dist, 200.0);

				NetherFog(reflection, dist, rayDist);

			#endif

			#ifdef DIMENSION_END
				if (hitDist > 5e4){
					BlackHole_AccretionDisc_Stars(reflection, rayDir, shadowModelViewInverseEnd[2]);
					PlanetEnd2(reflection, vec3(0.0), rayDir);
				}

				float rayDist = hitDist + dist;

				EndFog(reflection, rayDist, rayDir, shadowModelViewInverseEnd[2]);

				//if(isEyeInWater == 1) reflection *= vec3(0.5, 0.55, 0.7);
			#endif

		}

		reflection *= saturate(specular);

		framebuffer_altOutput = vec4(reflection, framebuffer_altOutput.a);
	}
}
