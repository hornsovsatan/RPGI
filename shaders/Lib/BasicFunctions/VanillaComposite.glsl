
/*
void VanillaFog(inout vec3 color, float dist){
	#ifndef DISABLE_BLINDNESS_DARKNESS
		if (darknessFactor > 0.0) color = mix(color, vec3(0.0), smoothstep(5.0, mix(far, 15.0, darknessFactor), dist) * darknessFactor);
		if (blindness > 0.0) color = mix(color, vec3(0.0), smoothstep(1.5, mix(far, 4.5, blindness), dist) * blindness);
	#endif

	if (isEyeInWater == 2) color = mix(color, vec3(0.3721, 0.0775, 0.0024) * TORCHLIGHT_BRIGHTNESS_MAIN, smoothstep(0.0, 1.0, dist));

	if (isEyeInWater == 3) color = mix(color, vec3(Radiance(colorSkylight)), smoothstep(0.0, 2.0, dist));
}
*/
void SelectionBox(inout vec3 color, vec3 albedo, bool isSelection){
	if (isSelection){
		float exposure = texelFetch(pixelData2D, ivec2(PIXELDATA_EXPOSURE, 0), 0).x * 0.13;
		color = albedo * exposure;
	}
}
