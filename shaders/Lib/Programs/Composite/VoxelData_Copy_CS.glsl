

#include "/Lib/Settings.glsl"
#include "/Lib/Utilities.glsl"


#if   PT_VOXEL_RESOLUTION_X == 128
	#define PT_VOXEL_WORKGROUPS_X 16
#elif PT_VOXEL_RESOLUTION_X == 192
	#define PT_VOXEL_WORKGROUPS_X 24
#elif PT_VOXEL_RESOLUTION_X == 256
	#define PT_VOXEL_WORKGROUPS_X 32
#elif PT_VOXEL_RESOLUTION_X == 384
	#define PT_VOXEL_WORKGROUPS_X 48
#elif PT_VOXEL_RESOLUTION_X == 512
	#define PT_VOXEL_WORKGROUPS_X 64
#endif

#if   PT_VOXEL_RESOLUTION_Y == 128
	#define PT_VOXEL_WORKGROUPS_Y 16
#elif PT_VOXEL_RESOLUTION_Y == 192
	#define PT_VOXEL_WORKGROUPS_Y 24
#elif PT_VOXEL_RESOLUTION_Y == 256
	#define PT_VOXEL_WORKGROUPS_Y 32
#elif PT_VOXEL_RESOLUTION_Y == 384
	#define PT_VOXEL_WORKGROUPS_Y 48
#elif PT_VOXEL_RESOLUTION_Y == 512
	#define PT_VOXEL_WORKGROUPS_Y 64
#endif

const ivec3 workGroups = ivec3(PT_VOXEL_WORKGROUPS_X, PT_VOXEL_WORKGROUPS_Y, PT_VOXEL_WORKGROUPS_X);
layout (local_size_x = 8, local_size_y = 8, local_size_z = 8) in;


layout (r32ui) restrict uniform uimage3D img_voxelID3D;
layout (r32ui) restrict uniform uimage3D img_voxelAtlas3D;
layout (rgba16) writeonly uniform image3D img_voxelData3D;


uniform usampler3D voxelID3D;
uniform usampler3D voxelAtlas3D;

#ifdef PT_SPARE_TRACING
	shared uint isOccupied_8;
	shared uint isOccupied_4[8];
	shared uint isOccupied_2[64];
#endif


#include "/Lib/PathTracing/Voxelizer/VoxelProfile.glsl"


void main(){
	#ifdef PT_SPARE_TRACING
		int id_4 = int((gl_LocalInvocationID.x >> 2u) + (gl_LocalInvocationID.y >> 2u) * 2u + (gl_LocalInvocationID.z >> 2u) * 4u);
		int id_2 = int((gl_LocalInvocationID.x >> 1u) + (gl_LocalInvocationID.y >> 1u) * 4u + (gl_LocalInvocationID.z >> 2u) * 16u);

		isOccupied_8 = 0u;
		isOccupied_4[id_4] = 0u;
		isOccupied_2[id_2] = 0u;

		barrier();
	#endif

	ivec3 drawTexel = ivec3(gl_GlobalInvocationID.xyz);

	vec4 voxelData;

	uint packVoxelID = texelFetch(voxelID3D, drawTexel, 0).x;
	float textureResolution = float((packVoxelID & 0x0f000000u) >> 24u);

	if (textureResolution > 0.0){
		voxelData.z = float(packVoxelID & 0x0000ffffu) / 65535.0;
		float skylight = float((packVoxelID & 0x00ff0000u) >> 16u);
		voxelData.w = Pack2xU8_to_U16(saturate(vec2(textureResolution, skylight) / 255.0));

		uint packVoxelAtlas = texelFetch(voxelAtlas3D, drawTexel, 0).x;
		voxelData.x = float((packVoxelAtlas & 0x0fffc000u) >> 14u) * (4.0 / 65535.0);
		voxelData.y = float(packVoxelAtlas & 0x00003fffu) * (4.0 / 65535.0);
	}else{
		voxelData = vec4(1.0);
	}

	imageStore(img_voxelID3D, drawTexel, uvec4(0u));
	imageStore(img_voxelAtlas3D, drawTexel, uvec4(0u));

	#ifdef PT_SPARE_TRACING
		uint occupied = uint(voxelData.z < 1.0);

		uint occupied_8 = atomicMax(isOccupied_8, occupied);

		barrier();

		if (isOccupied_8 == 0u){
			voxelData.z = 0.91;
		}else{
			uint occupied_4 = atomicMax(isOccupied_4[id_4], occupied);
			barrier();
			if (isOccupied_4[id_4] == 0u){
				voxelData.z = 0.71;
			}else{			
				uint occupied_2 = atomicMax(isOccupied_2[id_2], occupied);
				barrier();
				if (isOccupied_2[id_2] == 0u)
					voxelData.z = 0.61; 
			}
		}
	#endif

	imageStore(img_voxelData3D, drawTexel, voxelData);
}