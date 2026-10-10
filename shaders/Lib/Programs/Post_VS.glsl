

in vec3 vaPosition;

#if defined SUPER_RESOLUTION && defined FULLRES_BUFFER
	uniform vec2 fsrRenderScale;
#endif

void main(){
	#if defined SUPER_RESOLUTION && defined FULLRES_BUFFER
		gl_Position = vec4(vaPosition.xy * 2.0 * fsrRenderScale - 1.0, 0.0, 1.0);
	#else
		gl_Position = vec4(vaPosition.xy * 8.0 - vec2(6.5, 1.5), 0.0, 1.0);
	#endif
}
