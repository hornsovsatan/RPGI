

#include "/Lib/RTWSM/SampleWarp.glsl"


vec3 ShadowScreenPos_From_WorldPos(vec3 worldPos){
	#ifdef DIMENSION_END
		vec3 shadowPos = shadowModelViewEnd * worldPos;
	#else
		vec3 shadowPos = mat3(shadowModelView0, shadowModelView1, shadowModelView2) * worldPos;
	#endif
	shadowPos *= vec3(shadowProjection[0][0], shadowProjection[0][0], -shadowProjection[0][0] * 0.5);

	return shadowPos * 0.5 + 0.5;
}

vec3 DistortShadowScreenPos(vec3 shadowPos){
	vec2 warp = vec2(
		textureLod(rtwWarp1D, vec2(shadowPos.x, 0.25), 0.0).x,
		textureLod(rtwWarp1D, vec2(shadowPos.y, 0.75), 0.0).x
	);
	shadowPos.xy += warp * 2.0 - 1.0;

	if (shadowPos.xy != saturate(shadowPos.xy)) shadowPos.z = -1e20;

	//ShiftShadowScreenPos(shadowPos.xy);

	return shadowPos;
}


float SampleShadowBilinear(sampler2D shadowSampler, vec3 coord){ // Bilinear shadow rather than depth
	vec2 f = fract(coord.xy * shadowSize - 0.5);

	vec4 shadow = step(coord.z, textureGather(shadowSampler, coord.xy, 0));

	return mix(mix(shadow.w, shadow.z, f.x), mix(shadow.x, shadow.y, f.x), f.y);
}