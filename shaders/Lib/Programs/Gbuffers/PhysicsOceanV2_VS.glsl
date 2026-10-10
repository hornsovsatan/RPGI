//PhysicsOceanV2_VS


#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


#include "/Lib/IndividualFunctions/OceanPhysicsV2.glsl"


// VERTEX STAGE
in float physics_waviness;

out vec3 physics_localPosition;
out float physics_localWaviness;

void main() {
    // basic value to determine how shallow/far away from the shore the water is
    physics_localWaviness = physics_waviness;
    // transform gl_Vertex (since it is the raw mesh, i.e. not transformed yet)
    float baseWaveHeight = physics_waveHeight(gl_Vertex.xz, PHYSICS_ITERATIONS_OFFSET, physics_localWaviness, physics_gameTime);
    float rippleHeight = physics_rippleVertexHeight(gl_Vertex.xz);
    vec4 finalPosition = vec4(gl_Vertex.x, gl_Vertex.y + baseWaveHeight + rippleHeight, gl_Vertex.z, gl_Vertex.w);
    // pass this to the fragment shader to fetch the texture there for per fragment normals
    physics_localPosition = finalPosition.xyz;
    
    // now use finalPosition instead of gl_Vertex
}
