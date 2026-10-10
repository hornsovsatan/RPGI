#version 430


#define PT_OCCLUDED_WATER_SPECULAR
#define FULLRES_BUFFER


#define VS_FOG_TIME
#ifdef PT_OCCLUDED_WATER_SPECULAR
    #define VS_SHADOW_HIGHLIGHT
#endif
#include "/Lib/Programs/Composite/Overworld_VS.glsl"