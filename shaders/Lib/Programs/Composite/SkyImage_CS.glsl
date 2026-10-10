

#define PROGRAM_SKYIMAGE
#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


#if SKYBOX_RESOLUTION == 32
	const ivec3 workGroups = ivec3(6, 8, 1);
#elif SKYBOX_RESOLUTION == 48
	const ivec3 workGroups = ivec3(9, 12, 1);
#elif SKYBOX_RESOLUTION == 64
	const ivec3 workGroups = ivec3(12, 16, 1);
#elif SKYBOX_RESOLUTION == 96
	const ivec3 workGroups = ivec3(18, 24, 1);
#elif SKYBOX_RESOLUTION == 128
	const ivec3 workGroups = ivec3(24, 32, 1);
#elif SKYBOX_RESOLUTION == 192
	const ivec3 workGroups = ivec3(36, 48, 1);
#elif SKYBOX_RESOLUTION == 256
	const ivec3 workGroups = ivec3(48, 64, 1);
#endif


layout (local_size_x = 16, local_size_y = 8) in;

layout (rgba16f) uniform image2D img_skyBox2D;


vec3 CubemapProjectionInverse(vec2 texel){
	const float tileSize = SKYBOX_RESOLUTION;
	float tileSizeDivide = 1.0 / (0.5 * tileSize - 1.5);

	vec3 dir = vec3(0.0);

	if (texel.x < tileSize) {
		dir.x = step(tileSize, texel.y) * 2.0 - 1.0;
		dir.y = (texel.x - tileSize * 0.5) * tileSizeDivide;
		dir.z = (texel.y - tileSize * (step(tileSize, texel.y) + 0.5)) * tileSizeDivide;
	} else if (texel.x < 2.0 * tileSize) {
		dir.x = (texel.x - tileSize * 1.5) * tileSizeDivide;
		dir.y = step(tileSize, texel.y) * 2.0 - 1.0;
		dir.z = (texel.y - tileSize * (step(tileSize, texel.y) + 0.5)) * tileSizeDivide;
	} else {
		dir.x = (texel.x - tileSize * 2.5) * tileSizeDivide;
		dir.y = (texel.y - tileSize * (step(tileSize, texel.y) + 0.5)) * tileSizeDivide;
		dir.z = step(tileSize, texel.y) * 2.0 - 1.0;
	}

	return normalize(dir);
}


