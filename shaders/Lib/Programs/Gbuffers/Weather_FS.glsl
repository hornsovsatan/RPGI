//Weather_FS


#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


uniform sampler2D tex;


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 framebuffer_albedo;


in vec2 v_texCoord;


#if defined SUPER_RESOLUTION || defined CUSTOM_RENDER_RESOLUTION
	#include "/Lib/FidelityFX/FSR2/GbufferScale.glsl"
#endif


void main(){
	#if defined SUPER_RESOLUTION || defined CUSTOM_RENDER_RESOLUTION
		if (FsrDiscardFS(gl_FragCoord.xy)) discard;
	#endif

	vec4 albedo = texture(tex, v_texCoord);

	if(albedo.a < 0.1) discard;

	framebuffer_albedo = vec4(0.0, 0.0, 0.0, albedo.a);
}
