

vec3 ViewPos_From_ScreenPos(vec2 coord, float depth){
	#if defined TAA || defined SUPER_RESOLUTION
		coord -= UNIFORM_TAA_JITTER * 0.5;
	#endif
	vec3 ndcPos = vec3(coord, depth) * 2.0 - 1.0;
	vec3 viewPos = vec3(vec2(gbufferProjectionInverse0.x, gbufferProjectionInverse0.y) * ndcPos.xy, 0.0) + gbufferProjectionInverse1;
	return viewPos / (gbufferProjectionInverse0.z * ndcPos.z + gbufferProjectionInverse0.w);
}

vec3 ViewPos_From_ScreenPos_Raw(vec2 coord, float depth){
	vec3 ndcPos = vec3(coord, depth) * 2.0 - 1.0;
	vec3 viewPos = vec3(vec2(gbufferProjectionInverse0.x, gbufferProjectionInverse0.y) * ndcPos.xy, 0.0) + gbufferProjectionInverse1;
	return viewPos / (gbufferProjectionInverse0.z * ndcPos.z + gbufferProjectionInverse0.w);
}

vec3 ScreenPos_From_ViewPos(vec3 viewPos){
	vec3 screenPos = vec3(gbufferProjection0.x, gbufferProjection0.y, gbufferProjection0.z) * viewPos + gbufferProjection1;
	screenPos = screenPos * (0.5 / -viewPos.z) + 0.5;
	#if defined TAA || defined SUPER_RESOLUTION
		screenPos.xy += UNIFORM_TAA_JITTER * 0.5;
	#endif
	return screenPos;
}

vec3 ScreenPos_From_ViewPos_Raw(vec3 viewPos){
	vec3 screenPos = vec3(gbufferProjection0.x, gbufferProjection0.y, gbufferProjection0.z) * viewPos + gbufferProjection1;
	return screenPos * (0.5 / -viewPos.z) + 0.5;
}

float LinearDepth_From_ScreenDepth(float depth){
	depth = depth * 2.0 - 1.0;
	return 1.0 / (depth * gbufferProjectionInverse0.z + gbufferProjectionInverse0.w);
}

float ScreenDepth_From_LinearDepth(float depth){
	depth = (1.0 / depth - gbufferProjectionInverse0.w) / gbufferProjectionInverse0.z;
	return depth * 0.5 + 0.5;
}

#ifdef LOD_RENDERING

	vec3 ViewPos_From_ScreenPos_LOD(vec2 coord, float depth){
		#if defined TAA || defined SUPER_RESOLUTION
			coord -= UNIFORM_TAA_JITTER * 0.5;
		#endif
		vec3 ndcPos = vec3(coord, depth) * 2.0 - 1.0;
		vec3 viewPos = vec3(vec2(gbufferProjectionInverse0.x, gbufferProjectionInverse0.y) * ndcPos.xy, 0.0) + lodProjectionInverse1;
		return viewPos / (lodProjectionInverse0.x * ndcPos.z + lodProjectionInverse0.y);
	}

	vec3 ViewPos_From_ScreenPos_Raw_LOD(vec2 coord, float depth){
		vec3 ndcPos = vec3(coord, depth) * 2.0 - 1.0;
		vec3 viewPos = vec3(vec2(gbufferProjectionInverse0.x, gbufferProjectionInverse0.y) * ndcPos.xy, 0.0) + lodProjectionInverse1;
		return viewPos / (lodProjectionInverse0.x * ndcPos.z + lodProjectionInverse0.y);
	}

	vec3 ScreenPos_From_ViewPos_LOD(vec3 viewPos){
		vec3 screenPos = vec3(gbufferProjection0.x, gbufferProjection0.y, lodProjection0.w) * viewPos + lodProjection0.xyz;
		screenPos = screenPos * (0.5 / -viewPos.z) + 0.5;
		#if defined TAA || defined SUPER_RESOLUTION
			screenPos.xy += UNIFORM_TAA_JITTER * 0.5;
		#endif
		return screenPos;
	}

	vec3 ScreenPos_From_ViewPos_Raw_LOD(vec3 viewPos){
		vec3 screenPos = vec3(gbufferProjection0.x, gbufferProjection0.y, lodProjection0.w) * viewPos + lodProjection0.xyz;
		return screenPos * (0.5 / -viewPos.z) + 0.5;
	}

	float LinearDepth_From_ScreenDepth_LOD(float depth){
		depth = depth * 2.0 - 1.0;
		return 1.0 / (depth * lodProjectionInverse0.x + lodProjectionInverse0.y);
	}

	float ScreenDepth_From_LinearDepth_LOD(float depth){
		depth = (1.0 / depth - lodProjectionInverse0.y) / lodProjectionInverse0.x;
		return depth * 0.5 + 0.5;
	}

	float ScreenDepth_From_LODScreenDepth(float depth){
		depth = depth * 2.0 - 1.0;
		depth = 1.0 / (depth * lodProjectionInverse0.x + lodProjectionInverse0.y);
		depth = (1.0 / depth - gbufferProjectionInverse0.w) / gbufferProjectionInverse0.z;
    	return depth * 0.5 + 0.5;
	}

	vec4 ScreenDepth_From_LODScreenDepth(vec4 depth){
		depth = depth * 2.0 - 1.0;
		depth = 1.0 / (depth * lodProjectionInverse0.x + lodProjectionInverse0.y);
		depth = (1.0 / depth - gbufferProjectionInverse0.w) / gbufferProjectionInverse0.z;
    	return depth * 0.5 + 0.5;
	}

#endif