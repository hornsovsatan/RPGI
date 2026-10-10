

#define PROGRAM_UPDATE_SSBO

#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


const ivec3 workGroups = ivec3(4, 1, 1);
layout (local_size_x = 1) in;


#include "/Lib/BasicFunctions/PrecomputedAtmosphere.glsl"


vec2 CubemapProjection(vec3 dir){
	const float tileSize = SKYBOX_RESOLUTION;
	float tileSizeDivide = 0.5 * tileSize - 1.5;
	vec3 adir = abs(dir);

	vec2 texel;
	if (adir.x > adir.y && adir.x > adir.z){
		dir /= adir.x;
		texel.x = dir.y * tileSizeDivide + tileSize * 0.5;
		texel.y = dir.z * tileSizeDivide + tileSize * (step(0.0, dir.x) + 0.5);
	}else if (adir.y > adir.x && adir.y > adir.z){
		dir /= adir.y;
		texel.x = dir.x * tileSizeDivide + tileSize * 1.5;
		texel.y = dir.z * tileSizeDivide + tileSize * (step(0.0, dir.y) + 0.5);
	}else{
		dir /= adir.z;
		texel.x = dir.x * tileSizeDivide + tileSize * 2.5;
		texel.y = dir.y * tileSizeDivide + tileSize * (step(0.0, dir.z) + 0.5);
	}

	return texel * vec2(1.0 / (SKYBOX_RESOLUTION * 3.0), 1.0 / (SKYBOX_RESOLUTION * 2.0));
}


void main(){
	if (gl_WorkGroupID.x == 0u){
		ssb_cameraProjPrev0 = ssb_cameraProj0;
		ssb_cameraProjPrev1 = ssb_cameraProj1;
		ssb_cameraProj0 = gbufferProjection0;
		ssb_cameraProj1 = gbufferProjection1;
		ssb_cameraProjInv0 = gbufferProjectionInverse0;
		ssb_cameraProjInv1 = gbufferProjectionInverse1;

		#ifdef DIMENSION_OVERWORLD
			ssb_shadowRot0 = shadowModelView0;
			ssb_shadowRot1 = shadowModelView1;
			ssb_shadowRot2 = shadowModelView2;
		#endif

		#ifdef SUPER_RESOLUTION
			ssb_screenSize = fsrScreenSize;
			ssb_pixelSize = fsrPixelSize;
			ssb_taaJitter = fsrJitter;
		#else
			ssb_screenSize = screenSize;
			ssb_pixelSize = pixelSize;
			ssb_taaJitter = taaJitter;
		#endif

	}else if (gl_WorkGroupID.x == 1u){
		#ifndef DIMENSION_NETHER
			#ifdef DIMENSION_OVERWORLD
				vec3 shadowDir = shadowModelViewInverse2;
				vec3 sunDir = shadowDir;
			#else
				vec3 shadowDir = shadowModelViewInverseEnd[2];
				vec3 sunDir = shadowDir * fsign(0.5 - sunAngle);
			#endif
			ssb_shadowDir = shadowDir;
			ssb_sunDir = sunDir;
		#endif

		#ifdef DIMENSION_OVERWORLD
			#ifdef VS_CLOUD_LIGHTING
				vec3 atmoCamera = vec3(0.0, 500.0 * 0.001 + atmosphereModel_bottom_radius, 0.0);
			#else
				#ifdef ATMO_HORIZON
					vec3 atmoCamera = vec3(0.0, max(cameraPosition.y, ATMO_MIN_ALTITUDE) * 0.001 + atmosphereModel_bottom_radius, 0.0);
				#else
					vec3 atmoCamera = vec3(0.0, max(cameraPosition.y, 63.0) * 0.001 + atmosphereModel_bottom_radius, 0.0);
				#endif
			#endif
			ssb_atmoCamera = atmoCamera;

			vec3 colorMoonlight;
			vec3 colorSunSkylight;
			vec3 colorMoonSkylight;
			vec3 colorSunlight = GetSunAndSkyIrradiance(atmoCamera, sunDir, -sunDir, colorMoonlight, colorSunSkylight, colorMoonSkylight);

			float sunlightStrength = curve(saturate(sunDir.y * 30.0));
			float moonlightStrength = curve(saturate(sunDir.y * -5.0));
			float timeNoon = pow(1.0 - (clamp(sunDir.y, 0.2, 0.99) - 0.2) / 0.8, 6.0);
			ssb_fogTimeFactor = vec2(timeNoon, moonlightStrength);

			#ifdef COLD_MOONLIGHT
				DoNightEye(colorMoonlight);
			#endif

			ssb_sunIrradiance = colorSunlight;
			ssb_moonIrradiance = colorMoonlight;
			ssb_celestialIrradiance = colorSunlight + colorMoonlight;
			ssb_atmoIrradiance = colorSunSkylight + colorMoonSkylight;


			vec2 skyImageCoord = CubemapProjection(shadowDir);
			
			float cloudVisibility = saturate(textureLod(skyBox2D, skyImageCoord, 0.0).a * 1.5 - 0.5);
			cloudVisibility = mix(cloudVisibility, 1.0, curve(saturate((1.0 - saturate(sunDir.y)) * 12.0 - 11.0)) * saturate(1.0 - wetness * 1.5));
			cloudVisibility = mix(1.0, cloudVisibility, saturate(RAIN_SHADOW / 0.98));

			ssb_highlightVisibility = cloudVisibility * (timeNoon * 3.0 + 0.2);
		#endif
		
 	}else if (gl_WorkGroupID.x == 2u){
		#ifdef DIMENSION_OVERWORLD
			vec3 shadowDir = shadowModelViewInverseEnd[2];
			vec3 sunDir = shadowDir * fsign(0.5 - sunAngle);

			vec3 atmoCamera = vec3(0.0, mix(CLOUD_CLEAR_ALTITUDE, CLOUD_RAIN_ALTITUDE, wetness) * 0.001 + atmosphereModel_bottom_radius, 0.0);

			vec3 colorMoonlight;
			vec3 colorSunSkylight;
			vec3 colorMoonSkylight;
			vec3 colorSunlight = GetSunAndSkyIrradiance(atmoCamera, sunDir, -sunDir, colorMoonlight, colorSunSkylight, colorMoonSkylight);

			float sunlightStrength = curve(saturate(sunDir.y * 30.0));
			float moonlightStrength = curve(saturate(sunDir.y * -5.0));

			#ifdef COLD_MOONLIGHT
				DoNightEye(colorMoonlight);
			#endif

			ssb_cloudSunIrradiance = colorSunlight;
			ssb_cloudMoonIrradiance = colorMoonlight;
			ssb_cloudCelestialIrradiance = colorSunlight + colorMoonlight;
			ssb_cloudAtmoIrradiance = colorSunSkylight + colorMoonSkylight;
		#endif

	}else{

	}
	
}
