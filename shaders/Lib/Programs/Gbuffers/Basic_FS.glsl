//Basic_FS


#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


/* RENDERTARGETS: 0,1,2 */
layout(location = 0) out vec4 framebuffer_albedo;
layout(location = 1) out vec4 framebuffer_gsoildData;
layout(location = 2) out vec4 framebuffer_gsoildNormal;


flat in vec4 v_color;
in vec2 v_texCoord;
in vec3 v_normal;
in vec2 v_blockLight;
flat in float v_isLine;


#if defined SUPER_RESOLUTION || defined CUSTOM_RENDER_RESOLUTION
	#include "/Lib/FidelityFX/FSR2/GbufferScale.glsl"
#endif


void main(){
	#if defined SUPER_RESOLUTION || defined CUSTOM_RENDER_RESOLUTION
		if (FsrDiscardFS(gl_FragCoord.xy)) discard;
	#endif

	vec4 albedo = v_color;

	vec2 mcLightmap = saturate(v_blockLight + 1e-6);

	float materialIDs = MATID_LAND;

	#if MC_VERSION >= 11605
		if (albedo.a < 0.1) discard;
	#else
		if (albedo.a <= 0.004) discard;
	#endif

	if (albedo.a == 0.4){
		albedo.rgb = vec3(SELECTION_BOX_COLOR_R, SELECTION_BOX_COLOR_G, SELECTION_BOX_COLOR_B);
		materialIDs = MATID_SELECTION;
		mcLightmap = vec2(0.0);
	}

	if (v_isLine > 0.5){
		materialIDs = MATID_SELECTION;
		mcLightmap = vec2(0.0);
	}

	vec2 normalEnc = EncodeNormal(v_normal);

	framebuffer_albedo = vec4(albedo.rgb, 1.0);
	framebuffer_gsoildData = vec4(0.0, 0.0, Pack2xU8_to_U16(vec2(1.0, materialIDs / 255.0)), Pack2xU8_to_U16(mcLightmap));
	framebuffer_gsoildNormal = vec4(normalEnc, normalEnc);
}
