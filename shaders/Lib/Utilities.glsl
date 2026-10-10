

#define iterationRP_VERSION AT // [AT BT]
#define iterationRP_INFO AT // [AT BT]
#define INFO_0 AT // [AT BT]
#define INFO_1 0 // [0 1]
#define INFO_TACZ AT // [AT BT]
#define INFO_RES AT // [AT BT]
#define INFO_RES_0 AT // [AT BT]
#define INFO_RES_1 AT // [AT BT]

#define PI           3.14159265359
#define hPI          1.57079632679
#define TAU          6.28318530718
#define rPI          0.31830988618

// (5^(1/2) + 1) / 2
#define goldenRatio  1.61803398875
// ((9 - 69^(1/2))^(1/3) + (9 + 69^(1/2))^(1/3)) / (2^(1/3) * 3^(2/3))
#define plasticRatio 1.32471795724
// 2π / goldenRatio^2
#define goldenAngle  2.39996322973

#define rotMatGR     mat2(-0.047220096, 0.998884509, -0.998884509, -0.047220096)
#define rotMatGA     mat2(-0.737368878, 0.675490294, -0.675490294, -0.737368878)

#define min3(a, b, c)                   min(a, min(b, c))
#define max3(a, b, c)                   max(a, max(b, c))
#define min4(a, b, c, d)                min(min(a, b), min(c, d))
#define max4(a, b, c, d)                max(max(a, b), max(c, d))
#define min5(a, b, c, d, e)             min(a, min(b, min(c, min(d, e))))
#define max5(a, b, c, d, e)             max(a, max(b, max(c, max(d, e))))
#define min9(a, b, c, d, e, f, g, h, i) min(a, min(b, min(c, min(d, min(e, min(f, min(g, min(h, i))))))))
#define max9(a, b, c, d, e, f, g, h, i) max(a, max(b, max(c, max(d, max(e, max(f, max(g, max(h, i))))))))
#define saturate(x)                     clamp(x, 0.0, 1.0)
#define curve(x)                        ((x) * (x) * (3.0 - 2.0 * (x)))
#define Luminance(c)                    dot(c, vec3(0.2125, 0.7154, 0.0721))
#define Radiance(c)                     dot(c, vec3(0.333333333))
#define fsign(x)                        uintBitsToFloat((floatBitsToUint(x) & 0x80000000u) | 0x3f800000u)
#define fsign01(x)                      uintBitsToFloat((floatBitsToUint(x) & 0x80000000u) | 0x3f800000u)
#define fsqrt(x)                        intBitsToFloat(0x1fbd1df5 + (floatBitsToInt(x) >> 1))

float minVec2(vec2 v){
	return min(v.x, v.y);
}

float maxVec2(vec2 v){
	return max(v.x, v.y);
}

float minVec3(vec3 v){
	return min(v.x, min(v.y, v.z));
}

float maxVec3(vec3 v){
	return max(v.x, max(v.y, v.z));
}

float minVec4(vec4 v){
	return min(min(v.x, v.y), min(v.z, v.w));
}

float maxVec4(vec4 v){
	return max(max(v.x, v.y), max(v.z, v.w));
}

float curveTop(float x){
	x = x - 1.0;
	return 1.0 - x * x;
}

vec3 curveTop(vec3 x){
	x = x - 1.0;
	return 1.0 - x * x;
}

float remapSaturate(float x, float e0, float e1){
	return saturate((x - e0) / (e1 - e0));
}

float atan2(vec2 v){
	return v.x == 0.0 ?
		(1.0 - step(abs(v.y), 0.0)) * sign(v.y) * hPI :
		atan(v.y / v.x) + step(v.x, 0.0) * sign(v.y) * PI;
}

float facos(float x){
	float res = -0.156583 * abs(x) + hPI; 
	res *= fsqrt(1.0 - abs(x));
	return x >= 0 ? res : PI - res;
}


vec3 LinearToGamma(vec3 c){
	return pow(c, vec3(1.0 / 2.2));
}

