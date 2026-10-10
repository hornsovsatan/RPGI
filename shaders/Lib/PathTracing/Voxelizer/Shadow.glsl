

#include "/Lib/Settings.glsl"
#include "/Lib/Utilities.glsl"


//////////////////////////////////////////////////  Vertex Shader  /////////////////////////////////////////////////////////////
//////////////////////////////////////////////////  Vertex Shader  /////////////////////////////////////////////////////////////
//////////////////////////////////////////////////  Vertex Shader  /////////////////////////////////////////////////////////////
#ifdef PROGRAM_VSH

	uniform int renderStage;

	uniform mat4 shadowModelViewInverse;
	uniform mat4 shadowProjection;
	uniform mat4 shadowProjectionInverse;
	uniform vec3 cameraPositionFract;
	uniform vec3 cameraPosition;
	uniform float frameTimeCounter;
	uniform float wetness;

	uniform sampler2D noisetex;

	#ifdef DIMENSION_END
		const mat3 shadowModelViewInverseEnd = mat3(0.4523250774, -0.8087002661, -0.3760397683, 0.2486168185, 0.5192604694, -0.8176541093, 0.85649968, 0.2763556486, 0.4359310193);
		const mat3 shadowModelViewEnd = transpose(shadowModelViewInverseEnd);
	#else
		uniform vec3 shadowModelView0;
		uniform vec3 shadowModelView1;
		uniform vec3 shadowModelView2;
	#endif

	in vec4 mc_Entity;
	in vec4 at_midBlock;
	in vec2 mc_midTexCoord;

	out vec3 g_color;
	out vec3 g_texcoord_isWater;
	out vec3 g_worldPos;

	#ifdef PROGRAM_VOXEL
		flat out uint g_voxel;
		flat out vec3 g_voxelCoord;

		#ifdef VANILLA_EMISSIVE
			flat out vec2 g_mcLightLevel;
		#else
			flat out float g_mcLightLevel;
		#endif
	#endif


	#include "/Lib/PathTracing/Voxelizer/VoxelProfile.glsl"
	#include "/Lib/RTWSM/SampleWarp.glsl"

	#ifdef WAVING_PLANTS
		#include "/Lib/IndividualFunctions/WavingPlants.glsl"
	#endif



	vec2 SampleRTWWarpSmoothProject(vec3 worldPos){
		#ifdef DIMENSION_END
			worldPos = shadowModelViewEnd * worldPos;
		#else
			worldPos = mat3(shadowModelView0, shadowModelView1, shadowModelView2) * worldPos;
		#endif
		return SampleRTWWarpSmooth(worldPos.xy * shadowProjection[0][0] * 0.5 + 0.5);
	}

	vec2 SampleRTWWarpTrilinearSmooth(vec3 worldPos, vec3 midBlock){
		vec3 f = midBlock * 0.015625 + 0.5;

		vec3 midPos = worldPos - midBlock * 0.015625;
		
		return mix(
			mix(
				mix(SampleRTWWarpSmoothProject(midPos + vec3(-0.5, -0.5, -0.5)),
					SampleRTWWarpSmoothProject(midPos + vec3( 0.5, -0.5, -0.5)),
				f.x),
				mix(SampleRTWWarpSmoothProject(midPos + vec3(-0.5,  0.5, -0.5)),
					SampleRTWWarpSmoothProject(midPos + vec3( 0.5,  0.5, -0.5)),
				f.x),
			f.y),
			mix(
				mix(SampleRTWWarpSmoothProject(midPos + vec3(-0.5, -0.5,  0.5)),
					SampleRTWWarpSmoothProject(midPos + vec3( 0.5, -0.5,  0.5)),
				f.x),
				mix(SampleRTWWarpSmoothProject(midPos + vec3(-0.5,  0.5,  0.5)),
					SampleRTWWarpSmoothProject(midPos + vec3( 0.5,  0.5,  0.5)),
				f.x),
			f.y),
		f.z);

	}


	void main(){
		vec4 worldPos = shadowModelViewInverse * gl_ModelViewMatrix * gl_Vertex;

		float skylightmap = saturate(float(gl_MultiTexCoord1.y - 8) / 232.0);
		#ifdef WAVING_PLANTS
		#ifdef SHADOW_WAVING_PLANTS
			WavingPlants(worldPos, skylightmap);
		#endif
		#endif

		g_worldPos = worldPos.xyz;

		#ifdef DIMENSION_END
			worldPos.xyz = shadowModelViewEnd * worldPos.xyz;
		#else
			worldPos.xyz = mat3(shadowModelView0, shadowModelView1, shadowModelView2) * worldPos.xyz;
		#endif
		gl_Position = worldPos;
		gl_Position.xyz *= vec3(shadowProjection[0][0], shadowProjection[0][0], -shadowProjection[0][0] * 0.5);

		#ifndef PT_MIDBLOCK_TEMPFIX
			vec2 rtwWarp;

			if ((renderStage == MC_RENDER_STAGE_TERRAIN_SOLID || renderStage == MC_RENDER_STAGE_TERRAIN_TRANSLUCENT) &&
				all(lessThanEqual(abs(at_midBlock.xyz), vec3(32.0))) && 
				any(greaterThan(32.0 - abs(at_midBlock.xyz), vec3(0.01)))
			){
				rtwWarp = SampleRTWWarpTrilinearSmooth(g_worldPos, at_midBlock.xyz);
			}else{
				rtwWarp = SampleRTWWarpSmooth(gl_Position.xy * 0.5 + 0.5);
			}
		#else
			vec2 rtwWarp = SampleRTWWarpSmooth(gl_Position.xy * 0.5 + 0.5);
		#endif

		gl_Position.xy += rtwWarp * 2.0;
		
		g_color = gl_Color.rgb;

		#ifdef PROGRAM_VOXEL
			float isWater = float(mc_Entity.x == 6000.0);
		#else
			const float isWater = 0.0;
		#endif
		g_texcoord_isWater = vec3(mat2(gl_TextureMatrix[0]) * gl_MultiTexCoord0.xy + gl_TextureMatrix[0][3].xy, isWater);


		#ifdef PROGRAM_VOXEL
			vec3 worldNormal = mat3(shadowModelViewInverse) * normalize(gl_NormalMatrix * gl_Normal);

			//g_voxelID = mc_Entity.x;

			#ifdef VANILLA_EMISSIVE
				g_mcLightLevel = vec2(at_midBlock.w * at_midBlock.w * 0.00442222, skylightmap);
			#else
				g_mcLightLevel = skylightmap;
			#endif

			bool invalidID = mc_Entity.x > 5999.5 && abs(mc_Entity.x - 8400.0) > 400.5;
			#ifndef PT_FULLBLOCK_DETECTION
				invalidID = invalidID || mc_Entity.x < 0.5;
			#endif
			bool invalidNormal = maxVec3(abs(worldNormal)) < 0.99;
			
			g_voxelCoord = vec3(-2.0);

			if (!invalidID){
				if (mc_Entity.x <= 1.0){
					vec3 vertexPos = gl_Vertex.xyz + cameraPositionFract;
					vertexPos = abs(vertexPos - round(vertexPos));					
					bool invalidPos = vertexPos.x + vertexPos.y + vertexPos.z > 0.001;

					#ifdef PT_FULLBLOCK_DETECTION
					if (mc_Entity.x <= 0.0){
						invalidNormal = invalidNormal || invalidPos;
					}else
					#endif
					{
						invalidID = invalidNormal || invalidPos;
					}
				}

				g_voxel = (uint(invalidID) << 29u) | 
						  (uint(invalidNormal) << 28u) | 
						  //(uint(worldNormal.y > 0.7) << 27u) | 
						  uint(clamp(mc_Entity.x, 0.0, 30000.0));

				#ifdef PT_MIDBLOCK_TEMPFIX
					g_voxelCoord = g_worldPos + cameraPositionFract + (voxelResolution * 0.5) - worldNormal * 0.01;
				#else
					g_voxelCoord = g_worldPos + cameraPositionFract + (voxelResolution * 0.5) + at_midBlock.xyz * 0.015625;
				#endif

			}

		#endif
	}


