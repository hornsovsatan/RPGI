//_____________________________________________________________/\_______________________________________________________________
//==============================================================================================================================
//
//                                         [FFX SPD] Single Pass Downsampler 2.0
//
//==============================================================================================================================
// LICENSE
// =======
// Copyright (c) 2017-2020 Advanced Micro Devices, Inc. All rights reserved.
// -------
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
// -------
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
// Software.
// -------
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
// WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
//------------------------------------------------------------------------------------------------------------------------------

#extension GL_KHR_shader_subgroup_quad:require


shared uint spdCounter;

void SpdIncreaseAtomicCounter(uint slice){
    spdCounter = atomicAdd(ssb_spdAtomicCounter[slice], 1u);
}

uint SpdGetAtomicCounter(){
    return spdCounter;
}

void SpdResetAtomicCounter(uint slice){
    ssb_spdAtomicCounter[slice] = 0u;
}


shared vec4 spdIntermediate[16][16];

vec4 SpdLoadIntermediate(uint x, uint y){
    return spdIntermediate[x][y];
}

void SpdStoreIntermediate(uint x, uint y, vec4 value){
    spdIntermediate[x][y] = value;
}


// Only last active workgroup should proceed
bool SpdExitWorkgroup(uint numWorkGroups, uint localInvocationIndex, uint slice){
	// global atomic counter
	if (localInvocationIndex == 0){
		SpdIncreaseAtomicCounter(slice);
	}
	barrier();
	return (SpdGetAtomicCounter() != (numWorkGroups - 1));
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// User defined: vec4 SpdReduce4(vec4 v0, vec4 v1, vec4 v2, vec4 v3);

vec4 SpdReduceQuad(vec4 v){
	vec4 v0 = v;
	vec4 v1 = subgroupQuadSwapHorizontal(v);
	vec4 v2 = subgroupQuadSwapVertical(v);
	vec4 v3 = subgroupQuadSwapDiagonal(v);
	return SpdReduce4(v0, v1, v2, v3);

	/*
	// if SM6.0 is not available, you can use the AMD shader intrinsics
	// the AMD shader intrinsics are available in AMD GPU Services (AGS) library:
	// https://gpuopen.com/amd-gpu-services-ags-library/
	// works for DX11
	vec4 v0 = v;
	vec4 v1;
	v1.x = AmdExtD3DShaderIntrinsics_SwizzleF(v.x, AmdExtD3DShaderIntrinsicsSwizzle_SwapX1);
	v1.y = AmdExtD3DShaderIntrinsics_SwizzleF(v.y, AmdExtD3DShaderIntrinsicsSwizzle_SwapX1);
	v1.z = AmdExtD3DShaderIntrinsics_SwizzleF(v.z, AmdExtD3DShaderIntrinsicsSwizzle_SwapX1);
	v1.w = AmdExtD3DShaderIntrinsics_SwizzleF(v.w, AmdExtD3DShaderIntrinsicsSwizzle_SwapX1);
	vec4 v2;
	v2.x = AmdExtD3DShaderIntrinsics_SwizzleF(v.x, AmdExtD3DShaderIntrinsicsSwizzle_SwapX2);
	v2.y = AmdExtD3DShaderIntrinsics_SwizzleF(v.y, AmdExtD3DShaderIntrinsicsSwizzle_SwapX2);
	v2.z = AmdExtD3DShaderIntrinsics_SwizzleF(v.z, AmdExtD3DShaderIntrinsicsSwizzle_SwapX2);
	v2.w = AmdExtD3DShaderIntrinsics_SwizzleF(v.w, AmdExtD3DShaderIntrinsicsSwizzle_SwapX2);
	vec4 v3;
	v3.x = AmdExtD3DShaderIntrinsics_SwizzleF(v.x, AmdExtD3DShaderIntrinsicsSwizzle_ReverseX4);
	v3.y = AmdExtD3DShaderIntrinsics_SwizzleF(v.y, AmdExtD3DShaderIntrinsicsSwizzle_ReverseX4);
	v3.z = AmdExtD3DShaderIntrinsics_SwizzleF(v.z, AmdExtD3DShaderIntrinsicsSwizzle_ReverseX4);
	v3.w = AmdExtD3DShaderIntrinsics_SwizzleF(v.w, AmdExtD3DShaderIntrinsicsSwizzle_ReverseX4);
	return SpdReduce4(v0, v1, v2, v3);
	*/
	return v;
}

vec4 SpdReduceIntermediate(uvec2 i0, uvec2 i1, uvec2 i2, uvec2 i3){
	vec4 v0 = SpdLoadIntermediate(i0.x, i0.y);
	vec4 v1 = SpdLoadIntermediate(i1.x, i1.y);
	vec4 v2 = SpdLoadIntermediate(i2.x, i2.y);
	vec4 v3 = SpdLoadIntermediate(i3.x, i3.y);
	return SpdReduce4(v0, v1, v2, v3);
}

vec4 SpdReduceLoad4(uvec2 i0, uvec2 i1, uvec2 i2, uvec2 i3, uint slice){
	vec4 v0 = SpdLoad(ivec2(i0), slice);
	vec4 v1 = SpdLoad(ivec2(i1), slice);
	vec4 v2 = SpdLoad(ivec2(i2), slice);
	vec4 v3 = SpdLoad(ivec2(i3), slice);
	return SpdReduce4(v0, v1, v2, v3);
}

vec4 SpdReduceLoad4(uvec2 base, uint slice){
	return SpdReduceLoad4(
		uvec2(base + uvec2(0, 0)),
		uvec2(base + uvec2(0, 1)), 
		uvec2(base + uvec2(1, 0)), 
		uvec2(base + uvec2(1, 1)),
		slice);
}

vec4 SpdReduceLoadSourceImage4(uvec2 i0, uvec2 i1, uvec2 i2, uvec2 i3, uint slice){
	vec4 v0 = SpdLoadSourceImage(ivec2(i0), slice);
	vec4 v1 = SpdLoadSourceImage(ivec2(i1), slice);
	vec4 v2 = SpdLoadSourceImage(ivec2(i2), slice);
	vec4 v3 = SpdLoadSourceImage(ivec2(i3), slice);
	return SpdReduce4(v0, v1, v2, v3);
}

vec4 SpdReduceLoadSourceImage(uvec2 base, uint slice){
#ifdef SPD_LINEAR_SAMPLER
	return SpdLoadSourceImage(ivec2(base), slice);
#else
	return SpdReduceLoadSourceImage4(
		uvec2(base + uvec2(0, 0)),
		uvec2(base + uvec2(0, 1)), 
		uvec2(base + uvec2(1, 0)), 
		uvec2(base + uvec2(1, 1)),
		slice);
#endif
}

void SpdDownsampleMips_0_1(uint x, uint y, uvec2 workGroupID, uint localInvocationIndex, uint mip, uint slice){
	vec4 v[4];

	ivec2 tex = ivec2(workGroupID.xy * 64) + ivec2(x * 2, y * 2);
	ivec2 pix = ivec2(workGroupID.xy * 32) + ivec2(x, y);
	v[0] = SpdReduceLoadSourceImage(tex, slice);
	SpdStore(pix, v[0], 1, slice);

	tex = ivec2(workGroupID.xy * 64) + ivec2(x * 2 + 32, y * 2);
	pix = ivec2(workGroupID.xy * 32) + ivec2(x + 16, y);
	v[1] = SpdReduceLoadSourceImage(tex, slice);
	SpdStore(pix, v[1], 1, slice);

	tex = ivec2(workGroupID.xy * 64) + ivec2(x * 2, y * 2 + 32);
	pix = ivec2(workGroupID.xy * 32) + ivec2(x, y + 16);
	v[2] = SpdReduceLoadSourceImage(tex, slice);
	SpdStore(pix, v[2], 1, slice);
	
	tex = ivec2(workGroupID.xy * 64) + ivec2(x * 2 + 32, y * 2 + 32);
	pix = ivec2(workGroupID.xy * 32) + ivec2(x + 16, y + 16);
	v[3] = SpdReduceLoadSourceImage(tex, slice);
	SpdStore(pix, v[3], 1, slice);

	if (mip < 2) return;

	v[0] = SpdReduceQuad(v[0]);
	v[1] = SpdReduceQuad(v[1]);
	v[2] = SpdReduceQuad(v[2]);
	v[3] = SpdReduceQuad(v[3]);

	if ((localInvocationIndex % 4) == 0){
		SpdStore(ivec2(workGroupID.xy * 16) + ivec2(x/2, y/2), v[0], 2, slice);
		SpdStoreIntermediate(x/2, y/2, v[0]);

		SpdStore(ivec2(workGroupID.xy * 16) + ivec2(x/2 + 8, y/2), v[1], 2, slice);
		SpdStoreIntermediate(x/2 + 8, y/2, v[1]);

		SpdStore(ivec2(workGroupID.xy * 16) + ivec2(x/2, y/2 + 8), v[2], 2, slice);
		SpdStoreIntermediate(x/2, y/2 + 8, v[2]);

		SpdStore(ivec2(workGroupID.xy * 16) + ivec2(x/2 + 8, y/2 + 8), v[3], 2, slice);
		SpdStoreIntermediate(x/2 + 8, y/2 + 8, v[3]);
	}
}

void SpdDownsampleMip_2(uint x, uint y, uvec2 workGroupID, uint localInvocationIndex, uint mip, uint slice){
	vec4 v = SpdLoadIntermediate(x, y);
	v = SpdReduceQuad(v);
	// quad index 0 stores result
	if (localInvocationIndex % 4 == 0){
		SpdStore(ivec2(workGroupID.xy * 8) + ivec2(x/2, y/2), v, mip, slice);
		SpdStoreIntermediate(x + (y/2) % 2, y, v);
	}
}

void SpdDownsampleMip_3(uint x, uint y, uvec2 workGroupID, uint localInvocationIndex, uint mip, uint slice)
{
	if (localInvocationIndex < 64)
	{
		vec4 v = SpdLoadIntermediate(x * 2 + y % 2,y * 2);
		v = SpdReduceQuad(v);
		// quad index 0 stores result
		if (localInvocationIndex % 4 == 0){   
			SpdStore(ivec2(workGroupID.xy * 4) + ivec2(x/2, y/2), v, mip, slice);
			SpdStoreIntermediate(x * 2 + y/2, y * 2, v);
		}
	}
}

void SpdDownsampleMip_4(uint x, uint y, uvec2 workGroupID, uint localInvocationIndex, uint mip, uint slice)
{
	if (localInvocationIndex < 16)
	{
		vec4 v = SpdLoadIntermediate(x * 4 + y,y * 4);
		v = SpdReduceQuad(v);
		// quad index 0 stores result
		if (localInvocationIndex % 4 == 0){
			SpdStore(ivec2(workGroupID.xy * 2) + ivec2(x/2, y/2), v, mip, slice);
			SpdStoreIntermediate(x / 2 + y, 0, v);
		}
	}
}

void SpdDownsampleMip_5(uvec2 workGroupID, uint localInvocationIndex, uint mip, uint slice)
{
	if (localInvocationIndex < 4)
	{
		vec4 v = SpdLoadIntermediate(localInvocationIndex,0);
		v = SpdReduceQuad(v);
		// quad index 0 stores result
		if (localInvocationIndex % 4 == 0){   
			SpdStore(ivec2(workGroupID.xy), v, mip, slice);
		}
	}
}

void SpdDownsampleMips_6_7(uint x, uint y, uint mip, uint slice)
{
	ivec2 tex = ivec2(x * 4 + 0, y * 4 + 0);
	ivec2 pix = ivec2(x * 2 + 0, y * 2 + 0);
	vec4 v0 = SpdReduceLoad4(tex, slice);
	SpdStore(pix, v0, 7, slice);

	tex = ivec2(x * 4 + 2, y * 4 + 0);
	pix = ivec2(x * 2 + 1, y * 2 + 0);
	vec4 v1 = SpdReduceLoad4(tex, slice);
	SpdStore(pix, v1, 7, slice);

	tex = ivec2(x * 4 + 0, y * 4 + 2);
	pix = ivec2(x * 2 + 0, y * 2 + 1);
	vec4 v2 = SpdReduceLoad4(tex, slice);
	SpdStore(pix, v2, 7, slice);

	tex = ivec2(x * 4 + 2, y * 4 + 2);
	pix = ivec2(x * 2 + 1, y * 2 + 1);
	vec4 v3 = SpdReduceLoad4(tex, slice);
	SpdStore(pix, v3, 7, slice);

	if (mip < 8) return;
	// no barrier needed, working on values only from the same thread

	vec4 v = SpdReduce4(v0, v1, v2, v3);
	SpdStore(ivec2(x, y), v, 8, slice);
	SpdStoreIntermediate(x, y, v);
}

void SpdDownsampleNextFour(uint x, uint y, uvec2 workGroupID, uint localInvocationIndex, uint baseMip, uint mip, uint slice)
{
	if (mip < baseMip) return;
	barrier();
	SpdDownsampleMip_2(x, y, workGroupID, localInvocationIndex, baseMip, slice);

	if (mip < baseMip + 1) return;
	barrier();
	SpdDownsampleMip_3(x, y, workGroupID, localInvocationIndex, baseMip + 1, slice);

	if (mip < baseMip + 2) return;
	barrier();
	SpdDownsampleMip_4(x, y, workGroupID, localInvocationIndex, baseMip + 2, slice);

	if (mip < baseMip + 3) return;
	barrier();
	SpdDownsampleMip_5(workGroupID, localInvocationIndex, baseMip + 3, slice);
}

uvec2 ARmpRed8x8(uint a){
	return uvec2(
		bitfieldInsert(bitfieldExtract(a, 2, 3), a, 0, 1), 
		bitfieldInsert(bitfieldExtract(a, 3, 3), bitfieldExtract(a, 1, 2), 0, 2)
	);
}

void SpdDownsample(
	uvec2 workGroupID,
	uint localInvocationIndex,
	uint mip,
	uint numWorkGroups,
	uint slice
){
	uvec2 sub_xy = ARmpRed8x8(localInvocationIndex % 64);
	uint x = sub_xy.x + 8 * ((localInvocationIndex >> 6) % 2);
	uint y = sub_xy.y + 8 * ((localInvocationIndex >> 7));
	SpdDownsampleMips_0_1(x, y, workGroupID, localInvocationIndex, mip, slice);

	SpdDownsampleNextFour(x, y, workGroupID, localInvocationIndex, 3, mip, slice);

	if (mip < 7) return;

	if (SpdExitWorkgroup(numWorkGroups, localInvocationIndex, slice)) return;

	SpdResetAtomicCounter(slice);

	// After mip 6 there is only a single workgroup left that downsamples the remaining up to 64x64 texels.
	SpdDownsampleMips_6_7(x, y, mip, slice);

	SpdDownsampleNextFour(x, y, uvec2(0,0), localInvocationIndex, 9, mip, slice);
}

