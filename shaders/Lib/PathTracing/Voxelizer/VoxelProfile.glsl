

#ifdef DIMENSION_OVERWORLD

	#if SHADOW_RENDER_DISTANCE == 4
		#if PT_VOXEL_RESOLUTION_X >= 512 || PT_VOXEL_RESOLUTION_Y >= 512
			const float shadowDistance = 256.1;
		#elif PT_VOXEL_RESOLUTION_X >= 384 || PT_VOXEL_RESOLUTION_Y >= 384
			const float shadowDistance = 192.1;
		#elif PT_VOXEL_RESOLUTION_X >= 256 || PT_VOXEL_RESOLUTION_Y >= 256
			const float shadowDistance = 128.1;
		#elif PT_VOXEL_RESOLUTION_X >= 192 || PT_VOXEL_RESOLUTION_Y >= 192
			const float shadowDistance = 96.1;
		#else
			const float shadowDistance = 64.1;
		#endif

	#elif SHADOW_RENDER_DISTANCE == 6
		#if PT_VOXEL_RESOLUTION_X >= 512 || PT_VOXEL_RESOLUTION_Y >= 512
			const float shadowDistance = 256.1;
		#elif PT_VOXEL_RESOLUTION_X >= 384 || PT_VOXEL_RESOLUTION_Y >= 384
			const float shadowDistance = 192.1;
		#elif PT_VOXEL_RESOLUTION_X >= 256 || PT_VOXEL_RESOLUTION_Y >= 256
			const float shadowDistance = 128.1;
		#else
			const float shadowDistance = 96.1;
		#endif

	#elif SHADOW_RENDER_DISTANCE == 8
		#if PT_VOXEL_RESOLUTION_X >= 512 || PT_VOXEL_RESOLUTION_Y >= 512
			const float shadowDistance = 256.1;
		#elif PT_VOXEL_RESOLUTION_X >= 384 || PT_VOXEL_RESOLUTION_Y >= 384
			const float shadowDistance = 192.1;
		#else
			const float shadowDistance = 128.1;
		#endif

	#elif SHADOW_RENDER_DISTANCE == 12
		#if PT_VOXEL_RESOLUTION_X >= 512 || PT_VOXEL_RESOLUTION_Y >= 512
			const float shadowDistance = 256.1;
		#else
			const float shadowDistance = 192.1;
		#endif

	#elif SHADOW_RENDER_DISTANCE == 16
		const float shadowDistance = 256.1;

	#elif SHADOW_RENDER_DISTANCE == 24
		const float shadowDistance = 384.1;

	#elif SHADOW_RENDER_DISTANCE == 32
		const float shadowDistance = 512.1;

	#elif SHADOW_RENDER_DISTANCE == 48
		const float shadowDistance = 768.1;

	#elif SHADOW_RENDER_DISTANCE == 64
		const float shadowDistance = 1024.1;

	#elif SHADOW_RENDER_DISTANCE == 96
		const float shadowDistance = 1536.1;

	#elif SHADOW_RENDER_DISTANCE == 128
		const float shadowDistance = 2048.1;

	#endif

#endif


#ifdef DIMENSION_END

	#if SHADOW_RENDER_DISTANCE == 4
		#if PT_VOXEL_RESOLUTION_X >= 512 || PT_VOXEL_RESOLUTION_Y >= 512
			const float shadowDistance = 256.1;
			const float voxelDistance  = 256.0;
		#elif PT_VOXEL_RESOLUTION_X >= 384 || PT_VOXEL_RESOLUTION_Y >= 384
			const float shadowDistance = 192.1;
			const float voxelDistance  = 192.0;
		#elif PT_VOXEL_RESOLUTION_X >= 256 || PT_VOXEL_RESOLUTION_Y >= 256
			const float shadowDistance = 128.1;
			const float voxelDistance  = 128.0;
		#elif PT_VOXEL_RESOLUTION_X >= 192 || PT_VOXEL_RESOLUTION_Y >= 192
			const float shadowDistance = 96.1;
			const float voxelDistance  = 96.0;
		#else
			const float shadowDistance = 64.1;
			const float voxelDistance  = 64.0;
		#endif

	#elif SHADOW_RENDER_DISTANCE == 6
		#if PT_VOXEL_RESOLUTION_X >= 512 || PT_VOXEL_RESOLUTION_Y >= 512
			const float shadowDistance = 256.1;
			const float voxelDistance  = 256.0;
		#elif PT_VOXEL_RESOLUTION_X >= 384 || PT_VOXEL_RESOLUTION_Y >= 384
			const float shadowDistance = 192.1;
			const float voxelDistance  = 192.0;
		#elif PT_VOXEL_RESOLUTION_X >= 256 || PT_VOXEL_RESOLUTION_Y >= 256
			const float shadowDistance = 128.1;
			const float voxelDistance  = 128.0;
		#else
			const float shadowDistance = 96.1;
			const float voxelDistance  = 96.0;
		#endif

	#elif SHADOW_RENDER_DISTANCE == 8
		#if PT_VOXEL_RESOLUTION_X >= 512 || PT_VOXEL_RESOLUTION_Y >= 512
			const float shadowDistance = 256.1;
			const float voxelDistance  = 256.0;
		#elif PT_VOXEL_RESOLUTION_X >= 384 || PT_VOXEL_RESOLUTION_Y >= 384
			const float shadowDistance = 192.1;
			const float voxelDistance  = 192.0;
		#else
			const float shadowDistance = 128.1;
			const float voxelDistance  = 128.0;
		#endif

	#elif SHADOW_RENDER_DISTANCE == 12
		#if PT_VOXEL_RESOLUTION_X >= 512 || PT_VOXEL_RESOLUTION_Y >= 512
			const float shadowDistance = 256.1;
			const float voxelDistance  = 256.0;
		#else
			const float shadowDistance = 192.1;
			const float voxelDistance  = 192.0;
		#endif

	#elif SHADOW_RENDER_DISTANCE == 16
		const float shadowDistance = 256.1;
		const float voxelDistance  = 256.0;

	#elif SHADOW_RENDER_DISTANCE == 24
		const float shadowDistance = 384.1;
		const float voxelDistance  = 384.0;

	#elif SHADOW_RENDER_DISTANCE == 32
		const float shadowDistance = 512.1;
		const float voxelDistance  = 512.0;

	#elif SHADOW_RENDER_DISTANCE == 48
		const float shadowDistance = 768.1;
		const float voxelDistance  = 768.0;

	#elif SHADOW_RENDER_DISTANCE == 64
		const float shadowDistance = 1024.1;
		const float voxelDistance  = 1024.0;

	#elif SHADOW_RENDER_DISTANCE == 96
		const float shadowDistance = 1536.1;
		const float voxelDistance  = 1536.0;

	#elif SHADOW_RENDER_DISTANCE == 128
		const float shadowDistance = 2048.1;
		const float voxelDistance  = 2048.0;

	#endif

