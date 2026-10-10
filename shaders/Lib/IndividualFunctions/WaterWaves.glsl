

float WaveHeight(vec3 wavePos, const bool detail) {
	vec2 waveTime = vec2(frameTimeCounter * (vec2(0.03, 0.01) * WAVE_SPEED));


	vec2 waveCoord = wavePos.xz - wavePos.y * 0.1;
	waveCoord *= WAVE_SCALE * 0.022222;

	#ifndef CAUSZTICS_NORMAL

		float bw = textureLod(noisetex, wavePos.xz * 0.0025 + waveTime * 0.01, 0.0).z;

		float wave = 0.0;
		wave += textureLod(noisetex, waveCoord * vec2(1.0, 0.6) + waveTime + bw * 0.4, 0.0).z * 16.0;

		waveCoord = rotMatGA * (waveCoord * 2.0);
		wave += curveTop(textureLod(noisetex, waveCoord * vec2(1.0, 0.3) - waveTime - bw * 0.3, 0.0).z) * 12.0;

	#else

		float wave = 0.0;
		wave += textureLod(noisetex, waveCoord * vec2(1.0, 0.6) + waveTime, 0.0).z * 16.0;

		waveCoord = rotMatGA * (waveCoord * 2.0);
		wave += curveTop(textureLod(noisetex, waveCoord * vec2(1.0, 0.3) - waveTime, 0.0).z) * 12.0;

	#endif

	if (detail){
		float distortion = wave * 0.02;
		waveCoord += waveTime * -0.2;

		waveCoord = rotMatGA * (waveCoord * 1.8);
		wave += textureLod(noisetex, waveCoord * vec2(1.0, 0.4) + waveTime + distortion, 0.0).z * 2.0;

		waveCoord = rotMatGA * (waveCoord * 1.4);
		wave += textureLod(noisetex, waveCoord * vec2(1.0, 0.4) + waveTime + distortion, 0.0).z * 0.75;

		waveCoord = rotMatGA * (waveCoord * 1.4);
		wave += textureLod(noisetex, waveCoord * vec2(1.0, 0.6) + waveTime + distortion, 0.0).z * 1.25;
	}

	#ifndef CAUSZTICS_NORMAL
		wave = (1.0 - wave / 32.0) * (saturate(bw * 2.0 - 0.7) * 0.7 + 0.3);
	#else
		wave = (1.0 - wave / 32.0);
	#endif

	return wave;
}

vec3 WaveNormal(vec3 wavePos, const float waveHeight){
	//wavePos.xz -= 0.01;

	const float waveEps = 0.1 / WAVE_SCALE;

	vec3 waveNormal = vec3(
		WaveHeight(wavePos, true),
		WaveHeight(wavePos + vec3(waveEps, 0.0, 0.0), true),
		WaveHeight(wavePos + vec3(0.0, 0.0, waveEps), true)
	);

	waveNormal = vec3(waveNormal.x - waveNormal.y, waveNormal.x - waveNormal.z, 1.0);

	#ifndef CAUSZTICS_NORMAL
		waveNormal.xy *= waveHeight * WAVE_NORMAL_STRENGTH * 0.36;
	#else
		waveNormal.xy *= waveHeight * WAVE_NORMAL_STRENGTH * 0.2;
	#endif

	return normalize(waveNormal);
}

vec3 WaveParallax(vec3 wavePos, vec3 viewVector, float NdotU, float noise, inout float waterDist){
	if (abs(NdotU) > 0.999){
		const float waveRange = 0.6;

		viewVector /= -viewVector.y;
		viewVector.y -= 0.06;
		vec3 stepDir = viewVector * (waveRange / WAVE_PARALLAX_QUALITY);
		stepDir.xz *= (WAVE_PARALLAX_DEPTH * 2.7);

		wavePos -= stepDir * (5.0 + step(NdotU, 0.0) * 4.0);

		vec3 stepVector;
		float sampleHeight = WaveHeight(wavePos + stepVector, false);

		for (int i = 0; i < WAVE_PARALLAX_QUALITY; i++){
			stepVector = stepDir * float(i + noise);
			sampleHeight = WaveHeight(wavePos + stepVector, false);
			if (sampleHeight > stepVector.y + waveRange) break;
		}

		for (int i = 0; i < WAVE_PARALLAX_MAX_REFINEMENTS; i++){
			stepDir *= 0.5;
			stepVector += stepDir * fsign(stepVector.y + waveRange - sampleHeight);
			sampleHeight = WaveHeight(wavePos + stepVector, false);
		}
		stepVector += stepDir * (0.5 * fsign(stepVector.y - sampleHeight));

		waterDist += length(stepVector);

		return wavePos + stepVector;
	}else{
		return wavePos;
	}
}
