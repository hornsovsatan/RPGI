

#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"



/* RENDERTARGETS: 8 */
layout(location = 0) out vec4 framebuffer_altOutput;

layout(rgba16f) writeonly uniform image2D FBIMG_SST_TEMPORAL;


ivec2 texelCoord = ivec2(gl_FragCoord.xy);
vec2 texCoord = gl_FragCoord.xy * UNIFORM_PIXEL_SIZE;
uint randSeed = HashWellons32(uint(gl_FragCoord.x + screenSize.x * gl_FragCoord.y) * uint(frameCounter));

#ifdef DIMENSION_OVERWORLD
	in vec3 worldShadowVector;
	in vec3 worldSunVector;

	in vec3 colorShadowlight;
	in vec3 colorSunlight;
	in vec3 colorMoonlight;

	in vec3 colorSkylight;

	in float shadowHighlightStrength;
#endif

uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;

uniform sampler2D shadowcolor0;

uniform sampler3D voxelData3D;
uniform usampler3D voxelColor3D;

#ifdef PT_IRC
	uniform sampler3D irradianceCache3D;
	uniform sampler3D irradianceCache3D_Alt;
#endif


#include "/Lib/GbufferData.glsl"
#include "/Lib/Uniform/GbufferTransforms.glsl"
#include "/Lib/BasicFunctions/TemporalNoise.glsl"
#ifdef DIMENSION_NETHER
	#include "/Lib/BasicFunctions/NetherColor.glsl"
#endif

#include "/Lib/PathTracing/Voxelizer/VoxelProfile.glsl"
#include "/Lib/Uniform/ShadowTransforms.glsl"
#include "/Lib/PathTracing/Tracer/TracingUtilities.glsl"
#include "/Lib/PathTracing/Tracer/SampleIRC.glsl"
#include "/Lib/PathTracing/Voxelizer/BlockShape.glsl"
#include "/Lib/PathTracing/Tracer/ShadowTracing.glsl"

#ifdef DIMENSION_END
	#include "/Lib/IndividualFunctions/EndSkyTimer.glsl"
#endif


#include "/Lib/PathTracing/Tracer/SpecularTracer.glsl"


void main(){
	float depth = texelFetch(depthtex0, texelCoord, 0).x;

	#ifdef LOD_RENDERING
		if (depth == 1.0) depth = -texelFetch(LOD_DEPTH_TEX_0, texelCoord, 0).x;
	#endif

	if (abs(depth) == 1.0){
		imageStore(FBIMG_SST_TEMPORAL, texelCoord, vec4(0.0));
		discard;
	}

	bool isSmooth = false;
	GbufferData gbuffer = GetGbufferDataTranslucent(isSmooth);
	MaterialMask materialMask = CalculateMasks(gbuffer.materialID);

	framebuffer_altOutput = vec4(0.0);

	if (gbuffer.material.reflectionStrength > 0.0){
		vec3 viewPos = ViewPos_From_ScreenPos(texCoord, depth);
		#ifdef LOD_RENDERING
			if (depth < 0.0) viewPos = ViewPos_From_ScreenPos_LOD(texCoord, -depth);
		#endif
		vec3 worldPos = mat3(gbufferModelViewInverse) * viewPos.xyz;
		vec3 worldDir = normalize(worldPos.xyz);

		#ifdef DIMENSION_OVERWORLD
			float highlightStrength = float((materialMask.stainedGlass + materialMask.water > 0.5) && (isEyeInWater == 0 || materialMask.water < 0.5)) * shadowHighlightStrength;
			#ifdef SUNLIGHT_LEAK_FIX
				highlightStrength *= saturate(gbuffer.lightmap.g * 1e10);
			#endif
		#else
			const float highlightStrength = 0.0;
		#endif
	
		vec3 voxelPos = worldPos + gbufferModelViewInverse[3].xyz + cameraPositionFract + (voxelResolution * 0.5);
		voxelPos += gbuffer.vertexNormal * (-viewPos.z * 0.0003);

		framebuffer_altOutput = SpecularTracing(voxelPos, worldPos, worldDir, gbuffer.worldNormal, gbuffer.vertexNormal, gbuffer.material, gbuffer.lightmap.g, materialMask, isSmooth, highlightStrength);
	}
}
