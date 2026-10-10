

#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


#if SR_SHOULD_APPLY_SCALE == 1
	const vec2 workGroupsRender = vec2(SR_RENDER_SCALE_FACTOR, SR_RENDER_SCALE_FACTOR);
#else
	const vec2 workGroupsRender = vec2(FSR2_RENDER_SCALE_FACTOR, FSR2_RENDER_SCALE_FACTOR);
#endif
layout (local_size_x = 16, local_size_y = 8) in;


layout (rgba16) uniform image2D FBIMG_GSOLID_DATA;
layout (rgba16) uniform image2D FBIMG_GSOLID_NORMAL;
layout (rgba16) uniform image2D FBIMG_GTRANS_DATA;
layout (rgba16) uniform image2D FBIMG_GTRANS_NORMAL;
layout (rgba16f) writeonly uniform image2D FBIMG_MAIN_OUTPUT;
layout (r32ui) uniform uimage2D img_depthtexS;

void main(){
	ivec2 drawTexel = ivec2(gl_GlobalInvocationID.xy);
	#ifdef SUPER_RESOLUTION
		if (any(greaterThanEqual(vec2(drawTexel), fsrScreenSize))) return;
	#endif

	float gtransDepth = texelFetch(depthtex0, drawTexel, 0).x;
	float solidDepth = gtransDepth;

	#ifdef LOD_RENDERING
		if (gtransDepth == 1.0) gtransDepth = texelFetch(LOD_DEPTH_TEX_0, drawTexel, 0).x;
	#endif

	if (gtransDepth < 1.0){
		vec4 gtransData = texelFetch(FBTEX_GTRANS_DATA, drawTexel, 0);

		vec2 gtransMaterialIDs = Unpack2xU8_ID_LOD_Y_from_U16(gtransData.z);
		bool copySolid = gtransMaterialIDs.x == MATID_SKY;

		float particleDepth = uintBitsToFloat(texelFetch(depthtexS, drawTexel, 0).x);
		copySolid = copySolid || (gtransMaterialIDs.x == MATID_PARTICLE && particleDepth > gtransDepth);

		#ifdef LOD_RENDERING
			vec4 gsolidData = texelFetch(FBTEX_GSOLID_DATA, drawTexel, 0);
			vec2 gsolidMaterialIDs = Unpack2xU8_ID_LOD_Y_from_U16(gsolidData.z);
			copySolid = copySolid || gtransMaterialIDs.y != 0.0 && gsolidMaterialIDs.y == 0.0 && gsolidMaterialIDs.x != MATID_SKY;
		#endif

		if (copySolid){
			#ifndef LOD_RENDERING
				vec4 gsolidData = texelFetch(FBTEX_GSOLID_DATA, drawTexel, 0);
				vec2 gsolidMaterialIDs = Unpack2xU8_ID_LOD_Y_from_U16(gsolidData.z);
			#endif
			imageStore(FBIMG_GTRANS_DATA, drawTexel, gsolidData);
			imageStore(FBIMG_GTRANS_NORMAL, drawTexel, texelFetch(FBTEX_GSOLID_NORMAL, drawTexel, 0));

			if (gsolidMaterialIDs.x == MATID_HAND){
				vec3 albedo = GammaToLinear(texelFetch(FBTEX_ALBEDO, drawTexel, 0).rgb);
				float emissiveness = Unpack2xU8_Y_from_U16(gsolidData.y);
				float side = mix(float(heldBlockLightValue2), float(heldBlockLightValue), saturate(drawTexel.x * UNIFORM_PIXEL_SIZE.x * 10.0 - 4.5)) / 15.0;

				float weight = (Radiance(albedo) + emissiveness * 16.0) * saturate(side) * 2048.0;

				imageStore(FBIMG_MAIN_OUTPUT, drawTexel, vec4(albedo * weight, weight));
			}
			
		}else if (abs(gtransMaterialIDs.x - (MATID_SOLID_TRANS + 2.0)) < 2.5){
			if (gtransMaterialIDs.x == MATID_SOLID_TRANS_HAND) gtransData.z = Pack2xU8_to_U16(vec2(1.0, MATID_HAND / 255.0));
			
			imageStore(FBIMG_GSOLID_DATA, drawTexel, gtransData);
			imageStore(FBIMG_GSOLID_NORMAL, drawTexel, texelFetch(FBTEX_GTRANS_NORMAL, drawTexel, 0));
			
		}else{
			solidDepth = texelFetch(depthtex1, drawTexel, 0).x;

		}

		imageStore(img_depthtexS, drawTexel, uvec4(floatBitsToUint(solidDepth), 0u, 0u, 0u));
	}
}
