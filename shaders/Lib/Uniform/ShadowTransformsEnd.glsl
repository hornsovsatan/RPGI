

#include "/Lib/RTWSM/SampleWarp.glsl"


const mat3 shadowModelViewInverseEnd = mat3(0.4523250774, -0.8087002661, -0.3760397683, 0.2486168185, 0.5192604694, -0.8176541093, 0.85649968, 0.2763556486, 0.4359310193);
const mat3 shadowModelViewEnd = transpose(shadowModelViewInverseEnd);


vec3 ShadowScreenPos_From_WorldPos(vec3 worldPos){
	vec3 shadowPos = shadowModelViewEnd * worldPos;
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
