

#include "/Lib/Settings.glsl"

#include "/Lib/SSBODeclare.glsl"


uniform int heldItemId;
uniform int heldBlockLightValue;
uniform int heldItemId2;
uniform int heldBlockLightValue2;
uniform int worldTime;
uniform int frameCounter;
uniform float frameTime;
uniform float frameTimeCounter;
uniform float sunAngle;
uniform float aspectRatio;
uniform float viewWidth;
uniform float viewHeight;
uniform float near;
uniform float far;
uniform vec3 cameraPosition;
uniform vec3 cameraPositionFract;
uniform vec3 cameraPositionToPrevious;
uniform vec3 relativeEyePosition;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousModelView;
uniform mat4 shadowProjection;
uniform float wetness;
uniform ivec2 eyeBrightnessSmooth;
uniform int isEyeInWater;
uniform float nightVision;
uniform float blindness;
uniform int hideGUI;
uniform float darknessFactor;
uniform float darknessLightFactor;

uniform vec2 taaJitter;
uniform vec2 taaJitterToPrevious;
uniform vec2 previousTaaJitter;
uniform vec2 screenSize;
uniform vec2 pixelSize;
uniform vec3 gbufferProjection0;
uniform vec3 gbufferProjection1;
uniform vec4 gbufferProjectionInverse0;
uniform vec3 gbufferProjectionInverse1;
uniform vec3 gbufferPreviousProjection0;
uniform vec3 gbufferPreviousProjection1;
uniform vec3 shadowModelView0;
uniform vec3 shadowModelView1;
uniform vec3 shadowModelView2;
uniform vec3 shadowModelViewInverse2;
const mat3 shadowModelViewInverseEnd = mat3(0.4523250774, -0.8087002661, -0.3760397683, 0.2486168185, 0.5192604694, -0.8176541093, 0.85649968, 0.2763556486, 0.4359310193);
const mat3 shadowModelViewEnd = transpose(shadowModelViewInverseEnd);
uniform ivec2 eyeBrightness;
uniform float eyeBrightnessSmoothCurved;
uniform float eyeBrightnessZeroSmooth;
uniform float eyeBrightnessOneSmooth;
uniform float eyeSnowySmooth;
uniform float eyeNoPrecipitationSmooth;
uniform float eyeRxSmooth;
uniform float eyeRySmooth;
uniform float isSneakingSmooth;
uniform bool rtwDiscardRefresh;

#ifdef HDR_ENABLED
	uniform float HdrGamePeakBrightness;
	uniform float HdrGamePaperWhiteBrightness;
	uniform float HdrGameMinimumBrightness;
	uniform float HdrUIBrightness;
#endif


#ifdef SUPER_RESOLUTION
	uniform vec2 fsrScreenSize;
	uniform vec2 fsrPixelSize;
	uniform vec2 fsrRenderScale;
	uniform vec2 fsrJitter;
	uniform vec2 jitterRaw;

	uniform sampler2D fsrReconstructDepth2D;

	#define UNIFORM_SCREEN_SIZE fsrScreenSize
	#define UNIFORM_PIXEL_SIZE fsrPixelSize
	#define UNIFORM_TAA_JITTER fsrJitter
#else
	#ifdef CUSTOM_RENDER_RESOLUTION
		uniform vec2 fsrRenderScale;
		uniform vec2 fsrScreenSize;
	#endif

	#define UNIFORM_SCREEN_SIZE screenSize
	#define UNIFORM_PIXEL_SIZE pixelSize
	#define UNIFORM_TAA_JITTER taaJitter
#endif

#ifdef DISTANT_HORIZONS
	uniform vec4 lodProjection0;
	uniform vec2 lodProjectionInverse0;
	uniform vec3 lodProjectionInverse1;
	uniform vec2 lodPreviousProjection0;

	uniform float dhFarPlane;
	uniform int dhRenderDistance;

	uniform sampler2D dhDepthTex0;
	uniform sampler2D dhDepthTex1;

	#define LOD_FAR_PLANE dhFarPlane
	#define LOD_RENDER_DISTANCE dhRenderDistance
	#define LOD_DEPTH_TEX_0 dhDepthTex0
	#define LOD_DEPTH_TEX_1 dhDepthTex1
#endif

#ifdef VOXY
	uniform vec4 lodProjection0;
	uniform vec2 lodProjectionInverse0;
	uniform vec3 lodProjectionInverse1;
	uniform vec2 lodPreviousProjection0;

	uniform int vxRenderDistance;

	uniform sampler2D vxDepthTexTrans;
	uniform sampler2D vxDepthTexOpaque;

	#define LOD_FAR_PLANE 48000.0
	#define LOD_RENDER_DISTANCE (vxRenderDistance * 16)
	#define LOD_DEPTH_TEX_0 vxDepthTexTrans
	#define LOD_DEPTH_TEX_1 vxDepthTexOpaque
#endif

uniform sampler2D FBTEX_ALBEDO;
uniform sampler2D FBTEX_GSOLID_DATA;
uniform sampler2D FBTEX_GSOLID_NORMAL;
uniform sampler2D FBTEX_GTRANS_DATA;
uniform sampler2D FBTEX_GTRANS_NORMAL;
uniform sampler2D FBTEX_GWATER;
uniform sampler2D FBTEX_MAIN_OUTPUT;
uniform sampler2D FBTEX_MAIN_TEMPORAL;
uniform sampler2D FBTEX_ALT_OUTPUT;
uniform sampler2D FBTEX_SST_TEMPORAL;
uniform sampler2D FBTEX_DIFFUSE_TEMPORAL;
uniform sampler2D FBTEX_SPECULAR_TEMPORAL;
uniform sampler2D FBTEX_GSOLID_TEMPORAL;
#if defined VS_VELOCITY && defined SR_IRIS_EXT_VELOCITY
	uniform sampler2D colortex16;
#endif
#if SR_ENABLE == 1
	uniform sampler2D colortex17;
#endif

uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D depthtex2;
uniform usampler2D depthtexS;
#ifdef DIMENSION_OVERWORLD
	uniform usampler2D waterDepth2D;
#endif

uniform sampler2D noisetex;

uniform sampler2D pixelData2D;
uniform sampler2D skyBox2D;

uniform sampler2D atlas2D;
uniform sampler2D atlasSpecular2D;
uniform sampler3D CloudNoise3D;
uniform sampler3D CloudDetailedNoise3D;
uniform sampler3D atmoLut3D;
uniform sampler2D scatteringLut2D;