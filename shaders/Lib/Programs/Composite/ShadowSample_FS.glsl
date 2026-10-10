

#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"



uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;

uniform sampler3D voxelData3D;


/* RENDERTARGETS: 11 */
layout(location = 0) out vec4 framebuffer_specularTemporal;


ivec2 texelCoord = ivec2(gl_FragCoord.xy);
vec2 texCoord = gl_FragCoord.xy * UNIFORM_PIXEL_SIZE;

#ifdef DIMENSION_END
	const vec3 worldShadowVector = shadowModelViewInverseEnd[2];
	vec3 shadowVector = worldShadowVector * mat3(gbufferModelViewInverse);
#elif defined DIMENSION_OVERWORLD
	in vec3 worldShadowVector;
	in vec3 shadowVector;

	in vec3 colorShadowlight;
#endif


#include "/Lib/GbufferData.glsl"
#include "/Lib/Uniform/GbufferTransforms.glsl"

#include "/Lib/PathTracing/Voxelizer/VoxelProfile.glsl"
#include "/Lib/Uniform/ShadowTransforms.glsl"
#include "/Lib/PathTracing/Tracer/TracingUtilities.glsl"
#include "/Lib/PathTracing/Voxelizer/BlockShape.glsl"
#include "/Lib/PathTracing/Tracer/ShadowTracing.glsl"

#include "/Lib/BasicFunctions/TemporalNoise.glsl"
#ifndef DIMENSION_NETHER
	#include "/Lib/BasicFunctions/Sunlight_Shadow.glsl"
#endif

#ifdef DIMENSION_END
	#include "/Lib/IndividualFunctions/EndSkyTimer.glsl"
#endif


////////////////////////////// Main //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////// Main //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////// Main //////////////////////////////////////////////////////////////////////////////////////////////////////////////////




void main(){
	float depth = uintBitsToFloat(texelFetch(depthtexS, texelCoord, 0).x);

	#ifdef LOD_RENDERING
		bool isDH = depth == 1.0;
		if (isDH) depth = texelFetch(LOD_DEPTH_TEX_1, texelCoord, 0).x;
	#endif

	if (depth == 1.0) discard;


		GbufferData gbuffer 		= GetGbufferDataSoild();
		MaterialMask materialMask 	= CalculateMasks(gbuffer.materialID);

		#ifdef DECREASE_HAND_GHOSTING
			if (materialMask.hand > 0.5)
				depth = depth * (4.0 / MC_HAND_DEPTH) - (2.0 / MC_HAND_DEPTH + 1.0);
		#endif

		vec3 viewPos 				= ViewPos_From_ScreenPos(texCoord, depth);
		#ifdef LOD_RENDERING
			if (isDH) viewPos 		= ViewPos_From_ScreenPos_LOD(texCoord, depth);
		#endif


		vec3 worldPos				= mat3(gbufferModelViewInverse) * viewPos;

		vec3 viewDir 				= normalize(viewPos);
		vec3 worldDir 				= normalize(worldPos);

		#ifdef LOD_RENDERING
			float farDist 				= max(LOD_FAR_PLANE, 1024.0);
		#else
			float farDist 				= max(far * 1.2, 1024.0);
		#endif

		float opaqueDist 			= depth < 1.0 ? length(viewPos) : farDist;
		#ifdef LOD_RENDERING
			float shadowmapRange = saturate(3.2 - opaqueDist / min(shadowDistance, far) * 4.0 - float(isDH) * 1e10);
		#else
			float shadowmapRange = saturate(3.2 - opaqueDist / min(shadowDistance, far) * 4.0);
		#endif

		gbuffer.worldNormal = normalize(mix(gbuffer.worldNormal, vec3(0.0, 1.0, 0.0), materialMask.grass * 0.49));




		
		float sunlightTrans = materialMask.leaves * 0.25 + materialMask.grass * 0.2;
		float sunlight = saturate(dot(gbuffer.worldNormal, worldShadowVector)) + sunlightTrans;

		gbuffer.parallaxShadow = saturate(gbuffer.parallaxShadow + sunlightTrans * 1e10);


		vec3 shadow = vec3(1.0);
		#if PARALLAX_MODE > 0 && !defined LABPBR_SSS
			shadow *= gbuffer.parallaxShadow;
		#endif
		#ifdef DIMENSION_OVERWORLD
		#ifdef SUNLIGHT_LEAK_FIX
			float lightMask = saturate(gbuffer.lightmap.g * 1e5 + float(isEyeInWater == 1));
			shadow *= lightMask;
		#endif
		#endif

		#ifdef LABPBR_SSS
			vec3 sss = vec3(0.0);
		#endif

		if (sunlight * shadow.x > 0.0){
			#ifdef LABPBR_SSS
				shadow *= VariablePenumbraShadow(worldPos, gbuffer.vertexNormal, -viewPos.z, sunlight, gbuffer.albedo, gbuffer.lightmap.g, gbuffer.material.scattering, materialMask, sss);
			#else
				shadow *= VariablePenumbraShadow(worldPos, gbuffer.vertexNormal, -viewPos.z, sunlight, gbuffer.albedo, gbuffer.lightmap.g, gbuffer.material.scattering, materialMask);
			#endif
		}else{
			shadow = vec3(0.0);
		}

		#if PARALLAX_MODE > 0 && defined LABPBR_SSS
			shadow *= gbuffer.parallaxShadow;
		#endif

		if (any(greaterThan(sunlight * shadow, vec3(0.0)))){
			#ifdef PT_SHADOW
				shadow *= ShadowTracing(viewPos, worldPos + gbufferModelViewInverse[3].xyz, gbuffer.vertexNormal, worldShadowVector, gbuffer.lightmap.g);
			#endif


			#ifdef SCREEN_SPACE_SHADOWS
				float leaveMask = materialMask.leaves * shadowmapRange;

				#ifdef HAND_SCREEN_SHADOW
					#ifdef DISABLE_PLAYER_SCREEN_SPACE_SHADOWS
						#if PARALLAX_MODE > 0
							if (leaveMask + materialMask.entitiesSnow + materialMask.entityPlayer < 1.0)
						#else
							if (leaveMask + materialMask.entitiesSnow + materialMask.entityPlayer < 1.0 && gbuffer.parallaxShadow > 0.0)
						#endif
					#else
						#if PARALLAX_MODE > 0
							if (leaveMask + materialMask.entitiesSnow < 1.0)
						#else
							if (leaveMask + materialMask.entitiesSnow < 1.0 && gbuffer.parallaxShadow > 0.0)
						#endif
					#endif
				#else
					#ifdef DISABLE_PLAYER_SCREEN_SPACE_SHADOWS
						#if PARALLAX_MODE > 0
							if (leaveMask + materialMask.hand + materialMask.entitiesSnow + materialMask.entityPlayer < 1.0)
						#else
							if (leaveMask + materialMask.hand + materialMask.entitiesSnow + materialMask.entityPlayer < 1.0 && gbuffer.parallaxShadow > 0.0)
						#endif
					#else
						#if PARALLAX_MODE > 0
							if (leaveMask + materialMask.hand + materialMask.entitiesSnow < 1.0)
						#else
							if (leaveMask + materialMask.hand + materialMask.entitiesSnow < 1.0 && gbuffer.parallaxShadow > 0.0)
						#endif
					#endif
				#endif
					{
						shadow *= mix(ScreenSpaceShadow(viewPos, viewDir, depth, materialMask, shadowmapRange), 1.0, leaveMask);
					}
			#endif

		}

		framebuffer_specularTemporal = vec4(shadow, 1.0);
		
	
}
