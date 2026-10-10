

#ifdef RENDERING_MODE
	vec2 BlueNoise(ivec2 coord){
		return texelFetch(noisetex, coord & 127, 0).xy;
	}

	vec2 BlueNoise(){
		return texelFetch(noisetex, ivec2(gl_FragCoord.xy) & 127, 0).xy;
	}

	vec2 BlueNoiseTemporal(){
		return fract(texelFetch(noisetex, ivec2(gl_FragCoord.xy) & 127, 0).xy + vec2(goldenRatio, plasticRatio) * vec2(frameCounter));
	}

	vec2 BlueNoiseTemporal(int index){
		return fract(texelFetch(noisetex, ivec2(gl_FragCoord.xy) & 127, 0).xy + vec2(goldenRatio, plasticRatio) * vec2((frameCounter + index) & 63));
	}

	float BayerTemporal(){
		return fract(bayer64(gl_FragCoord.xy) + goldenRatio * float(frameCounter));
	}


	float IGNTemoral(){
		float frame = float(frameCounter);
		vec2 c = gl_FragCoord.xy + 5.588238 * frame;
		return fract(52.9829189 * fract(0.06711056 * c.x + 0.00583715 * c.y));
	}

#else
	vec2 BlueNoise(ivec2 coord){
		return texelFetch(noisetex, coord & 127, 0).xy;
	}

	vec2 BlueNoise(){
		return texelFetch(noisetex, ivec2(gl_FragCoord.xy) & 127, 0).xy;
	}

	vec2 BlueNoiseTemporal(){
		return fract(texelFetch(noisetex, ivec2(gl_FragCoord.xy) & 127, 0).xy + vec2(goldenRatio, plasticRatio) * vec2(frameCounter & 63));
	}

	vec2 BlueNoiseTemporal(int index){
		return fract(texelFetch(noisetex, ivec2(gl_FragCoord.xy) & 127, 0).xy + vec2(goldenRatio, plasticRatio) * vec2((frameCounter + index) & 63));
	}

	float BayerTemporal(){
		return fract(bayer64(gl_FragCoord.xy) + goldenRatio * float(frameCounter & 127));
	}


	float IGNTemoral(){
		float frame = float(frameCounter & 63);
		vec2 c = gl_FragCoord.xy + 5.588238 * frame;
		return fract(52.9829189 * fract(0.06711056 * c.x + 0.00583715 * c.y));
	}

#endif