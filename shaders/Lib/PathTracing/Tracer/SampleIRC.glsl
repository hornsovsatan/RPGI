

#ifdef PT_IRC

vec4 SampleIrradianceCache_Raw_OutBlocker(ivec3 ircTexel, float sampleWeight, out float blocker){
	vec4 ircColor = texelFetch(irradianceCache3D, ircTexel, 0);
	blocker = saturate(ircColor.a);
	ircColor = vec4(ircColor.rgb * sampleWeight, float(dot(ircColor.rgb, vec3(1.0)) > 0.0) * sampleWeight);
	return ircColor - blocker * ircColor;
}

vec4 SampleIrradianceCache_Raw_Blocker(ivec3 ircTexel, float sampleWeight){
	vec4 ircColor = texelFetch(irradianceCache3D, ircTexel, 0);
	sampleWeight *= saturate(1.0 - ircColor.a);
	return vec4(ircColor.rgb * sampleWeight, float(dot(ircColor.rgb, vec3(1.0)) > 0.0) * sampleWeight);
}

vec4 SampleIrradianceCache_Raw(ivec3 ircTexel, float sampleWeight){
	vec3 ircColor = texelFetch(irradianceCache3D, ircTexel, 0).rgb;
	return vec4(ircColor * sampleWeight, float(dot(ircColor, vec3(1.0)) > 0.0) * sampleWeight);
}


vec4 SampleIrradianceCache_Raw_OutBlocker_Alt(ivec3 ircTexel, float sampleWeight, out float blocker){
	vec4 ircColor = texelFetch(irradianceCache3D_Alt, ircTexel, 0);
	blocker = saturate(ircColor.a);
	ircColor = vec4(ircColor.rgb * sampleWeight, float(dot(ircColor.rgb, vec3(1.0)) > 0.0) * sampleWeight);
	return ircColor - blocker * ircColor;
}

vec4 SampleIrradianceCache_Raw_Blocker_Alt(ivec3 ircTexel, float sampleWeight){
	vec4 ircColor = texelFetch(irradianceCache3D_Alt, ircTexel, 0);
	sampleWeight *= saturate(1.0 - ircColor.a);
	return  vec4(ircColor.rgb * sampleWeight, float(dot(ircColor.rgb, vec3(1.0)) > 0.0) * sampleWeight);
}

vec4 SampleIrradianceCache_Raw_Alt(ivec3 ircTexel, float sampleWeight){
	vec3 ircColor = texelFetch(irradianceCache3D_Alt, ircTexel, 0).rgb;
	return vec4(ircColor * sampleWeight, float(dot(ircColor, vec3(1.0)) > 0.0) * sampleWeight);
}





vec3 SampleIrradianceCache(vec3 hitVoxelPos){
	vec3 ircColor = vec3(0.0);
	ivec3 ircTexel = ivec3(hitVoxelPos) + ((ircResolutionInt - voxelResolutionInt) >> 1);

	if (clamp(ircTexel, ivec3(0), ircResolutionInt - 1) == ircTexel){
		if ((frameCounter & 1) == 0){
			ircColor = texelFetch(irradianceCache3D, ircTexel, 0).rgb;
		}else{
			ircColor = texelFetch(irradianceCache3D_Alt, ircTexel, 0).rgb;
		}

		ircColor *= PT_IRC_DIFFUSE_IRRADIANCE_STRENGTH * 0.01;
	}

	return ircColor;
}