vec3 GammaToLinear(vec3 c){
	return pow(c, vec3(2.2));
}

float LinearToGamma(float c){
	return pow(c, 1.0 / 2.2);
}

float GammaToLinear(float c){
	return pow(c, 2.2);
}

vec3 LinearToSrgb(vec3 c) {
   return mix(
		c * 12.92, 
		pow(c, vec3(1.0 / 2.4)) * 1.055 - 0.055,
		step(vec3(0.0031308), c)
	);
}

vec3 SrgbToLinear(vec3 c) {
	return mix(
		c / 12.92,
		pow((c + 0.055) / 1.055, vec3(2.4)),
		step(vec3(0.04045), c)
	);
}

float LinearToCurve(float c){
	return pow(c, 0.25);
}

float CurveToLinear(float c){
	c = c * c;
	return c * c;
}

vec3 LinearToCurve(vec3 c){
	return pow(c, vec3(0.25));
}

vec3 CurveToLinear(vec3 c){
	c = c * c;
	return c * c;
}



vec3 AlbedoToAbsorption(vec3 albedo, float alpha){
	//return mix(vec3(0.95), albedo * 0.9, pow(alpha, 0.25));
	return mix(vec3(0.7), albedo * (1.0 - alpha * 0.6), fsqrt(alpha) * 0.33 + 0.67);
}


void DoNightEye(inout vec3 c){
	float luminance = Luminance(c);
	c = mix(c, luminance * vec3(0.7771, 1.0038, 1.6190), vec3(0.44444444));
}


float Pack2xU8_to_U16(vec2 x){
	uvec2 u = uvec2(saturate(x) * 255.0);
	return float((u.x << 8u) | u.y) / 65535.0;
}

vec2 Unpack2xU8_from_U16(float x){
	uint u = uint(x * 65535.0);
	return vec2(u >> 8u, u & 255u) / 255.0;
}

float Unpack2xU8_X_from_U16(float x){
	uint u = uint(x * 65535.0);
	return float(u >> 8u) / 255.0;
}

float Unpack2xU8_Y_from_U16(float x){
	uint u = uint(x * 65535.0);
	return float(u & 255u) / 255.0;
}

vec2 Unpack2xU8_ID_from_U16(float x){
	uint u = uint(x * 65535.0);
	return vec2(float(u >> 8u) / 255.0, float(u & 127u));
}

float Unpack2xU8_ID_Y_from_U16(float x){
	uint u = uint(x * 65535.0);
	return float(u & 127u);
}

vec2 Unpack2xU8_ID_LOD_Y_from_U16(float x){
	uint u = uint(x * 65535.0);
	return vec2(u & 127u, u & 128u);
}


vec2 Pack3xU10_to_2xU16(vec3 x){
	uvec3 u = uvec3(saturate(x) * 1023.0);
	return vec2((u.x << 5u) | (u.z >> 5u), (u.y << 5u) | (u.z & 31u)) / 65535.0;
}

vec3 Unpack3xU10_from_2xU16(vec2 x){
	uvec2 u = uvec2(x * 65535.0);
	return vec3(u.x >> 5u, u.y >> 5u, ((u.x & 31u) << 5u) | (u.y & 31u)) / 1023.0;
}





float Pack2xU16_to_F32(vec2 x){
	uvec2 u = uvec2(saturate(x) * 65535.0);
	return uintBitsToFloat((u.x << 16u) | u.y);
}

vec2 Unpack2xU16_from_F32(float x){
	uint u = floatBitsToUint(x);
	return vec2(u >> 16u, u & 65535u) / 65535.0;
}


vec2 Pack2xU16_to_2xF16(vec2 x){
	uvec2 u = uvec2(saturate(x) * 65535.0);
	return unpackHalf2x16((u.x << 16u) | u.y);
}

vec2 Unpack2xU16_from_2xF16(vec2 x){
	uint u = packHalf2x16(x);
	return vec2(u >> 16u, u & 65535u) / 65535.0;
}


