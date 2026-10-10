

#define PROGRAM_UPDATE_SSBO

#include "/Lib/Utilities.glsl"
#include "/Lib/UniformDeclare.glsl"


layout (rg16f) uniform image2D img_pixelData2D;

in vec3 vaPosition;


#include "/Lib/Uniform/GbufferTransforms.glsl"


float GetTransMaterialID(ivec2 coord){
	return Unpack2xU8_ID_Y_from_U16(texelFetch(FBTEX_GTRANS_DATA, coord, 0).z);
}

float ToHalf(float v){
    uint u = floatBitsToUint(v);

    uint sign = u & 0x80000000u;
    uint exp  = (u >> 23) & 0xFFu;
    uint mant = u & 0x007FFFFFu;

    //if (exp == 0u || exp == 0xFFu) return v;

    int e32 = int(exp) - 127;
    int e16 = e32 + 15;

    //if (e16 >= 31) return uintBitsToFloat(sign | 0x7F800000u);
    //if (e16 <= 0)  return uintBitsToFloat(sign);

    uint m10      = mant >> 13;
    uint roundBit = (mant >> 12) & 1u;
    uint sticky   = (mant & 0x0FFFu) != 0u ? 1u : 0u;

    if (roundBit == 1u && (sticky == 1u || (m10 & 1u) == 1u)){
        m10 += 1u;
        if (m10 == 0x400u){
            m10 = 0u;
            e16 += 1;
            if (e16 >= 31) return uintBitsToFloat(sign | 0x7F800000u);
        }
    }

    uint newExp  = uint(e32 + 127) << 23;
    uint newMant = m10 << 13;
    return uintBitsToFloat(sign | newExp | newMant);
}

void main(){
	#if defined FSR2 && defined FULLRES_BUFFER
		gl_Position = vec4(vaPosition.xy * 8.0 - vec2(6.5, 1.5), 0.0, 1.0);
	#else
		gl_Position = vec4(vaPosition.xy * 8.0 - vec2(6.5, 1.5), 0.0, 1.0);
	#endif
	
	if (gl_VertexID == 0){
		float preAlpha = texelFetch(pixelData2D, ivec2(PIXELDATA_TITLE_COUNTER, 0), 0).x;
		#ifdef RENDERING_MODE
			float newAlpha = preAlpha < 1.0 ? saturate(frameTimeCounter / RENDERING_MODE_COOLDOWN) : 1.0;

			float renderFrames = 0.0;
			if (rtwDiscardRefresh && newAlpha >= 1.0){
				vec2 prevData = texelFetch(pixelData2D, ivec2(PIXELDATA_RENDER_FRAMES, 0), 0).xy;
				renderFrames = min(prevData.x * 1000.0 + prevData.y + 1.0, 1e6);
			}
			imageStore(img_pixelData2D, ivec2(PIXELDATA_RENDER_FRAMES, 0), vec4(floor(renderFrames / 1000.0), mod(renderFrames, 1000.0), 0.0, 0.0));
		#else
			float newAlpha = preAlpha < 1.0 ? saturate(float(frameCounter) * 0.1) : 1.0;
		#endif
		imageStore(img_pixelData2D, ivec2(PIXELDATA_TITLE_COUNTER, 0), vec4(newAlpha, 0.0, 0.0, 0.0));



		float worldTimeF = float(worldTime + isEyeInWater * 150) + float(newAlpha < 1.0) * 150.0;
		imageStore(img_pixelData2D, ivec2(PIXELDATA_WORLDTIME, 0), vec4(worldTimeF, 0.0, 0.0, 0.0));



		#if defined DOF && CAMERA_FOCUS_MODE == 0
			float prevCenterDepth = texelFetch(pixelData2D, ivec2(PIXELDATA_CENTER_DEPTH, 0), 0).x;
			
			prevCenterDepth = prevCenterDepth <= 0.0 ? 0.98 : ScreenDepth_From_LinearDepth(prevCenterDepth);

			float f = exp2(-frameTime * (10.0 / DOF_DEPTH_SMMOOTH_HALFLIFE));
			ivec2 centerTexelCoord = ivec2(UNIFORM_SCREEN_SIZE * 0.5);

			#ifdef DOF_FOCUS_IGNORE_HAND_PARTICLE
				float centerMaterialID = GetTransMaterialID(centerTexelCoord);
				if (centerMaterialID == MATID_PARTICLE) f = 1.0;

				float centerDepth = 0.0;
				if (heldItemId != 11000.0 && centerMaterialID == MATID_HAND){
					centerDepth = texelFetch(depthtex2, centerTexelCoord, 0).x;
				}else{
					centerDepth = texelFetch(depthtex0, centerTexelCoord, 0).x;
				}

			#else
				float centerDepth = texelFetch(depthtex0, centerTexelCoord, 0).x;

			#endif

			#ifdef LOD_RENDERING
				if (centerDepth == 1.0){
					centerDepth = texelFetch(LOD_DEPTH_TEX_0, centerTexelCoord, 0).x;
					centerDepth = ScreenDepth_From_LODScreenDepth(centerDepth);
				}
			#endif

			centerDepth = max(LinearDepth_From_ScreenDepth(mix(centerDepth, prevCenterDepth, f)), 0.3);
			imageStore(img_pixelData2D, ivec2(PIXELDATA_CENTER_DEPTH, 0), vec4(centerDepth, 0.0, 0.0, 0.0));
		#endif



		#if FOG_SKYLIGHT_FALLOFF > 0
			vec2 bPacked = texelFetch(pixelData2D, ivec2(PIXELDATA_DAMPING_0, 0), 0).xy;
			vec2 vPacked = texelFetch(pixelData2D, ivec2(PIXELDATA_DAMPING_1, 0), 0).xy;
			
			float eyeBrightnessCurved = (bPacked.x + bPacked.y) / 32768.0;
			float currEyeBrightness = remapSaturate(float(eyeBrightness.y), 136.0, 192.0);

			#if FOG_SKYLIGHT_FALLOFF == 1
				const float w = 0.75;
			#elif FOG_SKYLIGHT_FALLOFF == 2
				const float w = 1.5;
			#elif FOG_SKYLIGHT_FALLOFF == 3
				const float w = 3.0;
			#endif

			float dx = eyeBrightnessCurved - currEyeBrightness;
			float dt = max(frameTime , 0.005);
			float v = (vPacked.x + vPacked.y)  / 32768.0;
			
			float ew = exp(-w * frameTime);
			float fx = v + w * dx;
			dx = (dx + fx * frameTime) * ew;
			v = (v - w * fx * frameTime) * ew;

			eyeBrightnessCurved = currEyeBrightness + dx;

			if (abs(eyeBrightnessCurved - currEyeBrightness) < 1e-3 || frameCounter == 1){
				eyeBrightnessCurved = currEyeBrightness;
				v = 0.0;
			}

			float b = eyeBrightnessCurved * 32768.0;
			float bHigh = ToHalf(b);
			float bLow = b - bHigh;
			v *= 32768.0;
			float vHigh = ToHalf(v);
			float vLow = v - vHigh;

			imageStore(img_pixelData2D, ivec2(PIXELDATA_EYE_BRIGHTNESS, 0), vec4(eyeBrightnessCurved, 0.0, 0.0, 0.0));
			imageStore(img_pixelData2D, ivec2(PIXELDATA_DAMPING_0, 0), vec4(bHigh, bLow, 0.0, 0.0));
			imageStore(img_pixelData2D, ivec2(PIXELDATA_DAMPING_1, 0), vec4(vHigh, vLow, 0.0, 0.0));
		#endif
	}
}