

#define PROGRAM_UPDATE_SSBO

#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


const ivec3 workGroups = ivec3(3, 1, 1);
layout (local_size_x = 1) in;


void main(){
	if (gl_WorkGroupID.x == 0u){
	
	//spd
		//level 0
		ivec2 offset = ivec2(0);
		ivec2 offsetSpaced = ivec2(0);
		ivec2 size = ivec2(screenSize);

		ssb_mipmapMapping[0u] = ivec4(offset, size);
		ssb_mipmapMappingSpaced[0u] = ivec4(offsetSpaced, size);

		//level 1
		offsetSpaced = ivec2(0, 1);
		size = ivec2(ceil(screenSize * 0.5));

		ssb_mipmapMapping[1u] = ivec4(offset, size);
		ssb_mipmapMappingSpaced[1u] = ivec4(offsetSpaced, size);

		//level 2+
		for (uint level = 2u; level < 16u; level++){
			if(bool(level & 1u)){
				offset.y += size.y;
				offsetSpaced.y += size.y + 1;
			}else{
				offset.x += size.x;
				offsetSpaced.x += size.x + 1;
			}
			size = ivec2(ceil(ldexp(screenSize, -ivec2(level))));

			ssb_mipmapMapping[level] = ivec4(offset, size);
			ssb_mipmapMappingSpaced[level] = ivec4(offsetSpaced, size);
		}

	}else if (gl_WorkGroupID.x == 1u){

	//spd
		uint maxLevel = min(uint(ceil(maxVec2(log2(screenSize)))), 12u);
		ssb_mipmapMaxLevel = maxLevel;

		for (uint u = 0u; u < 16u; u++){
			ssb_spdAtomicCounter[u] = 0u;
		}

	}else if (gl_WorkGroupID.x == 2u){

	// gbufferPreviousProjectionInverse
		mat4 gbufferPreviousProjection = mat4(
			gbufferPreviousProjection0.x,                          0.0,                          0.0,  0.0,
									 0.0, gbufferPreviousProjection0.y,                          0.0,  0.0,
									 0.0,                          0.0, gbufferPreviousProjection0.z, -1.0,
			gbufferPreviousProjection1.x, gbufferPreviousProjection1.y, gbufferPreviousProjection1.z,  0.0
		);

		mat4 gbufferPreviousProjectionInverse = inverse(gbufferPreviousProjection);
		ssb_gbufferPreviousProjectionInverse0 = vec4(gbufferPreviousProjectionInverse[0][0], gbufferPreviousProjectionInverse[1][1], gbufferPreviousProjectionInverse[2][3], gbufferPreviousProjectionInverse[3][3]);
		ssb_gbufferPreviousProjectionInverse1 = vec3(gbufferPreviousProjectionInverse[3][0], gbufferPreviousProjectionInverse[3][1], gbufferPreviousProjectionInverse[3][2]);
		
		//if (ssb_gbufferPreviousProjectionInverse0.z >= 0.0){
		//	ssb_gbufferPreviousProjectionInverse0 = gbufferProjectionInverse0;
		//	ssb_gbufferPreviousProjectionInverse1 = gbufferProjectionInverse1;
		//}


	}
}
