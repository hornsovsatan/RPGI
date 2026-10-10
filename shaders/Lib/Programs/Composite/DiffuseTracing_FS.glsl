

#define DIFFUSE_TRACING
#define DIFFUSE_TRACING_DIFFUSE


#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


/* RENDERTARGETS: 6 */
layout(location = 0) out vec4 framebuffer_mainOutput;

#if SR_ENABLE == 1 && SR_USING_ALGO == SR_ALGO_DLSSRR
	layout (rgba16f) writeonly uniform image2D colorimg20;
#endif

ivec2 texelCoord = ivec2(gl_FragCoord.xy);
vec2 texCoord = gl_FragCoord.xy * UNIFORM_PIXEL_SIZE;

#ifdef DIMENSION_OVERWORLD
	in vec3 colorShadowlight;
	in vec3 colorSkylight;
#endif

uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;

uniform sampler2D shadowcolor0;

uniform sampler3D voxelData3D;
uniform usampler3D voxelColor3D;

#ifdef PT_IRC
	uniform sampler3D irradianceCache3D;
	uniform sampler3D irradianceCache3D_Alt;
#endif


#include "/Lib/GbufferData.glsl"
#include "/Lib/Uniform/GbufferTransforms.glsl"
#include "/Lib/BasicFunctions/TemporalNoise.glsl"

#include "/Lib/BasicFunctions/Blocklight.glsl"
#ifdef DIMENSION_NETHER
	#include "/Lib/BasicFunctions/NetherColor.glsl"
#endif

#include "/Lib/PathTracing/Voxelizer/VoxelProfile.glsl"
#include "/Lib/Uniform/ShadowTransforms.glsl"
#include "/Lib/PathTracing/Tracer/TracingUtilities.glsl"
#include "/Lib/PathTracing/Tracer/SampleIRC.glsl"
#include "/Lib/PathTracing/Tracer/DiffuseTracer.glsl"
#include "/Lib/PathTracing/Voxelizer/BlockShape.glsl"
#include "/Lib/PathTracing/Tracer/ShadowTracing.glsl"

#ifdef DIMENSION_END
	#include "/Lib/IndividualFunctions/EndSkyTimer.glsl"
#endif


vec3 SkyLighting(vec3 raydir, float pdf, float lightmap){
	//float SdotN = dot(worldNormal, normalize(worldSunVector + vec3(0.0, 1.0, 0.0)));
	//float MdotN = dot(worldNormal, normalize(-worldSunVector + vec3(0.0, 1.0, 0.0)));

	//vec3 skylight = colorSunSkylight * (SdotN * 0.35 + 0.65);
	//skylight += colorMoonSkylight * (MdotN * 0.35 + 0.65);

	//vec3 skySunLight = colorShadowlight * (worldNormal.y * 0.015 + 0.02);

	//skylight += skySunLight;

	//#ifdef VOLUMETRIC_CLOUDS
	//	float coverage = mix(CLOUD_CLEAR_COVERY, CLOUD_RAIN_COVERY, wetness);
	//	//skylight += skySunLight * ((1.0 - wetness) * saturate(coverage * 4.0 - 0.6));
	//#endif

	//skylight = mix(skylight, colorShadowlight * (SdotN * 0.003 + 0.005), wetness * 0.6);

	vec2 skyCoord = CubemapProjection(raydir);
	vec3 skyColor = textureLod(skyBox2D, skyCoord, 0.0).rgb;
	skyColor *= pdf;
	#ifndef DIMENSION_END
		skyColor *= saturate(raydir.y * 25.0 + 0.5);
		skyColor *= isEyeInWater == 1 ? saturate(lightmap + 0.05) : lightmap;
	#endif
	
	return skyColor;
}