/*
float Pack8_4_4(vec3 x){
	uvec3 u = uvec3(saturate(x.x) * 255.0, saturate(x.yz) * 15.0);
	return float((u.x << 8u) | (u.y << 4u) | u.z) / 65535.0;
}

vec3 Unpack8_4_4(float x){
	uint u = uint(x * 65535.0);
	return vec3(u >> 8u, (u & 240u) >> 4u, u & 15u) * vec3(1.0 / 255.0, 1.0 / 15.0, 1.0 / 15.0);
}

float Unpack8_4_4_X(float x){
	uint u = uint(x * 65535.0);
	return float(u >> 8u) / 255.0;
}

float Unpack8_4_4_Y(float x){
	uint u = uint(x * 65535.0);
	return float((u & 240u) >> 4u) / 15.0;
}

float Unpack8_4_4_Z(float x){
	uint u = uint(x * 65535.0);
	return float(u & 15u) / 15.0;
}

vec2 PackU24_U8_to_2xU16(vec2 x){
	uint ux = min(uint(saturate(x.x) * 16777216.0), 16777215u);
	uint uy = uint(saturate(x.y) * 255.0);
	return vec2(ux >> 8u, ((ux & 255u) << 8u) | uy) / 65535.0;
}

vec2 UnpackU24_U8_from_2xU16(vec2 x){
	uvec2 u = uvec2(x * 65535.0);
	float fx = float((u.x << 8u) | (u.y >> 8u)) / 16777216.0;
	float fy = float(u.y & 255u) / 255.0;
	return vec2(fx, fy);
}

float Unpack24_8_X(vec2 x){
	uvec2 u = uvec2(x * 65535.0);
	return float((u.x << 8u) | (u.y >> 8u)) / 16777216.0;
}

*/



vec3 PosProject(vec3 pos, mat4 projectMat){
	return (vec3(vec2(projectMat[0][0], projectMat[1][1]) * pos.xy, 0.0) + projectMat[3].xyz) / (projectMat[2][3] * pos.z + projectMat[3][3]);
}

vec3 PosUnproject(vec3 pos, mat4 unprojectMat){
	return (vec3(unprojectMat[0][0], unprojectMat[1][1], unprojectMat[2][2]) * pos + unprojectMat[3].xyz) / -pos.z * 0.5 + 0.5;
}

// https://realtimecollisiondetection.net/blog/?p=15
// http://www.anyhere.com/gward/papers/jgtpap1.pdf
const mat3 packLogluv32Mat = mat3(
	0.2209, 0.3390, 0.4184,
	0.1138, 0.6780, 0.7319,
	0.0102, 0.1130, 0.2969
);

const mat3 unpackLogluv32Mat = mat3(
	6.0014, -2.7008, -1.7996,
	-1.3320, 3.1029, -5.7721,
	0.3008, -1.0882, 5.6268
);

vec2 PackLogluv2xU16(vec3 rgb){
	vec2 logluv = vec2(0.0);
    if (any(greaterThan(rgb, vec3(0.0)))){
		vec3 Xp_Y_XYZp = packLogluv32Mat * rgb;
		Xp_Y_XYZp = max(Xp_Y_XYZp, 1e-37);
 
    	logluv.x = Pack2xU8_to_U16(saturate(Xp_Y_XYZp.xy / Xp_Y_XYZp.z));
		logluv.y = log2(Xp_Y_XYZp.y) * (1.0 / 64.0) + 0.5;
	}
    return logluv;
}


vec3 UnpackLogluv2xU16(vec2 logluv) {
	vec3 rgb = vec3(0.0);
    if (any(greaterThan(logluv, vec2(0.0)))){
		vec2 uv = Unpack2xU8_from_U16(logluv.x);

		vec3 Xp_Y_XYZp;
		Xp_Y_XYZp.y = exp2(logluv.y * 64.0 - 32.0);
		Xp_Y_XYZp.z = Xp_Y_XYZp.y / uv.y;
		Xp_Y_XYZp.x = uv.x * Xp_Y_XYZp.z;

		rgb = max(unpackLogluv32Mat * Xp_Y_XYZp, 0.0);
	}
    return rgb;
}

