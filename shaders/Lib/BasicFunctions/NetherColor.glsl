

uniform float BiomeNetherWastesSmooth;
uniform float BiomeSoulSandValleySmooth;
uniform float BiomeCrimsonForestSmooth;
uniform float BiomeWarpedForestSmooth;
uniform float BiomeBasaltDeltasSmooth;


vec3 NetherLighting(){
	vec3 netherLighting = 	(vec3(1.77, 0.85, 0.27) * 0.8) * BiomeNetherWastesSmooth; //3000K
	netherLighting += 		(vec3(0.92, 0.99, 1.29) * 0.6) * BiomeSoulSandValleySmooth; //8500K
	netherLighting += 		(vec3(1.30, 0.95, 0.65) * 0.7) * BiomeCrimsonForestSmooth; //5000K
	netherLighting += 		(vec3(0.97, 0.99, 1.18) * 0.7) * BiomeWarpedForestSmooth; //7500K
	netherLighting += 		(vec3(1.07, 0.98, 0.99) * 1.2) * BiomeBasaltDeltasSmooth; //6000K
	return netherLighting * (NETHER_BRIGHTNESS * 8e-5);
}

vec4 NetherFogColor(){
	vec4 fog = 	vec4(0.990, 0.170, 0.005, 0.010) * BiomeNetherWastesSmooth;
	fog += 		vec4(0.030, 0.090, 0.160, 0.008) * BiomeSoulSandValleySmooth;
	fog += 		vec4(0.200, 0.020, 0.005, 0.010) * BiomeCrimsonForestSmooth;
	fog += 		vec4(0.045, 0.155, 0.200, 0.009) * BiomeWarpedForestSmooth;
	fog += 		vec4(0.500, 0.500, 0.500, 0.012) * BiomeBasaltDeltasSmooth;
	fog *= 		vec4(vec3(NETHER_BRIGHTNESS * 0.0025), NETHERFOG_DENSITY);
	return fog;
}

void NetherFog(inout vec3 color, float dist){
	vec4 fogColor = NetherFogColor();

	float fogDensity = fogColor.a;
	float fogFactor = 1.0 - exp2(-dist * fogDensity);
	fogFactor = fogFactor * fogFactor;

	color = mix(color, fogColor.rgb, fogFactor);
}

void NetherFog(inout vec3 color, float dist, float rayDist){
	vec4 fogColor = NetherFogColor();

	float fogDensity = fogColor.a;
	float fogFactor = 1.0 - exp2(-dist * fogDensity);
	float rayFogFactor = 1.0 - exp2(-rayDist * fogDensity);
	fogFactor = saturate(rayFogFactor * rayFogFactor - fogFactor * fogFactor);

	color = mix(color, fogColor.rgb, fogFactor);
}