vec3 SampleIrradianceCache_Bilinear_Blocker(vec3 hitVoxelPos){
	vec3 ircColor = vec3(0.0);

	vec3 ircTexelCoord = hitVoxelPos + vec3((ircResolutionInt - voxelResolutionInt) >> 1);
	ivec3 ircTexel = ivec3(ircTexelCoord);

	if (clamp(ircTexel, ivec3(1), ircResolutionInt - 2) == ircTexel){
		vec3 p = floor(ircTexelCoord + 0.5);
		vec3 f = saturate(ircTexelCoord + 0.5 - p);
		f = curve(f);

		vec3 axis = fsign(p - ircTexelCoord);
		f = mix(1.0 - f, f, axis * 0.5 + 0.5);
		vec3 rf = 1.0 - f;

		ivec3 iaxis = ivec3(axis);

		if ((frameCounter & 1) == 0){
			vec3 ircColor000 = texelFetch(irradianceCache3D, ivec3(ircTexel.x, ircTexel.y, ircTexel.z), 0).rgb;
			ircColor += ircColor000 * rf.x * rf.y * rf.z;

			vec4 ircColor100 = texelFetch(irradianceCache3D, ivec3(ircTexel.x + iaxis.x, ircTexel.y, ircTexel.z), 0);
			vec4 ircColor001 = texelFetch(irradianceCache3D, ivec3(ircTexel.x, ircTexel.y, ircTexel.z + iaxis.z), 0);
			float blocker = saturate(ircColor100.a) + saturate(ircColor001.a) * 2.0;

			vec4 ircColor010 = texelFetch(irradianceCache3D, ivec3(ircTexel.x, ircTexel.y + iaxis.y, ircTexel.z), 0);
			blocker += saturate(ircColor010.a) * 4.0;

			if (blocker < 6.5){
				vec4 ircColor101 = texelFetch(irradianceCache3D, ivec3(ircTexel.x + iaxis.x, ircTexel.y, ircTexel.z + iaxis.z), 0);
				blocker += saturate(ircColor101.a) * 8.0;

				vec4 ircColor110 = texelFetch(irradianceCache3D, ivec3(ircTexel.x + iaxis.x, ircTexel.y + iaxis.y, ircTexel.z), 0);
				blocker += saturate(ircColor110.a) * 16.0;

				vec4 ircColor011 = texelFetch(irradianceCache3D, ivec3(ircTexel.x, ircTexel.y + iaxis.y, ircTexel.z + iaxis.z), 0);
				blocker += saturate(ircColor011.a) * 32.0;

				int iblocker = int(round(blocker));
				if ((iblocker & 30) == 30){
					ircColor += ircColor100.rgb * f.x * rf.y * rf.z;

				}else if ((iblocker & 45) == 45){
					ircColor += ircColor001.rgb * rf.x * rf.y * f.z;

				}else if ((iblocker & 51) == 51){
					ircColor += ircColor010.rgb * rf.x * f.y * rf.z;

				}else{
					ircColor += ircColor100.rgb *  f.x * rf.y * rf.z;
					ircColor += ircColor001.rgb * rf.x * rf.y *  f.z;
					ircColor += ircColor010.rgb * rf.x *  f.y * rf.z;
					ircColor += ircColor101.rgb *  f.x * rf.y *  f.z;
					ircColor += ircColor110.rgb *  f.x *  f.y * rf.z;
					ircColor += ircColor011.rgb * rf.x *  f.y *  f.z;

					vec3 ircColor111 = texelFetch(irradianceCache3D, ivec3(ircTexel.x + iaxis.x, ircTexel.y + iaxis.y, ircTexel.z + iaxis.z), 0).rgb;
					ircColor += ircColor111.rgb * f.x * f.y * f.z;
				}
			}
		}else{
			vec3 ircColor000 = texelFetch(irradianceCache3D_Alt, ivec3(ircTexel.x, ircTexel.y, ircTexel.z), 0).rgb;
			ircColor += ircColor000 * rf.x * rf.y * rf.z;

			vec4 ircColor100 = texelFetch(irradianceCache3D_Alt, ivec3(ircTexel.x + iaxis.x, ircTexel.y, ircTexel.z), 0);
			vec4 ircColor001 = texelFetch(irradianceCache3D_Alt, ivec3(ircTexel.x, ircTexel.y, ircTexel.z + iaxis.z), 0);
			float blocker = saturate(ircColor100.a) + saturate(ircColor001.a) * 2.0;

			vec4 ircColor010 = texelFetch(irradianceCache3D_Alt, ivec3(ircTexel.x, ircTexel.y + iaxis.y, ircTexel.z), 0);
			blocker += saturate(ircColor010.a) * 4.0;

			if (blocker < 6.5){
				vec4 ircColor101 = texelFetch(irradianceCache3D_Alt, ivec3(ircTexel.x + iaxis.x, ircTexel.y, ircTexel.z + iaxis.z), 0);
				blocker += saturate(ircColor101.a) * 8.0;

				vec4 ircColor110 = texelFetch(irradianceCache3D_Alt, ivec3(ircTexel.x + iaxis.x, ircTexel.y + iaxis.y, ircTexel.z), 0);
				blocker += saturate(ircColor110.a) * 16.0;

				vec4 ircColor011 = texelFetch(irradianceCache3D_Alt, ivec3(ircTexel.x, ircTexel.y + iaxis.y, ircTexel.z + iaxis.z), 0);
				blocker += saturate(ircColor011.a) * 32.0;

				int iblocker = int(round(blocker));
				if ((iblocker & 30) == 30){
					ircColor += ircColor100.rgb * f.x * rf.y * rf.z;

				}else if ((iblocker & 45) == 45){
					ircColor += ircColor001.rgb * rf.x * rf.y * f.z;

				}else if ((iblocker & 51) == 51){
					ircColor += ircColor010.rgb * rf.x * f.y * rf.z;

				}else{
					ircColor += ircColor100.rgb *  f.x * rf.y * rf.z;
					ircColor += ircColor001.rgb * rf.x * rf.y *  f.z;
					ircColor += ircColor010.rgb * rf.x *  f.y * rf.z;
					ircColor += ircColor101.rgb *  f.x * rf.y *  f.z;
					ircColor += ircColor110.rgb *  f.x *  f.y * rf.z;
					ircColor += ircColor011.rgb * rf.x *  f.y *  f.z;

					vec3 ircColor111 = texelFetch(irradianceCache3D_Alt, ivec3(ircTexel.x + iaxis.x, ircTexel.y + iaxis.y, ircTexel.z + iaxis.z), 0).rgb;
					ircColor += ircColor111.rgb * f.x * f.y * f.z;
				}
			}
		}
	}

	return ircColor;
}