#endif	
//////////////////////////////////////////////////  Geometry Shader  ///////////////////////////////////////////////////////////
//////////////////////////////////////////////////  Geometry Shader  ///////////////////////////////////////////////////////////
//////////////////////////////////////////////////  Geometry Shader  ///////////////////////////////////////////////////////////
#ifdef PROGRAM_GSH


	layout(triangles) in;
	layout(triangle_strip, max_vertices = 3) out;


	uniform mat4 shadowProjection;
	uniform ivec2 atlasSize;
	uniform int renderStage;


	in vec3 g_color[];
	in vec3 g_texcoord_isWater[];
	in vec3 g_worldPos[];

	#ifdef PROGRAM_VOXEL
		layout (r32ui) restrict uniform uimage3D img_voxelID3D;
		layout (r32ui) restrict uniform uimage3D img_voxelColor3D;
		layout (r32ui) restrict uniform uimage3D img_voxelAtlas3D;

		flat in uint g_voxel[];
		flat in vec3 g_voxelCoord[];

		#ifdef VANILLA_EMISSIVE
			flat in vec2 g_mcLightLevel[];
		#else
			flat in float g_mcLightLevel[];
		#endif
	#endif

	out vec3 v_color;
	out vec3 v_texcoord_isWater;
	out vec3 v_worldPos;


	#include "/Lib/PathTracing/Voxelizer/VoxelProfile.glsl"


	void main(){		
		vec3 posDiff = vec3(
			distance(g_worldPos[0], g_worldPos[1]),
			distance(g_worldPos[1], g_worldPos[2]),
			distance(g_worldPos[2], g_worldPos[0])
		);

	#ifndef DIMENSION_NETHER
		float bias = saturate(maxVec3(posDiff) * 0.5 - 1.0) * shadowProjection[0][0] * 0.3;

		for (int i = 0; i < 3; i++) {
			gl_Position = gl_in[i].gl_Position;
			gl_Position.z += bias;
			//ShiftShadowNdcPos(gl_Position.xy);

			v_color = g_color[i];
			v_texcoord_isWater = g_texcoord_isWater[i];
			v_worldPos = g_worldPos[i];

			EmitVertex();
		}
		EndPrimitive();

	#endif


	#ifdef PROGRAM_VOXEL
		if (g_voxel[0] + g_voxel[1] + g_voxel[2] < 1000000000u){

		if (renderStage == MC_RENDER_STAGE_TERRAIN_SOLID || renderStage == MC_RENDER_STAGE_TERRAIN_TRANSLUCENT){

		vec3 voxelCoord = floor(g_voxelCoord[0] * 0.33333333 + g_voxelCoord[1] * 0.33333333 + g_voxelCoord[2] * 0.33333333);
		if (clamp(voxelCoord, vec3(0.0), vec3(voxelResolution - 1.0)) == voxelCoord){

			vec2 atlasResolution = vec2(atlasSize);

			vec2 maxTexCoord = max(g_texcoord_isWater[0].xy, max(g_texcoord_isWater[1].xy, g_texcoord_isWater[2].xy));
			vec2 minTexCoord = min(g_texcoord_isWater[0].xy, min(g_texcoord_isWater[1].xy, g_texcoord_isWater[2].xy));
			vec2 midTexCoord = (maxTexCoord + minTexCoord) * 0.5;

			vec2 coordSize = (maxTexCoord - minTexCoord) * atlasResolution;

			#if TEXTURE_RESOLUTION == 0
				float coordMaxSize = maxVec3(vec3(
					maxVec2(abs(g_texcoord_isWater[0].xy - g_texcoord_isWater[1].xy) * atlasResolution) / posDiff.x,
					maxVec2(abs(g_texcoord_isWater[1].xy - g_texcoord_isWater[2].xy) * atlasResolution) / posDiff.y,
					maxVec2(abs(g_texcoord_isWater[0].xy - g_texcoord_isWater[2].xy) * atlasResolution) / posDiff.z
				));

				float textureResolution = floor(coordMaxSize + 0.5);
			#else
				float textureResolution = TEXTURE_RESOLUTION;
			#endif

			float voxelID = float(g_voxel[0] & 0x000fffffu);

			float roundedResolution = clamp(round(log2(textureResolution)), 1.0, 15.0);

			vec2 atlasTiles = vec2(atlasSize) * exp2(-roundedResolution);

			#if PT_ATLAS_TILE_ALIGNED == 2
				midTexCoord = floor(midTexCoord * atlasTiles) + 0.5;
			
				#ifdef PT_LANTERN_VOXELIZATION
					if (abs(voxelID - 220.5) < 1.0){
						if (voxelID < 220.5){
							midTexCoord += vec2(-5.0 / 16.0, -7.0 / 16.0);
						}else{
							midTexCoord += vec2(-5.0 / 16.0, -6.0 / 16.0);
						}
					}
				#endif

				midTexCoord /= atlasTiles;
			#endif


			#ifdef VANILLA_EMISSIVE
				vec2 blockLight = vec2(g_mcLightLevel[0].x, g_mcLightLevel[0].y * 0.33333333 + g_mcLightLevel[1].y * 0.33333333 + g_mcLightLevel[2].y * 0.33333333);
			#else
				vec2 blockLight = vec2(0.0, g_mcLightLevel[0] * 0.33333333 + g_mcLightLevel[1] * 0.33333333 + g_mcLightLevel[2] * 0.33333333);
			#endif

			float voxelPriority = 8.0 * saturate(float((g_voxel[0] + g_voxel[1] + g_voxel[2]) >> 28u));

			#ifdef PT_FULLBLOCK_DETECTION
				if (voxelID > 0.0){
			#endif
				coordSize /= textureResolution;

				float quadArea = saturate(coordSize.x * coordSize.y);

				voxelPriority -= floor(quadArea * 7.2 + 0.1);

				#if PT_ATLAS_TILE_ALIGNED == 1
					if (
						(
						abs(voxelID - 28.5) < 20.0 // Glass Pane & Stairs
						|| (abs(voxelID - 103.0) < 23.5 && abs(abs(voxelID - 97.5) - 8.0) > 1.0) // Wall & Fence Gate
						)
						&& quadArea < 0.99
					){
						midTexCoord = (floor(midTexCoord * atlasTiles) + 0.5) / atlasTiles;
					}

				#endif

				#if PT_ATLAS_TILE_ALIGNED <= 1
					#ifdef PT_LANTERN_VOXELIZATION
						if (abs(voxelID - 220.5) < 1.0){
							float tileSize = 1.0 / atlasTiles.y;
							if (voxelID < 220.5){
								midTexCoord.y += (-4.5 / 16.0) * tileSize;
							}else{
								midTexCoord.y += (-3.5 / 16.0) * tileSize;
							}
						}
					#endif
				#endif

				if (abs(voxelID - 8400.0) < 400.5){
					voxelID -= 8000.0;

					if (voxelID > 499.5){
						blockLight.x = saturate(voxelID * 0.01 - 5.0) * 0.995;
						voxelID = 1.0;		
					}

				}else{
					#ifdef VANILLA_EMISSIVE
						float hardcodedLight = 
							float(uint(voxelID == 2.0) | uint(abs(voxelID - 224.5) < 5.0)) * 0.995 +
							float(abs(voxelID - 223.0) < 1.5                             ) * 0.005 +
							float(abs(voxelID - 188.5) < 31.0                            ) * 0.5;
						if (hardcodedLight > 0.0) blockLight.x = hardcodedLight;
					#else
						blockLight.x = 
							float(uint(voxelID == 2.0) | uint(abs(voxelID - 224.5) < 5.0)) * 0.995 +
							float(abs(voxelID - 223.0) < 1.5                             ) * 0.005 +
							float(abs(voxelID - 188.5) < 31.0                            ) * 0.5;
					#endif
				}
				
				voxelID = bool(
					uint(voxelID == 2.0) |
					uint(voxelID == 51.0) |
					uint(voxelID == 55.0) |
					uint(abs(voxelID - 6.0) < 2.5) |
					uint(abs(voxelID - 188.5) < 31.0) |
					uint(abs(voxelID - 8016.5) < 8.0)
				) 
				? 	1000.0 - voxelID
				: 	voxelID + 1000.0;


			#ifdef PT_FULLBLOCK_VERIFICATION
				if (voxelID == 1001.0){
					if (abs(posDiff.x + posDiff.y + posDiff.z - 3.41421356) > 0.001){
						voxelID = 65535.0;
						voxelPriority = -7.0;
					}
				}
			#endif

			#ifdef PT_FULLBLOCK_DETECTION
				}else{
					bool isFullBlock = abs(posDiff.x + posDiff.y + posDiff.z - 3.41421356) + voxelPriority < 0.001 && renderStage != MC_RENDER_STAGE_TERRAIN_TRANSLUCENT;
					#ifdef PT_FULLBLOCK_DETECTION_ALPHA_TRACING
						voxelID = isFullBlock ? 999.0 : 65535.0;
					#else
						voxelID = isFullBlock ? 1001.0 : 65535.0;
					#endif
					voxelPriority = float(isFullBlock) * 15.0 - 7.0;
				}
			#endif


			ivec3 voxelTexel = ivec3(voxelCoord);

			uint uPriority = uint(8.0 - voxelPriority) << 28u;

			uint uResolution = uint(roundedResolution) << 24u;
			uint uSkylight = uint(saturate(SkyLightmapCurve(blockLight.y * 1.07)) * 255.0) << 16u;
			uint packVoxelID = uPriority | uResolution | uSkylight | uint(voxelID);
			imageAtomicMax(img_voxelID3D, voxelTexel, packVoxelID);

			uvec2 uMidCoord = uvec2(round(saturate(midTexCoord * (16384.0 / 16383.0)) * 16383.0));
			uint packVoxelAtlas = uPriority | uMidCoord.x << 14u | uMidCoord.y;
			imageAtomicMax(img_voxelAtlas3D, voxelTexel, packVoxelAtlas);

			//uvec3 uColor = uvec3(round(saturate(g_color[0]) * 255.0));
			//uint uBlocklight = uint(round(saturate(blockLight.x) * 255.0));
			//uint uBlocklight = ((g_voxel[0] >> 20u) & 128u) | uint(round(saturate(blockLight.x) * 127.0));
			//uint packVoxelColor = uBlocklight << 24u | uColor.z << 16u | uColor.y << 8u | uColor.x;
			uint packVoxelColor = packUnorm4x8(vec4((g_color[0], blockLight.x)));
			imageAtomicMax(img_voxelColor3D, voxelTexel, packUnorm4x8(vec4(g_color[0], blockLight.x)));
			
		}}}

		#endif
	}