uint PackLogluvU32(vec3 rgb){
	uint logluv = 0u;
    if (any(greaterThan(rgb, vec3(0.0)))){
		vec3 Xp_Y_XYZp = packLogluv32Mat * rgb;
		Xp_Y_XYZp = max(Xp_Y_XYZp, 1e-37);
 
    	uvec2 uv = uvec2(saturate(Xp_Y_XYZp.xy / Xp_Y_XYZp.z) * 255.0);
		logluv = (uv.x << 24u) | (uv.y << 16u);
		logluv = logluv | uint(saturate(log2(Xp_Y_XYZp.y) * (1.0 / 64.0) + 0.5) * 65535.0);
	}
    return logluv;
}

vec3 UnpackLogluvU32(uint logluv){
	vec3 rgb = vec3(0.0);
    if (logluv > 0u){
		vec2 uv = vec2((logluv & 0xff000000u) >> 24u, (logluv & 0x00ff0000u) >> 16u) / 255.0;
		float l = float(logluv & 0x0000ffffu) / 65535.0;

		vec3 Xp_Y_XYZp;
		Xp_Y_XYZp.y = exp2(l * 64.0 - 32.0);
		Xp_Y_XYZp.z = Xp_Y_XYZp.y / uv.y;
		Xp_Y_XYZp.x = uv.x * Xp_Y_XYZp.z;

		rgb = max(unpackLogluv32Mat * Xp_Y_XYZp, 0.0);
	}
    return rgb;
}


float BitCountFloat(uint x){
    x = x - ((x >> 1u) & 0x55555555u);
    x = (x & 0x33333333u) + ((x >> 2u) & 0x33333333u);
	x = ((x + (x >> 4u) & 0xF0F0F0Fu) * 0x1010101u) >> 24u;
    return float(x);
}

vec3 DecodeNormalTex(vec3 texNormal){
	vec3 normal = vec3(0.0, 0.0, 1.0);

	if (abs(texNormal.x + texNormal.y + texNormal.z - 1.5) < 1.488){
		normal.xy = texNormal.xy * 2.0 - 1.0;
		normal.xy = max(abs(normal.xy) - 1.0 / 255.0, 0.0) * sign(normal.xy);
		normal.z = sqrt(1.0 - dot(normal.xy, normal.xy));
	}
	return normal;
}

vec2 OctWrap(vec2 v) {
	return (1.0 - abs(v.yx)) * fsign(v.xy);
}

vec2 EncodeNormal(vec3 n){
	n.xy /= (abs(n.x) + abs(n.y) + abs(n.z));
	n.xy = n.z >= 0.0 ? n.xy : OctWrap(n.xy);

	return n.xy * 0.5 + 0.5;
}

vec3 DecodeNormal(vec2 en){
	vec2 n = en * 2.0 - 1.0;

	float nz = 1.0 - abs(n.x) - abs(n.y);
	return normalize(vec3(nz >= 0 ? n : OctWrap(n), nz));
}

vec4 EncodeSH2(float x, vec3 dir){
	const float coefficient0 = 0.5 * sqrt(1.0 / PI);
	const float coefficient1 = 0.5 * sqrt(3.0 / PI);

	return vec4(
		 coefficient0 * x,
		-coefficient1 * x * dir.y,
		 coefficient1 * x * dir.z,
		-coefficient1 * x * dir.x
	);
}

vec3 DecodeSH2(vec4 shR, vec4 shG, vec4 shB, vec3 normal){
	const float coefficient0 = 0.5 * sqrt(1.0 / PI);
	const float coefficient1 = (1.0 / 3.0) * sqrt(3.0 / PI);

	vec4 dirCoeff = vec4(
		 coefficient0,
		-coefficient1 * normal.y,
		 coefficient1 * normal.z,
		-coefficient1 * normal.x
	);

	vec3 color = 	vec3(shR.x, shG.x, shB.x) * dirCoeff.x;
	color += 		vec3(shR.y, shG.y, shB.y) * dirCoeff.y;
	color += 		vec3(shR.z, shG.z, shB.z) * dirCoeff.z;
	color += 		vec3(shR.w, shG.w, shB.w) * dirCoeff.w;

	return color;
}

