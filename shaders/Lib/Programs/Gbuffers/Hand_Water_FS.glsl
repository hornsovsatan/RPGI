//Hand_Water_FS


#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


uniform sampler2D tex;
uniform sampler2D normals;
uniform sampler2D specular;


/* RENDERTARGETS: 0,3,4 */
layout(location = 0) out vec4 framebuffer_albedo;
layout(location = 1) out vec4 framebuffer_gtransData;
layout(location = 2) out vec4 framebuffer_gtransNormal;


in vec3 v_color;
in vec2 v_texCoord;
in vec3 v_worldPos;
in float v_blockLight;


#if defined SUPER_RESOLUTION || defined CUSTOM_RENDER_RESOLUTION
	#include "/Lib/FidelityFX/FSR2/GbufferScale.glsl"
#endif


vec4 sampleSpecular(vec2 coord, vec2 duv1, vec2 duv2){
	#ifdef TERRAIN_SPECULAR_MAP
		return textureGrad(specular, coord, duv1, duv2);
	#else
		return vec4(0.0);
	#endif
}


void main(){
//TBN
	vec2 duv1 = dFdx(v_texCoord);
	vec2 duv2 = dFdy(v_texCoord);
	
	vec3 dp1 = dFdx(v_worldPos);
	vec3 dp2 = dFdy(v_worldPos);

	#if defined SUPER_RESOLUTION || defined CUSTOM_RENDER_RESOLUTION
		if (FsrDiscardFS(gl_FragCoord.xy)) discard;
	#endif

	vec3 N = normalize(cross(dp1, dp2));
	vec3 dp2perp = cross(dp2, N);
	vec3 dp1perp = cross(N, dp1);
	vec3 T = normalize(dp2perp * duv1.x + dp1perp * duv2.x);
	vec3 B = normalize(dp2perp * duv1.y + dp1perp * duv2.y);
	float invmax = inversesqrt(max(dot(T, T), dot(B, B)));
	mat3 v_tbn = mat3(T * invmax, B * invmax, N);


//albedo
	vec4 albedo = textureGrad(tex, v_texCoord, duv1, duv2);

	if (albedo.a == 0.0) discard;

	albedo.rgb *= v_color;

	#if WHITE_DEBUG_WORLD > 0
		albedo.rgb = vec3(1.0);
	#endif


//wet effect
	#ifdef ENABLE_ROUGH_SPECULAR
		#ifdef DIMENSION_OVERWORLD
			#ifndef DISABLE_LOCAL_PRECIPITATION
				float wet = wetness * (1.0 - eyeSnowySmooth) * (1.0 - eyeNoPrecipitationSmooth) + SURFACE_WETNESS;
			#else
				float wet = wetness + SURFACE_WETNESS;
			#endif
			wet *= 0.5;
			wet *= saturate(blockLight.y * 10.0 - 9.0);
			wet *= saturate(v_tbn[2].y * 0.5 + 0.5);
		#else
			float wet = SURFACE_WETNESS;
			wet *= 0.5;
			wet *= saturate(v_tbn[2].y * 0.5 + 0.5);
		#endif

	#else
		float wet = 0.0;
	#endif


//normal
	#ifdef MC_NORMAL_MAP
		vec3 normalTex = DecodeNormalTex(textureGrad(normals, v_texCoord, duv1, duv2).rgb);
		#ifdef ENABLE_ROUGH_SPECULAR 
			normalTex = mix(normalTex, vec3(0.0, 0.0, 1.0), saturate(wet * 1.5));
		#endif
	#else
		vec3 normalTex = vec3(0.0, 0.0, 1.0);
	#endif

	vec3 worldNormal = v_tbn * normalize(normalTex);

	#ifdef HAND_NORMAL_CLAMP
		vec3 worldDir = -normalize(v_worldPos);
		worldNormal = normalize(worldNormal + v_tbn[2] * inversesqrt(saturate(dot(worldNormal, worldDir)) + 0.001));
	#endif


//output
	vec4 specularTex = sampleSpecular(v_texCoord, duv1, duv2);

	vec2 albedoEnc;
	vec2 materialEnc = vec2(specularTex.r, MATID_STAINEDGLASS / 255.0);

	if (albedo.a == 1.0){
		#if defined MC_SPECULAR_MAP && TEXTURE_PBR_FORMAT == 2
			specularTex.a = specularTex.b;
		#endif

		#ifdef LABPBR_EMISSIVENESS
			#if TEXTURE_PBR_FORMAT < 2
				specularTex.a -= step(1.0, specularTex.a);
			#endif
			//#if HARDCODED_EMISSIVENESS_MODE > 0
			//	specularTex.a = max(specularTex.a, v_emissiveness);
			//#endif
		#else
			specularTex.a = 0.0;
		#endif
		
		#ifdef ENABLE_ROUGH_SPECULAR
			specularTex.r = mix(specularTex.r, 1.0, wet);
		#endif

		albedoEnc = vec2(Pack2xU8_to_U16(specularTex.rg), Pack2xU8_to_U16(specularTex.ba));
		materialEnc = vec2(1.0, MATID_SOLID_TRANS_HAND / 255.0);
	}else{
		albedoEnc = vec2(Pack2xU8_to_U16(albedo.rg), Pack2xU8_to_U16(albedo.ba));
		albedo.a = 0.0;
	}

	framebuffer_albedo = albedo;
	framebuffer_gtransData = vec4(albedoEnc, Pack2xU8_to_U16(materialEnc), Pack2xU8_to_U16(vec2(0.0, saturate(v_blockLight + 1e-6))));
	framebuffer_gtransNormal = vec4(EncodeNormal(worldNormal), EncodeNormal(v_tbn[2]));}
