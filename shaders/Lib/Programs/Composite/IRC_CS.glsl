

#define DIFFUSE_TRACING
#define DIFFUSE_TRACING_IRC


#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


#include "/Lib/PathTracing/Voxelizer/VoxelProfile.glsl"


#if PT_IRC_RESOLUTION_X == 128
	#define PT_IRC_WORKGROUPS_X 8
#elif PT_IRC_RESOLUTION_X == 192
	#define PT_IRC_WORKGROUPS_X 12
#elif PT_IRC_RESOLUTION_X == 256
	#define PT_IRC_WORKGROUPS_X 16
#elif PT_IRC_RESOLUTION_X == 384
	#define PT_IRC_WORKGROUPS_X 24
#elif PT_IRC_RESOLUTION_X == 512
	#define PT_IRC_WORKGROUPS_X 32
#endif

#if PT_IRC_RESOLUTION_Y == 128
	#define PT_IRC_WORKGROUPS_Y 16
#elif PT_IRC_RESOLUTION_Y == 192
	#define PT_IRC_WORKGROUPS_Y 24
#elif PT_IRC_RESOLUTION_Y == 256
	#define PT_IRC_WORKGROUPS_Y 32
#elif PT_IRC_RESOLUTION_Y == 384
	#define PT_IRC_WORKGROUPS_Y 48
#elif PT_IRC_RESOLUTION_Y == 512
	#define PT_IRC_WORKGROUPS_Y 64
#endif

const ivec3 workGroups = ivec3(PT_IRC_WORKGROUPS_X, PT_IRC_WORKGROUPS_Y, PT_IRC_RESOLUTION_X);
layout (local_size_x = 16, local_size_y = 8) in;


layout (rgba16f) restrict uniform image3D img_irradianceCache3D;
layout (rgba16f) restrict uniform image3D img_irradianceCache3D_Alt;


uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;

uniform sampler3D voxelData3D;
uniform usampler3D voxelColor3D;

uniform sampler3D irradianceCache3D;
uniform sampler3D irradianceCache3D_Alt;


uniform ivec3 cameraPositionInt;
uniform ivec3 previousCameraPositionInt;


#ifdef DIMENSION_NETHER
	#include "/Lib/BasicFunctions/NetherColor.glsl"
#endif

#include "/Lib/Uniform/ShadowTransforms.glsl"
#include "/Lib/PathTracing/Tracer/TracingUtilities.glsl"
#include "/Lib/PathTracing/Tracer/DiffuseTracer.glsl"
#include "/Lib/PathTracing/Voxelizer/BlockShape.glsl"
#include "/Lib/PathTracing/Tracer/ShadowTracing.glsl"

#ifdef DIMENSION_END
	#include "/Lib/IndividualFunctions/EndSkyTimer.glsl"
#endif