//https://www.activision.com/cdn/research/ZH3-Publication.pdf

vec3 DecodeHallucinatedZH3(vec4 shR, vec4 shG, vec4 shB, vec3 normal){
	vec3 zonalAxis = normalize(vec3(-Luminance(vec3(shR.w, shG.w, shB.w)), -Luminance(vec3(shR.y, shG.y, shB.y)), Luminance(vec3(shR.z, shG.z, shB.z))));

	vec3 ratio = abs(vec3(
		dot(vec3(-shR.w, -shR.y, shR.z) , zonalAxis),
		dot(vec3(-shG.w, -shG.y, shG.z) , zonalAxis),
		dot(vec3(-shB.w, -shB.y, shB.z) , zonalAxis)
	));
	ratio = abs(ratio / vec3(shR.x, shG.x, shB.x));

	vec3 zonalL2Coeff = vec3(shR.x, shG.x, shB.x) * ratio * (0.08 + 0.6 * ratio);

	float fZ = dot(zonalAxis, normal);
	float zhNormal = sqrt(5.0f / (16.0f * PI)) * (3.0f * fZ * fZ - 1.0f);

    vec3 result = DecodeSH2(shR, shG, shB, normal);
    result += 0.25f * zhNormal * zonalL2Coeff;
    return result;
}

float SkyLightmapCurve(float lightmap){
	lightmap = 1.0 - pow(1.0 - lightmap * 0.9, 0.7);
	return saturate(lightmap * lightmap * lightmap * 1.95);
}


float D_Walter(float NdotH, float roughness){
	float roughness2 = roughness * roughness;
	float k = NdotH * NdotH * (roughness2 - 1.0) + 1.0;
	return roughness2 / (PI * k * k);
}

float F_Schlick(float VdotH, float f0, float f90){
	VdotH = 1.0 - VdotH;
	float VdotH2 = VdotH * VdotH;
	return f0 + (f90 - f0) * VdotH2 * VdotH2 * VdotH;
}

vec3 F_Schlick_Reflection(float VdotH, vec3 f0){
	VdotH = 1.0 - VdotH;
	float VdotH2 = VdotH * VdotH;
	return f0 + (1.0 - f0) * (VdotH2 * VdotH2 * VdotH);
}

float V_Schlick(float NdotL, float NdotV, float roughness){
	float k = roughness * 0.5;
	return (NdotL + 1e-10) / ((NdotL * (1.0 - k) + k) * (NdotV * (1.0 - k) + k) + 1e-20);
}


//Brent Burley. 2012. Physically Based Shading at Disney. Physically Based Shading in Film and Game Production, ACM SIGGRAPH 2012 Courses.
float Fd_Burley(vec3 n, vec3 v, vec3 l, float roughness){
	vec3 h = normalize(v + l);
	float LdotH = saturate(dot(l, h));
	float NdotL = saturate(dot(n, l));
	float NdotV = saturate(dot(n, v));

	float f90 = 0.5 + 2.0 * roughness * LdotH * LdotH;

	float lightScatter = F_Schlick(NdotL, 1.0, f90);
	float viewScatter = F_Schlick(NdotV, 1.0, f90);

	return NdotL * lightScatter * viewScatter * rPI;
}

float Fd_Burley_FullRoughness(vec3 n, vec3 v, vec3 l){
	vec3 h = normalize(v + l);
	float LdotH = saturate(dot(l, h));
	float NdotL = saturate(dot(n, l));
	float NdotV = saturate(dot(n, v));

	float f90 = 0.5 + 2.0 * LdotH * LdotH;

	float lightScatter = F_Schlick(NdotL, 1.0, f90);
	float viewScatter = F_Schlick(NdotV, 1.0, f90);

	return NdotL * lightScatter * viewScatter * 2.0;
}

