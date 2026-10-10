//PhysicsOceanV2_GS


#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"


layout(triangles) in;
layout(triangle_strip, max_vertices = 3) out;


#include "/Lib/IndividualFunctions/OceanPhysicsV2.glsl"
