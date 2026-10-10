//DH_Terrain_FS


#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


/* RENDERTARGETS: 3,4,5 */
layout(location = 0) out vec4 framebuffer_gtransData;
layout(location = 1) out vec4 framebuffer_gtransNormal;
layout(location = 2) out vec4 framebuffer_gwater;

#ifdef DIMENSION_OVERWORLD
	layout(r32ui) uniform uimage2D img_waterDepth2D;
#endif


in vec4 v_color;
in vec3 v_worldPos;
in mat3 v_tbn;
in float v_blockLight;
flat in float v_materialIDs;


#if defined SUPER_RESOLUTION || defined CUSTOM_RENDER_RESOLUTION
	#include "/Lib/FidelityFX/FSR2/GbufferScale.glsl"
#endif
#include "/Lib/BasicFunctions/TemporalNoise.glsl"

#include "/Lib/IndividualFunctions/WaterWaves.glsl"
#include "/Lib/IndividualFunctions/Ripple.glsl"


vec3 ViewPos_From_ScreenPos_LOD(vec2 coord, float depth){
	#if defined TAA || defined SUPER_RESOLUTION
		coord -= UNIFORM_TAA_JITTER * 0.5;
	#endif
	vec3 ndcPos = vec3(coord, depth) * 2.0 - 1.0;
	vec3 viewPos = vec3(vec2(gbufferProjectionInverse0.x, gbufferProjectionInverse0.y) * ndcPos.xy, 0.0) + lodProjectionInverse1;
	return viewPos / (lodProjectionInverse0.x * ndcPos.z + lodProjectionInverse0.y);
}

float LinearDepth_From_ScreenDepth_LOD(float depth){
	depth = depth * 2.0 - 1.0;
	return 1.0 / (depth * lodProjectionInverse0.x + lodProjectionInverse0.y);
}


void DH_noise(inout vec4 color, vec3 pos){
	const float steps = DH_TEXTURE_NOISE_STEPS;
	pos = floor(pos * steps) / steps;
	
	float weight = Luminance(color.rgb) * 2.0 - 1.0;
	weight = 1.0 - weight * weight;
	weight *= DH_TEXTURE_NOISE_STRENGTH * color.a;

	float noise = fract(sin(dot(pos.xy + fract(sin(pos.z * (91.3458)) * 47453.5453), vec2(12.9898, 78.233))) * 43758.5453);
	noise = (noise * 2.0 - 1.0) * weight;

	color.rgb = saturate(color.rgb - color.rgb * noise);
}


void main(){
	#if defined SUPER_RESOLUTION || defined CUSTOM_RENDER_RESOLUTION
		if (FsrDiscardFS(gl_FragCoord.xy)) discard;
	#endif

	float opaqueDepth = texelFetch(depthtex0, ivec2(gl_FragCoord.xy), 0).x;

	#ifdef DH_TERRAIN_CULLING
		if (length(v_worldPos) < far * 0.7 || opaqueDepth < 1.0) discard;
	#else
		if (opaqueDepth < 1.0) discard;
	#endif

//albedo
	vec4 albedo = v_color;
	#ifdef DH_TEXTURE_NOISE
		DH_noise(albedo, v_worldPos + cameraPosition + v_tbn[2] * 0.001);
	#endif

	#if WHITE_DEBUG_WORLD > 0
		albedo.rgb = vec3(WHITE_DEBUG_WORLD * 0.1);
	#endif

//wet effect
	vec3 mcPos = v_worldPos + cameraPosition;

//normal
	bool isWater = v_materialIDs == MATID_WATER;
	float dist = 0.0;
	vec3 waterNormal = v_tbn[2];

	if (isWater){
		float waterDist = LinearDepth_From_ScreenDepth_LOD(gl_FragCoord.z);
		float parallaxWaterDist = waterDist;
		#ifdef WAVE_PARALLAX
			vec3 viewVector = v_worldPos - gbufferModelViewInverse[3].xyz;
			float noise = BlueNoiseTemporal().x;

			mcPos = WaveParallax(mcPos, viewVector, v_tbn[2].y, noise, parallaxWaterDist);
		#endif
		float NdotU = saturate(waterNormal.y + float(isEyeInWater == 1) * 2.0);
		waterNormal = WaveNormal(mcPos, NdotU * 13.0 + 5.0);

		waterNormal = v_tbn * waterNormal;


		dist = length(v_worldPos);

		float opaqueDist = length(ViewPos_From_ScreenPos_LOD(gl_FragCoord.xy * UNIFORM_PIXEL_SIZE, opaqueDepth));
		dist = opaqueDist - dist;

		#ifdef DIMENSION_OVERWORLD
			if (dist > 0.0){
				ivec2 drawTexel = ivec2(gl_FragCoord.xy);
				imageAtomicMin(img_waterDepth2D, drawTexel, floatBitsToUint(parallaxWaterDist));
				#ifdef PT_OCCLUDED_WATER_SPECULAR
					drawTexel.y += int(screenSize.y);
					imageAtomicMin(img_waterDepth2D, drawTexel, floatBitsToUint(waterDist));
				#endif
			}
		#endif
	}

	vec2 normalEnc = EncodeNormal(waterNormal);


	framebuffer_gtransData = vec4(Pack2xU8_to_U16(albedo.rg), Pack2xU8_to_U16(albedo.ba), Pack2xU8_to_U16(vec2(1.0, (v_materialIDs + 128.0) / 255.0)), Pack2xU8_to_U16(vec2(0.0, saturate(v_blockLight + 1e-6))));
	framebuffer_gtransNormal = vec4(normalEnc, EncodeNormal(v_tbn[2]));
	framebuffer_gwater = vec4(normalEnc, Pack2xU8_to_U16(vec2(dist * 0.02, v_blockLight + 1e-6)), float(isWater));
}