vec3 SpecularGGX(vec3 n, vec3 v, vec3 l, float roughness, vec3 f0){
	vec3 h = normalize(v + l);
	float NdotH = saturate(dot(n, h));
	float LdotH = saturate(dot(l, h));
	float NdotL = saturate(dot(n, l));
	float NdotV = saturate(dot(n, v));

	vec3 GGX = F_Schlick_Reflection(LdotH, f0);
	GGX *= V_Schlick(NdotL, NdotV, roughness)
	     * D_Walter(NdotH, roughness);

	return GGX;
}


//Modified from "Sampling Visible GGX Normals with Spherical Caps. High-Performance Graphics (2023). URL: https://arxiv.org/pdf/2306.05044"
vec3 GGXVNDF(vec3 viewVector, vec3 normal, float roughness, vec2 noise, float clip){ //, out float pdfWeight
	vec3 normalUp = normalize(vec3(0.0, normal.z, -normal.y));
	mat3 toTangent = mat3(cross(normalUp, normal), normalUp, normal);
	vec3 tangentView = -viewVector * toTangent;

	vec3 orthoNormal = vec3(roughness * tangentView.xy, tangentView.z);
	float orthoLength = length(orthoNormal);
	orthoNormal /= orthoLength;

	#if false
		//https://www.shadertoy.com/view/MX3XDf
		float angle = (2.0 * noise.x - 1.0) * PI;
		
		float dist = 1.0f + length(tangentView.xy);
		float roughness2 = roughness * roughness; 
		float dist2 = dist * dist;
		float k = (1.0 - roughness) * dist2 / (dist2 + roughness * orthoNormal.z * orthoNormal.z); 

		float bound = tangentView.z > 0.0 ? k * orthoNormal.z : orthoNormal.z;

		pdfWeight = (k * tangentView.z + orthoLength) / (tangentView.z + orthoLength);

		noise.y *= clip;

		float z = (1.0 - noise.y) * (1.0 + bound) - bound;
		float sinTheta = sqrt(saturate(1.0 - z * z));
		vec3 sampleVector = vec3(vec2(cos(angle), sin(angle)) * sinTheta, z) + orthoNormal;

	#else
		noise.y *= clip;
		float z = 1.0 - orthoNormal.z * noise.y - noise.y;
		float sinTheta = sqrt(saturate(1.0 - z * z));
		float angle = TAU * noise.x;
		vec3 sampleVector = vec3(vec2(cos(angle), sin(angle)) * sinTheta, z) + orthoNormal;

	#endif

	vec3 vndf = normalize(vec3(roughness * sampleVector.xy, sampleVector.z));
	return reflect(viewVector, toTangent * vndf);
}

 vec3 SEVNDF(vec3 viewVector, vec3 normal, float roughness, vec2 noise, float clip){
	noise.y *= clip;
	float angle = TAU * noise.x;
	float radius = sqrt((1.0 - noise.y) / (1.0 + (roughness * roughness - 1.0) * noise.y));
	float sinTheta = sqrt(1.0 - radius * radius);

	float x = sinTheta * cos(angle);
	float y = sinTheta * sin(angle);

	vec3 T = normalize(cross(normal, vec3(0.0, 1.0, 1.0)));
	vec3 B = cross(T, normal);

	return reflect(viewVector, T * x + B * y + normal * radius);
 }


vec3 HSV_to_RGB_Smooth(float h, float s, float v){
    vec3 rgb = abs(mod(h * 6.0 + vec3(0.0,4.0,2.0), 6.0) - 3.0);
	rgb = curve(saturate(rgb - 1.0));
	return v * mix(vec3(1.0), rgb, s);
}

