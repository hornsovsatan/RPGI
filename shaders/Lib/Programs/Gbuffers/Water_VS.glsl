//Water_VS


#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


in vec4 mc_Entity;

out vec3 v_color;
out vec2 v_texCoord;
out vec3 v_worldPos;
out vec2 v_blockLight;
flat out float v_materialIDs;

#if defined TERRAIN_VS_TBN && !defined PROGRAM_COLORWHEEL
	in vec4 at_tangent;
	out mat3 v_tbn;
#endif


#if defined SUPER_RESOLUTION || defined CUSTOM_RENDER_RESOLUTION
	#include "/Lib/FidelityFX/FSR2/GbufferScale.glsl"
#endif


void main(){
	vec4 worldPos = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
	v_worldPos = worldPos.xyz;
	gl_Position = gl_ProjectionMatrix * gbufferModelView * worldPos;

	#if defined SUPER_RESOLUTION || defined CUSTOM_RENDER_RESOLUTION
		#ifdef CUSTOM_RENDER_RESOLUTION
			RedoProject(gl_Position);
		#endif
		FsrScaleVS(gl_Position, taaJitter);
	#else
		#ifdef TAA
			gl_Position.xy = taaJitter * gl_Position.w + gl_Position.xy;
		#endif
	#endif

	v_color = gl_Color.rgb;
	v_texCoord = mat2(gl_TextureMatrix[0]) * gl_MultiTexCoord0.xy + gl_TextureMatrix[0][3].xy;

	#if defined TERRAIN_VS_TBN && !defined PROGRAM_COLORWHEEL
		vec3 N = normalize(mat3(gbufferModelViewInverse) * gl_NormalMatrix * gl_Normal);
		vec3 T = normalize(mat3(gbufferModelViewInverse) * gl_NormalMatrix * at_tangent.xyz);
		vec3 B = cross(T, N) * sign(at_tangent.w);
		v_tbn = mat3(T, B, N);
	#endif

	v_blockLight = saturate(vec2(gl_MultiTexCoord1.xy - 8) / 232.0);

	if (mc_Entity.x == 6000.0){
		v_materialIDs = MATID_WATER;
	}else if(abs(mc_Entity.x - 8016.5) < 8.0){
		v_materialIDs = MATID_STAINEDGLASS_EMISSIVE;
	}else{
		v_materialIDs = MATID_STAINEDGLASS;
	}
}
