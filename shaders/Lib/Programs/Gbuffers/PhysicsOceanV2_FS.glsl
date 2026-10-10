//PhysicsOceanV2_FS


#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


/* RENDERTARGETS: 3,4,5 */
layout(location = 1) out vec4 framebuffer_gtransData;
layout(location = 2) out vec4 framebuffer_gtransNormal;
layout(location = 3) out vec4 framebuffer_gwater;


#include "/Lib/IndividualFunctions/OceanPhysicsV2.glsl"


// FRAGMENT STAGE
in vec3 physics_localPosition;
in float physics_localWaviness;

void main() {
    WavePixelData wave = physics_wavePixel(physics_localPosition.xz, physics_localWaviness, physics_iterationsNormal, physics_gameTime);
    
	framebuffer_gtransData = vec4(albedoEnc, Pack2xU8_to_U16(materialEnc), Pack2xU8_to_U16(blockLight + 1e-6));
	framebuffer_gtransNormal = vec4(normalEnc, EncodeNormal(tbn[2]));
	framebuffer_gwater = vec4(normalEnc, Pack2xU8_to_U16(vec2(dist * 0.02, blockLight.y + 1e-6)), float(isWater));
}