

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


layout (r32ui) writeonly uniform uimage3D img_voxelColor3D;


void main(){
	#ifndef PT_TRACING_EYE
		ivec3 drawTexel = ivec3(gl_GlobalInvocationID.xyz);

		imageStore(img_voxelColor3D, drawTexel, uvec4(0u));
	#endif
}