vec3 DiffuseTracing(vec3 viewPosRaw, float depth, vec3 vertexNormal, vec3 worldNormal, vec2 lightmap){
	#ifdef LOD_RENDERING
		if (depth < 0.0){
			viewPosRaw = ViewPos_From_ScreenPos_LOD(texCoord, -depth);
			depth = 1.1;
		}
	#endif
	vec3 worldPos = mat3(gbufferModelViewInverse) * viewPosRaw.xyz;
	worldPos += gbufferModelViewInverse[3].xyz;

	vec3 voxelPos = worldPos + cameraPositionFract + (voxelResolution * 0.5);
	voxelPos += vertexNormal * (-viewPosRaw.z * 0.0003);

	#if defined PT_DIFFUSE_SST && PARALLAX_MODE > 0 && defined PT_DIFFUSE_SST_PARALLAX
		float parallaxDist = texelFetch(FBTEX_GWATER, texelCoord, 0).x;
		bool isParallax = parallaxDist > 0.0;
		viewPosRaw += parallaxDist * normalize(viewPosRaw);
	#endif

	const vec3 blackbody = vec3(1.088, 0.979, 0.923);

	uint randSeed = HashWellons32(uint(gl_FragCoord.x + screenSize.x * gl_FragCoord.y) * uint(frameCounter));

#if PT_DIFFUSE_SPP > 1 || (defined RENDERING_MODE && RENDERING_MODE_SPP > 1)

	vec3 result = vec3(0.0);

#if defined RENDERING_MODE && RENDERING_MODE_SPP > 1
	vec2 currFramesData = texelFetch(pixelData2D, ivec2(PIXELDATA_RENDER_FRAMES, 0), 0).xy;
	float renderFrames = currFramesData.x * 1000.0 + currFramesData.y - 10.0;

	int spp = renderFrames > 0.5 ? RENDERING_MODE_SPP : PT_DIFFUSE_SPP;
	for (int i = 0; i < spp; i++){

#else
	for (int i = 0; i < PT_DIFFUSE_SPP; i++){

#endif
	

#endif

		vec3 diffuse = vec3(0.0);

		vec3 hitVoxelPos = voxelPos;
		vec3 hitNormal = worldNormal;
		vec3 rayDir = HemisphereUnitVector(hitNormal, randSeed);
		if (dot(rayDir, vertexNormal) <= 0.0) rayDir = HemisphereUnitVector(vertexNormal, randSeed);
		float pdf = saturate(dot(rayDir, hitNormal)) * 2.0;

		//pdf = saturate(dot(rayDir, vertexNormal) * 1e10) * Fd_Burley_FullRoughness(hitNormal, normalize(worldPos), rayDir);
		
	#ifdef PT_DIFFUSE_SST

		bool sh = false;
		vec4 viewPos = vec4(viewPosRaw, 0.0);
		
		if (depth > 0.7){
			
			vec3 viewRayDir = rayDir * mat3(gbufferModelViewInverse);
			vec3 viewVertexNormal = vertexNormal * mat3(gbufferModelViewInverse);			
			float radius = min(-viewPos.z * 5e-4 + 0.025, -viewPos.z * 0.02 / gbufferProjection0.y);
			viewPos.w = radius * 6.0;
			float distThreshold = (0.0075 / PT_DIFFUSE_SST_THICKNESS) / radius;
			float noise = RandWellons(randSeed);
			
			for (int i = 0; i < 6; i++){
				float stepLength = float(i) + noise;
				stepLength = stepLength * stepLength * radius;
				vec3 stepViewPos = viewPos.xyz + viewRayDir * stepLength;

				vec2 sampleCoord = (vec2(gbufferProjection0.x, gbufferProjection0.y) * stepViewPos.xy + gbufferProjection1.xy) / -stepViewPos.z * 0.5 + 0.5;

				if (saturate(sampleCoord) != sampleCoord) break;

				#if defined SUPER_RESOLUTION || defined CUSTOM_RENDER_RESOLUTION
					float sampleDepth = uintBitsToFloat(textureLod(depthtexS, sampleCoord * fsrRenderScale, 0.0).x);
				#else
					float sampleDepth = uintBitsToFloat(textureLod(depthtexS, sampleCoord, 0.0).x);
				#endif
				vec3 sampleViewPos = vec3(sampleCoord, sampleDepth);

				#ifdef LOD_RENDERING
					if (sampleDepth == 1.0){
						#if defined DISTANT_HORIZONS && (defined SUPER_RESOLUTION || defined CUSTOM_RENDER_RESOLUTION)
							sampleDepth = textureLod(LOD_DEPTH_TEX_1, sampleCoord * fsrRenderScale, 0.0).x;
						#else
							sampleDepth = textureLod(LOD_DEPTH_TEX_1, sampleCoord, 0.0).x;
						#endif
						sampleViewPos = ViewPos_From_ScreenPos_Raw_LOD(sampleViewPos.xy, sampleDepth);
					}else{
						sampleViewPos = ViewPos_From_ScreenPos_Raw(sampleViewPos.xy, sampleViewPos.z);
					}
				#else
					sampleViewPos = ViewPos_From_ScreenPos_Raw(sampleViewPos.xy, sampleViewPos.z);
				#endif

				#if PARALLAX_MODE > 0 && defined PT_DIFFUSE_SST_PARALLAX
					#if defined SUPER_RESOLUTION || defined CUSTOM_RENDER_RESOLUTION
						float parallaxDist = textureLod(FBTEX_GWATER, sampleCoord * fsrRenderScale, 0.0).x;
					#else
						float parallaxDist = textureLod(FBTEX_GWATER, sampleCoord, 0.0).x;
					#endif
					sampleViewPos += saturate(parallaxDist - sampleViewPos.z * 1.1451e-4) * normalize(sampleViewPos);
				#endif				

				vec3 posDiff = sampleViewPos - viewPos.xyz;
				float depthGradient = dot(posDiff, viewVertexNormal);

				#if PARALLAX_MODE > 0 && defined PT_DIFFUSE_SST_PARALLAX
					sh = isParallax || depthGradient > -viewPos.z * 0.002 + 0.005;
				#else
					sh = depthGradient > -viewPos.z * 0.002 + 0.005;
				#endif

				float distDiff = (sampleViewPos.z - stepViewPos.z) * distThreshold;
				sh = sh && (dot(normalize(posDiff), viewRayDir) > 0.99 || saturate(distDiff) == distDiff);

				if(sh){
					#if defined PT_DIFFUSE_SST_REPORJECT
						viewPos.xyz = sampleViewPos;
					#else
						viewPos.xy = sampleCoord;
					#endif
					break;
				}
			}
		}
		

		if (sh){
			#if defined PT_DIFFUSE_SST_REPORJECT
				vec3 prevPos = mat3(gbufferPreviousModelView) * (mat3(gbufferModelViewInverse) * viewPos.xyz + gbufferModelViewInverse[3].xyz + cameraPositionToPrevious) + gbufferPreviousModelView[3].xyz;
				viewPos.z = prevPos.z;
				viewPos.xy = (vec2(gbufferPreviousProjection0.x, gbufferPreviousProjection0.y) * prevPos.xy + gbufferPreviousProjection1.xy) / -prevPos.z * 0.5 + 0.5;

				diffuse = vec3(saturate(viewPos.xy) == viewPos.xy);
				ivec2 sampleTexel = ivec2(viewPos.xy * UNIFORM_SCREEN_SIZE);

				vec3 sampleVertexNormal = DecodeNormal(texelFetch(FBTEX_GSOLID_NORMAL, sampleTexel, 0).zw);
				diffuse *= (saturate(dot(-rayDir, sampleVertexNormal) * 1e10) * 0.7 + 0.3) * saturate(dot(rayDir, hitNormal)) * 2.0;

				vec4 prevData = texelFetch(FBTEX_SST_TEMPORAL, sampleTexel, 0);

				#ifdef LOD_RENDERING
					float prevDist = 1e10;
					if (prevData.w >= 0.0){
						prevDist = LinearDepth_From_ScreenDepth(1.0 - prevData.w);
					}else{
						prevDist = LinearDepth_From_ScreenDepth_LOD(prevData.w + 1.0);
					}
				#else
					float prevDist = LinearDepth_From_ScreenDepth(1.0 - prevData.w);
				#endif

				
				diffuse *= step(abs(prevDist + viewPos.z), viewPos.w);

				diffuse *= prevData.rgb;

			#else
				ivec2 sampleTexel = ivec2(viewPos.xy * UNIFORM_SCREEN_SIZE);

				vec3 sampleVertexNormal = DecodeNormal(texelFetch(FBTEX_GSOLID_NORMAL, sampleTexel, 0).zw);
				diffuse = vec3((saturate(dot(-rayDir, sampleVertexNormal)) * 0.7 + 0.3) * saturate(dot(rayDir, hitNormal)) * 2.0);

				diffuse *= texelFetch(FBTEX_SST_TEMPORAL, sampleTexel, 0).rgb;

			#endif

			//diffuse = vec3(1.0, 0.0, 0.0);
		}else

	#endif

	#ifdef LOD_RENDERING

		if (clamp(hitVoxelPos, vec3(0.0), vec3(voxelResolution)) != hitVoxelPos || depth > 1.0){		

	#else

		if (clamp(hitVoxelPos, vec3(0.0), vec3(voxelResolution)) != hitVoxelPos){

	#endif

			#if defined DIMENSION_OVERWORLD || defined DIMENSION_END
				diffuse = SkyLighting(rayDir, pdf, lightmap.y);
			#endif

			#if defined DIMENSION_OVERWORLD
				diffuse += (vec3(0.97, 0.99, 1.18) * NOLIGHT_BRIGHTNESS) * pdf;
			#endif
			#ifdef DIMENSION_END
				diffuse += (blackbody * NOLIGHT_BRIGHTNESS * 10.0) * pdf;
			#endif
			#ifdef DIMENSION_NETHER
				diffuse += NetherLighting() * pdf;
			#endif	

			diffuse += BlockLighting(lightmap.x);		

		}else{
			#ifdef DIMENSION_OVERWORLD
				#ifdef SUNLIGHT_LEAK_FIX
				float hitSkylight = lightmap.y;
				#endif
				vec3 sunLight = colorShadowlight * (1.0 - wetness * RAIN_SHADOW);
				float waterFogLight = dot(vec3(2e-4), colorSkylight) * float(isEyeInWater == 1);
			#endif
			#ifdef DIMENSION_END
				vec3 sunLight = (blackbody * SUNLIGHT_INTENSITY * 0.7) * (planetShadow * planetShadow);
			#endif

			vec2 atlasPixelSize = 1.0 / vec2(textureSize(atlas2D, 0));
		
			Ray ray = PackRay(hitVoxelPos, rayDir);
			vec3 hitSurface = vec3(pdf);


			vec3 voxelCoord = floor(ray.ori);
			vec3 totalStep = (ray.sdir * (voxelCoord - ray.ori + 0.5) + 0.5) * abs(ray.rdir);
			float rayLength = 0.0;
			vec3 tracingNext = step(totalStep, vec3(minVec3(totalStep)));

			vec4 voxelColor = vec4(0.0);
			#ifdef PT_LOWRES_ATLAS
				vec3 atlasCoord = vec3(0.0);
			#else
				vec2 atlasCoord = vec2(0.0);
			#endif

			bool exitTracing = true;			
			bool traceTranslucent = true;
		
			for (int i = 0; i < PT_DIFFUSE_TRACING_DISTANCE; i++){
				if (rayLength > PT_DIFFUSE_TRACING_DISTANCE || clamp(voxelCoord, vec3(0.0), vec3(voxelResolution - 0.5)) != voxelCoord) break; //out of voxel range ?

				vec4 voxelData = texelFetch(voxelData3D, ivec3(voxelCoord), 0);
				float voxelID = floor(voxelData.z * 65535.0 - 999.9);

				if (abs(voxelID) <= 5999.0){

					if (voxelID >= 237.0){
						diffuse += HitLightShpere(ray, voxelCoord, voxelID, rayLength) * hitSurface;		
					} //light sphere

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
									vec3 surfaceNormal = rayLength == 0.0 ? -vertexNormal : hitNormal;
									float LdotN = saturate(dot(ray.dir, surfaceNormal));
									float k = (PT_DIFFUSE_REFRACTION_IOR * PT_DIFFUSE_REFRACTION_IOR - 1.0) - LdotN * LdotN;
									vec3 refractDir = (ray.dir - (LdotN + sqrt(k)) * surfaceNormal) * PT_DIFFUSE_REFRACTION_IOR;
									
									ray = PackRay(hitVoxelPos - refractDir * rayLength, refractDir);
									totalStep = (ray.sdir * (voxelCoord - ray.ori + 0.5) + 0.5) * abs(ray.rdir);
								#endif

							}else{
								#ifdef PT_TRACING_ALPHA
									#ifdef PT_DIFFUSE_FULLBLOCK_NO_SELF_INTERSECTION
										if (!bool((uint(voxelID <= 1.0) & uint(rayLength <= 0.0)) | (uint(voxelID <= 0.0) & uint(voxelColor.a < 0.1))))
									#else
										if (voxelID >= 0.0 || bool(uint(voxelColor.a >= 0.1) & uint(rayLength > 0.0)))
									#endif
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
						} //hit shape
					} //cube block

				} //has voxel

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


		} //in voxel range

#if PT_DIFFUSE_SPP > 1 || (defined RENDERING_MODE && RENDERING_MODE_SPP > 1)
		
		result += diffuse;
	}

	#if defined RENDERING_MODE && RENDERING_MODE_SPP > 1
		return result / spp;
	#else
		return result / PT_DIFFUSE_SPP;
	#endif

#else
		
	return diffuse;

#endif
}


void main(){
	float depth = uintBitsToFloat(texelFetch(depthtexS, texelCoord, 0).x);

	#ifdef LOD_RENDERING
		if (depth == 1.0) depth = -texelFetch(LOD_DEPTH_TEX_1, texelCoord, 0).x;
	#endif

	if (abs(depth) == 1.0) discard;

	GbufferData gbuffer = GetGbufferDataSoild();
	vec3 viewPos = ViewPos_From_ScreenPos(texCoord, depth);

	vec3 lighting = DiffuseTracing(viewPos, depth, gbuffer.vertexNormal, gbuffer.worldNormal, gbuffer.lightmap);

	framebuffer_mainOutput = vec4(max(lighting * 100.0, vec3(0.0)), 0.0);
	#if SR_ENABLE == 1 && SR_USING_ALGO == SR_ALGO_DLSSRR
		imageStore(colorimg20, texelCoord, framebuffer_mainOutput);
	#endif
}
