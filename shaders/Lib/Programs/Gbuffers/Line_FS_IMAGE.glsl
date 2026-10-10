//Line_FS


#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 framebuffer_albedo;

layout(rgba8) uniform image2D colorimg0;
layout(rgba16) uniform image2D FBIMG_GSOLID_DATA;


flat in vec4 v_color;


#if defined SUPER_RESOLUTION || defined CUSTOM_RENDER_RESOLUTION
	#include "/Lib/FidelityFX/FSR2/GbufferScale.glsl"
#endif


void main(){
	#if defined SUPER_RESOLUTION || defined CUSTOM_RENDER_RESOLUTION
		if (FsrDiscardFS(gl_FragCoord.xy)) discard;
	#endif

	vec4 albedo = v_color;

	if(albedo.a > 0.1 && gl_FragCoord.z < texelFetch(depthtex0, ivec2(gl_FragCoord.xy), 0).x){
		if (albedo.a == 0.4)
			albedo.rgb = vec3(SELECTION_BOX_COLOR_R, SELECTION_BOX_COLOR_G, SELECTION_BOX_COLOR_B);

		imageStore(colorimg0, ivec2(gl_FragCoord.xy), vec4(albedo.rgb, 1.0));
		imageStore(FBIMG_GSOLID_DATA, ivec2(gl_FragCoord.xy), vec4(0.0, 0.0, MATID_SELECTION / 255.0, 0.0));
	}

	discard;

	framebuffer_albedo = vec4(0.0);
}
