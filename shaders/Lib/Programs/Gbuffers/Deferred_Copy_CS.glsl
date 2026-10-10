

#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


const vec2 workGroupsRender = vec2(1.0, 1.0);

layout (local_size_x = 16, local_size_y = 8) in;


layout (rgba16) writeonly uniform image2D FBIMG_GTRANS_DATA;
layout (rgba16) writeonly uniform image2D FBIMG_GTRANS_NORMAL;


void main(){
	ivec2 drawTexel = ivec2(gl_GlobalInvocationID.xy);

	vec4 gsoildData = texelFetch(FBTEX_GSOLID_DATA, drawTexel, 0);
	//if(Unpack2xU8_ID_Y_from_U16(gsoildData.z) == 0.0) return;

	imageStore(FBIMG_GTRANS_DATA, drawTexel, gsoildData);
	imageStore(FBIMG_GTRANS_NORMAL, drawTexel, texelFetch(FBTEX_GSOLID_NORMAL, drawTexel, 0));
}
