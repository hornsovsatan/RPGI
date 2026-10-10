//Terrain_VS


#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


uniform int renderStage;


in vec4 mc_Entity;
#ifdef VANILLA_EMISSIVE
	in vec4 at_midBlock;
#endif

out vec3 g_color;
out vec2 g_texCoord;
out vec3 g_worldPos;
out vec2 g_blockLight;
flat out float g_materialIDs;
flat out float g_emissiveness;


in vec2 mc_midTexCoord;

#ifdef TERRAIN_VS_TBN
	in vec4 at_tangent;
	out mat3 g_tbn;
#endif

#if PARALLAX_MODE > 0
	out float g_quadCoordX;
	out vec4 g_quadCoordMapping;
#endif

#if defined SUPER_RESOLUTION || defined CUSTOM_RENDER_RESOLUTION
	#include "/Lib/FidelityFX/FSR2/GbufferScale.glsl"
#endif

#ifdef WAVING_PLANTS
	#include "/Lib/IndividualFunctions/WavingPlants.glsl"
#endif


void main(){
	vec4 worldPos = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
	
	g_color = gl_Color.rgb;
	g_texCoord =  mat2(gl_TextureMatrix[0]) * gl_MultiTexCoord0.xy + gl_TextureMatrix[0][3].xy;
	g_blockLight = saturate(vec2(gl_MultiTexCoord1.xy - 8) / 232.0);
	if(mc_Entity.x == 213.0) g_blockLight.x = min(g_blockLight.x, 0.85);

	#ifdef WAVING_PLANTS
		WavingPlants(worldPos, g_blockLight.y);
	#endif

	g_worldPos = worldPos.xyz;
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

	#if PARALLAX_MODE > 0
		vec2 midTexCoord = mat2(gl_TextureMatrix[0]) * mc_midTexCoord + gl_TextureMatrix[0][3].xy;
		vec2 quadCoord = g_texCoord - midTexCoord;
		g_quadCoordMapping = vec4(abs(quadCoord) * 2.0, midTexCoord - abs(quadCoord));
		g_quadCoordX = fsign(quadCoord.x) * 0.5 + 0.5;
	#endif

	#ifdef TERRAIN_VS_TBN
		vec3 N = normalize(mat3(gbufferModelViewInverse) * gl_NormalMatrix * gl_Normal);
		vec3 T = normalize(mat3(gbufferModelViewInverse) * gl_NormalMatrix * at_tangent.xyz);
		vec3 B = cross(T, N) * sign(at_tangent.w);
		g_tbn = mat3(T, B, N);
	#endif

	g_materialIDs = MATID_LAND;
	#ifdef VANILLA_EMISSIVE
		g_emissiveness = saturate(at_midBlock.w / 15.0);
		g_emissiveness = g_emissiveness * g_emissiveness;
	#else
		g_emissiveness = 0.0;
	#endif

	#ifdef MOD_BLOCK_SUPPORT
	#endif

	#ifdef GENERAL_GRASS_FIX
		vec3 an = abs(gl_Normal);
		if (all(lessThan(an, vec3(0.99)))){
			g_materialIDs = MATID_GRASS;
		}
	#endif

	if (mc_Entity.x > 1.5){
		if (mc_Entity.x < 515.5){
			if (mc_Entity.x == 2.0){
				g_emissiveness = 1.0;

			}else if (mc_Entity.x == 4.0){
				g_materialIDs = MATID_LEAVES;

			}else if (abs(mc_Entity.x - 244.0) < 3.5){ // 241 - 247
				g_materialIDs = MATID_FIRE + mc_Entity.x - 241.0;
				g_emissiveness = 1.0;

			}else if (abs(mc_Entity.x - 250.5) < 2.0){ // candle 249 - 252
				g_materialIDs = MATID_TORCH;
				g_emissiveness = mc_Entity.x * 0.1 - 24.6;

			}else if (abs(mc_Entity.x - 189.5) < 32){ // 158 - 221
				g_emissiveness = 0.5;

			}else if (abs(mc_Entity.x - 223.0) < 1.5){ // 222 - 224
				g_materialIDs = MATID_ENDROD;
				g_emissiveness = 1.0;

			}
		}else{
			if (mc_Entity.x < 4095.5){
				g_emissiveness = floor(mc_Entity.x / 512.0) * 0.125;

			}else if (mc_Entity.x < 7200.5){
				g_materialIDs = MATID_GRASS;

			}else if (mc_Entity.x == 8242.0){
				g_materialIDs = MATID_TORCH;
				g_emissiveness = -1.0;
				
			}else if (abs(mc_Entity.x - 8549.5) < 51.0){
				g_emissiveness = saturate(mc_Entity.x * 0.01 - 85.0);

			}else if (mc_Entity.x == 9002.0){
				float power = saturate(g_color.r * 1.1 - 0.1) * float(g_color.r > 0.3 && g_color.b == 0.0);
				g_emissiveness = power * power * 0.15;
				
			}
		}
	}
}
