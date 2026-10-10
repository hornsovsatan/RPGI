

#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


#ifdef SUPER_RESOLUTION
/*
const int 	colortex7Format 		= RGBA16F;
const int 	colortex15Format 		= RGBA8;

const bool	colortex15Clear 		= false;
*/
#else



#ifdef RENDERING_MODE
/*
const int 	colortex7Format 		= RGBA32F;
*/
#else
#ifdef DIMENSION_NETHER
/*
const int 	colortex7Format 		= RGBA32F;
*/
#else
/*
const int 	colortex7Format 		= RGBA16F;
*/
#endif
#endif
#endif

#if defined VS_VELOCITY && defined SR_IRIS_EXT_VELOCITY
/*
const int 	colortex16Format 		= RGBA16F;
const bool	colortex16Clear 		= true;
*/
#endif

#if SR_ENABLE == 1
/*
const int 	colortex17Format 		= RGBA16F;
const bool	colortex17Clear 		= false;
*/
#if SR_USING_ALGO == SR_ALGO_DLSSRR
/*
const int 	colortex18Format 		= RGBA16F;
const int 	colortex19Format 		= RGBA16F;
const int 	colortex20Format 		= RGBA16F;
const int 	colortex21Format 		= R32F;
const int 	colortex22Format 		= R16F;

const int 	colortex18Clear 		= true;
const int 	colortex19Clear 		= true;
const int 	colortex20Clear 		= true;
const int 	colortex21Clear 		= true;
const int 	colortex22Clear 		= true;
*/
#endif
#endif

#ifdef HDR_ENABLED
/*
const int 	colortex0Format 		= RGBA16F;
*/
#else
/*
const int 	colortex0Format 		= RGBA8;
*/
#endif

/*
const int 	colortex1Format 		= RGBA16;
const int 	colortex2Format 		= RGBA16;
const int 	colortex3Format 		= RGBA16;
const int 	colortex4Format 		= RGBA16;
const int 	colortex5Format 		= RGBA16;
const int 	colortex6Format 		= RGBA16F;
const int 	colortex8Format 		= RGBA16F;
const int 	colortex9Format 		= RGBA16F;
const int 	colortex10Format 		= RGBA16F;
const int 	colortex11Format 		= RGBA16F;
const int 	colortex12Format 		= RG16;


const bool	colortex0Clear 			= true;
const vec4	colortex0ClearColor 	= vec4(0.0, 0.0, 0.0, 1.0);
const bool	colortex1Clear 			= true;
const vec4	colortex1ClearColor 	= vec4(0.0, 0.0, 0.0, 0.0);
const bool	colortex2Clear 			= true;
const bool	colortex3Clear 			= true;
const bool	colortex4Clear 			= true;
const bool	colortex5Clear 			= true;
const bool	colortex6Clear 			= true;
const bool	colortex7Clear 			= false;
const bool	colortex8Clear 			= true;
const bool	colortex9Clear 			= false;
const bool	colortex10Clear 		= false;
const bool	colortex11Clear 		= false;
const bool	colortex12Clear 		= false;


const float shadowIntervalSize 			= 4.0;
const float shadowDistanceRenderMul 	= 1.0;

const bool 	shadowHardwareFiltering0 	= false;
const bool 	shadowHardwareFiltering1 	= false;
const bool 	shadowtex0Mipmap 			= false;
const bool 	shadowtex0Nearest 			= false;
const bool 	shadowtex1Mipmap 			= false;
const bool 	shadowtex1Nearest 			= false;
const bool 	shadowcolor0Mipmap 			= false;
const bool 	shadowcolor0Nearest 		= false;


const int 	noiseTextureResolution 	= 64;

const float wetnessHalflife 		= 10.0; 	//[10.0 20.0 30.0 50.0 75.0 100.0 150.0 200.0 300.0 500.0]
const float drynessHalflife 		= 10.0; 	//[10.0 20.0 30.0 50.0 75.0 100.0 150.0 200.0 300.0 500.0]
const float eyeBrightnessHalflife 	= 10.0;

const float sunPathRotation 		= -35.0; 	// [-90.0 -89.0 -88.0 -87.0 -86.0 -85.0 -84.0 -83.0 -82.0 -81.0 -80.0 -79.0 -78.0 -77.0 -76.0 -75.0 -74.0 -73.0 -72.0 -71.0 -70.0 -69.0 -68.0 -67.0 -66.0 -65.0 -64.0 -63.0 -62.0 -61.0 -60.0 -59.0 -58.0 -57.0 -56.0 -55.0 -54.0 -53.0 -52.0 -51.0 -50.0 -49.0 -48.0 -47.0 -46.0 -45.0 -44.0 -43.0 -42.0 -41.0 -40.0 -39.0 -38.0 -37.0 -36.0 -35.0 -34.0 -33.0 -32.0 -31.0 -30.0 -29.0 -28.0 -27.0 -26.0 -25.0 -24.0 -23.0 -22.0 -21.0 -20.0 -19.0 -18.0 -17.0 -16.0 -15.0 -14.0 -13.0 -12.0 -11.0 -10.0 -9.0 -8.0 -7.0 -6.0 -5.0 -4.0 -3.0 -2.0 -1.0 0.0 1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0 11.0 12.0 13.0 14.0 15.0 16.0 17.0 18.0 19.0 20.0 21.0 22.0 23.0 24.0 25.0 26.0 27.0 28.0 29.0 30.0 31.0 32.0 33.0 34.0 35.0 36.0 37.0 38.0 39.0 40.0 41.0 42.0 43.0 44.0 45.0 46.0 47.0 48.0 49.0 50.0 51.0 52.0 53.0 54.0 55.0 56.0 57.0 58.0 59.0 60.0 61.0 62.0 63.0 64.0 65.0 66.0 67.0 68.0 69.0 70.0 71.0 72.0 73.0 74.0 75.0 76.0 77.0 78.0 79.0 80.0 81.0 82.0 83.0 84.0 85.0 86.0 87.0 88.0 89.0 90.0]

const float ambientOcclusionLevel 	= 1.0;
const int 	superSamplingLevel 		= 0;
*/


