

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferProjection;


void FsrScaleVS(inout vec4 position, vec2 jitter){
	position.xy /= position.w;
	position.xy = position.xy * fsrRenderScale + fsrRenderScale - 1.0;
	#ifdef CUSTOM_RENDER_RESOLUTION
		position.xy += jitter * fsrRenderScale;
	#else
		position.xy += jitter;
	#endif
	position.xy *= position.w;
}

bool FsrDiscardFS(vec2 fragCoord){
	return any(greaterThan(fragCoord, fsrScreenSize));
}

#ifdef CUSTOM_RENDER_RESOLUTION
	void RedoProject(inout vec4 position){
		position = gbufferProjectionInverse * position;
		mat4 projectMat = gbufferProjection;
		projectMat[0][0] = gbufferProjection0.x;
		projectMat[1][1] = gbufferProjection0.y;
		position = projectMat * position;
	}

	#ifdef LOD_RENDERING
		uniform mat4 dhProjection;
		uniform mat4 dhProjectionInverse;
		void RedoProjectDH(inout vec4 position){
			position = dhProjectionInverse * position;
			mat4 projectMat = dhProjection;
			projectMat[0][0] = gbufferProjection0.x;
			projectMat[1][1] = gbufferProjection0.y;
			position = projectMat * position;
		}
	#endif

#endif