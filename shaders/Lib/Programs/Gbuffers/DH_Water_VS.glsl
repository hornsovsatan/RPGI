//DH_Terrain_VS


#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


out vec4 v_color;
out vec3 v_worldPos;
out mat3 v_tbn;
out float v_blockLight;
flat out float v_materialIDs;


#if defined SUPER_RESOLUTION || defined CUSTOM_RENDER_RESOLUTION
	#include "/Lib/FidelityFX/FSR2/GbufferScale.glsl"
#endif

#ifndef CUSTOM_RENDER_RESOLUTION
	uniform mat4 dhProjection;
#endif


void main(){
	vec4 worldPos = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
	v_worldPos = worldPos.xyz;
	gl_Position = dhProjection * gl_ModelViewMatrix * gl_Vertex;

	#if defined SUPER_RESOLUTION || defined CUSTOM_RENDER_RESOLUTION
		#ifdef CUSTOM_RENDER_RESOLUTION
			RedoProjectDH(gl_Position);
		#endif
		FsrScaleVS(gl_Position, taaJitter);
	#else
		#ifdef TAA
			gl_Position.xy = taaJitter * gl_Position.w + gl_Position.xy;
		#endif
	#endif

	v_color = gl_Color;
	vec2 lmcoord = vec2(gl_TextureMatrix[1][0][0] * gl_MultiTexCoord1.x, gl_TextureMatrix[1][1][1] * gl_MultiTexCoord1.y) + gl_TextureMatrix[1][3].xy;
	v_blockLight = saturate(lmcoord.y * 1.103449 - 0.0689656);

	mat3 normalMat = mat3(gbufferModelViewInverse) * gl_NormalMatrix;

	vec3 N = normalize(normalMat * gl_Normal);
	vec3 T = vec3(abs(N.y) + N.z, 0.0, -N.x);
	vec3 B = vec3(0.0, abs(N.y) - 1.0, N.y);

	v_tbn = mat3(T, B, N);

	v_materialIDs = MATID_STAINEDGLASS;
	if (dhMaterialId == DH_BLOCK_WATER) v_materialIDs = MATID_WATER;
}