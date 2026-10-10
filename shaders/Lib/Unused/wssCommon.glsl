// License: CC0 (https://creativecommons.org/publicdomain/zero/1.0/)

    #define USE_HQ_KERNEL
     
    // #define USE_AXISALIGNED_OBSTACLES

const float GridScale = 25.0;// vertex spacing; 1 -> meters | 100 -> centimeters 

const float GridSize = 1143.0;// vertex count per dimension

const float th = 0.6;
const float df = 0.9975;

const int fi = 9;
const int afi = fi * 60;


vec2 PatchUVfromScreenUV(vec2 screenUV, vec2 screenResolution)
{
    return vec2(GridSize * 0.5) + (screenUV - screenResolution.xy*0.5)/screenResolution.xx * 226.0;
}


/*
// x: [0, inf], s: (-1, 1] / (soft, hard]
float SoftClip(float x, float s)
{
    return (1.0 + x - sqrt(1.0 - 2.0*s*x + x*x)) / (1.0 + s);
}

vec3 SoftClip(vec3 x, float s)
{
    return (1.0 + x - sqrt(1.0 - 2.0*s*x + x*x)) / (1.0 + s);
}

*/




#define rsqrt inversesqrt
#define clamp01(x) clamp(x, 0.0, 1.0)
#define If(cond, resT, resF) mix(resF, resT, cond)

const float Pi = 3.14159265359;
const float Pi05 = Pi * 0.5;

float Pow2(float x) {return x*x;}
float Pow3(float x) {return x*x*x;}
float Pow4(float x) {return Pow2(Pow2(x));}

/* http://keycode.info/ */
#define KEY_LEFT  37
#define KEY_UP    38
#define KEY_RIGHT 39
#define KEY_DOWN  40

#define KEY_CTRL 17
#define KEY_SHIFT 16
#define KEY_SPACE 32 
#define KEY_A 0x41
#define KEY_D 0x44
#define KEY_S 0x53
#define KEY_W 0x57

#define KEY_N1 49
#define KEY_N2 50
#define KEY_N3 51
#define KEY_N4 52
#define KEY_N5 53
#define KEY_N6 54
#define KEY_N7 55
#define KEY_N8 56

vec3 GammaEncode(vec3 x) {return pow(x, vec3(1.0 / 2.2));}

vec2 AngToVec(float ang)
{	
	return vec2(cos(ang), sin(ang));
}


vec3 AngToVec(vec2 ang)
{
    float sinPhi   = sin(ang.x);
    float cosPhi   = cos(ang.x);
    float sinTheta = sin(ang.y);
    float cosTheta = cos(ang.y);    

    return vec3(cosPhi * cosTheta, 
                         sinTheta, 
                sinPhi * cosTheta); 
}

float cubic(float x) {return x*x*(3.-2.*x);}
vec2  cubic(vec2  x) {return x*x*(3.-2.*x);}
vec3  cubic(vec3  x) {return x*x*(3.-2.*x);}
vec4  cubic(vec4  x) {return x*x*(3.-2.*x);}

float quintic(float x){ return ((x * 6.0 - 15.0) * x + 10.0) * x*x*x;}
vec2  quintic(vec2  x){ return ((x * 6.0 - 15.0) * x + 10.0) * x*x*x;}
vec3  quintic(vec3  x){ return ((x * 6.0 - 15.0) * x + 10.0) * x*x*x;}
vec4  quintic(vec4  x){ return ((x * 6.0 - 15.0) * x + 10.0) * x*x*x;}


uint  asuint2(float x) { return x == 0.0 ? 0u : floatBitsToUint(x); }
uvec2 asuint2(vec2 x) { return uvec2(asuint2(x.x ), asuint2(x.y)); }
uvec3 asuint2(vec3 x) { return uvec3(asuint2(x.xy), asuint2(x.z)); }
uvec4 asuint2(vec4 x) { return uvec4(asuint2(x.xy), asuint2(x.zw)); }

float Float01(uint x) { return float(    x ) * (1.0 / 4294967296.0); }
float Float11(uint x) { return float(int(x)) * (1.0 / 2147483648.0); }

vec2 Float01(uvec2 x) { return vec2(      x ) * (1.0 / 4294967296.0); }
vec2 Float11(uvec2 x) { return vec2(ivec2(x)) * (1.0 / 2147483648.0); }

vec3 Float01(uvec3 x) { return vec3(      x ) * (1.0 / 4294967296.0); }
vec3 Float11(uvec3 x) { return vec3(ivec3(x)) * (1.0 / 2147483648.0); }

vec4 Float01(uvec4 x) { return vec4(      x ) * (1.0 / 4294967296.0); }
vec4 Float11(uvec4 x) { return vec4(ivec4(x)) * (1.0 / 2147483648.0); }

// constants rounded to nearest primes
const uint rPhi1  = 2654435761u;

const uint rPhi2a = 3242174893u;
const uint rPhi2b = 2447445397u;

const uint rPhi3a = 3518319149u;
const uint rPhi3b = 2882110339u;
const uint rPhi3c = 2360945581u;

const uint rPhi4a = 3679390609u;
const uint rPhi4b = 3152041517u;
const uint rPhi4c = 2700274807u;
const uint rPhi4d = 2313257579u;

const uvec2 rPhi2 = uvec2(rPhi2a, rPhi2b);
const uvec3 rPhi3 = uvec3(rPhi3a, rPhi3b, rPhi3c);
const uvec4 rPhi4 = uvec4(rPhi4a, rPhi4b, rPhi4c, rPhi4d);

uint  Roberts(uint  off, uint n) { return off + rPhi1 * n; }
uvec2 Roberts(uvec2 off, uint n) { return off + rPhi2 * n; }
uvec3 Roberts(uvec3 off, uint n) { return off + rPhi3 * n; }
uvec4 Roberts(uvec4 off, uint n) { return off + rPhi4 * n; }

// http://marc-b-reynolds.github.io/math/2016/03/29/weyl_hash.html
uint WeylHash(uvec2 c) 
{
    return ((c.x * 0x3504f333u) ^ (c.y * 0xf1bbcdcbu)) * 741103597u; 
}

// low bias version https://nullprogram.com/blog/2018/07/31/
uint WellonsHash(uint x)
{
    x ^= x >> 16u;
    x *= 0x7feb352dU;
    x ^= x >> 15u;
    x *= 0x846ca68bU;
    x ^= x >> 16u;

    return x;
}

uvec2 WellonsHash(uvec2 v) { return uvec2(WellonsHash(v.x), WellonsHash(v.y)); }

