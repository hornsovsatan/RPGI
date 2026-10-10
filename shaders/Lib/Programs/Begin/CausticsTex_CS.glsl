

#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


const ivec3 workGroups = ivec3(32, 64, 1);
layout (local_size_x = 16, local_size_y = 8) in;

layout (rg16f) writeonly uniform image2D img_pixelData2D;
layout (rgba16f) writeonly uniform image2D FBIMG_ALT_OUTPUT;


#ifdef DIMENSION_OVERWORLD
	#include "/Lib/BasicFunctions/PrecomputedAtmosphere.glsl"
#endif

#define CAUSZTICS_NORMAL
#include "/Lib/IndividualFunctions/WaterWaves.glsl"


void main(){
	#ifdef DIMENSION_OVERWORLD
		if (gl_GlobalInvocationID.xy == uvec2(0u)){
			#ifdef ATMO_HORIZON
				vec3 camera = vec3(0.0, max(cameraPosition.y, ATMO_MIN_ALTITUDE) * 0.001 + atmosphereModel_bottom_radius, 0.0);
			#else
				vec3 camera = vec3(0.0, max(cameraPosition.y, 63.0) * 0.001 + atmosphereModel_bottom_radius, 0.0);
			#endif

			vec3 worldShadowVector = shadowModelViewInverse2;
			vec3 worldSunVector = worldShadowVector * (step(sunAngle, 0.5) * 2.0 - 1.0);
			vec3 colorSunSkylight;
			vec3 colorMoonSkylight;
			vec3 colorMoonlight;
			vec3 colorSunlight = GetSunAndSkyIrradiance(camera, worldSunVector, -worldSunVector, colorMoonlight, colorSunSkylight, colorMoonSkylight);

			colorSunlight *= 1.0 - curve(saturate((1.0 - saturate(worldSunVector.y)) * 30.0 - 29.0));
			colorMoonlight *= 1.0 - curve(saturate((1.0 - saturate(-worldSunVector.y)) * 5.0 - 4.0));
			#ifdef COLD_MOONLIGHT
				DoNightEye(colorMoonlight);
			#endif

			vec3 colorShadowlight = colorSunlight + colorMoonlight;
			vec3 colorSkylight = colorSunSkylight + colorMoonSkylight;
		
			imageStore(FBIMG_ALT_OUTPUT, ivec2(0, 0), vec4(colorShadowlight, 0.0));
			imageStore(FBIMG_ALT_OUTPUT, ivec2(1, 0), vec4(colorSkylight, 0.0));
		}
	#endif

	vec2 causticsCoord = vec2(gl_GlobalInvocationID.xy) * (50.0 / 512.0);
	
	vec3 waveNormal = WaveNormal(vec3(causticsCoord.x, 0.0, causticsCoord.y), 18.0);

	imageStore(img_pixelData2D, ivec2(gl_GlobalInvocationID.x, gl_GlobalInvocationID.y + 1), vec4(waveNormal.xy / waveNormal.z, 0.0, 0.0));
}
