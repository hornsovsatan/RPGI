//Weather_VS


#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


out vec2 v_texCoord;


#if defined SUPER_RESOLUTION || defined CUSTOM_RENDER_RESOLUTION
	#include "/Lib/FidelityFX/FSR2/GbufferScale.glsl"
#endif


void main(){
	vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;;
	vec4 worldPos = gbufferModelViewInverse * viewPos;

	#ifdef RENDERING_MODE
		float angle = dot(worldPos.xyz + cameraPosition.xyz, vec3(3.0, 0.5, 3.0));
	#else
		float angle = dot(worldPos.xyz + cameraPosition.xyz, vec3(3.0, 0.5, 3.0)) + frameTimeCounter * 0.2;
	#endif
	vec2 rot = vec2(sin(angle), cos(angle));
	vec2 offset = (vec2(RAIN_WIND_X, RAIN_WIND_Z) + rot * RAIN_DISTURBANCE) * worldPos.y;

	worldPos.xz += eyeBrightnessOneSmooth * offset;

	gl_Position = gl_ProjectionMatrix * gbufferModelView * worldPos;

	#if defined SUPER_RESOLUTION || defined CUSTOM_RENDER_RESOLUTION
		#ifdef CUSTOM_RENDER_RESOLUTION
			RedoProject(gl_Position);
		#endif
		FsrScaleVS(gl_Position, vec2(0.0));
	#else

	#endif

	v_texCoord =  mat2(gl_TextureMatrix[0]) * gl_MultiTexCoord0.xy + gl_TextureMatrix[0][3].xy;
}