#ifdef EYES_LIGHTING
#endif
#ifdef ENTITIES_VS_TBN
#endif
#ifdef ENTITIES_PARALLAX
#endif
#ifdef ENTITIES_STATUS_COLOR
#endif
#ifdef PT_TAG_DETECTION
#endif
#ifdef HAND_SCREEN_SHADOW
#endif
#ifdef DISABLE_HAND_DOF
#endif
#ifdef DECREASE_HAND_GHOSTING
#endif
#ifdef MOTION_BLUR
#endif
#ifdef DISABLE_PLAYER_TAA_MOTION_BLUR
#endif
#ifdef PT_DIFFUSE_SST_REPORJECT
#endif
#ifdef PT_SPECULAR_SCREEN_REUSE
#endif
#ifdef TAA_SUBPIXEL_SHARPNING
#endif
#ifdef RENDERING_MODE_MOTION_VALIDATION
#endif
#ifdef WAVEFORM_SCOPE
#endif
#ifdef LABPBR_PREDEFINED_METAL
#endif
#ifdef FSR2_QUALITY
#endif
#ifdef FSR2_BALANCE
#endif
#ifdef FSR2_PERFORMANCE
#endif
#ifdef FSR2_SUPER_PERFORMANCE
#endif

uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;

uniform sampler3D voxelData3D;

#ifdef PT_IRC
	uniform sampler3D irradianceCache3D;
	uniform sampler3D irradianceCache3D_Alt;
#endif

/* RENDERTARGETS: 6 */
layout(location = 0) out vec4 framebuffer_mainOutput;

layout(rgba16f) writeonly uniform image2D FBIMG_SST_TEMPORAL;

#if SR_ENABLE == 1 && SR_USING_ALGO == SR_ALGO_DLSSRR
	layout (rgba16f) writeonly uniform image2D colorimg18;
	layout (rgba16f) uniform image2D colorimg20;
#endif

ivec2 texelCoord = ivec2(gl_FragCoord.xy);
vec2 texCoord = gl_FragCoord.xy * UNIFORM_PIXEL_SIZE;

#ifdef DIMENSION_END
	const vec3 worldShadowVector = shadowModelViewInverseEnd[2];
	vec3 shadowVector = worldShadowVector * mat3(gbufferModelViewInverse);
#elif defined DIMENSION_OVERWORLD
	in vec3 worldShadowVector;
	in vec3 shadowVector;

	in vec3 colorShadowlight;
#endif


#include "/Lib/GbufferData.glsl"
#include "/Lib/Uniform/GbufferTransforms.glsl"

#include "/Lib/PathTracing/Voxelizer/VoxelProfile.glsl"
#include "/Lib/Uniform/ShadowTransforms.glsl"
#include "/Lib/PathTracing/Tracer/TracingUtilities.glsl"
#include "/Lib/PathTracing/Voxelizer/BlockShape.glsl"
#include "/Lib/PathTracing/Tracer/ShadowTracing.glsl"

#include "/Lib/BasicFunctions/TemporalNoise.glsl"
#include "/Lib/BasicFunctions/PrecomputedAtmosphere.glsl"
#include "/Lib/BasicFunctions/Blocklight.glsl"
#include "/Lib/BasicFunctions/HeldLight.glsl"
#ifndef DIMENSION_NETHER
	#include "/Lib/BasicFunctions/Sunlight_Shadow.glsl"
#endif

#ifdef DIMENSION_END
	#include "/Lib/IndividualFunctions/EndSkyTimer.glsl"
#endif


////////////////////////////// Main //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////// Main //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////// Main //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#ifdef PT_IRC
vec4 SampleIrradianceCache_Raw_OutBlocker(ivec3 ircTexel, float sampleWeight, out float blocker){
	vec4 ircColor = texelFetch(irradianceCache3D, ircTexel, 0);
	blocker = saturate(ircColor.a);
	ircColor = vec4(ircColor.rgb * sampleWeight, float(dot(ircColor.rgb, vec3(1.0)) > 0.0) * sampleWeight);
	return ircColor - blocker * ircColor;
}

vec4 SampleIrradianceCache_Raw_Blocker(ivec3 ircTexel, float sampleWeight){
	vec4 ircColor = texelFetch(irradianceCache3D, ircTexel, 0);
	sampleWeight *= saturate(1.0 - ircColor.a);
	return vec4(ircColor.rgb * sampleWeight, float(dot(ircColor.rgb, vec3(1.0)) > 0.0) * sampleWeight);
}

