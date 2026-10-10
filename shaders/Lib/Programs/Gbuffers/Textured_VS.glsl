//Textured_VS


#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


out vec4 v_color;
out vec2 v_texCoord;
out vec2 v_blockLight;


#if defined SUPER_RESOLUTION || defined CUSTOM_RENDER_RESOLUTION
	#include "/Lib/FidelityFX/FSR2/GbufferScale.glsl"
#endif


void main(){
	gl_Position = gl_ModelViewMatrix * gl_Vertex;
	gl_Position.z += 1e-5;
	gl_Position = gl_ProjectionMatrix * gl_Position;

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

	v_color = gl_Color;
	v_texCoord =  mat2(gl_TextureMatrix[0]) * gl_MultiTexCoord0.xy + gl_TextureMatrix[0][3].xy;
	v_blockLight = saturate(vec2(gl_MultiTexCoord1.xy - 8) / 232.0);
	//v_blockLight.x = step(1.0, v_blockLight.x);
}

