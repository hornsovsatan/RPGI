#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


/* RENDERTARGETS: 6 */
layout(location = 0) out vec4 framebuffer_mainOutput;


ivec2 texelCoord = ivec2(gl_FragCoord.xy);
vec2 texCoord = gl_FragCoord.xy * UNIFORM_PIXEL_SIZE;


#ifdef DIMENSION_OVERWORLD
	in vec3 worldSunVector;
	in vec2 fogTime;
	in float cloudVisibility;
#endif

#include "/Lib/BasicFunctions/PrecomputedAtmosphere.glsl"

#include "/Lib/GbufferData.glsl"
#include "/Lib/Uniform/GbufferTransforms.glsl"


vec2 CubemapProjection(vec3 dir){
	const float tileSize = SKYBOX_RESOLUTION;
	float tileSizeDivide = 0.5 * tileSize - 1.5;
	vec3 adir = abs(dir);

	vec2 texel;
	if (adir.x > adir.y && adir.x > adir.z){
		dir /= adir.x;
		texel.x = dir.y * tileSizeDivide + tileSize * 0.5;
		texel.y = dir.z * tileSizeDivide + tileSize * (step(0.0, dir.x) + 0.5);
	}else if (adir.y > adir.x && adir.y > adir.z){
		dir /= adir.y;
		texel.x = dir.x * tileSizeDivide + tileSize * 1.5;
		texel.y = dir.z * tileSizeDivide + tileSize * (step(0.0, dir.y) + 0.5);
	}else{
		dir /= adir.z;
		texel.x = dir.x * tileSizeDivide + tileSize * 2.5;
		texel.y = dir.y * tileSizeDivide + tileSize * (step(0.0, dir.z) + 0.5);
	}

	return texel * vec2(1.0 / (SKYBOX_RESOLUTION * 3.0), 1.0 / (SKYBOX_RESOLUTION * 2.0));
}

/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void main(){
	#ifdef SHOW_TODO
	#error "cp0 : sun and moon"
	#endif
	vec3 color = texelFetch(FBTEX_MAIN_OUTPUT, texelCoord, 0).rgb;

	if (isEyeInWater == 1){
		float materialIDs = GetTransMaterialID(texelCoord);

		if (materialIDs == MATID_WATER){

			float depth = texelFetch(depthtex0, texelCoord, 0).x;
			float opaqueDepth = uintBitsToFloat(texelFetch(depthtexS, texelCoord, 0).x);

			vec3 worldPos = mat3(gbufferModelViewInverse) * ViewPos_From_ScreenPos(texCoord, depth);
			vec3 worldDir = normalize(worldPos);
			vec3 worldNormal = DecodeNormal(texelFetch(FBTEX_GTRANS_NORMAL, texelCoord, 0).xy);

			vec3 refractedWorldDir = refract(worldDir, worldNormal, WATER_IOR);
			#ifdef DIMENSION_OVERWORLD
				if (opaqueDepth == 1.0){
					vec2 skyImageCoord = CubemapProjection(refractedWorldDir);
					vec4 skyImage = textureLod(skyBox2D, skyImageCoord, 0.0);

					#ifdef ATMO_HORIZON
						vec3 camera = vec3(0.0, max(cameraPosition.y, ATMO_MIN_ALTITUDE) * 0.001 + atmosphereModel_bottom_radius, 0.0);
					#else
						vec3 camera = vec3(0.0, max(cameraPosition.y, 63.0) * 0.001 + atmosphereModel_bottom_radius, 0.0);
					#endif

					vec3 transmittance = GetTransmittance(camera, refractedWorldDir);
					
					vec3 celestial = RenderSunDisc(refractedWorldDir, worldSunVector) * (3.2 - fogTime.x * 3.0);
					celestial += RenderMoonDisc(refractedWorldDir, -worldSunVector);
					celestial *= mix(1.0, skyImage.a, saturate(mix(1.0, RAIN_SHADOW / 0.98, wetness)));

					color += skyImage.rgb + celestial * transmittance * 200.0;
				}
			#endif
			if (length(refractedWorldDir) < 0.5){
				color = vec3(0.0);
			}
		}
		#ifdef WATER_FOG
			else{
				float depth = uintBitsToFloat(texelFetch(depthtexS, texelCoord, 0).x);
				if (depth > 0.999999) color = vec3(0.0);
			}
		#endif
	}
		
	framebuffer_mainOutput = vec4(color, 0.0);
}