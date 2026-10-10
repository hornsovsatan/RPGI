

#include "/Lib/Settings.glsl"
#include "/Lib/Utilities.glsl"


layout(location = 0) out vec4 framebuffer_albedo;
layout(location = 1) out vec4 framebuffer_gsoildData;
layout(location = 2) out vec4 framebuffer_gsoildNormal;


#define UNIFORM_TAA_JITTER taaJitterVX
#ifdef SUPER_RESOLUTION
	#define UNIFORM_PIXEL_SIZE fsrPixelSize
#else
	#define UNIFORM_PIXEL_SIZE pixelSize
#endif

#include "/Lib/Uniform/GbufferTransforms.glsl"
#include "/Lib/IndividualFunctions/Ripple.glsl"


void voxy_emitFragment(VoxyFragmentParameters parameters){
//albedo
	vec3 albedo = parameters.sampledColour.rgb * parameters.tinting.rgb;
	
	#if WHITE_DEBUG_WORLD > 0
		albedo = vec3(WHITE_DEBUG_WORLD * 0.1);
	#endif

//material
	float materialIDs = MATID_LAND;
	float emissiveness = 0.0;

	if (parameters.customId > 1.5){
		if (parameters.customId < 6999.5){
			if (parameters.customId == 2.0){
				emissiveness = 1.0;
				
			}else if (parameters.customId == 4.0){
				materialIDs = MATID_LEAVES;
				albedo = LinearToGamma(GammaToLinear(albedo) * 0.65);

			}else if (abs(parameters.customId - 244.0) < 3.5){ // 241 - 247
				materialIDs = MATID_FIRE + parameters.customId - 241.0;
				emissiveness = 1.0;

			}else if (abs(parameters.customId - 250.5) < 2.0){ // candle 249 - 252
				materialIDs = MATID_TORCH;
				emissiveness = parameters.customId * 0.1 - 24.6;

			}else if (abs(parameters.customId - 191.0) < 33.5){ // 158 - 224
				emissiveness = 0.5;

			}
		}else{
			if (parameters.customId < 7200.5){
				materialIDs = MATID_GRASS;

			}else if (parameters.customId == 8242.0){
				materialIDs = MATID_TORCH;
				emissiveness = saturate(2.0 * parameters.sampledColour.r - 1.5 * parameters.sampledColour.g);;
				
			}else if (abs(parameters.customId - 8549.5) < 51.0){
				emissiveness = saturate(parameters.customId * 0.01 - 85.0);

			}else if (parameters.customId == 9002.0){
				float power = saturate(parameters.tinting.r * 1.1 - 0.1) * float(parameters.tinting.r > 0.3 && parameters.tinting.b == 0.0);
				emissiveness = power * power * 0.15;
				
			}
		}
	}

//lightmap
	vec2 blockLight = saturate(parameters.lightMap * 16.0 / 15.0 - 0.5 / 15.0);

//normal
	vec3 vertexNormal = vec3(
		(parameters.face >> 2u) &  1u,
		(parameters.face >> 1u) == 0u,
		(parameters.face >> 1u) &  1u
	) * uintBitsToFloat((parameters.face << 31u) ^ 0xbf800000u);

//wet effect
	#ifdef ENABLE_ROUGH_SPECULAR
		vec3 viewPos = ViewPos_From_ScreenPos_LOD(gl_FragCoord.xy * UNIFORM_PIXEL_SIZE - 0.5 * taaJitterVX, gl_FragCoord.z);
		vec3 worldPos = mat3(gbufferModelViewInverse) * viewPos;
		vec3 mcPos = worldPos + cameraPosition;
		
		const float porosity = TEXTURE_DEFAULT_POROSITY;

		#ifdef DIMENSION_OVERWORLD
			#ifndef DISABLE_LOCAL_PRECIPITATION
				float wet = wetness * (1.0 - eyeSnowySmooth) * (1.0 - eyeNoPrecipitationSmooth) + SURFACE_WETNESS;
			#else
				float wet = wetness + SURFACE_WETNESS;
			#endif

			wet *= float(abs(emissiveness - 0.99) > 0.005);
			wet *= step(0.9, blockLight.y);

			if (wet > 1e-7){
				GetModulatedRainSpecular(wet, mcPos, blockLight.y);
				ApplyPorosity(wet, albedo, porosity, vertexNormal.y);
			}

		#else
			float wet = SURFACE_WETNESS;

			if (wet > 1e-7){
				GetModulatedRainSpecular(wet, mcPos, 1.0);
				ApplyPorosity(wet, albedo, porosity, vertexNormal.y);
			}
		#endif

	#else
		float wet = 0.0;
	#endif

//output
	vec2 normalEnc = EncodeNormal(vertexNormal);

	framebuffer_albedo = vec4(albedo, 1.0);
	framebuffer_gsoildData = vec4(Pack2xU8_to_U16(vec2(wet, 0.0)), Pack2xU8_to_U16(vec2(0.0, emissiveness)), Pack2xU8_to_U16(vec2(1.0, (materialIDs + 128.0) / 255.0)), Pack2xU8_to_U16(blockLight + 1e-6));
	framebuffer_gsoildNormal = vec4(normalEnc, normalEnc);
}