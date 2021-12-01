//#define real float
//#define real2 float2
//#define real3 float3
//#define real4 float4
//
//#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/AtmosphericScattering/AtmosphericScattering.cs.hlsl"
//#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/LightDefinition.cs.hlsl"
//
//#define FLOAT_EPS  5.960464478e-8
//
//// ----------------------------------------------------------------------------
//// Macros that override the register local for constant buffers (for ray tracing mainly)
//// ----------------------------------------------------------------------------
//#if (SHADER_STAGE_RAY_TRACING && UNITY_RAY_TRACING_GLOBAL_RESOURCES)
//#define GLOBAL_RESOURCE(type, name, reg) type name : register(reg, space1);
//#define GLOBAL_CBUFFER_START(name, reg) cbuffer name : register(reg, space1) {
//#else
//#define GLOBAL_RESOURCE(type, name, reg) type name;
//#define GLOBAL_CBUFFER_START(name, reg) CBUFFER_START(name)
//#endif
//
//int _DirectionalShadowIndex;
//
////struct DirectionalLightData
////{
////    float3 positionRWS;
////    uint lightLayers;
////    float lightDimmer;
////    float volumetricLightDimmer;
////    float3 forward;
////    int cookieMode;
////    float4 cookieScaleOffset;
////    float3 right;
////    int shadowIndex;
////    float3 up;
////    int contactShadowIndex;
////    float3 color;
////    int contactShadowMask;
////    float3 shadowTint;
////    float shadowDimmer;
////    float volumetricShadowDimmer;
////    int nonLightMappedOnly;
////    float minRoughness;
////    int screenSpaceShadowIndex;
////    float4 shadowMaskSelector;
////    float diffuseDimmer;
////    float specularDimmer;
////    float penumbraTint;
////    float isRayTracedContactShadow;
////    float distanceFromCamera;
////    float angularDiameter;
////    float flareFalloff;
////    float __unused__;
////    float3 flareTint;
////    float flareSize;
////    float3 surfaceTint;
////    float4 surfaceTextureScaleOffset;
////};
//StructuredBuffer<DirectionalLightData> _DirectionalLightDatas;
//
//GLOBAL_CBUFFER_START(ShaderVariablesGlobal, b0)
//float4x4 _ViewMatrix;
//float4x4 _InvViewMatrix;
//float4x4 _ProjMatrix;
//float4x4 _InvProjMatrix;
//float4x4 _ViewProjMatrix;
//float4x4 _CameraViewProjMatrix;
//float4x4 _InvViewProjMatrix;
//float4x4 _NonJitteredViewProjMatrix;
//float4x4 _PrevViewProjMatrix;
//float4x4 _PrevInvViewProjMatrix;
//float4 _WorldSpaceCameraPos_Internal;
//float4 _PrevCamPosRWS_Internal;
//float4 _ScreenSize;
//float4 _RTHandleScale;
//float4 _RTHandleScaleHistory;
////float4 _ZBufferParams;
////float4 _ProjectionParams;
////float4 unity_OrthoParams;
////float4 _ScreenParams;
//float4 _FrustumPlanes[6];
//float4 _ShadowFrustumPlanes[6];
//float4 _TaaFrameInfo;
//float4 _TaaJitterStrength;
////float4 _Time;
////float4 _SinTime;
////float4 _CosTime;
////float4 unity_DeltaTime;
//float4 _TimeParameters;
//float4 _LastTimeParameters;
//int _FogEnabled;
//int _PBRFogEnabled;
//int _EnableVolumetricFog;
//float _MaxFogDistance;
//float4 _FogColor;
//float _FogColorMode;
//float _Pad0;
//float _Pad1;
//float _Pad2;
//float4 _MipFogParameters;
//float4 _HeightFogBaseScattering;
//float _HeightFogBaseExtinction;
//float _HeightFogBaseHeight;
//float _GlobalFogAnisotropy;
//int _VolumetricFilteringEnabled;
//float2 _HeightFogExponents;
//float _Pad4;
//float _Pad5;
//float4 _VBufferViewportSize;
//float4 _VBufferLightingViewportScale;
//float4 _VBufferLightingViewportLimit;
//float4 _VBufferDistanceEncodingParams;
//float4 _VBufferDistanceDecodingParams;
//uint _VBufferSliceCount;
//float _VBufferRcpSliceCount;
//float _VBufferRcpInstancedViewCount;
//float _VBufferLastSliceDist;
//float4 _ShadowAtlasSize;
//float4 _CascadeShadowAtlasSize;
//float4 _AreaShadowAtlasSize;
//float4 _CachedShadowAtlasSize;
//float4 _CachedAreaShadowAtlasSize;
//float4x4 _Env2DCaptureVP[32];
//float4 _Env2DCaptureForward[32];
//float4 _Env2DAtlasScaleOffset[32];
//uint _DirectionalLightCount;
//uint _PunctualLightCount;
//uint _AreaLightCount;
//uint _EnvLightCount;
//int _EnvLightSkyEnabled;
//uint _CascadeShadowCount;
////int _DirectionalShadowIndex;
//uint _EnableLightLayers;
//uint _EnableSkyReflection;
//uint _EnableSSRefraction;
//float _SSRefractionInvScreenWeightDistance;
//float _ColorPyramidLodCount;
//float _DirectionalTransmissionMultiplier;
//float _ProbeExposureScale;
//float _ContactShadowOpacity;
//float _ReplaceDiffuseForIndirect;
//float4 _AmbientOcclusionParam;
//float _IndirectDiffuseLightingMultiplier;
//uint _IndirectDiffuseLightingLayers;
//float _ReflectionLightingMultiplier;
//uint _ReflectionLightingLayers;
//float _MicroShadowOpacity;
//uint _EnableProbeVolumes;
//uint _ProbeVolumeCount;
//float _Pad6;
//float4 _CookieAtlasSize;
//float4 _CookieAtlasData;
//float4 _PlanarAtlasData;
//uint _NumTileFtplX;
//uint _NumTileFtplY;
//float g_fClustScale;
//float g_fClustBase;
//float g_fNearPlane;
//float g_fFarPlane;
//int g_iLog2NumClusters;
//uint g_isLogBaseBufferEnabled;
//uint _NumTileClusteredX;
//uint _NumTileClusteredY;
//int _EnvSliceSize;
//float _Pad7;
//float4 _ShapeParamsAndMaxScatterDists[16];
//float4 _TransmissionTintsAndFresnel0[16];
//float4 _WorldScalesAndFilterRadiiAndThicknessRemaps[16];
//uint4 _DiffusionProfileHashTable[16];
//uint _EnableSubsurfaceScattering;
//uint _TexturingModeFlags;
//uint _TransmissionFlags;
//uint _DiffusionProfileCount;
//float2 _DecalAtlasResolution;
//uint _EnableDecals;
//uint _DecalCount;
//uint _OffScreenRendering;
//uint _OffScreenDownsampleFactor;
//uint _XRViewCount;
//int _FrameCount;
//float4 _CoarseStencilBufferSize;
//int _IndirectDiffuseMode;
//int _EnableRayTracedReflections;
//int _RaytracingFrameIndex;
//uint _EnableRecursiveRayTracing;
//float4 _ProbeVolumeAtlasResolutionAndSliceCount;
//float4 _ProbeVolumeAtlasResolutionAndSliceCountInverse;
//float4 _ProbeVolumeAtlasOctahedralDepthResolutionAndInverse;
//int _ProbeVolumeLeakMitigationMode;
//float _ProbeVolumeBilateralFilterWeightMin;
//float _ProbeVolumeBilateralFilterWeight;
//uint _EnableDecalLayers;
//float4 _ProbeVolumeAmbientProbeFallbackPackedCoeffs[7];
//int _TransparentCameraOnlyMotionVectors;
//float _GlobalTessellationFactorMultiplier;
//float _SpecularOcclusionBlend;
//float _Pad9;
//CBUFFER_END
//
//UNITY_DECLARE_TEXCUBEARRAY(_SkyTexture);
//
//
//float OpticalDepthHeightFog(float baseExtinction, float baseHeight, float2 heightExponents,
//    float cosZenith, float startHeight)
//{
//    float H = heightExponents.y;
//    float rcpH = heightExponents.x;
//    float Z = cosZenith;
//    float absZ = max(abs(cosZenith), FLOAT_EPS);
//    float rcpAbsZ = rcp(absZ);
//
//    float minHeight = (Z >= 0) ? startHeight : -rcp(FLOAT_EPS);
//    float h = max(minHeight - baseHeight, 0);
//
//    float homFogDist = max((baseHeight - minHeight) * rcpAbsZ, 0);
//    float expFogMult = exp(-h * rcpH) * (rcpAbsZ * H);
//
//    return baseExtinction * (homFogDist + expFogMult);
//
//   /* float H = heightExponents.y;
//    float rcpH = heightExponents.x;
//    float Z = cosZenith;
//    float absZ = max(abs(cosZenith), FLOAT_EPS);
//    float rcpAbsZ = rcp(absZ);
//
//    float endHeight = startHeight + intervalLength * Z;
//    float minHeight = min(startHeight, endHeight);
//    float h = max(minHeight - baseHeight, 0);
//
//    float homFogDist = clamp((baseHeight - minHeight) * rcpAbsZ, 0, intervalLength);
//    float expFogDist = intervalLength - homFogDist;
//    float expFogMult = exp(-h * rcpH) * (1 - exp(-expFogDist * absZ * rcpH)) * (rcpAbsZ * H);
//
//    return baseExtinction * (homFogDist + expFogMult);*/
//}
//
//
//
//float4 SampleSkyTexture(float3 texCoord, float lod, int sliceIndex)
//{
//    return UNITY_SAMPLE_TEXCUBEARRAY_LOD(_SkyTexture, float4(texCoord, sliceIndex), lod);
//}
//
//float3 GetFogColor(float3 V, float fragDist)
//{
//    float3 color = _FogColor.rgb;
//
//    if (_FogColorMode == FOGCOLORMODE_SKY_COLOR)
//    {
//        return 1;
//        // Based on Uncharted 4 "Mip Sky Fog" trick: http://advances.realtimerendering.com/other/2016/naughty_dog/NaughtyDog_TechArt_Final.pdf
//        float mipLevel = (1.0 - _MipFogParameters.z * saturate((fragDist - _MipFogParameters.x) / (_MipFogParameters.y - _MipFogParameters.x))) * (ENVCONSTANTS_CONVOLUTION_MIP_COUNT - 1);
//        // For the atmospheric scattering, we use the GGX convoluted version of the cubemap. That matches the of the idnex 0
//        color *= SampleSkyTexture(-V, mipLevel, 0).rgb; // '_FogColor' is the tint
//    }
//
//    return color;
//}
//
//
//void SampleFog(float height, float cameraDist, float3 lightForward, float3 viewDir, float exposure, out float4 color)
//{
//    if (_FogEnabled)
//    {
//        color = 1;
//        color.rgb = GetFogColor(viewDir, cameraDist);
//        return;
//        color = float4(0.0, 0.0, 0.0, 0.0);
//        float expFogStart = 0.0f;
//
//        float  cosZenithAngle = -lightForward.y;
//      /*  float3 oDepth = OpticalDepthHeightFog(_HeightFogBaseExtinction, _HeightFogBaseHeight,
//            _HeightFogExponents, cosZenithAngle, height);
//       
//        float3 transm = exp(-oDepth);
//        color.rgb *= transm;*/
//
//
//        float3 volAlbedo = _HeightFogBaseScattering.xyz / _HeightFogBaseExtinction;
//        float  odFallback = OpticalDepthHeightFog(_HeightFogBaseExtinction, _HeightFogBaseHeight,
//            _HeightFogExponents, cosZenithAngle, height);
//        float  trFallback = exp(-odFallback);
//        float  trCamera = 1 - color.a;
//
//        color.rgb += trCamera * GetFogColor(viewDir, cameraDist) * exposure * volAlbedo * (1 - trFallback);
//        color.a = 1 - (trCamera * trFallback);
//    }
//
//}

