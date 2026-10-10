

#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


/* RENDERTARGETS: 6 */
layout(location = 0) out vec4 framebuffer_mainOutput;


ivec2 texelCoord = ivec2(gl_FragCoord.xy);

#include "/Lib/GbufferData.glsl"


vec3 FidelityFX_CAS(sampler2D originSampler, vec3 sampleE, ivec2 texelCoord){
	//      +---+
	//    g | h | i
	//  +---+---+---+
	//  | d | e | f |
	//  +---+---+---+
	//    a | b | c
	//      +---+

	vec3 sampleB = texelFetch(originSampler, ivec2(texelCoord.x, texelCoord.y - 1), 0).rgb;
	vec3 sampleD = texelFetch(originSampler, ivec2(texelCoord.x - 1, texelCoord.y), 0).rgb;
	vec3 sampleF = texelFetch(originSampler, ivec2(texelCoord.x + 1, texelCoord.y), 0).rgb;
	vec3 sampleH = texelFetch(originSampler, ivec2(texelCoord.x, texelCoord.y + 1), 0).rgb;
	float luminanceB = Luminance(sampleB);
	float luminanceD = Luminance(sampleD);
	float luminanceE = Luminance(sampleE);
	float luminanceF = Luminance(sampleF);
	float luminanceH = Luminance(sampleH);

	float minCross = min5(luminanceB, luminanceD, luminanceE, luminanceF, luminanceH);
	float maxCross = max5(luminanceB, luminanceD, luminanceE, luminanceF, luminanceH);

	const float sharpness = CAS_SHARPNESS;

	float weight = sqrt(saturate(min(minCross, 2.0 - maxCross) / maxCross)) * (-0.1 - sharpness * 0.01);

	#ifdef CAS_DENOISE
		float noise = luminanceB * 0.25 + luminanceD * 0.25 + luminanceF * 0.25 + luminanceH * 0.25 - luminanceE;
		noise = saturate(abs(noise) / (maxCross - minCross));
		weight *= 1.0 - 0.5 * noise;
	#endif

	vec3 sharpen = (sampleB * weight + sampleD * weight + sampleF * weight + sampleH * weight + sampleE) / (1.0 + 4.0 * weight);

	return max(sharpen, vec3(0.0));
}

vec3 Fxaa(vec3 rgbM, vec2 coord){

	#define FXAA_REDUCE_MIN   (1.0/64.0)
	#define FXAA_REDUCE_MUL   (1.0/8.0)
	#define FXAA_SPAN_MAX     16.0
	
	vec3 rgbNW = textureLod(FBTEX_MAIN_OUTPUT, coord + pixelSize * vec2(-0.5, -0.5), 0.0).xyz;
	vec3 rgbNE = textureLod(FBTEX_MAIN_OUTPUT, coord + pixelSize * vec2( 0.5, -0.5), 0.0).xyz;
	vec3 rgbSW = textureLod(FBTEX_MAIN_OUTPUT, coord + pixelSize * vec2(-0.5,  0.5), 0.0).xyz;
	vec3 rgbSE = textureLod(FBTEX_MAIN_OUTPUT, coord + pixelSize * vec2( 0.5,  0.5), 0.0).xyz;

	vec3 luma = vec3(0.299, 0.587, 0.114);
	float lumaNW = dot(rgbNW, luma);
	float lumaNE = dot(rgbNE, luma);
	float lumaSW = dot(rgbSW, luma);
	float lumaSE = dot(rgbSE, luma);
	float lumaM  = dot(rgbM,  luma);

	float lumaMin = min(lumaM, min(min(lumaNW, lumaNE), min(lumaSW, lumaSE)));
	float lumaMax = max(lumaM, max(max(lumaNW, lumaNE), max(lumaSW, lumaSE)));

	vec2 dir;
	dir.x = -((lumaNW + lumaNE) - (lumaSW + lumaSE));
	dir.y =  ((lumaNW + lumaSW) - (lumaNE + lumaSE));

	float dirReduce = max(
		(lumaNW + lumaNE + lumaSW + lumaSE) * (0.25 * FXAA_REDUCE_MUL),
		FXAA_REDUCE_MIN);
	float rcpDirMin = 1.0/(min(abs(dir.x), abs(dir.y)) + dirReduce);
	dir = min(vec2( FXAA_SPAN_MAX,  FXAA_SPAN_MAX),
		  max(vec2(-FXAA_SPAN_MAX, -FXAA_SPAN_MAX),
		  dir * rcpDirMin)) * pixelSize;

	vec3 rgbA = (1.0/2.0) * (
	textureLod(FBTEX_MAIN_OUTPUT, coord + dir * vec2(1.0/3.0 - 0.5), 0.0).xyz +
	textureLod(FBTEX_MAIN_OUTPUT, coord + dir * vec2(2.0/3.0 - 0.5), 0.0).xyz);
	vec3 rgbB = rgbA * (1.0/2.0) + (1.0/4.0) * (
	textureLod(FBTEX_MAIN_OUTPUT, coord + dir * vec2(0.0/3.0 - 0.5), 0.0).xyz +
	textureLod(FBTEX_MAIN_OUTPUT, coord + dir * vec2(3.0/3.0 - 0.5), 0.0).xyz);

	float lumaB = dot(rgbB, luma);

	if ((lumaB < lumaMin) || (lumaB > lumaMax)) {
		return rgbA;
	} else {
		return rgbB;
	}
}

/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void main(){
	vec3 color = texelFetch(FBTEX_MAIN_OUTPUT, texelCoord, 0).rgb;

	#if defined DECREASE_HAND_GHOSTING && defined DISABLE_PLAYER_TAA_MOTION_BLUR	
		float materialIDs = GetTransMaterialID(texelCoord);
		if (materialIDs == MATID_HAND || materialIDs == MATID_ENTITIES_PLAYER){
			vec2 texCoord = (vec2(texelCoord) + 0.5) * pixelSize;
			color = Fxaa(color, texCoord);
		}else

	#elif defined DECREASE_HAND_GHOSTING
		float materialIDs = GetTransMaterialID(texelCoord);
		if (materialIDs == MATID_HAND){
			vec2 texCoord = (vec2(texelCoord) + 0.5) * pixelSize;
			color = Fxaa(color, texCoord);
		}else

	#elif defined DISABLE_PLAYER_TAA_MOTION_BLUR
		float materialIDs = GetTransMaterialID(texelCoord);
		if (materialIDs == MATID_ENTITIES_PLAYER){
			vec2 texCoord = (vec2(texelCoord) + 0.5) * pixelSize;
			color = Fxaa(color, texCoord);
		}else

	#endif
		{
			#if (CAS_SHARPNESS > 0 && defined TAA && FSR2_SCALE < 0) || (FSR2_RCAS_SHARPNESS > 0 && FSR2_SCALE >= 0)
				color = FidelityFX_CAS(FBTEX_MAIN_OUTPUT, color, texelCoord);
			#endif
		}
	
	framebuffer_mainOutput = vec4(color, 0.0);
}
