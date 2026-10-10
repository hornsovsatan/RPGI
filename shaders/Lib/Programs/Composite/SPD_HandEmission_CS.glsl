

#define PROGRAM_UPDATE_SSBO


#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


#ifdef HELDLIGHT_CUSTOM_COLOR
	const ivec3 workGroups = ivec3(1, 1, 1);
#else
	const vec2 workGroupsRender = vec2(0.25, 0.25);
#endif
layout (local_size_x = 16, local_size_y = 16) in;


layout (rgba16f) uniform image2D FBIMG_ALT_OUTPUT;
layout (rg16f) uniform image2D img_pixelData2D;


vec4 SpdLoadSourceImage(ivec2 p, uint slice){
	ivec4 mipmapMapping = ssb_mipmapMappingSpaced[0u];
	ivec2 readTexel = clamp(p, ivec2(0), mipmapMapping.zw - 1);
	return texelFetch(FBTEX_MAIN_OUTPUT, readTexel, 0);
}

vec4 SpdLoad(ivec2 p, uint slice){
	ivec4 mipmapMapping = ssb_mipmapMappingSpaced[6u];
	ivec2 readTexel = clamp(p, ivec2(0), mipmapMapping.zw - 1) + mipmapMapping.xy;
	return texelFetch(FBTEX_ALT_OUTPUT, readTexel, 0);
}

void SpdStore(ivec2 p, vec4 value, uint mip, uint slice){
	if (mip == ssb_mipmapMaxLevel){
		if (p == ivec2(0)){

			vec3 handEmission;

			uvec2 isTorch = uvec2(heldItemId == 10000, heldItemId2 == 10000);
			uvec2 notLight = uvec2(heldBlockLightValue == 0, heldBlockLightValue2 == 0);
			
			if (bool((isTorch.x & notLight.y) | (isTorch.y & notLight.x) | (isTorch.x & isTorch.y))){
				const vec3 torchColor = pow(vec3(COLOR_TORCH_R, COLOR_TORCH_G, COLOR_TORCH_B), vec3(2.0)) * BRIGHTNESS_TORCH;
				handEmission = torchColor;
			}else{
				handEmission = mix(vec3(0.0), value.rgb / (value.a + 1e-20), saturate(value.a * 0.1));
				
				vec3 handEmissionPrev = vec3(
					texelFetch(pixelData2D, ivec2(PIXELDATA_HANDEMISSION_RG, 0), 0).xy, 
					texelFetch(pixelData2D, ivec2(PIXELDATA_HANDEMISSION_BA, 0), 0).x
				);

				float frameTimeFixed = saturate(frameTime * 2.0 + step(frameCounter, 20) * 100.0) * step(1.0, value.a);
				handEmission = mix(handEmissionPrev, handEmission, frameTimeFixed);
			}

			imageStore(img_pixelData2D, ivec2(PIXELDATA_HANDEMISSION_RG, 0), vec4(handEmission.rg, 0.0, 0.0));
			imageStore(img_pixelData2D, ivec2(PIXELDATA_HANDEMISSION_BA, 0), vec4(handEmission.b, 0.0, 0.0, 0.0));
		}
	}else if (mip == 6u){
		ivec4 mipmapMapping = ssb_mipmapMappingSpaced[mip];
		ivec2 drawTexel = clamp(p, ivec2(0), mipmapMapping.zw - 1) + mipmapMapping.xy;
		imageStore(FBIMG_ALT_OUTPUT, drawTexel, value);
	}
}

vec4 SpdReduce4(vec4 v0, vec4 v1, vec4 v2, vec4 v3){
	return v0 * 0.25 + v1 * 0.25 + v2 * 0.25 + v3 * 0.25;
}


#include "/Lib/FidelityFX/SPD/SPD.glsl"

void main(){
	#ifndef HELDLIGHT_CUSTOM_COLOR
		if (heldBlockLightValue + heldBlockLightValue2 <= 0) return;
		uint totalNumWorkGroups = gl_NumWorkGroups.x * gl_NumWorkGroups.y;
		SpdDownsample(gl_WorkGroupID.xy, gl_LocalInvocationIndex, ssb_mipmapMaxLevel, totalNumWorkGroups, gl_WorkGroupID.z);
	#endif
}