/*
vec3 SampleIrradianceCache_Smooth(vec3 hitVoxelPos, vec3 hitNormal){
	ivec3 hitVoxelCoord = ivec3(hitVoxelPos);
	ivec3 ircTexel = hitVoxelCoord + ((ircResolution - voxelResolutionInt) >> 1);
	vec4 ircColor = vec4(0.0);

	if (clamp(ircTexel, 1, ircResolution - 2) == ircTexel){
		vec3 centerOffset = vec3(hitVoxelCoord) + 0.5 - hitVoxelPos;

		hitNormal = abs(hitNormal);
		hitNormal.xy = step(maxVec3(hitNormal), hitNormal.xz);
		vec3 T = vec3(1.0 - hitNormal.x, hitNormal.x, 0.0);
		vec3 B = vec3(0.0, hitNormal.y, 1.0 - hitNormal.y);

		if ((frameCounter & 1) == 0){
			vec3 sampleOffset = centerOffset;
			float sampleWeight = exp2(-dot(sampleOffset, sampleOffset) * PT_IRC_BLUR_FACTOR);
			ircColor += SampleIrradianceCache_Raw(ircTexel, sampleWeight);

			sampleOffset = centerOffset -T;
			sampleWeight = exp2(-dot(sampleOffset, sampleOffset) * PT_IRC_BLUR_FACTOR);
			ircColor += SampleIrradianceCache_Raw(ircTexel + ivec3(-T), sampleWeight);

			sampleOffset = centerOffset -B;
			sampleWeight = exp2(-dot(sampleOffset, sampleOffset) * PT_IRC_BLUR_FACTOR);
			ircColor += SampleIrradianceCache_Raw(ircTexel + ivec3(-B), sampleWeight);

			sampleOffset = centerOffset -T -B;
			sampleWeight = exp2(-dot(sampleOffset, sampleOffset) * PT_IRC_BLUR_FACTOR);
			ircColor += SampleIrradianceCache_Raw(ircTexel + ivec3(-T -B), sampleWeight);

			sampleOffset = centerOffset +T;
			sampleWeight = exp2(-dot(sampleOffset, sampleOffset) * PT_IRC_BLUR_FACTOR);
			ircColor += SampleIrradianceCache_Raw(ircTexel + ivec3(T), sampleWeight);

			sampleOffset = centerOffset +T -B;
			sampleWeight = exp2(-dot(sampleOffset, sampleOffset) * PT_IRC_BLUR_FACTOR);
			ircColor += SampleIrradianceCache_Raw(ircTexel + ivec3(T -B), sampleWeight);

			sampleOffset = centerOffset +B;
			sampleWeight = exp2(-dot(sampleOffset, sampleOffset) * PT_IRC_BLUR_FACTOR);
			ircColor += SampleIrradianceCache_Raw(ircTexel + ivec3(B), sampleWeight);

			sampleOffset = centerOffset -T +B;
			sampleWeight = exp2(-dot(sampleOffset, sampleOffset) * PT_IRC_BLUR_FACTOR);
			ircColor += SampleIrradianceCache_Raw(ircTexel + ivec3(-T +B), sampleWeight);

			sampleOffset = centerOffset +T +B;
			sampleWeight = exp2(-dot(sampleOffset, sampleOffset) * PT_IRC_BLUR_FACTOR);
			ircColor += SampleIrradianceCache_Raw(ircTexel + ivec3(T +B), sampleWeight);
		}else{
			vec3 sampleOffset = centerOffset;
			float sampleWeight = exp2(-dot(sampleOffset, sampleOffset) * PT_IRC_BLUR_FACTOR);
			ircColor += SampleIrradianceCache_Raw_Alt(ircTexel, sampleWeight);

			sampleOffset = centerOffset -T;
			sampleWeight = exp2(-dot(sampleOffset, sampleOffset) * PT_IRC_BLUR_FACTOR);
			ircColor += SampleIrradianceCache_Raw_Alt(ircTexel + ivec3(-T), sampleWeight);

			sampleOffset = centerOffset -B;
			sampleWeight = exp2(-dot(sampleOffset, sampleOffset) * PT_IRC_BLUR_FACTOR);
			ircColor += SampleIrradianceCache_Raw_Alt(ircTexel + ivec3(-B), sampleWeight);

			sampleOffset = centerOffset -T -B;
			sampleWeight = exp2(-dot(sampleOffset, sampleOffset) * PT_IRC_BLUR_FACTOR);
			ircColor += SampleIrradianceCache_Raw_Alt(ircTexel + ivec3(-T -B), sampleWeight);

			sampleOffset = centerOffset +T;
			sampleWeight = exp2(-dot(sampleOffset, sampleOffset) * PT_IRC_BLUR_FACTOR);
			ircColor += SampleIrradianceCache_Raw_Alt(ircTexel + ivec3(T), sampleWeight);

			sampleOffset = centerOffset +T -B;
			sampleWeight = exp2(-dot(sampleOffset, sampleOffset) * PT_IRC_BLUR_FACTOR);
			ircColor += SampleIrradianceCache_Raw_Alt(ircTexel + ivec3(T -B), sampleWeight);

			sampleOffset = centerOffset +B;
			sampleWeight = exp2(-dot(sampleOffset, sampleOffset) * PT_IRC_BLUR_FACTOR);
			ircColor += SampleIrradianceCache_Raw_Alt(ircTexel + ivec3(B), sampleWeight);

			sampleOffset = centerOffset -T +B;
			sampleWeight = exp2(-dot(sampleOffset, sampleOffset) * PT_IRC_BLUR_FACTOR);
			ircColor += SampleIrradianceCache_Raw_Alt(ircTexel + ivec3(-T +B), sampleWeight);

			sampleOffset = centerOffset +T +B;
			sampleWeight = exp2(-dot(sampleOffset, sampleOffset) * PT_IRC_BLUR_FACTOR);
			ircColor += SampleIrradianceCache_Raw_Alt(ircTexel + ivec3(T +B), sampleWeight);
		}

		ircColor.rgb *= 0.01 / max(ircColor.a, 1e-10);
	}

	return ircColor.rgb;
}
*/
vec3 SampleIrradianceCache_Full(vec3 hitVoxelPos, vec3 hitNormal, vec3 skylightColor, vec3 shadowlightColor, float lightmap){
	vec3 ircColor = vec3(0.0);
	ivec3 ircTexel = ivec3(hitVoxelPos) + ((ircResolutionInt - voxelResolutionInt) >> 1);

	if (clamp(ircTexel, ivec3(0), ircResolutionInt - 1) == ircTexel){
		if ((frameCounter & 1) == 0){
			ircColor = texelFetch(irradianceCache3D, ircTexel, 0).rgb * 0.01;
		}else{
			ircColor = texelFetch(irradianceCache3D_Alt, ircTexel, 0).rgb * 0.01;
		}
	}else{
		#if defined DIMENSION_OVERWORLD || defined DIMENSION_END
			ircColor = SimpleSkyLighting(skylightColor, shadowlightColor, hitNormal.y, lightmap);
		#else
			ircColor = NetherLighting();
		#endif

		#ifdef DIMENSION_OVERWORLD
			ircColor += vec3(0.97, 0.99, 1.18) * NOLIGHT_BRIGHTNESS;
			ircColor += vec3(WATER_SCATTERING_R, WATER_SCATTERING_G, WATER_SCATTERING_B) * (dot(vec3(2e-4), skylightColor) * float(isEyeInWater == 1));
		#endif
	}

	return ircColor;
}

