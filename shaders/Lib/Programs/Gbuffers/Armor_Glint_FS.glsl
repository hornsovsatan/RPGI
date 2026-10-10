//Armor_Glint_FS


#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


uniform sampler2D tex;


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 framebuffer_albedo;


in vec4 v_color;
in vec2 v_texCoord;


#if defined SUPER_RESOLUTION || defined CUSTOM_RENDER_RESOLUTION
	#include "/Lib/FidelityFX/FSR2/GbufferScale.glsl"
#endif


void main(){
	#if defined SUPER_RESOLUTION || defined CUSTOM_RENDER_RESOLUTION
		if (FsrDiscardFS(gl_FragCoord.xy)) discard;
	#endif

	vec4 albedo = texture(tex, v_texCoord);
	albedo *= v_color;

	#if WHITE_DEBUG_WORLD > 0
		albedo.rgb = vec3(WHITE_DEBUG_WORLD * 0.1);
	#endif

	framebuffer_albedo = albedo;
}