vec4 SampleIrradianceCache_Raw(ivec3 ircTexel, float sampleWeight){
	vec3 ircColor = texelFetch(irradianceCache3D, ircTexel, 0).rgb;
	return vec4(ircColor * sampleWeight, float(dot(ircColor, vec3(1.0)) > 0.0) * sampleWeight);
}

vec4 SampleIrradianceCache_Raw_OutBlocker_Alt(ivec3 ircTexel, float sampleWeight, out float blocker){
	vec4 ircColor = texelFetch(irradianceCache3D_Alt, ircTexel, 0);
	blocker = saturate(ircColor.a);
	ircColor = vec4(ircColor.rgb * sampleWeight, float(dot(ircColor.rgb, vec3(1.0)) > 0.0) * sampleWeight);
	return ircColor - blocker * ircColor;
}

vec4 SampleIrradianceCache_Raw_Blocker_Alt(ivec3 ircTexel, float sampleWeight){
	vec4 ircColor = texelFetch(irradianceCache3D_Alt, ircTexel, 0);
	sampleWeight *= saturate(1.0 - ircColor.a);
	return  vec4(ircColor.rgb * sampleWeight, float(dot(ircColor.rgb, vec3(1.0)) > 0.0) * sampleWeight);
}

vec4 SampleIrradianceCache_Raw_Alt(ivec3 ircTexel, float sampleWeight){
	vec3 ircColor = texelFetch(irradianceCache3D_Alt, ircTexel, 0).rgb;
	return vec4(ircColor * sampleWeight, float(dot(ircColor, vec3(1.0)) > 0.0) * sampleWeight);
}

vec3 SampleIrradianceCache(vec3 hitVoxelPos){
	ivec3 ircTexel = ivec3(hitVoxelPos) + ((ircResolutionInt - voxelResolutionInt) >> 1);
	vec3 ircColor = vec3(0.0);
	if ((frameCounter & 1) == 0){
		ircColor = texelFetch(irradianceCache3D, ircTexel, 0).rgb;
	}else{
		ircColor = texelFetch(irradianceCache3D_Alt, ircTexel, 0).rgb;
	}
	return ircColor * 0.01;
}

