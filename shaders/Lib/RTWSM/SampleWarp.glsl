

uniform sampler2D rtwWarp1D;

const float warpPixelScale = float(RTW_RESOLUTION) / 512.0 * shadowSize / 2048.0;

vec2 SampleRTWWarpSmooth(vec2 coord){
	coord = coord * float(RTW_RESOLUTION) - 0.5;

	vec2 f = fract(coord);
	ivec2 texel = ivec2(coord);

	texel = clamp(texel, 0, RTW_RESOLUTION - 2);

	float warpX = mix(
		texelFetch(rtwWarp1D, ivec2(texel.x,     0), 0).x,
		texelFetch(rtwWarp1D, ivec2(texel.x + 1, 0), 0).x,
		f.x
	);

	float warpY = mix(
		texelFetch(rtwWarp1D, ivec2(texel.y,     1), 0).x,
		texelFetch(rtwWarp1D, ivec2(texel.y + 1, 1), 0).x,
		f.y
	);

	return vec2(
		warpX * 2.0 - 1.0,
		warpY * 2.0 - 1.0
	);
}

vec4 SampleRTWWarpSmoothWithPixelSize(vec2 coord){
	coord = coord * float(RTW_RESOLUTION) - 0.5;

	vec2 f = fract(coord);
	ivec2 texel = ivec2(coord);

	texel = clamp(texel, 0, RTW_RESOLUTION - 2);

	vec2 warpX = mix(
		texelFetch(rtwWarp1D, ivec2(texel.x,     0), 0).xy,
		texelFetch(rtwWarp1D, ivec2(texel.x + 1, 0), 0).xy,
		f.x
	);

	vec2 warpY = mix(
		texelFetch(rtwWarp1D, ivec2(texel.y,     1), 0).xy,
		texelFetch(rtwWarp1D, ivec2(texel.y + 1, 1), 0).xy,
		f.y
	);

	return vec4(
		warpX.x * 2.0 - 1.0,
		warpY.x * 2.0 - 1.0,
		warpX.y,
		warpY.y
	);
}