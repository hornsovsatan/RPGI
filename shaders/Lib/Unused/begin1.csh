#version 430


#include "/Lib/UniformDeclare.glsl"
#include "/Lib/Utilities.glsl"

#include "/Lib/Unused/wssCommon.glsl"


const ivec3 workGroups = ivec3(128, 256, 1);
layout (local_size_x = 16, local_size_y = 8) in;

layout (rg32f) writeonly uniform image2D img_rippleX2D;

uniform sampler2D rippleX2D;
uniform sampler2D rippleY2D;
uniform sampler2D rippleXY2D;

#define FETCH(uv) texelFetch(rippleY2D, clamp(uv, ivec2(0), ivec2(GridSize-1.0)), 0)


void main(){
    ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
    vec2 uv0 = vec2(uv) + 0.5;

    if(uv0.x > GridSize || uv0.y > GridSize) return;

    vec4 col = vec4(0.0);
    
    vec2 h12 = texelFetch(rippleX2D, uv, 0).xy;
    
    float terrH = -th;

    vec2 tuv = fract(uv0 / GridScale / 2.54);
    float tn = textureLod(noisetex, tuv, 0.0).z;
    terrH = -0.3 - tn * 0.7;
    //terrH *= 0.7;

    float mask = 1.0;
    float D = clamp01(-terrH);
    float lD2 = clamp01(-terrH-1.0);

    // 30 tabs version (vertical pass; horizontal pass in Buffer B)
    float lowp3[4] = float[4](5.0/16.0, 15.0/64.0, 3.0/32.0, 1.0/64.0);   
    float lowp7[8] = float[8](429.0/2048.0, 3003.0/16384.0, 1001.0/8192.0, 1001.0/16384.0, 91.0/4096.0, 91.0/16384.0, 7.0/8192.0, 1.0/16384.0);   
    float lapl7[8] = float[8](3.22, -1.9335988099476562, 0.4384577800334821, -0.1637450351359609, 0.07015324480535713, -0.02963974593026339, 0.010609595665007715, -0.0022370294899667453);   

    float lowpass3  = 0.0;
    float lowpass7  = 0.0;
    float laplacian = 0.0;
    
    for(int y = -7; y <= 7; ++y)
    {
        vec3 f = FETCH(uv + ivec2(0, y)).xyz;
    
        int i = abs(y);

        lowpass3  += f.x * (i < 4 ? lowp3[i] : 0.0);
        lowpass7  += f.y * lowp7[i];
        laplacian += f.z * lapl7[i];
    }

    vec4 f0 = FETCH(uv);
    
    laplacian += f0.w;
    
    float highpass = f0.z - mix(lowpass3, lowpass7, 0.772 * lD2);
    float halfLaplacian =   mix(highpass, laplacian, 0.19)*1.255;

    float Aa = laplacian;
    float Ab = halfLaplacian;
   

  
    float A = mix(Aa, Ab, (D*D) / (2.0/7.0 + 5.0/7.0 * (D*D))) * D;
    
   // A = Ab;// deep
   // A = Aa * 0.5;// shallow

    A *= -9.81*GridScale;



    int fc = frameCounter % afi;

    uint se = uint(fc) + 432423u;
    // rain drops
    if(WellonsHash(se) < 140000000u)
    {
        for (float x = 0.0; x < 9.0; x++){
        for (float y = 0.0; y < 9.0; y++){
            vec2 c = Float01(uvec2(
                HashWellons32(se + 90898u), 
                HashWellons32(se + 444444444u)
            ));
            c = (c + vec2(x, y)) * GridSize / 9.0;

            vec2 vec = (uv0 - c);
        
            float v = exp2(-dot(vec, vec) * 0.9);
            h12 = mix(h12, vec2(Float01(HashWellons32(se + 114514u)) * 0.6 + 0.2), v);
        }}
    }

    float dt = 0.016667;
    float dt2 =  dt * dt;

    float h0 = 0.0;
    float h1 = h12.x;
    float h2 = h12.y;

#if 1
    // Verlet integration
    h0 = (2.0 * h1 - h2) + A * dt2;

#else

    // ...damped version
    float a = 1.0/2.0;
    float adt = a * dt;
    
    h0 = (((2.0 + adt) * h1 - h2) + A * dt2) / (1.0 + adt);

#endif

    vec2 h01 = vec2(h0, h1);

    // exponential state buffer smoothing
    float beta = 2.0;
    h01 = mix(h01, h12, 1.0-exp2(-dt*beta));


    // grid windowing
    bool isGridWindowed = true;
    if(isGridWindowed)
    {
        float r = 32.0;

        vec2 u = min((vec2(GridSize*0.5) - abs(uv0 - vec2(GridSize*0.5))) / r, vec2(1.0));

        u = 1.0 - u;
        u *= u;
        u *= u;
        u = 1.0 - u;

        float s = u.x*u.y;

        h01 *= mix(0.75, 1.0, s);        
    }
    
    h01 *= df; 

    //h01 = vec2(tn);
    
    col = vec4(h01, 0.0, 0.0);




	imageStore(img_rippleX2D, uv, col);
}