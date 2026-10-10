

#include "/Lib/Utilities.glsl"
#include "/Lib/UniformDeclare.glsl"


layout (rgba8) writeonly uniform image2D colorimg0;


#if WAVEFORM_SIZE == 0

	const ivec3 workGroups = ivec3(450, 1, 1);
	layout (local_size_x = 1, local_size_y = 256) in;

	#if WAVEFORM_TYPE == 1
		shared vec3 colorCache[256];
	#else
		shared float colorCache[256];
	#endif


	void main(){
		#if WAVEFORM_TYPE == 0
			const vec2 tileSize = vec2(150.0, 256.0);
		#else
			const vec2 tileSize = vec2(450.0, 256.0);
		#endif

		const float intensity = 0.06 * WAVEFORM_INTENSITY;

#else

	const ivec3 workGroups = ivec3(900, 1, 1);
	layout (local_size_x = 1, local_size_y = 512) in;

	#if WAVEFORM_TYPE == 1
		shared vec3 colorCache[512];
	#else
		shared float colorCache[512];
	#endif


	void main(){
		#if WAVEFORM_TYPE == 0
			const vec2 tileSize = vec2(300.0, 512.0);
		#else
			const vec2 tileSize = vec2(900.0, 512.0);
		#endif

		const float intensity = 0.03 * WAVEFORM_INTENSITY;

#endif

	const vec2 tilePixelSize = 1.0 / tileSize;
	const float thres = 200.0 / WAVEFORM_THRESHOLD;


	vec2 sampleCoord = vec2(gl_GlobalInvocationID.xy) + 0.5;
	sampleCoord *= tilePixelSize;
	

	#if WAVEFORM_TYPE == 0
		if (sampleCoord.x < 1.0){
			colorCache[gl_LocalInvocationIndex] = textureLod(FBTEX_MAIN_OUTPUT, sampleCoord, 0.0).r;

		}else if (sampleCoord.x < 2.0){
			colorCache[gl_LocalInvocationIndex] = textureLod(FBTEX_MAIN_OUTPUT, vec2(sampleCoord.x - 1.0, sampleCoord.y), 0.0).g;

		}else{
			colorCache[gl_LocalInvocationIndex] = textureLod(FBTEX_MAIN_OUTPUT, vec2(sampleCoord.x - 2.0, sampleCoord.y), 0.0).b;

		}

	#elif WAVEFORM_TYPE == 1
		colorCache[gl_LocalInvocationIndex] = textureLod(FBTEX_MAIN_OUTPUT, sampleCoord, 0.0).rgb;

	#else
		colorCache[gl_LocalInvocationIndex] = Luminance(textureLod(FBTEX_MAIN_OUTPUT, sampleCoord, 0.0).rgb);

	#endif


	barrier();


	ivec2 drawTexel = ivec2(gl_GlobalInvocationID.xy) + ivec2(WAVEFORM_OFFEST_X, WAVEFORM_OFFEST_Y);


	#if WAVEFORM_OPACITY == 100
		vec3 color = vec3(0.0);
	#else
		vec3 color = texelFetch(FBTEX_ALBEDO, drawTexel, 0).rgb;
		color *= 1.0 - float(WAVEFORM_OPACITY) * 0.01;
	#endif

	float altitude = float(gl_LocalInvocationIndex);

	if (altitude == floor(tileSize.y * (0.2 / 1.4)) - 1.0 ||
		altitude == floor(tileSize.y * (1.2 / 1.4)) + 1.0
	) 
	color = vec3(0.45);

	if (altitude == floor(tileSize.y * (0.45 / 1.4)) ||
		altitude == floor(tileSize.y * (0.7 / 1.4)) ||
		altitude == floor(tileSize.y * (0.95 / 1.4))
	)
	color = vec3(0.2);

	vec2 tcoord = abs(fract(sampleCoord) - 0.5);
	if (any(greaterThan(tcoord, 0.5 - tilePixelSize)))
	color = vec3(0.7);

	
 
	vec3 result = vec3(0.0);
	float level = (altitude + 0.5) * (tilePixelSize.y * 1.4) - 0.2;

	#if WAVEFORM_SIZE == 0
		for (int i = 0; i < 256; i++){
	#else
		for (int i = 0; i < 512; i++){
	#endif
		result += intensity * (saturate(1.0 - abs(colorCache[i] - level) * thres));
	}

	#if WAVEFORM_TYPE == 0
		if (sampleCoord.x < 1.0){
			result.gb = vec2(0.0);
		}else if (sampleCoord.x < 2.0){
			result.rb = vec2(0.0);
		}else{
			result.rg = vec2(0.0);
		}
	#endif

	color.rgb = mix(color.rgb, vec3(1.0), result.rgb);


	imageStore(colorimg0, drawTexel, vec4(color, 0.0));

}