vec3 Oklab_LCh_to_sRGB(float l, float c, float h){
	h *= (PI / 180.0);

	vec3 lab = vec3(
		l,
		c * cos(h),
		c * sin(h)
	);

	vec3 lms = vec3(
    	lab.x + 0.3963377774 * lab.y + 0.2158037573 * lab.z,
    	lab.x - 0.1055613458 * lab.y - 0.0638541728 * lab.z,
    	lab.x - 0.0894841775 * lab.y - 1.2914855480 * lab.z
	);

    lms = lms * lms * lms;

    return vec3(
		 4.0767416621 * lms.x - 3.3077115913 * lms.y + 0.2309699292 * lms.z,
		-1.2684380046 * lms.x + 2.6097574011 * lms.y - 0.3413193965 * lms.z,
		-0.0041960863 * lms.x - 0.7034186147 * lms.y + 1.7076147010 * lms.z
    );
}

vec3 BlackbodyXyz(float temperature){
	// https://en.wikipedia.org/wiki/Planckian_locus
	const mat2x4 splineX = mat2x4(-0.2661293e9, -0.2343589e6, 0.8776956e3, 0.179910,
								  -3.0258469e9,  2.1070479e6, 0.2226347e3, 0.240390);

	const mat3x4 splineY = mat3x4(-1.1063814, -1.34811020, 2.18555832, -0.20219683,
								  -0.9549476, -1.37418593, 2.09137015, -0.16748867,
								   3.0817580, -5.87338670, 3.75112997, -0.37001483);

	float rt = 1.0 / temperature;
	float rt2 = rt * rt;
	vec4 coeffX = vec4(rt2 * rt, rt2, rt, 1.0);

	float x = dot(coeffX, temperature < 4000.0 ? splineX[0] : splineX[1]);
	float x2 = x * x;
	vec4 coeffY = vec4(x2 * x, x2, x, 1.0);

	float z = 1.0 / dot(coeffY, temperature < 2222.0 ? splineY[0] : temperature < 4000.0 ? splineY[1] : splineY[2]);

	vec3 xyz = vec3(x * z, 1.0, z);
	xyz.z -= xyz.x + 1.0;

	return xyz;

	/*
	const float temperature = 3999.95;
	const mat2x4 splineX = mat2x4(-0.2661293e9, -0.2343589e6, 0.8776956e3, 0.179910,
								-3.0258469e9,  2.1070479e6, 0.2226347e3, 0.240390);

	const mat3x4 splineY = mat3x4(-1.1063814, -1.34811020, 2.18555832, -0.20219683,
								-0.9549476, -1.37418593, 2.09137015, -0.16748867,
								3.0817580, -5.87338670, 3.75112997, -0.37001483);

	const float rt = 1.0 / temperature;
	const float rt2 = rt * rt;
	const vec4 coeffX = vec4(rt2 * rt, rt2, rt, 1.0);
	
	const float xSp0 = dot(coeffX, splineX[0]) + saturate((temperature - 4000.0) * 1e10) * 1e10;
	const float xSp1 = dot(coeffX, splineX[0]) + saturate((3999.9 - temperature) * 1e10) * 1e10;

	const float x = min(xSp0, xSp1);
	const float x2 = x * x;
	const vec4 coeffY = vec4(x2 * x, x2, x, 1.0);

	const float zSp0 = dot(coeffY, splineY[0]) + saturate((0.504166 - x) * 1e10) * 1e10;
	const float zSp1 = dot(coeffY, splineY[1]) + saturate((x - 0.504167) * 1e10) * 1e10 + saturate((0.380007 - x) * 1e10) * 1e10;
	const float zSp2 = dot(coeffY, splineY[2]) + saturate((x - 0.380008) * 1e10) * 1e10;

	const float z = 1.0 / min3(zSp0, zSp1, zSp2);

	const float xyzX = x * z;
	const float xyzZ = z - xyzX - 1.0;


	const mat3 xyzToSrgb = mat3( 3.24097, -0.96924,  0.05563,
								-1.53738,  1.87597, -0.20398,
								-0.49861,  0.04156,  1.05697);

	const vec3 blackbody = max(xyzToSrgb * vec3(xyzX, 1.0, xyzZ), vec3(0.0));
	*/
}