vec3 SampleIrradianceCache_Full_Smooth(vec3 hitVoxelPos, vec3 hitNormal, vec3 skylightColor, vec3 shadowlightColor, float lightmap){
	vec4 ircColor = vec4(0.0);
	ivec3 hitVoxelCoord = ivec3(hitVoxelPos);
	ivec3 ircTexel = hitVoxelCoord + ((ircResolutionInt - voxelResolutionInt) >> 1);

	if (clamp(ircTexel, ivec3(1), ircResolutionInt - 2) == ircTexel){
		vec3 centerOffset = vec3(hitVoxelCoord) + 0.5 - hitVoxelPos;

		hitNormal = abs(hitNormal);
		hitNormal.xy = step(maxVec3(hitNormal), hitNormal.xz);
		vec3 T = vec3(1.0 - hitNormal.x, hitNormal.x, 0.0);
		vec3 B = vec3(0.0, hitNormal.y, 1.0 - hitNormal.y);

		float blocker = 0.0;

		if ((frameCounter & 1) == 0){
			vec3 sampleOffset = centerOffset;
			float sampleWeight = exp2(-dot(sampleOffset, sampleOffset) * PT_IRC_BLUR_FACTOR);
			ircColor += SampleIrradianceCache_Raw(ircTexel, sampleWeight);

			sampleOffset = centerOffset -T;
			sampleWeight = exp2(-dot(sampleOffset, sampleOffset) * PT_IRC_BLUR_FACTOR);
			ircColor += SampleIrradianceCache_Raw_OutBlocker(ircTexel + ivec3(-T), sampleWeight, blocker);

			float blocker00 = blocker;
			float blocker01 = blocker;

			sampleOffset = centerOffset -B;
			sampleWeight = exp2(-dot(sampleOffset, sampleOffset) * PT_IRC_BLUR_FACTOR);
			ircColor += SampleIrradianceCache_Raw_OutBlocker(ircTexel + ivec3(-B), sampleWeight, blocker);

			blocker00 += blocker;
			float blocker10 = blocker;

			if (blocker00 < 1.5){
				sampleOffset = centerOffset -T -B;
				sampleWeight = exp2(-dot(sampleOffset, sampleOffset) * PT_IRC_BLUR_FACTOR);
				ircColor += SampleIrradianceCache_Raw_Blocker(ircTexel + ivec3(-T -B), sampleWeight);
			}

			sampleOffset = centerOffset +T;
			sampleWeight = exp2(-dot(sampleOffset, sampleOffset) * PT_IRC_BLUR_FACTOR);
			ircColor += SampleIrradianceCache_Raw_OutBlocker(ircTexel + ivec3(T), sampleWeight, blocker);

			blocker10 += blocker;
			float blocker11 = blocker;

			if (blocker10 < 1.5){
				sampleOffset = centerOffset +T -B;
				sampleWeight = exp2(-dot(sampleOffset, sampleOffset) * PT_IRC_BLUR_FACTOR);
				ircColor += SampleIrradianceCache_Raw_Blocker(ircTexel + ivec3(T -B), sampleWeight);
			}

			sampleOffset = centerOffset +B;
			sampleWeight = exp2(-dot(sampleOffset, sampleOffset) * PT_IRC_BLUR_FACTOR);
			ircColor += SampleIrradianceCache_Raw_OutBlocker(ircTexel + ivec3(B), sampleWeight, blocker);

			blocker01 += blocker;
			blocker11 += blocker;

			if (blocker01 < 1.5){
				sampleOffset = centerOffset -T +B;
				sampleWeight = exp2(-dot(sampleOffset, sampleOffset) * PT_IRC_BLUR_FACTOR);
				ircColor += SampleIrradianceCache_Raw_Blocker(ircTexel + ivec3(-T +B), sampleWeight);
			}

			if (blocker11 < 1.5){
				sampleOffset = centerOffset +T +B;
				sampleWeight = exp2(-dot(sampleOffset, sampleOffset) * PT_IRC_BLUR_FACTOR);
				ircColor += SampleIrradianceCache_Raw_Blocker(ircTexel + ivec3(T +B), sampleWeight);
			}
		}else{
			vec3 sampleOffset = centerOffset;
			float sampleWeight = exp2(-dot(sampleOffset, sampleOffset) * PT_IRC_BLUR_FACTOR);
			ircColor += SampleIrradianceCache_Raw_Alt(ircTexel, sampleWeight);

			sampleOffset = centerOffset -T;
			sampleWeight = exp2(-dot(sampleOffset, sampleOffset) * PT_IRC_BLUR_FACTOR);
			ircColor += SampleIrradianceCache_Raw_OutBlocker_Alt(ircTexel + ivec3(-T), sampleWeight, blocker);

			float blocker00 = blocker;
			float blocker01 = blocker;

			sampleOffset = centerOffset -B;
			sampleWeight = exp2(-dot(sampleOffset, sampleOffset) * PT_IRC_BLUR_FACTOR);
			ircColor += SampleIrradianceCache_Raw_OutBlocker_Alt(ircTexel + ivec3(-B), sampleWeight, blocker);

			blocker00 += blocker;
			float blocker10 = blocker;

			if (blocker00 < 1.5){
				sampleOffset = centerOffset -T -B;
				sampleWeight = exp2(-dot(sampleOffset, sampleOffset) * PT_IRC_BLUR_FACTOR);
				ircColor += SampleIrradianceCache_Raw_Blocker_Alt(ircTexel + ivec3(-T -B), sampleWeight);
			}

			sampleOffset = centerOffset +T;
			sampleWeight = exp2(-dot(sampleOffset, sampleOffset) * PT_IRC_BLUR_FACTOR);
			ircColor += SampleIrradianceCache_Raw_OutBlocker_Alt(ircTexel + ivec3(T), sampleWeight, blocker);

			blocker10 += blocker;
			float blocker11 = blocker;

			if (blocker10 < 1.5){
				sampleOffset = centerOffset +T -B;
				sampleWeight = exp2(-dot(sampleOffset, sampleOffset) * PT_IRC_BLUR_FACTOR);
				ircColor += SampleIrradianceCache_Raw_Blocker_Alt(ircTexel + ivec3(T -B), sampleWeight);
			}

			sampleOffset = centerOffset +B;
			sampleWeight = exp2(-dot(sampleOffset, sampleOffset) * PT_IRC_BLUR_FACTOR);
			ircColor += SampleIrradianceCache_Raw_OutBlocker_Alt(ircTexel + ivec3(B), sampleWeight, blocker);

			blocker01 += blocker;
			blocker11 += blocker;

			if (blocker01 < 1.5){
				sampleOffset = centerOffset -T +B;
				sampleWeight = exp2(-dot(sampleOffset, sampleOffset) * PT_IRC_BLUR_FACTOR);
				ircColor += SampleIrradianceCache_Raw_Blocker_Alt(ircTexel + ivec3(-T +B), sampleWeight);
			}

			if (blocker11 < 1.5){
				sampleOffset = centerOffset +T +B;
				sampleWeight = exp2(-dot(sampleOffset, sampleOffset) * PT_IRC_BLUR_FACTOR);
				ircColor += SampleIrradianceCache_Raw_Blocker_Alt(ircTexel + ivec3(T +B), sampleWeight);
			}
		}

		ircColor.rgb *= 0.01 / max(ircColor.a, 1e-10);
	}else{
		#if defined DIMENSION_OVERWORLD || defined DIMENSION_END
			ircColor.rgb = SimpleSkyLighting(skylightColor, shadowlightColor, hitNormal.y, lightmap);
		#else
			ircColor.rgb = NetherLighting();
		#endif

		#ifdef DIMENSION_OVERWORLD
			ircColor.rgb += vec3(0.97, 0.99, 1.18) * NOLIGHT_BRIGHTNESS;
			ircColor.rgb += vec3(WATER_SCATTERING_R, WATER_SCATTERING_G, WATER_SCATTERING_B) * (dot(vec3(2e-4), skylightColor) * float(isEyeInWater == 1));
		#endif
		
	}

	return ircColor.rgb;
}

#endif