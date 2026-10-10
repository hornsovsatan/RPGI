//Entities_VS Spidereyes_VS Block_VS Hand_VS


#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


#ifdef PROGRAM_ENTITIES
	uniform int entityId;
#endif

#ifdef PROGRAM_BLOCK
	uniform int blockEntityId;
#endif

uniform int currentRenderedItemId;


out vec4 v_color;
out vec2 v_texCoord;
out vec3 v_worldPos;
out vec2 v_blockLight;
flat out float v_materialIDs;
flat out float v_emissiveness;

#if (defined ENTITIES_VS_TBN && (defined PROGRAM_ENTITIES || defined PROGRAM_SPIDEREYES) && (MC_VERSION < 11500 || MC_VERSION > 11604)) || (defined PROGRAM_HAND && MC_VERSION < 11300)
	in vec4 at_tangent;

	out mat3 v_tbn;
#endif

#ifdef PROGRAM_BLOCK
	out vec4 v_portalCoord;
#endif

#if defined ENTITIES_PARALLAX && PARALLAX_MODE > 0
	in vec2 mc_midTexCoord;

	flat out vec4 v_quadCoordMapping;
#endif


#if defined VS_VELOCITY && defined SR_IRIS_EXT_VELOCITY
	in vec3 at_velocity;

	out vec3 v_velocity;
	#ifdef PROGRAM_HAND
		flat out float v_fovFactor;
	#endif
#endif



#if defined SUPER_RESOLUTION || defined CUSTOM_RENDER_RESOLUTION
	#include "/Lib/FidelityFX/FSR2/GbufferScale.glsl"
#endif



