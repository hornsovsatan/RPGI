

#ifdef MC_GL_VENDOR_NVIDIA
	#extension GL_NV_shader_subgroup_partitioned : enable
	#extension GL_KHR_shader_subgroup_ballot : enable
#else
	#extension GL_KHR_shader_subgroup_shuffle : enable
#endif

#include "/Lib/Utilities.glsl"
#include "/Lib/UniformDeclare.glsl"


#if SR_SHOULD_APPLY_SCALE == 1
	const vec2 workGroupsRender = vec2(SR_RENDER_SCALE_FACTOR, SR_RENDER_SCALE_FACTOR);
#else
	const vec2 workGroupsRender = vec2(FSR2_RENDER_SCALE_FACTOR, FSR2_RENDER_SCALE_FACTOR);
#endif
layout (local_size_x = 16, local_size_y = 8) in;

layout (r32ui) uniform uimage2D img_rtwImportance2D;


#include "/Lib/Uniform/GbufferTransforms.glsl"


void main(){
	#ifdef RENDERING_MODE
		vec2 currFramesData = texelFetch(pixelData2D, ivec2(PIXELDATA_RENDER_FRAMES, 0), 0).xy;
		float renderFrames = currFramesData.x * 1000.0 + currFramesData.y - 10.0;
		if (renderFrames > 0.5) return;
	#else
		if (rtwDiscardRefresh) return;
	#endif
	
	ivec2 texelCoord = ivec2(gl_GlobalInvocationID.xy);

	float depth = uintBitsToFloat(texelFetch(depthtexS, texelCoord, 0).x);

	if (depth >= 0.7 && depth < 1.0){
		vec2 texCoord = (vec2(texelCoord) + 0.5) * UNIFORM_PIXEL_SIZE;

		vec3 viewPos = ViewPos_From_ScreenPos(texCoord, depth);
		vec3 worldPos = mat3(gbufferModelViewInverse) * viewPos + gbufferModelViewInverse[3].xyz;

		#ifdef DIMENSION_END
			vec3 shadowScreenPos = shadowModelViewEnd * worldPos;
		#else
			vec3 shadowScreenPos = mat3(shadowModelView0, shadowModelView1, shadowModelView2) * worldPos;
		#endif
		shadowScreenPos *= vec3(shadowProjection[0][0], shadowProjection[0][0], -shadowProjection[0][0] * 0.5);
		shadowScreenPos = shadowScreenPos * 0.5 + 0.5;

		if (saturate(shadowScreenPos.xy) == shadowScreenPos.xy){
			float dist = -viewPos.z / gbufferProjection0.y;

			float importance = 1.0 / (pow(dist, RTW_BACKWARD_DIST_FACTOR) * 0.1 + 1.0);

			vec3 normal = DecodeNormal(texelFetch(FBTEX_GSOLID_NORMAL, texelCoord, 0).ba);

			importance *= 1.0 + RTW_BACKWARD_NORMAL_FACTOR * saturate(dot(normal, -normalize(worldPos)));

			ivec2 shadowTexelCoord = ivec2(shadowScreenPos.xy * float(RTW_RESOLUTION));
			uint drawTexelData = uint(shadowTexelCoord.x | (shadowTexelCoord.y << 16));

			#ifdef MC_GL_VENDOR_NVIDIA			
				uvec4 partitionballot = subgroupPartitionNV(drawTexelData);
				
				if (subgroupBallotFindLSB(partitionballot) == gl_SubgroupInvocationID){
					importance = subgroupPartitionedMaxNV(importance, partitionballot);
					imageAtomicMax(img_rtwImportance2D, shadowTexelCoord, floatBitsToUint(importance));
				}
			#else
				for (uint u = 1u; u < gl_SubgroupSize; u = u << 1u){
					if (drawTexelData != subgroupShuffleXor(drawTexelData, u)){
						imageAtomicMax(img_rtwImportance2D, shadowTexelCoord, floatBitsToUint(importance));
						return;
					}else{
						if ((gl_SubgroupInvocationID & u) == u) return;
					}
				}
				imageAtomicMax(img_rtwImportance2D, shadowTexelCoord, floatBitsToUint(importance));
			#endif
		}
	}

	vec4 hitWorldPos = texelFetch(FBTEX_SST_TEMPORAL, texelCoord, 0);

	if	(hitWorldPos.w > 0.0){
		#ifdef DIMENSION_END
			vec3 shadowScreenPos = shadowModelViewEnd * hitWorldPos.xyz;
		#else
			vec3 shadowScreenPos = mat3(shadowModelView0, shadowModelView1, shadowModelView2) * hitWorldPos.xyz;
		#endif
		shadowScreenPos *= vec3(shadowProjection[0][0], shadowProjection[0][0], -shadowProjection[0][0] * 0.5);
		shadowScreenPos = shadowScreenPos * 0.5 + 0.5;

		if (saturate(shadowScreenPos.xy) == shadowScreenPos.xy){
			float dist = length(hitWorldPos.xyz) / gbufferProjection0.y;

			float importance = (hitWorldPos.w * 10.0) / (pow(dist, RTW_BACKWARD_DIST_FACTOR) + 10.0);

			ivec2 shadowTexelCoord = ivec2(shadowScreenPos.xy * float(RTW_RESOLUTION));
			uint drawTexelData = uint(shadowTexelCoord.x | (shadowTexelCoord.y << 16));

			#ifdef MC_GL_VENDOR_NVIDIA			
				uvec4 partitionballot = subgroupPartitionNV(drawTexelData);
				
				if (subgroupBallotFindLSB(partitionballot) == gl_SubgroupInvocationID){
					importance = subgroupPartitionedMaxNV(importance, partitionballot);
					imageAtomicMax(img_rtwImportance2D, shadowTexelCoord, floatBitsToUint(importance));
				}
			#else
				for (uint u = 1u; u < gl_SubgroupSize; u = u << 1u){
					if (drawTexelData != subgroupShuffleXor(drawTexelData, u)){
						imageAtomicMax(img_rtwImportance2D, shadowTexelCoord, floatBitsToUint(importance));
						return;
					}else{
						if ((gl_SubgroupInvocationID & u) == u) return;
					}
				}
				imageAtomicMax(img_rtwImportance2D, shadowTexelCoord, floatBitsToUint(importance));
			#endif
		}
	}

}