vec3 Blackbody(float temperature){
	const mat3 xyzToSrgb = mat3( 3.24097, -0.96924,  0.05563,
								-1.53738,  1.87597, -0.20398,
								-0.49861,  0.04156,  1.05697);

	return max(xyzToSrgb * BlackbodyXyz(temperature), vec3(0.0));
}

vec3 RayPlaneIntersection(vec3 ori, vec3 dir, vec3 normal){
	float rayPlaneAngle = dot(dir, normal);

	float planeRayDist = 1e8;
	vec3 intersectionPos = dir * planeRayDist;

	if (rayPlaneAngle > 0.0001 || rayPlaneAngle < -0.0001){
		planeRayDist = dot(-ori, normal) / rayPlaneAngle;
		intersectionPos = ori + dir * planeRayDist;
	}

	return intersectionPos;
}

vec2 RaySphereIntersection(vec3 ori, vec3 dir, float radius){
	float b = dot(ori, dir);
	float c = -radius * radius + dot(ori, ori);
	float d = b * b - c;

	vec2 intersection = vec2(1e10, -1e10);

	if (d >= 0.0){
		d = sqrt(d);
		intersection = vec2(-b - d, -b + d);
	}

	return intersection;
}


float RayleighPhaseFunction(float nu) {
	return 0.059683104 * (nu * nu + 1.0);
}

float MiePhaseFunction(float g, float nu) {
	float gg = g * g;
	float k = 0.1193662 * (1.0 - gg) / (2.0 + gg);
	return k * (1.0 + nu * nu) * pow(1.0 + gg - 2.0 * g * nu, -1.5);
}

float HenyeyGreenstein(float inCosAngle, float inG){
	float num = 1.0 - inG * inG;
	float denom = 1.0 + inG * inG - 2.0 * inG * inCosAngle;
	float rsqrt_denom = inversesqrt(denom);
	return num * rsqrt_denom * rsqrt_denom * rsqrt_denom * (0.25 / PI);
}

float IGN(vec2 c){
	return fract(52.9829189 * fract(0.06711056 * c.x + 0.00583715 * c.y));
}

float bayer2(vec2 a) {
	a = floor(a);

	return fract(dot(a, vec2(0.5, a.y * 0.75)));
}

float bayer4  (vec2 a) { return bayer2 (0.5   * a) * 0.25     + bayer2(a); }
float bayer8  (vec2 a) { return bayer4 (0.5   * a) * 0.25     + bayer2(a); }
float bayer16 (vec2 a) { return bayer4 (0.25  * a) * 0.0625   + bayer4(a); }
float bayer32 (vec2 a) { return bayer8 (0.25  * a) * 0.0625   + bayer4(a); }
float bayer64 (vec2 a) { return bayer8 (0.125 * a) * 0.015625 + bayer8(a); }
float bayer128(vec2 a) { return bayer16(0.125 * a) * 0.015625 + bayer8(a); }

//https://extremelearning.com.au/unreasonable-effectiveness-of-quasirandom-sequences/
float Sequences_R1(float n) {
	const float alpha = 1.0 / goldenRatio;
	return fract(0.5 + n * alpha);
}

vec2 Sequences_R2(float n) {
	const vec2 alpha = 1.0 / vec2(plasticRatio, plasticRatio * plasticRatio);
	return fract(0.5 + n * alpha);
}

// https://nullprogram.com/blog/2018/07/31/
uint HashWellons32(uint x){
	x ^= x >> 17;
	x *= 0xed5ad4bbu;
	x ^= x >> 11;
	x *= 0xac4c1b51u;
	x ^= x >> 15;
	x *= 0x31848babu;
	x ^= x >> 14;
	return x;
}

float HashWellons32_Linear(float x){
	float p = floor(x);
	float f = x - p;

	uvec2 a = uint(p) + uvec2(0u, 1u);
	a ^= a >> 17;
	a *= 0xed5ad4bbu;
	a ^= a >> 11;
	a *= 0xac4c1b51u;
	a ^= a >> 15;
	a *= 0x31848babu;
	a ^= a >> 14;

	return mix(float(a.x) / float(0xffffffffu), float(a.y) / float(0xffffffffu), f);
}