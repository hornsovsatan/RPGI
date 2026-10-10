

uint HashWellons(inout uint randSeed){
	return randSeed = HashWellons32(randSeed);
}

float RandWellons(inout uint randSeed){
	randSeed = HashWellons32(randSeed);
	return float(randSeed) / float(0xffffffffu);
}

vec3 RandUnitVector(inout uint randSeed){
	vec2 noise = vec2(RandWellons(randSeed), RandWellons(randSeed));
	vec2 randAngle = vec2(TAU * noise.x, acos(2.0 * noise.y - 1.0));
	return vec3(sin(randAngle.x) * sin(randAngle.y), cos(randAngle.x) * sin(randAngle.y), cos(randAngle.y));
}

vec3 HemisphereUnitVector(vec3 n, inout uint randSeed){
	vec3 randVector = RandUnitVector(randSeed);
	return randVector * fsign(dot(randVector, n));
}

vec3 RandUnitVector(vec2 noise){
	vec2 randAngle = vec2(TAU * noise.x, acos(2.0 * noise.y - 1.0));
	return vec3(sin(randAngle.x) * sin(randAngle.y), cos(randAngle.x) * sin(randAngle.y), cos(randAngle.y));
}

vec3 HemisphereUnitVector(vec3 n, vec2 noise){
	vec3 randVector = RandUnitVector(noise);
	return randVector * fsign(dot(randVector, n));
}