#endif



const ivec3 voxelResolutionInt 	= ivec3(PT_VOXEL_RESOLUTION_X, PT_VOXEL_RESOLUTION_Y, PT_VOXEL_RESOLUTION_X);

#ifndef DIMENSION_END
	#if PT_VOXEL_RESOLUTION_X >= PT_VOXEL_RESOLUTION_Y
		#if   PT_VOXEL_RESOLUTION_X == 128
			const float voxelDistance = 64.0;
		#elif PT_VOXEL_RESOLUTION_X == 192
			const float voxelDistance = 96.0;
		#elif PT_VOXEL_RESOLUTION_X == 256
			const float voxelDistance = 128.0;
		#elif PT_VOXEL_RESOLUTION_X == 384
			const float voxelDistance = 192.0;
		#elif PT_VOXEL_RESOLUTION_X == 512
			const float voxelDistance = 256.0;
		#endif
	#else
		#if   PT_VOXEL_RESOLUTION_Y == 128
			const float voxelDistance = 64.0;
		#elif PT_VOXEL_RESOLUTION_Y == 192
			const float voxelDistance = 96.0;
		#elif PT_VOXEL_RESOLUTION_Y == 256
			const float voxelDistance = 128.0;
		#elif PT_VOXEL_RESOLUTION_Y == 384
			const float voxelDistance = 192.0;
		#elif PT_VOXEL_RESOLUTION_Y == 512
			const float voxelDistance = 256.0;
		#endif
	#endif
#endif


#ifdef DIMENSION_NETHER
	#if PT_VOXEL_RESOLUTION_X >= PT_VOXEL_RESOLUTION_Y
		#if   PT_VOXEL_RESOLUTION_X == 128
			const float shadowDistance = 64.0;
		#elif PT_VOXEL_RESOLUTION_X == 192
			const float shadowDistance = 96.0;
		#elif PT_VOXEL_RESOLUTION_X == 256
			const float shadowDistance = 128.0;
		#elif PT_VOXEL_RESOLUTION_X == 384
			const float shadowDistance = 192.0;
		#elif PT_VOXEL_RESOLUTION_X == 512
			const float shadowDistance = 256.0;
		#endif
	#else
		#if   PT_VOXEL_RESOLUTION_Y == 128
			const float shadowDistance = 64.0;
		#elif PT_VOXEL_RESOLUTION_Y == 192
			const float shadowDistance = 96.0;
		#elif PT_VOXEL_RESOLUTION_Y == 256
			const float shadowDistance = 128.0;
		#elif PT_VOXEL_RESOLUTION_Y == 384
			const float shadowDistance = 192.0;
		#elif PT_VOXEL_RESOLUTION_Y == 512
			const float shadowDistance = 256.0;
		#endif
	#endif
#endif


const vec3 voxelResolution = vec3(voxelResolutionInt);


const int shadowMapResolution 	= 2048; // [1024 1536 2048 3072 4096 6144 8192]
const float shadowSize 			= float(shadowMapResolution);
const float shadowPixelSize 	= 1.0 / shadowSize;



const ivec3 ircResolutionInt = min(ivec3(PT_IRC_RESOLUTION_X, PT_IRC_RESOLUTION_Y, PT_IRC_RESOLUTION_X), voxelResolutionInt);


// 128 6  * 24 2816 8
// 192 10 * 20 3968 7
// 256 13 * 20 5376 8
// 384 17 * 23 8832 7
// 512 21 * 25 12800 9

// 196 14^3 2744
// 256 16^3 4096
// 324 18^3 5832
// 400 20^3 8000
// 528 23 * 23 12144