#ifdef DIMENSION_OVERWORLD

	vec3 worldShadowVector = shadowModelViewInverse2;
	vec3 worldSunVector = worldShadowVector * (step(sunAngle, 0.5) * 2.0 - 1.0);


	vec2 BlueNoiseTemporal(vec2 fragCoord){
		return fract(texelFetch(noisetex, ivec2(fragCoord) & 127, 0).xy + vec2(goldenRatio, plasticRatio) * vec2(frameCounter & 63));
	}

	#include "/Lib/BasicFunctions/PrecomputedAtmosphere.glsl"

	#include "/Lib/IndividualFunctions/NUBIS.glsl"
	#include "/Lib/IndividualFunctions/PlanarClouds.glsl"


	////////////////////////////// Main //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	////////////////////////////// Main //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	////////////////////////////// Main //////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	void main(){
		vec2 fragCoord = vec2(gl_GlobalInvocationID.xy) + 0.5;

		vec3 cameraSkyBox = vec3(0.0, max(cameraPosition.y, ATMO_SKYBOX_MIN_ALTITUDE) * 0.001 + atmosphereModel_bottom_radius, 0.0);
		vec3 worldDir = CubemapProjectionInverse(fragCoord);

		#ifdef ATMO_HORIZON
			vec3 camera = vec3(0.0, max(cameraPosition.y, ATMO_MIN_ALTITUDE) * 0.001 + atmosphereModel_bottom_radius, 0.0);
		#else
			vec3 camera = vec3(0.0, max(cameraPosition.y, 63.0) * 0.001 + atmosphereModel_bottom_radius, 0.0);
		#endif

		vec3 colorShadowlight = texelFetch(FBTEX_ALT_OUTPUT, ivec2(0), 0).rgb;
		vec3 colorSkylight = texelFetch(FBTEX_ALT_OUTPUT, ivec2(1, 0), 0).rgb;

		vec2 noise_0 = BlueNoiseTemporal(fragCoord).xy;

		vec2 cloudAltitude = vec2(mix(CLOUD_CLEAR_ALTITUDE, CLOUD_RAIN_ALTITUDE, wetness));
		cloudAltitude.y += mix(CLOUD_CLEAR_THICKNESS, CLOUD_RAIN_THICKNESS, wetness);

		float wind = 0.0005 * (frameTimeCounter * CLOUD_SPEED + 10.0 * FTC_OFFSET);
		vec3 windDirection = vec3(1.0, wetness * 0.1 - 0.05, -0.4) * wind;

		vec3 skyImage = vec3(0.0);

		#ifdef ATMO_REFLECTION_HORIZON
			bool horizon = true;
		#else
			bool horizon = false;
		#endif
		vec3 transmittance = vec3(1.0);
		bool ray_r_mu_intersects_ground;
		vec3 atmosphere = GetSkyRadiance(cameraSkyBox, worldDir, worldSunVector, -worldSunVector, horizon, transmittance, ray_r_mu_intersects_ground);

		skyImage += atmosphere;

		float cloudTransmittance = 1.0;
		#ifdef VOLUMETRIC_CLOUDS
			if ((cameraPosition.y > cloudAltitude.x || !ray_r_mu_intersects_ground) && (cameraPosition.y < cloudAltitude.y || worldDir.y < 0.0))
				NubisCumulus(skyImage, worldDir, cloudAltitude, colorShadowlight, colorSkylight, windDirection, camera, noise_0, cloudTransmittance);
		#endif

		#ifdef PLANAR_CLOUDS
			if (cameraPosition.y < PC_ALTITUDE && !ray_r_mu_intersects_ground)
				PlanarClouds(skyImage, worldDir, colorShadowlight, colorSkylight, cameraSkyBox, noise_0.x, cloudTransmittance);
		#endif

		#ifdef CAVE_MODE
			skyImage = mix(skyImage, vec3(max(NOLIGHT_BRIGHTNESS, 0.00005) * 0.07), eyeBrightnessZeroSmooth);
		#endif

		vec4 skyBox = vec4(skyImage, cloudTransmittance);

		ivec2 drawTexel = ivec2(gl_GlobalInvocationID.xy);
		vec4 prevData = texelFetch(skyBox2D, drawTexel, 0);

		float blendweight = 0.97;
		if (abs(float(worldTime + isEyeInWater * 150) - texelFetch(pixelData2D, ivec2(PIXELDATA_WORLDTIME, 0), 0).x) > 100.0 || frameCounter == 1) blendweight = 0.0;

		skyBox = mix(skyBox, prevData, blendweight);

		imageStore(img_skyBox2D, drawTexel, skyBox);
	}


#else

	#include "/Lib/IndividualFunctions/EndSky.glsl"


	void main(){
		vec3 skyImage = vec3(0.0);

		vec3 viewVector = CubemapProjectionInverse(vec2(gl_GlobalInvocationID.xy) + 0.5);

		PlanetEnd2(skyImage, vec3(0.0), viewVector);
		EndFog(skyImage, 1024.0, viewVector, shadowModelViewInverseEnd[2]);

		//ivec2 drawTexel = ivec2(gl_GlobalInvocationID.xy);
		//vec3 prevData = texelFetch(skyBox2D, drawTexel, 0).rgb;

		//skyImage = mix(skyImage, prevData, frameCounter == 1 ? 0.0 : 0.9);

		imageStore(img_skyBox2D, ivec2(gl_GlobalInvocationID.xy), vec4(skyImage, 0.0));
	}


#endif