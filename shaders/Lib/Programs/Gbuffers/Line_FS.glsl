//Line_FS


#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


/* RENDERTARGETS: 0,1 */
layout(location = 0) out vec4 framebuffer_albedo;
layout(location = 1) out vec4 framebuffer_gsoildData;


flat in vec4 v_color;


#if defined SUPER_RESOLUTION || defined CUSTOM_RENDER_RESOLUTION
	#include "/Lib/FidelityFX/FSR2/GbufferScale.glsl"
#endif


void main(){
	#if defined SUPER_RESOLUTION || defined CUSTOM_RENDER_RESOLUTION
		if (FsrDiscardFS(gl_FragCoord.xy)) discard;
	#endif

	vec4 albedo = v_color;

	if (albedo.a < 0.1) discard;

	if (albedo.a == 0.4)
		albedo.rgb = vec3(SELECTION_BOX_COLOR_R, SELECTION_BOX_COLOR_G, SELECTION_BOX_COLOR_B);

	framebuffer_albedo = vec4(albedo.rgb, 1.0);
	framebuffer_gsoildData = vec4(0.0, 0.0, Pack2xU8_to_U16(vec2(1.0, MATID_SELECTION / 255.0)), 0.0);
}
