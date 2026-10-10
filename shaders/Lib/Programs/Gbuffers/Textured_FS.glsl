//Textured_FS


#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


uniform sampler2D tex;


/* RENDERTARGETS: 3 */
//layout(location = 0) out vec4 framebuffer_albedo;
layout(location = 0) out vec4 framebuffer_gtransData;

layout (r32ui) uniform uimage2D img_depthtexS;


in vec4 v_color;
in vec2 v_texCoord;
in vec2 v_blockLight;


#if defined SUPER_RESOLUTION || defined CUSTOM_RENDER_RESOLUTION
	#include "/Lib/FidelityFX/FSR2/GbufferScale.glsl"
#endif


void main(){
	#if defined SUPER_RESOLUTION || defined CUSTOM_RENDER_RESOLUTION
		if (FsrDiscardFS(gl_FragCoord.xy)) discard;
	#endif

//albedo
    vec4 albedo = texture(tex, v_texCoord);
    albedo *= v_color;

	if(albedo.a < 0.004) discard;

	#if WHITE_DEBUG_WORLD > 0
        albedo.rgb = vec3(1.0);
    #endif

//material ID
	//float materialIDs = MATID_PARTICLE + float(v_blockLight.x > 0.999999);

	//framebuffer_albedo = vec4(albedo.rgb, 1.0);
	imageAtomicMin(img_depthtexS, ivec2(gl_FragCoord.xy), floatBitsToUint(gl_FragCoord.z));

    framebuffer_gtransData = vec4(Pack2xU8_to_U16(albedo.rg), Pack2xU8_to_U16(albedo.ba), Pack2xU8_to_U16(vec2(1.0, MATID_PARTICLE / 255.0)), Pack2xU8_to_U16(v_blockLight + 1e-6));
}
