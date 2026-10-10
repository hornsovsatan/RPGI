//Skybasic_VS


#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


uniform int renderStage;


out vec4 v_color;


#if defined SUPER_RESOLUTION || defined CUSTOM_RENDER_RESOLUTION
	#include "/Lib/FidelityFX/FSR2/GbufferScale.glsl"
#endif


void main(){
	#if STAR_TYPE < 2
		gl_Position = vec4(0.0, 0.0, -2.0, 1.0);
	#else
		if (renderStage == MC_RENDER_STAGE_STARS){
			gl_Position = gl_ProjectionMatrix * gl_ModelViewMatrix * gl_Vertex;
			vec4 worldPos = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;

			const float rotYAngle = SUNRISE_ROTATION * 0.01745329252;
			const mat3 rotY = mat3(
				cos(rotYAngle), 0.0, -sin(rotYAngle),
				0.0,            1.0,  0.0,
				sin(rotYAngle), 0.0,  cos(rotYAngle)
			);
			worldPos.xyz = worldPos.xyz * rotY;
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
		}else{
			gl_Position = vec4(0.0, 0.0, -2.0, 1.0);
		}
	#endif

	v_color = gl_Color;
}