vec3 SampleIrradianceCache_Full_Smooth(vec3 hitVoxelPos, vec3 hitNormal){
	ivec3 hitVoxelCoord = ivec3(hitVoxelPos);
	ivec3 ircTexel = hitVoxelCoord + ((ircResolutionInt - voxelResolutionInt) >> 1);
	vec4 ircColor = vec4(0.0);

	if (clamp(ircTexel, ivec3(1), ircResolutionInt - 2) == ircTexel){
		vec3 centerOffset = vec3(hitVoxelCoord) + 0.5 - hitVoxelPos;

		hitNormal = abs(hitNormal);
		hitNormal.xy = step(maxVec3(hitNormal), hitNormal.xz);
		vec3 T = vec3(1.0 - hitNormal.x, hitNormal.x, 0.0);
		vec3 B = vec3(0.0, hitNormal.y, 1.0 - hitNormal.y);

		float blocker = 0.0;

		if ((frameCounter & 1) == 0){
			vec3 sampleOffset = centerOffset;
			float sampleWeight = exp2(-dot(sampleOffset, sampleOffset) * PT_IRC_BLUR_FACTOR);
			ircColor += SampleIrradianceCache_Raw(ircTexel, sampleWeight);

			sampleOffset = centerOffset -T;
			sampleWeight = exp2(-dot(sampleOffset, sampleOffset) * PT_IRC_BLUR_FACTOR);
			ircColor += SampleIrradianceCache_Raw_OutBlocker(ircTexel + ivec3(-T), sampleWeight, blocker);

			float blocker00 = blocker;
			float blocker01 = blocker;

			sampleOffset = centerOffset -B;
			sampleWeight = exp2(-dot(sampleOffset, sampleOffset) * PT_IRC_BLUR_FACTOR);
			ircColor += SampleIrradianceCache_Raw_OutBlocker(ircTexel + ivec3(-B), sampleWeight, blocker);

			blocker00 += blocker;
			float blocker10 = blocker;

			if (blocker00 < 1.5){
				sampleOffset = centerOffset -T -B;
				sampleWeight = exp2(-dot(sampleOffset, sampleOffset) * PT_IRC_BLUR_FACTOR);
				ircColor += SampleIrradianceCache_Raw_Blocker(ircTexel + ivec3(-T -B), sampleWeight);
			}

			sampleOffset = centerOffset +T;
			sampleWeight = exp2(-dot(sampleOffset, sampleOffset) * PT_IRC_BLUR_FACTOR);
			ircColor += SampleIrradianceCache_Raw_OutBlocker(ircTexel + ivec3(T), sampleWeight, blocker);

			blocker10 += blocker;
			float blocker11 = blocker;

			if (blocker10 < 1.5){
				sampleOffset = centerOffset +T -B;
				sampleWeight = exp2(-dot(sampleOffset, sampleOffset) * PT_IRC_BLUR_FACTOR);
				ircColor += SampleIrradianceCache_Raw_Blocker(ircTexel + ivec3(T -B), sampleWeight);
			}

			sampleOffset = centerOffset +B;
			sampleWeight = exp2(-dot(sampleOffset, sampleOffset) * PT_IRC_BLUR_FACTOR);
			ircColor += SampleIrradianceCache_Raw_OutBlocker(ircTexel + ivec3(B), sampleWeight, blocker);

			blocker01 += blocker;
			blocker11 += blocker;

			if (blocker01 < 1.5){
				sampleOffset = centerOffset -T +B;
				sampleWeight = exp2(-dot(sampleOffset, sampleOffset) * PT_IRC_BLUR_FACTOR);
				ircColor += SampleIrradianceCache_Raw_Blocker(ircTexel + ivec3(-T +B), sampleWeight);
			}

			if (blocker11 < 1.5){
				sampleOffset = centerOffset +T +B;
				sampleWeight = exp2(-dot(sampleOffset, sampleOffset) * PT_IRC_BLUR_FACTOR);
				ircColor += SampleIrradianceCache_Raw_Blocker(ircTexel + ivec3(T +B), sampleWeight);
			}
		}else{
			vec3 sampleOffset = centerOffset;
			float sampleWeight = exp2(-dot(sampleOffset, sampleOffset) * PT_IRC_BLUR_FACTOR);
			ircColor += SampleIrradianceCache_Raw_Alt(ircTexel, sampleWeight);

			sampleOffset = centerOffset -T;
			sampleWeight = exp2(-dot(sampleOffset, sampleOffset) * PT_IRC_BLUR_FACTOR);
			ircColor += SampleIrradianceCache_Raw_OutBlocker_Alt(ircTexel + ivec3(-T), sampleWeight, blocker);

			float blocker00 = blocker;
			float blocker01 = blocker;

			sampleOffset = centerOffset -B;
			sampleWeight = exp2(-dot(sampleOffset, sampleOffset) * PT_IRC_BLUR_FACTOR);
			ircColor += SampleIrradianceCache_Raw_OutBlocker_Alt(ircTexel + ivec3(-B), sampleWeight, blocker);

			blocker00 += blocker;
			float blocker10 = blocker;

			if (blocker00 < 1.5){
				sampleOffset = centerOffset -T -B;
				sampleWeight = exp2(-dot(sampleOffset, sampleOffset) * PT_IRC_BLUR_FACTOR);
				ircColor += SampleIrradianceCache_Raw_Blocker_Alt(ircTexel + ivec3(-T -B), sampleWeight);
			}

			sampleOffset = centerOffset +T;
			sampleWeight = exp2(-dot(sampleOffset, sampleOffset) * PT_IRC_BLUR_FACTOR);
			ircColor += SampleIrradianceCache_Raw_OutBlocker_Alt(ircTexel + ivec3(T), sampleWeight, blocker);

			blocker10 += blocker;
			float blocker11 = blocker;

			if (blocker10 < 1.5){
				sampleOffset = centerOffset +T -B;
				sampleWeight = exp2(-dot(sampleOffset, sampleOffset) * PT_IRC_BLUR_FACTOR);
				ircColor += SampleIrradianceCache_Raw_Blocker_Alt(ircTexel + ivec3(T -B), sampleWeight);
			}

			sampleOffset = centerOffset +B;
			sampleWeight = exp2(-dot(sampleOffset, sampleOffset) * PT_IRC_BLUR_FACTOR);
			ircColor += SampleIrradianceCache_Raw_OutBlocker_Alt(ircTexel + ivec3(B), sampleWeight, blocker);

			blocker01 += blocker;
			blocker11 += blocker;

			if (blocker01 < 1.5){
				sampleOffset = centerOffset -T +B;
				sampleWeight = exp2(-dot(sampleOffset, sampleOffset) * PT_IRC_BLUR_FACTOR);
				ircColor += SampleIrradianceCache_Raw_Blocker_Alt(ircTexel + ivec3(-T +B), sampleWeight);
			}

			if (blocker11 < 1.5){
				sampleOffset = centerOffset +T +B;
				sampleWeight = exp2(-dot(sampleOffset, sampleOffset) * PT_IRC_BLUR_FACTOR);
				ircColor += SampleIrradianceCache_Raw_Blocker_Alt(ircTexel + ivec3(T +B), sampleWeight);
			}
		}

		ircColor.rgb *= 0.01 / max(ircColor.a, 1e-10);
	}else{
		ircColor.r = 0.1;
	}

	return ircColor.rgb;
}



