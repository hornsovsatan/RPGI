//Hand_Water_VS


#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


in vec4 mc_Entity;

out vec3 v_color;
out vec2 v_texCoord;
out vec3 v_worldPos;
out float v_blockLight;


#if defined SUPER_RESOLUTION || defined CUSTOM_RENDER_RESOLUTION
	#include "/Lib/FidelityFX/FSR2/GbufferScale.glsl"
#endif


void main(){
	vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;
	v_worldPos = vec3(gbufferModelViewInverse * viewPos);
	gl_Position = gl_ProjectionMatrix * viewPos;

	#if defined SUPER_RESOLUTION || defined CUSTOM_RENDER_RESOLUTION
		#ifdef CUSTOM_RENDER_RESOLUTION
			gl_Position = gbufferProjectionInverse * gl_Position;
			mat4 projectMat = gbufferProjection;
			projectMat[0][0] *= viewWidth / viewHeight / fsrScreenSize.x * fsrScreenSize.y;
			gl_Position = projectMat * gl_Position;
		#endif
		FsrScaleVS(gl_Position, taaJitter);
	#else
		#ifdef TAA
			gl_Position.xy = taaJitter * gl_Position.w + gl_Position.xy;
		#endif
	#endif

	v_color = gl_Color.rgb;
	v_texCoord = mat2(gl_TextureMatrix[0]) * gl_MultiTexCoord0.xy + gl_TextureMatrix[0][3].xy;

	v_blockLight = saturate(float(gl_MultiTexCoord1.y - 8) / 232.0);
}