#endif
//////////////////////////////////////////////////  Fragment Shader  ///////////////////////////////////////////////////////////
//////////////////////////////////////////////////  Fragment Shader  ///////////////////////////////////////////////////////////
//////////////////////////////////////////////////  Fragment Shader  ///////////////////////////////////////////////////////////
#ifdef PROGRAM_FSH


	#include "/Lib/PathTracing/Voxelizer/VoxelProfile.glsl"


	layout(location = 0) out vec4 shadowbuffer0;


	uniform mat4 shadowModelViewInverse;
	uniform vec3 cameraPosition;
	uniform ivec2 atlasSize;
	uniform int isEyeInWater;
	uniform vec2 screenSize;
	uniform vec2 pixelSize;
	uniform int frameCounter;
	uniform int renderStage;
	
	uniform sampler2D tex;
	uniform sampler2D noisetex;
	uniform sampler2D pixelData2D;

	#include "/Lib/BasicFunctions/TemporalNoise.glsl"

	#include "/Lib/RTWSM/SampleWarp.glsl"


	in vec3 v_color;
	in vec3 v_texcoord_isWater;
	in vec3 v_worldPos;
	


	vec2 GetWavesNormalFromTex(vec3 pos){
		const float maxCausticsNormalHeight = CAUSTICS_TEX_RESOLUTION;

		vec2 coord = pos.xz;

		#ifdef SHOW_TODO
		#error "caustics : shadowVectorRefracted"
		#endif

		//float k = 1.0 - (1.0 / (WATER_IOR * WATER_IOR)) * (1.0 - shadowModelViewInverse[2].y * shadowModelViewInverse[2].y);
		//vec3 shadowVectorRefracted = -shadowModelViewInverse[2].xyz * (1.0 / WATER_IOR);
		//shadowVectorRefracted.y -= (1.0 / WATER_IOR) * -shadowModelViewInverse[2].y + sqrt(k);

		//coord.x += pos.y * shadowVectorRefracted.x / shadowVectorRefracted.y;
		//coord.y += pos.y * shadowVectorRefracted.z / shadowVectorRefracted.y;

		coord = fract(coord * 0.02);
		coord = coord * vec2(511.0 / 512.0, 511.0 / 513.0) + vec2(0.5 / 512.0, 1.5 / 513.0);

		return textureLod(pixelData2D, coord, 0.0).xy;
	}

	float CalculateWaterCaustics(vec3 worldPos){
		vec2 dither = BlueNoiseTemporal() - 0.5;

		float caustics = 0.0;

		for (float i = -1.0; i <= 1.0; i++){
		for (float j = -1.0; j <= 1.0; j++){
			vec3 lookupPoint = worldPos;
			lookupPoint.xz +=  (dither + vec2(i, j)) * 0.12;

			vec2 wavesNormal = GetWavesNormalFromTex(lookupPoint);

			vec2 collisionPoint = lookupPoint.xz - wavesNormal * 3.0;
			collisionPoint -= worldPos.xz;

			float dist = fsqrt(dot(collisionPoint, collisionPoint));

			caustics += exp2(-dist * 50.0);
		}}

		return saturate(caustics * 0.7);
	}


	void main(){
		#ifndef DIMENSION_NETHER
			//vec3 shadowScreenCoord = gl_FragCoord.xyz;

			//vec2 pixelDiff = (gl_FragCoord.xy - vec2(voxelWidth, 0.0)) - (v_texcoord_mcLightLevel.zw + SampleRTWWarpSmooth(v_texcoord_mcLightLevel.zw)) * 2048.0;
			//float realDepth = gl_FragCoord.z + pixelDiff.x * dFdx(gl_FragCoord.z) + pixelDiff.y * dFdy(gl_FragCoord.z);
			//gl_FragDepth = realDepth;

			vec4 albedoTex = textureLod(tex, v_texcoord_isWater.xy, 0.0);
			
			if (albedoTex.a < 0.004) discard;

			albedoTex.rgb *= v_color;

			if (v_texcoord_isWater.z > 0.5){
				vec3 mcPos = v_worldPos.xyz + cameraPosition;
				float caustics = CalculateWaterCaustics(mcPos);

				float altitude = mcPos.y * 0.5 + 32.0;
				float p = floor(altitude);

				albedoTex = vec4(caustics, altitude - p, p / 255.0, 0.0);

			}else{
				albedoTex.a = albedoTex.a * 0.996 + 0.004;
			}

			shadowbuffer0 = vec4(albedoTex);
			
		#endif
	}


#endif