vec3 SampleIrradianceCache_Bilinear_Blocker(vec3 hitVoxelPos){
	vec3 ircColor = vec3(0.0);

	vec3 ircTexelCoord = hitVoxelPos + vec3((ircResolutionInt - voxelResolutionInt) >> 1);
	ivec3 ircTexel = ivec3(ircTexelCoord);

	if (clamp(ircTexel, ivec3(1), ircResolutionInt - 2) == ircTexel){
		vec3 p = floor(ircTexelCoord + 0.5);
		vec3 f = saturate(ircTexelCoord + 0.5 - p);
		f = curve(f);

		vec3 axis = fsign(p - ircTexelCoord);
		f = mix(1.0 - f, f, axis * 0.5 + 0.5);
		vec3 rf = 1.0 - f;

		ivec3 iaxis = ivec3(axis);

		if ((frameCounter & 1) == 0){
			vec3 ircColor000 = texelFetch(irradianceCache3D, ivec3(ircTexel.x, ircTexel.y, ircTexel.z), 0).rgb;
			ircColor += ircColor000 * rf.x * rf.y * rf.z;

			vec4 ircColor100 = texelFetch(irradianceCache3D, ivec3(ircTexel.x + iaxis.x, ircTexel.y, ircTexel.z), 0);
			vec4 ircColor001 = texelFetch(irradianceCache3D, ivec3(ircTexel.x, ircTexel.y, ircTexel.z + iaxis.z), 0);
			float blocker = saturate(ircColor100.a) + saturate(ircColor001.a) * 2.0;

			vec4 ircColor010 = texelFetch(irradianceCache3D, ivec3(ircTexel.x, ircTexel.y + iaxis.y, ircTexel.z), 0);
			blocker += saturate(ircColor010.a) * 4.0;

			if (blocker < 6.5){
				vec4 ircColor101 = texelFetch(irradianceCache3D, ivec3(ircTexel.x + iaxis.x, ircTexel.y, ircTexel.z + iaxis.z), 0);
				blocker += saturate(ircColor101.a) * 8.0;

				vec4 ircColor110 = texelFetch(irradianceCache3D, ivec3(ircTexel.x + iaxis.x, ircTexel.y + iaxis.y, ircTexel.z), 0);
				blocker += saturate(ircColor110.a) * 16.0;

				vec4 ircColor011 = texelFetch(irradianceCache3D, ivec3(ircTexel.x, ircTexel.y + iaxis.y, ircTexel.z + iaxis.z), 0);
				blocker += saturate(ircColor011.a) * 32.0;

				int iblocker = int(round(blocker));
				if ((iblocker & 30) == 30){
					ircColor += ircColor100.rgb * f.x * rf.y * rf.z;

				}else if ((iblocker & 45) == 45){
					ircColor += ircColor001.rgb * rf.x * rf.y * f.z;

				}else if ((iblocker & 51) == 51){
					ircColor += ircColor010.rgb * rf.x * f.y * rf.z;

				}else{
					ircColor += ircColor100.rgb *  f.x * rf.y * rf.z;
					ircColor += ircColor001.rgb * rf.x * rf.y *  f.z;
					ircColor += ircColor010.rgb * rf.x *  f.y * rf.z;
					ircColor += ircColor101.rgb *  f.x * rf.y *  f.z;
					ircColor += ircColor110.rgb *  f.x *  f.y * rf.z;
					ircColor += ircColor011.rgb * rf.x *  f.y *  f.z;

					vec3 ircColor111 = texelFetch(irradianceCache3D, ivec3(ircTexel.x + iaxis.x, ircTexel.y + iaxis.y, ircTexel.z + iaxis.z), 0).rgb;
					ircColor += ircColor111.rgb * f.x * f.y * f.z;
				}
			}
		}else{
			vec3 ircColor000 = texelFetch(irradianceCache3D_Alt, ivec3(ircTexel.x, ircTexel.y, ircTexel.z), 0).rgb;
			ircColor += ircColor000 * rf.x * rf.y * rf.z;

			vec4 ircColor100 = texelFetch(irradianceCache3D_Alt, ivec3(ircTexel.x + iaxis.x, ircTexel.y, ircTexel.z), 0);
			vec4 ircColor001 = texelFetch(irradianceCache3D_Alt, ivec3(ircTexel.x, ircTexel.y, ircTexel.z + iaxis.z), 0);
			float blocker = saturate(ircColor100.a) + saturate(ircColor001.a) * 2.0;

			vec4 ircColor010 = texelFetch(irradianceCache3D_Alt, ivec3(ircTexel.x, ircTexel.y + iaxis.y, ircTexel.z), 0);
			blocker += saturate(ircColor010.a) * 4.0;

			if (blocker < 6.5){
				vec4 ircColor101 = texelFetch(irradianceCache3D_Alt, ivec3(ircTexel.x + iaxis.x, ircTexel.y, ircTexel.z + iaxis.z), 0);
				blocker += saturate(ircColor101.a) * 8.0;

				vec4 ircColor110 = texelFetch(irradianceCache3D_Alt, ivec3(ircTexel.x + iaxis.x, ircTexel.y + iaxis.y, ircTexel.z), 0);
				blocker += saturate(ircColor110.a) * 16.0;

				vec4 ircColor011 = texelFetch(irradianceCache3D_Alt, ivec3(ircTexel.x, ircTexel.y + iaxis.y, ircTexel.z + iaxis.z), 0);
				blocker += saturate(ircColor011.a) * 32.0;

				int iblocker = int(round(blocker));
				if ((iblocker & 30) == 30){
					ircColor += ircColor100.rgb * f.x * rf.y * rf.z;

				}else if ((iblocker & 45) == 45){
					ircColor += ircColor001.rgb * rf.x * rf.y * f.z;

				}else if ((iblocker & 51) == 51){
					ircColor += ircColor010.rgb * rf.x * f.y * rf.z;

				}else{
					ircColor += ircColor100.rgb *  f.x * rf.y * rf.z;
					ircColor += ircColor001.rgb * rf.x * rf.y *  f.z;
					ircColor += ircColor010.rgb * rf.x *  f.y * rf.z;
					ircColor += ircColor101.rgb *  f.x * rf.y *  f.z;
					ircColor += ircColor110.rgb *  f.x *  f.y * rf.z;
					ircColor += ircColor011.rgb * rf.x *  f.y *  f.z;

					vec3 ircColor111 = texelFetch(irradianceCache3D_Alt, ivec3(ircTexel.x + iaxis.x, ircTexel.y + iaxis.y, ircTexel.z + iaxis.z), 0).rgb;
					ircColor += ircColor111.rgb * f.x * f.y * f.z;
				}
			}
		}
	}

	return ircColor;
}




