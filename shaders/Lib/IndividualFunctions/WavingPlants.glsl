

float CurveBlinearTexture(vec2 texel){
	vec2 p = floor(texel);
	vec2 f = curve(texel - p);
	return textureLod(noisetex, (p + f) / 128.0, 0.0).x;
}

float BicubicBlurTexture(vec2 coord){
	vec2 p = floor(coord);
	vec2 f = coord - p;

	vec2 ff = f * f;
	vec4 w0;
	vec4 w1;
	w0.xz = 1.0 - f; w0.xz *= w0.xz * w0.xz;
	w1.yw = ff * f;
	w1.xz = 3.0 * w1.yw + 4.0 - 6.0 * ff;
	w0.yw = 6.0 - w1.xz - w1.yw - w0.xz;

	vec4 s = w0 + w1;
	vec4 c = p.xxyy + vec2(-0.5, 1.5).xyxy + w1 / s;
	c *= 1.0 / 128.0;

	vec2 m = s.xz / (s.xz + s.yw);
	return mix(mix(textureLod(noisetex, c.yw, 0.0).x, textureLod(noisetex, c.xw, 0.0).x, m.x),
			   mix(textureLod(noisetex, c.yz, 0.0).x, textureLod(noisetex, c.xz, 0.0).x, m.x),
		   m.y);
}


void WavingPlants(inout vec4 worldPos, float lightmap){
#if WAVING_RANGE < 999
	const float wavingRange = WAVING_RANGE;
	float dist = length(worldPos.xyz);
	if (dist < wavingRange)
#endif
	{
		bool isLeaves = mc_Entity.x == 4.0 || mc_Entity.x == 7040.0;
		if (isLeaves || abs(mc_Entity.x - 7020.0) < 10.5){
			worldPos.xyz += cameraPosition.xyz;
			float timer = frameTimeCounter * WAVING_SPEED;

			vec2 rainAmp = 1.0 + wetness * vec2(0.5, 0.2);

			vec2 uv = (worldPos.xz + timer * vec2(5.0, -1.0)) * 0.05;
			float windStrength = BicubicBlurTexture(uv);
			windStrength = windStrength * 0.85 + 0.15;

			float lightWeight = saturate(lightmap * 3.0 - 1.5);
			windStrength *= lightWeight * lightWeight;

			#if WAVING_RANGE < 999
				windStrength *= saturate((dist - wavingRange) * (1.0 / (wavingRange * -0.25)));
			#endif

			if (isLeaves){
				windStrength *= sin(timer * 2.22 * rainAmp.y                 + worldPos.x * 1.0 + worldPos.z * 0.5) * (0.015 * LEAVES_AMPLITUDE) + (0.015 * LEAVES_AMPLITUDE);
				worldPos.xyz += sin(timer * (120.0 / vec3(19.0, 11.0, 17.0)) + worldPos.x * 1.2 - worldPos.z * 1.5) * vec3(1.0, 0.5, 1.0) * windStrength * rainAmp.x;

			}else{
				float grassWeight = step(gl_MultiTexCoord0.y, mc_midTexCoord.y);
				if (mc_Entity.x == 7020.0){
					grassWeight = grassWeight * 0.6;
				} else if (mc_Entity.x == 7021.0){
					grassWeight = grassWeight * 0.6 + 0.6;
				}
				windStrength *= grassWeight * GRASS_AMPLITUDE;

				float isWheats = float(mc_Entity.x == 7011.0);

				uv = uv * (4.0 + 4.0 * isWheats) + timer * (vec2(-2.0, 2.0) * 0.2);
				float rand = BicubicBlurTexture(uv);

				vec2 offset = sin(
					(timer * rainAmp.y) * vec2(5.0, 3.0)
					+ rand * vec2(14.0, 21.0)
					+ worldPos.zx * (GRASS_DISTURBANCE - isWheats * (GRASS_DISTURBANCE * 0.7))
				) * vec2(0.07, 0.04) * rainAmp.x;
				
				worldPos.xz += (offset + vec2(-0.05, 0.02) * rainAmp.x) * windStrength;
				worldPos.y  += (cos(max(abs(offset.x) * 2.0, abs(offset.y))) - 1.0) * windStrength;
			}

			worldPos.xyz -= cameraPosition.xyz;
		}
	}
}