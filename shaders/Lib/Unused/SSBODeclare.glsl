

#ifdef PROGRAM_UPDATE_SSBO
	layout(std430, binding = 0) restrict buffer uniformData{
#else
	layout(std430, binding = 0) restrict readonly buffer uniformData{
#endif

 	vec3 ssb_cameraProj0;
	vec3 ssb_cameraProj1;
	vec4 ssb_cameraProjInv0;
	vec3 ssb_cameraProjInv1;
 	vec3 ssb_cameraProjPrev0;
	vec3 ssb_cameraProjPrev1;

	vec3 ssb_shadowRot0;
	vec3 ssb_shadowRot1;
	vec3 ssb_shadowRot2;

	vec3 ssb_shadowDir;
	vec3 ssb_sunDir;

	vec2 ssb_screenSize;
	vec2 ssb_pixelSize;
	vec2 ssb_taaJitter;
	

	vec3 ssb_atmoCamera;

	vec3 ssb_sunIrradiance;
	vec3 ssb_moonIrradiance;
	vec3 ssb_celestialIrradiance;
	vec3 ssb_atmoIrradiance;

	vec3 ssb_cloudSunIrradiance;
	vec3 ssb_cloudMoonIrradiance;
	vec3 ssb_cloudCelestialIrradiance;
	vec3 ssb_cloudAtmoIrradiance;

	vec2 ssb_fogTimeFactor;
	//float ssb_sunVisibility;
	float ssb_highlightVisibility;


	float ssb_worldTime;
	bool ssb_refreshTemporal;

	float ssb_luminanceAvg;
	float ssb_exposure;

	float ssb_centerDepthSmooth;

	#ifdef RENDERING_MODE
		float ssb_renderModeCoolingDown;
		float ssb_renderFrames;
	#endif
};