vec4 IrradianceCache(ivec3 ircTexel, ivec3 voxelTexel, ivec3 cameraPositionIntToPrevious){
	vec4 ircColor = vec4(0.0, 0.0, 0.0, 1.0);

	vec4 currVoxelData = texelFetch(voxelData3D, voxelTexel, 0);
	float currVoxelID = floor(currVoxelData.z * 65535.0 - 999.9);

	if (abs(currVoxelID) > 1.0 && clamp(voxelTexel, ivec3(1), voxelResolutionInt - 2) == voxelTexel){
		ircColor.a = float(
			//abs(currVoxelID - 6.5) < 2.0 ||
			abs(currVoxelID - 36.5) < 12.0 ||
			currVoxelID == 56.0 ||
			currVoxelID == 59.0 ||
			currVoxelID == 65.0
		) * 2.0 - 1.0;

		float skylight = 0.0;
 
		vec4 closeVoxelData = texelFetch(voxelData3D, voxelTexel + ivec3(0, 0, -1), 0);
		float closeVoxelID = abs(floor(closeVoxelData.z * 65535.0 - 999.9));
		vec2 hasCloseVoxel = vec2(step(closeVoxelID, 2.0), step(closeVoxelID, 240.0));
		skylight = max(skylight, Unpack2xU8_Y_from_U16(closeVoxelData.w) * hasCloseVoxel.y);
		vec3 sampleOffset = vec3(0.0, 0.0, -1.0) * hasCloseVoxel.x;
		vec2 hasVoxel = hasCloseVoxel;

		closeVoxelData = texelFetch(voxelData3D, voxelTexel + ivec3(0, -1, 0), 0);
		closeVoxelID = abs(floor(closeVoxelData.z * 65535.0 - 999.9));
		hasCloseVoxel = vec2(step(closeVoxelID, 2.0), step(closeVoxelID, 240.0));
		skylight = max(skylight, Unpack2xU8_Y_from_U16(closeVoxelData.w) * hasCloseVoxel.y);
		sampleOffset += vec3(0.0, -1.0, 0.0) * hasCloseVoxel.x;
		hasVoxel += hasCloseVoxel;

		closeVoxelData = texelFetch(voxelData3D, voxelTexel + ivec3(-1, 0, 0), 0);
		closeVoxelID = abs(floor(closeVoxelData.z * 65535.0 - 999.9));
		hasCloseVoxel = vec2(step(closeVoxelID, 2.0), step(closeVoxelID, 240.0));
		skylight = max(skylight, Unpack2xU8_Y_from_U16(closeVoxelData.w) * hasCloseVoxel.y);
		sampleOffset += vec3(-1.0, 0.0, 0.0) * hasCloseVoxel.x;
		hasVoxel += hasCloseVoxel;

		closeVoxelData = texelFetch(voxelData3D, voxelTexel + ivec3(1, 0, 0), 0);
		closeVoxelID = abs(floor(closeVoxelData.z * 65535.0 - 999.9));
		hasCloseVoxel = vec2(step(closeVoxelID, 2.0), step(closeVoxelID, 240.0));
		skylight = max(skylight, Unpack2xU8_Y_from_U16(closeVoxelData.w) * hasCloseVoxel.y);
		sampleOffset += vec3(1.0, 0.0, 0.0) * hasCloseVoxel.x;
		hasVoxel += hasCloseVoxel;

		closeVoxelData = texelFetch(voxelData3D, voxelTexel + ivec3(0, 1, 0), 0);
		closeVoxelID = abs(floor(closeVoxelData.z * 65535.0 - 999.9));
		hasCloseVoxel = vec2(step(closeVoxelID, 2.0), step(closeVoxelID, 240.0));
		skylight = max(skylight, Unpack2xU8_Y_from_U16(closeVoxelData.w) * hasCloseVoxel.y);
		sampleOffset += vec3(0.0, 1.0, 0.0) * hasCloseVoxel.x;
		hasVoxel += hasCloseVoxel;

		closeVoxelData = texelFetch(voxelData3D, voxelTexel + ivec3(0, 0, 1), 0);
		closeVoxelID = abs(floor(closeVoxelData.z * 65535.0 - 999.9));
		hasCloseVoxel = vec2(step(closeVoxelID, 2.0), step(closeVoxelID, 240.0));
		skylight = max(skylight, Unpack2xU8_Y_from_U16(closeVoxelData.w) * hasCloseVoxel.y);
		sampleOffset += vec3(0.0, 0.0, 1.0) * hasCloseVoxel.x;
		hasVoxel += hasCloseVoxel;

		float hasCurrVoxel = step(abs(currVoxelID), 240.0);
		if(abs(currVoxelID) <= 5999.0){	
			skylight = Unpack2xU8_Y_from_U16(currVoxelData.w);
			hasVoxel.y += hasCurrVoxel;
		}
		
		const ivec3 particleBorderStart = (voxelResolutionInt >> 1) - ivec3(32, 16, 32);
		const ivec3 particleBorderEnd = (voxelResolutionInt >> 1) + ivec3(31, 15, 32);
		if(clamp(voxelTexel, particleBorderStart, particleBorderEnd) == voxelTexel){
			if (hasVoxel.y <= 0.0){
				skylight = isEyeInWater == 1 ? 0.05 : eyeBrightnessSmoothCurved;
				hasVoxel.y += 1.0;
			}
		}

		if (hasVoxel.y > 0.0){
			bool sampleHemisphere = hasVoxel.x == 1.0 && hasCurrVoxel == 0.0;
			//sampleHemisphere = false;
			sampleOffset *= float(sampleHemisphere);
			#ifdef DIMENSION_OVERWORLD
				vec3 sunLight = texelFetch(FBTEX_ALT_OUTPUT, ivec2(0), 0).rgb * (1.0 - wetness * RAIN_SHADOW);
				float waterFogLight = dot(vec3(2e-4), texelFetch(FBTEX_ALT_OUTPUT, ivec2(1, 0), 0).rgb) * float(isEyeInWater == 1);
			#endif
			#ifdef DIMENSION_END
				const vec3 blackbody = vec3(1.088, 0.979, 0.923);
				vec3 sunLight = (blackbody * SUNLIGHT_INTENSITY * 0.7) * (planetShadow * planetShadow);
			#endif

			vec3 voxelPos = vec3(voxelTexel) + 0.5;
			voxelPos += sampleOffset * 0.49999;
		
			vec2 atlasPixelSize = 1.0 / vec2(textureSize(atlas2D, 0));

			//float vaildSampleCounts = 1e-10;

			uint randSeed = HashWellons32((
				gl_GlobalInvocationID.x + 
				gl_GlobalInvocationID.y * uint(ircResolutionInt.y) +
				gl_GlobalInvocationID.z * uint(ircResolutionInt.z * ircResolutionInt.z)) *
				uint(frameCounter)
			);


			for (int i = 0; i < PT_IRC_SPP; i++){
				vec3 hitVoxelPos = voxelPos;
				vec3 hitNormal = -sampleOffset;
				float pdf = 1.0;
				float hitSkylight = skylight;

				Ray ray;

				if (sampleHemisphere){
					ray = PackRay(hitVoxelPos, HemisphereUnitVector(hitNormal, randSeed));
					pdf = saturate(dot(ray.dir, hitNormal)) * 2.0;
				}else{
					ray = PackRay(hitVoxelPos, RandUnitVector(randSeed));
					pdf = 1.6;
				}

				bool exitTracing = true;

				vec3 voxelCoord = floor(ray.ori);
				vec3 totalStep = (ray.sdir * (voxelCoord - ray.ori + 0.5) + 0.5) * abs(ray.rdir);
				float rayLength = 0.0;
				vec3 tracingNext = step(totalStep, vec3(minVec3(totalStep)));


				vec3 diffuse = vec3(0.0);
				vec3 hitSurface = vec3(pdf);
				vec4 voxelColor = vec4(0.0);
				#ifdef PT_LOWRES_ATLAS
					vec3 atlasCoord = vec3(0.0);
				#else
					vec2 atlasCoord = vec2(0.0);
				#endif

				bool initialHit = false;
				bool traceTranslucent = true;

				if (abs(currVoxelID) <= 5999.0){

					if (currVoxelID >= 237.0){
						diffuse += HitLightShpere(ray, voxelCoord, currVoxelID, rayLength) * hitSurface;						
					} //hit light sphere ?

					if (abs(currVoxelID) <= 240.0){
						bool eliminated = false;

						bool isTranslucent = bool(
							uint(abs(currVoxelID) == 3.0) |
							uint(abs(abs(currVoxelID) - 16.5) < 8.0)
						);

						if ((traceTranslucent || !isTranslucent) && IsHitBlock_FromOrigin_WithInternalIntersection(ray, totalStep, tracingNext, voxelCoord, abs(currVoxelID), rayLength, hitNormal, eliminated)){
							if (eliminated) continue;

							hitVoxelPos = ray.ori + ray.dir * rayLength + hitNormal * (rayLength * 1e-6 + 1e-5);

							vec2 voxelDataW = Unpack2xU8_from_U16(currVoxelData.w);

							#ifdef PT_LOWRES_ATLAS
								atlasCoord = GetAtlasCoordWithLod(voxelCoord, currVoxelData.xy, voxelDataW.x, hitVoxelPos, hitNormal, atlasPixelSize);
								voxelColor = textureLod(atlas2D, atlasCoord.xy, atlasCoord.z);
							#else
								atlasCoord = GetAtlasCoord(voxelCoord, currVoxelData.xy, voxelDataW.x, hitVoxelPos, hitNormal, atlasPixelSize);
								voxelColor = textureLod(atlas2D, atlasCoord.xy, 0);
							#endif

							if (isTranslucent){
								vec3 translucentColor = GammaToLinear(voxelColor.rgb);
								if (currVoxelID < 0.0) diffuse += translucentColor * (Radiance(translucentColor) * pdf * (BLOCKLIGHT_BRIGHTNESS * 0.5));
								hitSurface *= AlbedoToAbsorption(translucentColor, voxelColor.a);
								traceTranslucent = false;
							}else{
								#ifdef PT_TRACING_ALPHA
									if (currVoxelID >= 0.0 || bool(uint(voxelColor.a >= 0.1) & uint(rayLength > 0.0)))
								#endif
									{
										initialHit = true;
										exitTracing = false;
										#ifdef DIMENSION_OVERWORLD
										#ifdef SUNLIGHT_LEAK_FIX
											hitSkylight = voxelDataW.y;
										#endif
										#endif
										break;
									}
							}
						} //hit shape ?
					}

				}

				if (!initialHit){
					#ifdef PT_SPARE_TRACING
						if (abs(currVoxelData.z - 0.76) < 0.16){
							float spareSize = floor(currVoxelData.z * 20.0 - 10.0);

							vec3 spareOrigin = floor(voxelCoord / spareSize) * spareSize;

							vec3 boxMin = spareOrigin - ray.ori;
							vec3 boxMax = boxMin + spareSize;

							vec3 t1 = ray.rdir * boxMin;
							vec3 t2 = ray.rdir * boxMax;

							vec3 tMax = max(t1, t2);
							rayLength = minVec3(tMax);

							tracingNext = step(tMax, vec3(rayLength));

							vec3 exitVoxelCoord = floor(ray.ori + rayLength * ray.dir + tracingNext * ray.sdir * 0.5);

							totalStep += (exitVoxelCoord - voxelCoord) * ray.sdir * abs(ray.rdir);
							voxelCoord = exitVoxelCoord;
						}else{
							rayLength = minVec3(totalStep);
							tracingNext = step(totalStep, vec3(rayLength));
							voxelCoord += tracingNext * ray.sdir;
							totalStep += tracingNext * abs(ray.rdir);
						}
					#else
						rayLength = minVec3(totalStep);
						tracingNext = step(totalStep, vec3(rayLength));
						voxelCoord += tracingNext * ray.sdir;
						totalStep += tracingNext * abs(ray.rdir);
					#endif

					for (int i = 0; i < PT_DIFFUSE_TRACING_DISTANCE; i++){
						if (rayLength > PT_DIFFUSE_TRACING_DISTANCE || clamp(voxelCoord, vec3(0.0), vec3(voxelResolution - 0.5)) != voxelCoord){
							exitTracing = true;
							break;
						} //out of voxel range ?

						vec4 voxelData = texelFetch(voxelData3D, ivec3(voxelCoord), 0);
						float voxelID = floor(voxelData.z * 65535.0 - 999.9);

						if (abs(voxelID) <= 5999.0){

							if (voxelID >= 237.0){
								diffuse += HitLightShpere(ray, voxelCoord, voxelID, rayLength) * hitSurface;
									
							} //hit light sphere ?			

							if (abs(voxelID) <= 240.0){

								bool isTranslucent = bool(
									uint(abs(voxelID) == 3.0) |
									uint(abs(abs(voxelID) - 16.5) < 8.0)
								);

								if ((traceTranslucent || !isTranslucent) && IsHitBlock(ray, totalStep, tracingNext, voxelCoord, abs(voxelID), rayLength, hitNormal)){

									hitVoxelPos = ray.ori + ray.dir * rayLength + hitNormal * (rayLength * 1e-6 + 1e-5);

									vec2 voxelDataW = Unpack2xU8_from_U16(voxelData.w);

									#ifdef PT_LOWRES_ATLAS
										atlasCoord = GetAtlasCoordWithLod(voxelCoord, voxelData.xy, voxelDataW.x, hitVoxelPos, hitNormal, atlasPixelSize);
										voxelColor = textureLod(atlas2D, atlasCoord.xy, atlasCoord.z);
									#else
										atlasCoord = GetAtlasCoord(voxelCoord, voxelData.xy, voxelDataW.x, hitVoxelPos, hitNormal, atlasPixelSize);
										voxelColor = textureLod(atlas2D, atlasCoord.xy, 0);
									#endif
									
									if (isTranslucent){
										vec3 translucentColor = GammaToLinear(voxelColor.rgb);
										if (voxelID < 0.0) diffuse += translucentColor * (Radiance(translucentColor) * pdf * (BLOCKLIGHT_BRIGHTNESS * 0.5));
										hitSurface *= AlbedoToAbsorption(translucentColor, voxelColor.a);
										traceTranslucent = false;

										#ifdef PT_DIFFUSE_REFRACTION
											float LdotN = saturate(dot(ray.dir, hitNormal));
											float k = (PT_DIFFUSE_REFRACTION_IOR * PT_DIFFUSE_REFRACTION_IOR - 1.0) - LdotN * LdotN;
											vec3 refractDir = (ray.dir - (LdotN + sqrt(k)) * hitNormal) * PT_DIFFUSE_REFRACTION_IOR;
											
											ray = PackRay(hitVoxelPos - refractDir * rayLength, refractDir);
											totalStep = (ray.sdir * (voxelCoord - ray.ori + 0.5) + 0.5) * abs(ray.rdir);
										#endif

									}else{
										#ifdef PT_TRACING_ALPHA
											if (voxelID >= 0.0 || bool(uint(voxelColor.a >= 0.1) & uint(rayLength > 0.0)))
										#endif
											{
												exitTracing = false;
												#ifdef DIMENSION_OVERWORLD
												#ifdef SUNLIGHT_LEAK_FIX
													hitSkylight = voxelDataW.y;
												#endif
												#endif
												break;
											}
									}
								} //hit shape ?
							}

						}

						#ifdef PT_SPARE_TRACING
							if (abs(voxelData.z - 0.76) < 0.16){
								float spareSize = floor(voxelData.z * 20.0 - 10.0);

								vec3 spareOrigin = floor(voxelCoord / spareSize) * spareSize;

								vec3 boxMin = spareOrigin - ray.ori;
								vec3 boxMax = boxMin + spareSize;

								vec3 t1 = ray.rdir * boxMin;
								vec3 t2 = ray.rdir * boxMax;

								vec3 tMax = max(t1, t2);
								rayLength = minVec3(tMax);

								tracingNext = step(tMax, vec3(rayLength));

								vec3 exitVoxelCoord = floor(ray.ori + rayLength * ray.dir + tracingNext * ray.sdir * 0.5);

								totalStep += (exitVoxelCoord - voxelCoord) * ray.sdir * abs(ray.rdir);
								voxelCoord = exitVoxelCoord;
							}else{
								rayLength = minVec3(totalStep);
								tracingNext = step(totalStep, vec3(rayLength));
								voxelCoord += tracingNext * ray.sdir;
								totalStep += tracingNext * abs(ray.rdir);
							}
						#else
							rayLength = minVec3(totalStep);
							tracingNext = step(totalStep, vec3(rayLength));
							voxelCoord += tracingNext * ray.sdir;
							totalStep += tracingNext * abs(ray.rdir);
						#endif
					} //stepping loop
				}

				//vaildSampleCounts += 1.0;

				DiffuseReturnHit(
					diffuse, 
					exitTracing, 
					ray, 
					rayLength, 
					hitVoxelPos, 
					hitNormal, 
					hitSurface,
					#if defined DIMENSION_OVERWORLD && defined SUNLIGHT_LEAK_FIX
						hitSkylight, 
					#endif
					pdf,
					cameraPositionIntToPrevious,
					sampleHemisphere,
					voxelColor, 
					voxelCoord, 
					atlasCoord
					#ifndef DIMENSION_NETHER
						,sunLight 
						#ifdef DIMENSION_OVERWORLD
						,waterFogLight
						#else
						,blackbody
						#endif
					#endif
				);


				ircColor.rgb += diffuse;
			}
			//ircColor.rgb /= vaildSampleCounts;	
			ircColor.rgb /= PT_IRC_SPP;

			vec4 prevIrcColor = vec4(0.0);
			ivec3 prevIrcTexel = ircTexel + cameraPositionIntToPrevious;
			if (clamp(prevIrcTexel, ivec3(0), ircResolutionInt - 1) == prevIrcTexel){
				if ((frameCounter & 1) == 0){
					prevIrcColor = texelFetch(irradianceCache3D_Alt, prevIrcTexel, 0);
				}else{
					prevIrcColor = texelFetch(irradianceCache3D, prevIrcTexel, 0);
				}
			}

			//#ifdef PT_IRC_INITIAL_SKYLIGHT
			//	if (dot(prevIrcColor.rgb, vec3(1.0)) <= 0.0 && clamp(ircTexel, ivec3(15), ircResolutionInt - 16) != ircTexel){
			//		#if defined DIMENSION_OVERWORLD || defined DIMENSION_END
			//			prevIrcColor.rgb = SimpleSkyLighting(texelFetch(FBTEX_ALT_OUTPUT, ivec2(1, 0), 0).rgb, texelFetch(FBTEX_ALT_OUTPUT, ivec2(0), 0).rgb, 0.0, saturate(skylight * 2.0 - 1.0));
			//		#endif
			//		#ifdef DIMENSION_NETHER
			//			prevIrcColor.rgb = NetherLighting();
			//		#endif
			//	}else{
			//		prevIrcColor.rgb *= 0.01;
			//	}
			//#else
			//	prevIrcColor.rgb *= 0.01;
			//#endif

			#if SR_ENABLE == 1 && SR_USING_ALGO == SR_ALGO_DLSSRR
				float accumFrames = min(abs(prevIrcColor.a) + 1.0, PT_IRC_MAX_ACCUM * 2.0);
			#else
				float accumFrames = min(abs(prevIrcColor.a) + 1.0, PT_IRC_MAX_ACCUM);
			#endif
			bool worldTimeVaildation = abs(float(worldTime + isEyeInWater * 150) - texelFetch(pixelData2D, ivec2(PIXELDATA_WORLDTIME, 0), 0).x) <= 100.0;
			if (!worldTimeVaildation) accumFrames = 1.0;

			ircColor.rgb = mix(prevIrcColor.rgb, ircColor.rgb * 100.0 * float(worldTimeVaildation), 1.0 / accumFrames);
			ircColor.rgb = max(ircColor.rgb, 1e-7);
			ircColor.a *= accumFrames;
		}
	}

	return ircColor;
}


void main(){
	ivec3 ircTexel = ivec3(gl_GlobalInvocationID.xyz);
	ivec3 voxelTexel = ircTexel + ((voxelResolutionInt - ircResolutionInt) >> 1);
	ivec3 cameraPositionIntToPrevious = cameraPositionInt - previousCameraPositionInt;

	if (clamp(voxelTexel, ivec3(0), voxelResolutionInt - 1) == voxelTexel){
		if ((frameCounter & 1) == 0){
			imageStore(img_irradianceCache3D, ircTexel, IrradianceCache(ircTexel, voxelTexel, cameraPositionIntToPrevious));
		}else{	
			imageStore(img_irradianceCache3D_Alt, ircTexel, IrradianceCache(ircTexel, voxelTexel, cameraPositionIntToPrevious));
		}
	}
}