void main(){
	vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;
	v_worldPos = vec3(gbufferModelViewInverse * viewPos);
	gl_Position = gl_ProjectionMatrix * viewPos;

	#if defined VS_VELOCITY && defined SR_IRIS_EXT_VELOCITY && defined PROGRAM_HAND
		v_fovFactor = gl_ProjectionMatrix[1][1];
	#endif

	#if defined SUPER_RESOLUTION || defined CUSTOM_RENDER_RESOLUTION
		#ifdef CUSTOM_RENDER_RESOLUTION
			#ifdef PROGRAM_HAND
				gl_Position = gbufferProjectionInverse * gl_Position;
				mat4 projectMat = gbufferProjection;
				projectMat[0][0] *= viewWidth / viewHeight / fsrScreenSize.x * fsrScreenSize.y;
				gl_Position = projectMat * gl_Position;
			#else
				RedoProject(gl_Position);
			#endif
		#endif
		#if defined CUSTOM_RENDER_RESOLUTION && defined PROGRAM_HAND && defined DECREASE_HAND_GHOSTING
			FsrScaleVS(gl_Position, vec2(0.0));
		#else
			FsrScaleVS(gl_Position, taaJitter);
		#endif
	#else
		#ifdef TAA
			#if defined PROGRAM_HAND
				#ifndef DECREASE_HAND_GHOSTING
					gl_Position.xy = taaJitter * gl_Position.w + gl_Position.xy;
				#endif
			#elif defined PROGRAM_ENTITIES
				#ifdef DISABLE_PLAYER_TAA_MOTION_BLUR
					if(entityId != 7003)
				#endif
					gl_Position.xy = taaJitter * gl_Position.w + gl_Position.xy;
			#else
				gl_Position.xy = taaJitter * gl_Position.w + gl_Position.xy;
			#endif
		#endif
	#endif


	v_color = gl_Color;
	v_texCoord = mat2(gl_TextureMatrix[0]) * gl_MultiTexCoord0.xy + gl_TextureMatrix[0][3].xy;

	//#if defined PROGRAM_HAND && defined TACZ_ADAPTIVE_EMISSIVE
	//	v_blockLight = saturate(vec2(gl_MultiTexCoord1.x - 8, eyeBrightness.y - 8) / 232.0);
	//#else
		v_blockLight = saturate(vec2(gl_MultiTexCoord1.xy - 8) / vec2(232.0, 216.0));

		#if HARDCODED_EMISSIVENESS_MODE == 2 && (defined PROGRAM_ENTITIES || defined PROGRAM_BLOCK)
			v_emissiveness = float(v_blockLight.x == 1.0);
		#else
			v_emissiveness = 0.0;
		#endif

		#if !defined PROGRAM_BLOCK
			v_blockLight.x = min(v_blockLight.x, 0.85);
		#endif
	//#endif


	#if (defined ENTITIES_VS_TBN && (defined PROGRAM_ENTITIES || defined PROGRAM_SPIDEREYES) && (MC_VERSION < 11500 || MC_VERSION > 11604)) || (defined PROGRAM_HAND && MC_VERSION < 11300)
		vec3 N = normalize(mat3(gbufferModelViewInverse) * gl_NormalMatrix * gl_Normal);
		vec3 T = normalize(mat3(gbufferModelViewInverse) * gl_NormalMatrix * at_tangent.xyz);
		vec3 B = cross(T, N) * sign(at_tangent.w);
		v_tbn = mat3(T, B, N);
	#endif
	

	#ifdef PROGRAM_BLOCK
		v_portalCoord = gl_Position * 0.5;
		v_portalCoord.xy = vec2(v_portalCoord.x + v_portalCoord.w, v_portalCoord.y + v_portalCoord.w);
		v_portalCoord.zw = gl_Position.zw;
	#endif


	#if defined ENTITIES_PARALLAX && PARALLAX_MODE > 0
		vec2 midTexCoord = mat2(gl_TextureMatrix[0]) * mc_midTexCoord + gl_TextureMatrix[0][3].xy;
		vec2 quadCoord = v_texCoord - midTexCoord;
		v_quadCoordMapping = vec4(abs(quadCoord) * 2.0, midTexCoord - abs(quadCoord));
		//v_quadCoordX = fsign(quadCoord.x) * 0.5 + 0.5;
	#endif


	
	#if defined VS_VELOCITY && defined SR_IRIS_EXT_VELOCITY
		v_velocity = at_velocity;
	#endif
	
	
	v_materialIDs = MATID_LAND;

	#ifdef PROGRAM_ENTITIES
		if (entityId > 10000 && entityId <= 10100){
			v_emissiveness = float(entityId) * 0.01 - 100.0;

		}else if(entityId == 11001){
			v_materialIDs = MATID_LIGHTNING;

		}else if(entityId == 11002){
			v_materialIDs = MATID_ENTITIES_NODISCARD;
			
		}else if(entityId == 11003){
			v_materialIDs = MATID_ENTITIES_PLAYER;
		
		}else if(entityId == 12000){
			v_materialIDs = 256.0;
		
		}
		#if defined VS_VELOCITY && defined SR_IRIS_EXT_VELOCITY
			else if(entityId == 12001){
				v_materialIDs = MATID_NO_VELOCITY;
			}
		#endif
	#endif

	#ifdef PROGRAM_SPIDEREYES
		v_emissiveness = 0.2;
	#endif

	#ifdef PROGRAM_BLOCK
		if (blockEntityId == 9000){
			v_materialIDs = MATID_END_PORTAL;
			v_emissiveness = 0.5;

		}
		#if defined VS_VELOCITY && defined SR_IRIS_EXT_VELOCITY
			else if(blockEntityId == 9001){
				v_materialIDs = MATID_NO_VELOCITY;
			}
		#endif

	#endif

	#ifdef PROGRAM_HAND
		v_materialIDs = MATID_HAND;

		if (currentRenderedItemId > 10000 && currentRenderedItemId <= 10100){
			v_emissiveness = float(currentRenderedItemId) * 0.01 - 100.0;

		}

		#ifdef TACZ_ADAPTIVE_EMISSIVE
			if(gl_MultiTexCoord1.x == 240 && heldBlockLightValue + heldBlockLightValue <= 0) v_emissiveness = 1.0;
		#endif
	#elif defined VS_VELOCITY && defined SR_IRIS_EXT_VELOCITY
		if (!rtwDiscardRefresh && abs(v_velocity) == vec3(0.0)){
			v_materialIDs = MATID_NO_VELOCITY;
		}
	#endif
/*
	#ifdef HAS_COLORWHEEL
		if (texelFetch(FBTEX_SST_TEMPORAL, ivec2(0), 0).w == -1.0){
			gl_Position = gl_ProjectionMatrix * gl_ModelViewMatrix * gl_Vertex;
			gl_Position.z -= 1e-3;

			#ifdef CUSTOM_RENDER_RESOLUTION
				RedoProject(gl_Position);	
			#endif
			#if defined SUPER_RESOLUTION || defined CUSTOM_RENDER_RESOLUTION
				FsrScaleVS(gl_Position, vec2(0.0));
			#endif

			v_materialIDs = MATID_OVERLAY;
		}
	#endif
*/
}
