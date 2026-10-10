

#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


/* RENDERTARGETS: 8 */
layout(location = 0) out vec4 framebuffer_altOutput;


ivec2 texelCoord = ivec2(gl_FragCoord.xy);
vec2 texCoord = gl_FragCoord.xy * pixelSize;


vec4 BicubicBlurTexture(sampler2D texSampler, vec2 coord, vec2 texSize){
    vec2 texPixelSize = 1.0 / texSize;
    coord = coord * texSize - 0.5;

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
    c *= texPixelSize.xxyy;

    vec2 m = s.xz / (s.xz + s.yw);
    return mix(mix(textureLod(texSampler, c.yw, 0.0), textureLod(texSampler, c.xw, 0.0), m.x),
                mix(textureLod(texSampler, c.yz, 0.0), textureLod(texSampler, c.xz, 0.0), m.x),
                m.y);
}


void main(){
	vec2 originSize = vec2(0.25);
	const float intervalWidth = 3.0;

	vec2 tCoord = texCoord * 2.0;
	vec2 border = pixelSize * 8.0 + 1.0;
	
	#ifdef DIMENSION_OVERWORLD
		#if defined SUPER_RESOLUTION || defined CUSTOM_RENDER_RESOLUTION
			float rainAlpha = saturate(textureLod(FBTEX_ALBEDO, tCoord * fsrRenderScale, 0.0).a * RAIN_VISIBILITY);
		#else
			float rainAlpha = saturate(textureLod(FBTEX_ALBEDO, tCoord, 0.0).a * RAIN_VISIBILITY);
		#endif
	#else
		const float rainAlpha = 1.0;
	#endif

	vec2 coord = texCoord;
	vec2 sampleOrigin = vec2(0.0);
	
	#if HIGHLIGHT_DIFFUSION_FILTER == 2
		const float weightLod0 = 3.0;
		const float weightLod1 = 2.5;
		const float weightLod2 = 2.0;
		const float weightLod3 = 1.0;
		const float weightLod4 = 0.48225309;
		const float weightLod5 = 0.40187757;
		const float weightLod6 = 0.33489798;
		const float rWeights = 0.125;
	#elif HIGHLIGHT_DIFFUSION_FILTER == 1
		const float weightLod0 = 2.0;
		const float weightLod1 = 1.6;
		const float weightLod2 = 1.2;
		const float weightLod3 = 0.9;
		const float weightLod4 = 0.48225309;
		const float weightLod5 = 0.40187757;
		const float weightLod6 = 0.33489798;
		const float rWeights = 0.178;
	#else
		const float weightLod0 = 1.0;
		const float weightLod1 = 0.83333333;
		const float weightLod2 = 0.69444444;
		const float weightLod3 = 0.57870370;
		const float weightLod4 = 0.48225309;
		const float weightLod5 = 0.40187757;
		const float weightLod6 = 0.33489798;
		const float rWeights = 0.28;
	#endif

	const float weightRainLod0 = 5.0;
	const float weightRainLod1 = 4.0;
	const float weightRainLod2 = 3.0;
	const float weightRainLod3 = 2.0;
	const float weightRainLod4 = 1.0;
	const float weightRainLod5 = 1.0;
	const float weightRainLod6 = 1.0;
	const float rRainWeights = 0.07;

	vec3 bloom = vec3(0.0);
	if (tCoord.x <= border.x && tCoord.y <= border.y){

		bloom += BicubicBlurTexture(FBTEX_ALT_OUTPUT, coord * 0.5, screenSize).rgb * mix(weightRainLod0, weightLod0, rainAlpha);

		sampleOrigin.x -= originSize.x + pixelSize.x * intervalWidth;
		originSize *= 0.5;
		bloom += BicubicBlurTexture(FBTEX_ALT_OUTPUT, coord * 0.25 - sampleOrigin, screenSize).rgb * mix(weightRainLod1, weightLod1, rainAlpha);

		sampleOrigin.x -= originSize.x + pixelSize.x * intervalWidth;
		originSize *= 0.5;
		bloom += BicubicBlurTexture(FBTEX_ALT_OUTPUT, coord * 0.125 - sampleOrigin, screenSize).rgb * mix(weightRainLod2, weightLod2, rainAlpha);

		sampleOrigin.x -= originSize.x + pixelSize.x * intervalWidth;
		originSize *= 0.5;
		bloom += BicubicBlurTexture(FBTEX_ALT_OUTPUT, coord * 0.0625 - sampleOrigin, screenSize).rgb * mix(weightRainLod3, weightLod3, rainAlpha);

		sampleOrigin.x -= originSize.x + pixelSize.x * intervalWidth;
		originSize *= 0.5;
		bloom += BicubicBlurTexture(FBTEX_ALT_OUTPUT, coord * 0.03125 - sampleOrigin, screenSize).rgb * mix(weightRainLod4, weightLod4, rainAlpha);

		sampleOrigin.x -= originSize.x + pixelSize.x * intervalWidth;
		originSize *= 0.5;
		bloom += BicubicBlurTexture(FBTEX_ALT_OUTPUT, coord * 0.015625 - sampleOrigin, screenSize).rgb * mix(weightRainLod5, weightLod5, rainAlpha);

		sampleOrigin.x -= originSize.x + pixelSize.x * intervalWidth;
		originSize *= 0.5;
		bloom += BicubicBlurTexture(FBTEX_ALT_OUTPUT, coord * 0.0078125 - sampleOrigin, screenSize).rgb * mix(weightRainLod6, weightLod6, rainAlpha);

	}

	bloom *= mix(rRainWeights, rWeights, rainAlpha); // 0.23118661

	framebuffer_altOutput = vec4(bloom, 0.0);
}
