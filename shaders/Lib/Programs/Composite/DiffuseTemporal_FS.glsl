

#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


uniform sampler2D prevDepth2D;


/* RENDERTARGETS: 10,12 */
layout(location = 0) out vec4 framebuffer_diffuseTemporal;
layout(location = 1) out vec4 framebuffer_gsolidTemporal;
//layout(location = 2) out vec4 framebuffer12;


ivec2 texelCoord = ivec2(gl_FragCoord.xy);
vec2 texCoord = gl_FragCoord.xy * UNIFORM_PIXEL_SIZE;


#include "/Lib/GbufferData.glsl"
#include "/Lib/Uniform/GbufferTransforms.glsl"
#include "/Lib/BasicFunctions/TemporalNoise.glsl"

#include "/Lib/PathTracing/Denoiser/DiffuseTemporalFilter.glsl"


/*
	vec3 RGB_To_YCoCg(vec3 color) {
		return vec3(color.r * 0.25 + color.g * 0.5 + color.b * 0.25, color.r * 0.5 - color.b * 0.5, color.r * -0.25 + color.g * 0.5 + color.b * -0.25);
	}

	vec3 YCoCg_To_RGB(vec3 color) {
		float temp = color.r - color.b;
		return vec3(temp + color.g, color.r + color.b, temp - color.g);
	}

	vec3 SampleCurrColorFetch(ivec2 coord){
		return RGB_To_YCoCg(texelFetch(FBTEX_SPECULAR_TEMPORAL, coord, 0).rgb);
	}
*/


void main(){
	#ifdef RENDERING_MODE
		if(rtwDiscardRefresh) discard;
	#endif

	float depth = uintBitsToFloat(texelFetch(depthtexS, texelCoord, 0).x);

	#ifdef LOD_RENDERING
		if (depth == 1.0) depth = -texelFetch(LOD_DEPTH_TEX_1, texelCoord, 0).x;
	#endif

    if (abs(depth) == 1.0) discard;

	vec4 normalData = texelFetch(FBTEX_GSOLID_NORMAL, texelCoord, 0);

	//vec3 prevWorldPos;
	//float normalWeight;
	//vec3 prevScreenPos = GetPreviousPos(vec3(texCoord, depth), prevWorldPos, normalWeight);

	//float prevVaildation;
	framebuffer_diffuseTemporal = DiffuseTemporalFilter(depth, normalData);

	//vec2 specularTex = Unpack2xU8_from_U16(texelFetch(FBTEX_GSOLID_DATA, texelCoord, 0).x);
	//float smoothness = specularTex.y > 229.5 / 255.0 ? -specularTex.x : specularTex.x;

	framebuffer_gsolidTemporal = vec4(normalData.xy, 0.0, 0.0);

/*
	vec3 shadow = SampleCurrColorFetch(texelCoord);
	prevVaildation = saturate(prevVaildation * 5.0);

	if	(prevVaildation > 0.0){
		vec3 color0 = SampleCurrColorFetch(texelCoord + ivec2(-1, -1));
		vec3 color1 = SampleCurrColorFetch(texelCoord + ivec2( 0, -1));
		vec3 color2 = SampleCurrColorFetch(texelCoord + ivec2( 1, -1));
		vec3 color3 = SampleCurrColorFetch(texelCoord + ivec2(-1,  0));
		vec3 color5 = SampleCurrColorFetch(texelCoord + ivec2( 1,  0));
		vec3 color6 = SampleCurrColorFetch(texelCoord + ivec2(-1,  1));
		vec3 color7 = SampleCurrColorFetch(texelCoord + ivec2( 0,  1));
		vec3 color8 = SampleCurrColorFetch(texelCoord + ivec2( 1,  1));

		vec3 avgColor = (shadow + color0 + color1 + color2 + color3 + color5 + color6 + color7 + color8) / 9.0;
		vec3 m2 = (shadow * shadow + color0 * color0 + color1 * color1 + color2 * color2 + color3 * color3 + color5 * color5 + color6 * color6 + color7 * color7 + color8 * color8) / 9.0;
		vec3 variance = sqrt(m2 - avgColor * avgColor);


		vec3 prevShadow = RGB_To_YCoCg(textureLod(colortex12, prevScreenPos.xy, 0.0).rgb);

		vec3 minColor = min(avgColor - variance, shadow);
		vec3 maxColor = max(avgColor + variance, shadow);
		prevShadow = clamp(prevShadow, minColor, maxColor);

		shadow = mix(shadow, prevShadow, 0.95 * prevVaildation);
	}

	framebuffer12 = vec4(YCoCg_To_RGB(shadow), 0.0);
*/
}