#endif


void main(){
	float depth = uintBitsToFloat(texelFetch(depthtexS, texelCoord, 0).x);

	#ifdef LOD_RENDERING
		bool isDH = depth == 1.0;
		if (isDH) depth = texelFetch(LOD_DEPTH_TEX_1, texelCoord, 0).x;
	#endif

	if (depth < 1.0){

		GbufferData gbuffer 		= GetGbufferDataSoild();
		MaterialMask materialMask 	= CalculateMasks(gbuffer.materialID);

		#if SR_ENABLE == 1 && SR_USING_ALGO == SR_ALGO_DLSSRR
			imageStore(colorimg18, texelCoord, vec4(gbuffer.albedo, 0.0));
		#endif

		#ifdef DECREASE_HAND_GHOSTING
			if (materialMask.hand > 0.5)
				depth = depth * (4.0 / MC_HAND_DEPTH) - (2.0 / MC_HAND_DEPTH + 1.0);
		#endif

		vec3 viewPos 				= ViewPos_From_ScreenPos(texCoord, depth);
		#ifdef LOD_RENDERING
			if (isDH) viewPos 		= ViewPos_From_ScreenPos_LOD(texCoord, depth);
		#endif


		vec3 worldPos				= mat3(gbufferModelViewInverse) * viewPos;

		vec3 viewDir 				= normalize(viewPos);
		vec3 worldDir 				= normalize(worldPos);
		vec3 viewNormal 			= gbuffer.worldNormal * mat3(gbufferModelViewInverse);

		#ifdef LOD_RENDERING
			float farDist 				= max(LOD_FAR_PLANE, 1024.0);
		#else
			float farDist 				= max(far * 1.2, 1024.0);
		#endif

		float opaqueDist 			= depth < 1.0 ? length(viewPos) : farDist;
		#ifdef LOD_RENDERING
			float shadowmapRange = saturate(3.2 - opaqueDist / min(shadowDistance, far) * 4.0 - float(isDH) * 1e10);
		#else
			float shadowmapRange = saturate(3.2 - opaqueDist / min(shadowDistance, far) * 4.0);
		#endif

	/*
		#ifdef VOLUMETRIC_CLOUDS
			#ifdef CLOUD_SHADOW
				float cloudShadow = CloudShadowFromTex(worldPos);
			#else
				float cloudShadow = 1.0 - wetness * RAIN_SHADOW;
			#endif
		#else
			float cloudShadow = 1.0 - wetness * RAIN_SHADOW;
		#endif
	*/
		float cloudShadow = 1.0 - wetness * RAIN_SHADOW;

		vec3 color = vec3(0.0);

		#if SR_ENABLE == 0 || SR_USING_ALGO != SR_ALGO_DLSSRR
			#if defined DEBUG_IRC && defined PT_IRC
				vec3 voxelPos = worldPos + gbufferModelViewInverse[3].xyz + cameraPositionFract + (voxelResolution * 0.5);
				voxelPos += gbuffer.vertexNormal * (-viewPos.z * 0.0003);

				color += SampleIrradianceCache_Full_Smooth(voxelPos, gbuffer.vertexNormal);
				//color += SampleIrradianceCache(voxelPos);
				//color += SampleIrradianceCache_Bilinear_Blocker(voxelPos) * 0.01;
			#else
				color += texelFetch(FBTEX_MAIN_OUTPUT, texelCoord, 0).rgb * 0.01;
				//color += texelFetch(FBTEX_DIFFUSE_TEMPORAL, texelCoord, 0).rgb * 0.01;
			#endif
		#endif
	
		#if defined LABPBR_EMISSIVENESS || HARDCODED_EMISSIVENESS_MODE > 0
			vec3 textureLighting = TextureLighting(gbuffer.albedo, gbuffer.material.emissiveness, materialMask);
		#else
			vec3 textureLighting = vec3(0.0);
		#endif

		if(heldBlockLightValue + heldBlockLightValue2 > 0)
			color += HeldLighting(textureLighting, viewPos, viewDir, viewNormal, gbuffer.albedo, gbuffer.material.roughness, materialMask.hand > 0.5);


		#ifndef DIMENSION_NETHER
			gbuffer.material.scattering *= saturate(1.0 - materialMask.leaves - materialMask.grass);
			vec3 worldNormal = normalize(mix(gbuffer.worldNormal, vec3(0.0, 1.0, 0.0), materialMask.grass * 0.49));

			float sunlight = Fd_Burley(worldNormal, -worldDir, worldShadowVector, gbuffer.material.roughness);

			//float sunlightTrans = saturate(materialMask.leaves * 3.0) * 0.25 + materialMask.particle * 0.4 + materialMask.grass * 0.15;

			#ifdef SUNLIGHT_RIMS
				vec2 rims = ShadowRims(viewPos, worldDir, gbuffer.vertexNormal, depth, materialMask, worldPos);
			#endif
			//rims = vec2(0.0);

			float sunlightTrans = materialMask.leaves * 0.25 + materialMask.grass * 0.2;
			#ifdef SUNLIGHT_RIMS
				//sunlight = mix(max(sunlight, rims.y * (RIMS_TERRAIN_STRENGTH * 0.1)), 0.6 + rims.y * RIMS_PLANTS_STRENGTH * 0.0, sunlightTrans);

				sunlight = mix(sunlight, 0.6, sunlightTrans);

				if (sunlightTrans < 0.1){
					sunlight = max(sunlight, rims.y * (RIMS_TERRAIN_STRENGTH * 0.1));

				}else{
					sunlight = max(sunlight, rims.y * sunlightTrans * (RIMS_PLANTS_STRENGTH * 1.5));
				}
			#else
				sunlight = mix(sunlight, 0.6, sunlightTrans);
			#endif
			gbuffer.parallaxShadow = saturate(gbuffer.parallaxShadow + sunlightTrans * 1e10);


			#ifdef DIMENSION_OVERWORLD
				vec3 sunlightMult = colorShadowlight * cloudShadow;
				#ifdef CAVE_MODE
					sunlightMult *= mix(1.0, 0.1, eyeBrightnessZeroSmooth);
				#endif
			#else
				const vec3 blackbody = vec3(1.088, 0.979, 0.923);
				vec3 sunlightMult = (blackbody * SUNLIGHT_INTENSITY * 0.7) * (planetShadow * planetShadow);
			#endif

			vec3 shadow = sunlightMult;
			#if PARALLAX_MODE > 0 && !defined LABPBR_SSS
				shadow *= gbuffer.parallaxShadow;
			#endif
			#ifdef DIMENSION_OVERWORLD
			#ifdef SUNLIGHT_LEAK_FIX
				float lightMask = saturate(gbuffer.lightmap.g * 1e5 + float(isEyeInWater == 1));
				shadow *= lightMask;
			#endif
			#endif

			#ifdef LABPBR_SSS
				vec3 sss = vec3(0.0);
			#endif

			if ((sunlight + gbuffer.material.scattering) * shadow.x > 0.0){
				#ifdef LABPBR_SSS
					shadow *= VariablePenumbraShadow(worldPos, gbuffer.vertexNormal, -viewPos.z, sunlight, gbuffer.albedo, gbuffer.lightmap.g, gbuffer.material.scattering, materialMask, sss);
					#ifdef DIMENSION_OVERWORLD
					#ifdef SUNLIGHT_LEAK_FIX
						sss *= lightMask;
					#endif
					#endif
					color += sss * sunlightMult;
				#else
					shadow *= VariablePenumbraShadow(worldPos, gbuffer.vertexNormal, -viewPos.z, sunlight, gbuffer.albedo, gbuffer.lightmap.g, gbuffer.material.scattering, materialMask);
				#endif
			}

			#if PARALLAX_MODE > 0 && defined LABPBR_SSS
				shadow *= gbuffer.parallaxShadow;
			#endif


			bool isMetal = gbuffer.material.metalness > 229.5 / 255.0;


			float metalnessMask = float(isMetal);
			#ifdef DISABLE_HAND_SPECULAR
				if (materialMask.hand > 0.5) metalnessMask = 0.0;
			#elif defined DECREASE_HAND_SPECULAR
				if (materialMask.hand > 0.5){
					metalnessMask *= saturate(1.0 - gbuffer.material.roughness * 3.0);
					metalnessMask = min(metalnessMask, 0.5);
				}
			#endif
			vec3 sunlightSpecular = vec3(0.0);


			if (any(greaterThan(sunlight * shadow, vec3(0.0)))){
				#ifdef PT_SHADOW
					float tracingShadow = ShadowTracing(viewPos, worldPos + gbufferModelViewInverse[3].xyz, gbuffer.vertexNormal, worldShadowVector, gbuffer.lightmap.g);
					#ifdef SUNLIGHT_RIMS
						shadow *= mix(tracingShadow, 1.0, rims.x);
					#else
						shadow *= tracingShadow;
					#endif

				#endif

				vec3 f0 = vec3(gbuffer.material.metalness);

				if (isMetal){
					#if TEXTURE_PBR_FORMAT == 1 && defined LABPBR_PREDEFINED_METAL
						if(gbuffer.material.metalness < 237.5 / 255.0){
							f0 = PredefinedMetalF0(gbuffer.material.metalness, gbuffer.albedo);
						}else{
							f0 = gbuffer.albedo * (1.0 - METAL_MINIMAL_F0) + METAL_MINIMAL_F0;
						}				
					#else
						f0 = gbuffer.albedo * (1.0 - METAL_MINIMAL_F0) + METAL_MINIMAL_F0;
					#endif
				}


				sunlightSpecular = SpecularGGX(viewNormal, -viewDir, shadowVector, clamp(gbuffer.material.roughness, 0.0015, 0.9), f0);
				sunlightSpecular *= saturate(4.0 - gbuffer.material.roughness * 3.5) * 0.16;
				//#ifdef DIMENSION_END
				//	sunlightSpecular *= remapSaturate(gbuffer.material.roughness, 0.01, 0.05);
				//#endif


				#ifdef SCREEN_SPACE_SHADOWS
					float leaveMask = materialMask.leaves * shadowmapRange;

					#ifdef HAND_SCREEN_SHADOW
						#ifdef DISABLE_PLAYER_SCREEN_SPACE_SHADOWS
							#if PARALLAX_MODE > 0
								if (leaveMask + materialMask.entitiesSnow + materialMask.entityPlayer < 1.0)
							#else
								if (leaveMask + materialMask.entitiesSnow + materialMask.entityPlayer < 1.0 && gbuffer.parallaxShadow > 0.0)
							#endif
						#else
							#if PARALLAX_MODE > 0
								if (leaveMask + materialMask.entitiesSnow < 1.0)
							#else
								if (leaveMask + materialMask.entitiesSnow < 1.0 && gbuffer.parallaxShadow > 0.0)
							#endif
						#endif
					#else
						#ifdef DISABLE_PLAYER_SCREEN_SPACE_SHADOWS
							#if PARALLAX_MODE > 0
								if (leaveMask + materialMask.hand + materialMask.entitiesSnow + materialMask.entityPlayer < 1.0)
							#else
								if (leaveMask + materialMask.hand + materialMask.entitiesSnow + materialMask.entityPlayer < 1.0 && gbuffer.parallaxShadow > 0.0)
							#endif
						#else
							#if PARALLAX_MODE > 0
								if (leaveMask + materialMask.hand + materialMask.entitiesSnow < 1.0)
							#else
								if (leaveMask + materialMask.hand + materialMask.entitiesSnow < 1.0 && gbuffer.parallaxShadow > 0.0)
							#endif
						#endif
					#endif
						{
							float screenSpaceShadow = mix(ScreenSpaceShadow(viewPos, viewDir, depth, materialMask, shadowmapRange), 1.0, leaveMask);
							#ifdef SUNLIGHT_RIMS
								shadow *= mix(screenSpaceShadow, 1.0, rims.x);
							#else
								shadow *= screenSpaceShadow;
							#endif
						}
				#endif

				color += shadow * (sunlight * (1.0 - metalnessMask * (METALMASK_STRENGTH * 0.1 + 0.9)));

				sunlightSpecular *= shadow;
			}

			if (isMetal) imageStore(FBIMG_SST_TEMPORAL, texelCoord, vec4(sunlightSpecular + textureLighting * gbuffer.albedo, 0.0));

			#if SR_ENABLE == 1 && SR_USING_ALGO == SR_ALGO_DLSSRR
				vec3 fliteredColor = color + texelFetch(FBTEX_MAIN_OUTPUT, texelCoord, 0).rgb * 0.01;
				color += imageLoad(colorimg20, texelCoord).rgb * 0.01;

				fliteredColor = fliteredColor * (1.0 - metalnessMask * METALMASK_STRENGTH) + textureLighting;
				fliteredColor = fliteredColor * gbuffer.albedo + sunlightSpecular;

				imageStore(colorimg20, texelCoord, vec4(fliteredColor, 0.0));
			#endif

			color = color * (1.0 - metalnessMask * METALMASK_STRENGTH) + textureLighting;
			color = color * gbuffer.albedo + sunlightSpecular;


		#else
			if (texelCoord.x < 0) color = texelFetch(shadowtex0, ivec2(-1), 0).rgb;

			bool isMetal = gbuffer.material.metalness > 229.5 / 255.0;

			#ifdef DISABLE_HAND_SPECULAR
				float metalnessMask = 0.0;
			#elif defined DECREASE_HAND_SPECULAR
				float metalnessMask = float(isMetal);
				if (materialMask.hand > 0.5){
					metalnessMask *= saturate(1.0 - gbuffer.material.roughness * 3.0);
					metalnessMask = min(metalnessMask, 0.5);
				}
			#else
				float metalnessMask = float(isMetal);
			#endif

			if (isMetal) imageStore(FBIMG_SST_TEMPORAL, texelCoord, vec4(textureLighting * gbuffer.albedo, 0.0));

			#if SR_ENABLE == 1 && SR_USING_ALGO == SR_ALGO_DLSSRR
				vec3 fliteredColor = color + texelFetch(FBTEX_MAIN_OUTPUT, texelCoord, 0).rgb * 0.01;
				color += imageLoad(colorimg20, texelCoord).rgb * 0.01;
				
				fliteredColor = (fliteredColor * (1.0 - metalnessMask * METALMASK_STRENGTH) + textureLighting) * gbuffer.albedo;

				imageStore(colorimg20, texelCoord, vec4(fliteredColor, 0.0));
			#endif

			color = (color * (1.0 - metalnessMask * METALMASK_STRENGTH) + textureLighting) * gbuffer.albedo;

		#endif


		color += vec3(1.0) * materialMask.lightning;
	
		framebuffer_mainOutput = vec4(max(color, vec3(0.0)), 0.0);


	}else{
		#if !defined DIMENSION_NETHER && !defined DISABLE_SKY_RENDERING
			framebuffer_mainOutput = texelFetch(FBTEX_ALT_OUTPUT, texelCoord, 0);			
		#endif
		#if SR_ENABLE == 1 && SR_USING_ALGO == SR_ALGO_DLSSRR
			imageStore(colorimg18, texelCoord, vec4(0.5, 0.5, 0.5, 0.0));
		#endif
	}

	//#ifdef HAS_COLORWHEEL
	//	if (texelCoord == ivec2(0)) imageStore(FBIMG_SST_TEMPORAL, ivec2(0), vec4(0.0, 0.0, 0.0, -1.0));
	//#endif
}
