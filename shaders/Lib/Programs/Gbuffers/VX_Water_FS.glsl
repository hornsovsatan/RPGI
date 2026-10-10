

#include "/Lib/Settings.glsl"
#include "/Lib/Utilities.glsl"


layout(location = 0) out vec4 framebuffer_gtransData;
layout(location = 1) out vec4 framebuffer_gtransNormal;
layout(location = 2) out vec4 framebuffer_gwater;

//#if defined PT_OCCLUDED_WATER_SPECULAR && defined DIMENSION_OVERWORLD
//	layout(r32ui) uniform uimage2D img_waterDepth2D;
//#endif


#define UNIFORM_TAA_JITTER taaJitterVX
#ifdef SUPER_RESOLUTION
	#define UNIFORM_PIXEL_SIZE fsrPixelSize
#else
	#define UNIFORM_PIXEL_SIZE pixelSize
#endif

#include "/Lib/Uniform/GbufferTransforms.glsl"
#include "/Lib/BasicFunctions/TemporalNoise.glsl"

#include "/Lib/IndividualFunctions/WaterWaves.glsl"


void voxy_emitFragment(VoxyFragmentParameters parameters){
//albedo
	vec4 albedo = parameters.sampledColour * parameters.tinting;

//lightmap
	vec2 blockLight = vec2(0.0, saturate(parameters.lightMap.y * 16.0 / 15.0 - 0.5 / 15.0));

//TBN
	vec3 N = vec3(
		(parameters.face >> 2u) &  1u,
		(parameters.face >> 1u) == 0u,
		(parameters.face >> 1u) &  1u
	) * uintBitsToFloat((parameters.face << 31u) ^ 0xbf800000u);
	
	vec3 T = vec3(abs(N.y) + N.z, 0.0, -N.x);
	vec3 B = vec3(0.0, abs(N.y) - 1.0, N.y);

	mat3 tbn = mat3(T, B, N);

//material
	float materialIDs = MATID_STAINEDGLASS;
	bool isWater = parameters.customId == 6000.0;

//normal
	vec3 waterNormal = tbn[2];
	float dist = 0.0;
	
	if (isWater){
		materialIDs = MATID_WATER;

		vec3 viewPos = ViewPos_From_ScreenPos_LOD(gl_FragCoord.xy * UNIFORM_PIXEL_SIZE - 0.5 * taaJitterVX, gl_FragCoord.z);
		vec3 worldPos = mat3(gbufferModelViewInverse) * viewPos;
		vec3 mcPos = worldPos + cameraPosition;
		
		float nonsense;
		#ifdef WAVE_PARALLAX
			vec3 viewVector = worldPos - gbufferModelViewInverse[3].xyz;
			float noise = BlueNoiseTemporal().x;

			mcPos = WaveParallax(mcPos, viewVector, tbn[2].y, noise, nonsense);
		#endif
		float NdotU = saturate(waterNormal.y + float(isEyeInWater == 1) * 2.0);
		waterNormal = WaveNormal(mcPos, NdotU * 13.0 + 5.0);

		waterNormal = tbn * waterNormal;

		dist = length(worldPos);
		vec3 worldDir = -worldPos / dist;

		float opaqueDist = length(ViewPos_From_ScreenPos_LOD(gl_FragCoord.xy * UNIFORM_PIXEL_SIZE, texelFetch(vxDepthTexOpaque, ivec2(gl_FragCoord.xy), 0).x));
		dist = opaqueDist - dist;

		//#if defined PT_OCCLUDED_WATER_SPECULAR && defined DIMENSION_OVERWORLD
		//	if (dist > 0.0) imageAtomicMin(img_waterDepth2D, ivec2(gl_FragCoord.xy), floatBitsToUint(100000.0));
		//#endif
	}

//output
	vec2 normalEnc = EncodeNormal(waterNormal);

	framebuffer_gtransData = vec4(Pack2xU8_to_U16(albedo.rg), Pack2xU8_to_U16(albedo.ba), Pack2xU8_to_U16(vec2(1.0, (materialIDs + 128.0) / 255.0)), Pack2xU8_to_U16(blockLight + 1e-6));
	framebuffer_gtransNormal = vec4(normalEnc, EncodeNormal(tbn[2]));
    framebuffer_gwater = vec4(normalEnc, Pack2xU8_to_U16(vec2(dist * 0.02, blockLight.y + 1e-6)), float(isWater));
}
