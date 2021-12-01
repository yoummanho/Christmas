Shader "Hidden/KriptoFX/Water/KW_WaterVolumetricLighting_HDRP"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}

    }
        SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
                HLSLPROGRAM

                #pragma vertex vert
                #pragma fragment frag

#pragma target 4.5

                #pragma multi_compile _ LIGHTLOOP_DISABLE_TILE_AND_CLUSTER
                #pragma multi_compile _ ENABLE_REPROJECTION
                #pragma multi_compile _ ENABLE_ANISOTROPY
                #pragma multi_compile _ VL_PRESET_OPTIMAL
                #pragma multi_compile _ SUPPORT_LOCAL_LIGHTS

                //#define LIGHT_EVALUATION_NO_CONTACT_SHADOWS // To define before LightEvaluation.hlsl
                // #define LIGHT_EVALUATION_NO_HEIGHT_FOG

        /*        #ifndef LIGHTLOOP_DISABLE_TILE_AND_CLUSTER
                    #define USE_BIG_TILE_LIGHTLIST
                #endif*/



                #define PREFER_HALF             0
                #define GROUP_SIZE_1D           8
                #define SHADOW_USE_DEPTH_BIAS   0 // Too expensive, not particularly effective
                #define SHADOW_LOW          // Different options are too expensive.
                #define SHADOW_AUTO_FLIP_NORMAL 0 // No normal information, so no need to flip
                #define SHADOW_VIEW_BIAS        1 // Prevents light leaking through thin geometry. Not as good as normal bias at grazing angles, but cheaper and independent from the geometry.
                #define USE_DEPTH_BUFFER        1 // Accounts for opaque geometry along the camera ray

                // Filter out lights that are not meant to be affecting volumetric once per thread rather than per voxel. This has the downside that it limits the max processable lights to MAX_SUPPORTED_LIGHTS
                // which might be lower than the max number of lights that might be in the big tile. 
                //#define PRE_FILTER_LIGHT_LIST   1 && defined(USE_BIG_TILE_LIGHTLIST)
              // #define USE_CLUSTERED_LIGHTLIST 
                 #define USE_FPTL_LIGHTLIST // Use light tiles for contact shadows
                #define LIGHTLOOP_DISABLE_TILE_AND_CLUSTER

                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/GeometricTools.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Filtering.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/VolumeRendering.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/EntityLighting.hlsl"


                #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Builtin/BuiltinData.hlsl"

                #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
                #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/ShaderPass.cs.hlsl"

                #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/VolumetricLighting/VolumetricLighting.cs.hlsl"
                #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/VolumetricLighting/VBuffer.hlsl"

                #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Sky/PhysicallyBasedSky/PhysicallyBasedSkyCommon.hlsl"

                #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/Lighting.hlsl"
                #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/LightLoop/LightLoopDef.hlsl"
                #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/LightEvaluation.hlsl"

//#if PRE_FILTER_LIGHT_LIST
//
//#if MAX_NR_BIG_TILE_LIGHTS_PLUS_ONE > 48
//#define MAX_SUPPORTED_LIGHTS 48
//#else
//#define MAX_SUPPORTED_LIGHTS MAX_NR_BIG_TILE_LIGHTS_PLUS_ONE
//#endif
//
//int gs_localLightList[GROUP_SIZE_1D * GROUP_SIZE_1D][MAX_SUPPORTED_LIGHTS];
//
//#endif



                 static const float ditherPattern[8][8] = {
                { 0.012f, 0.753f, 0.200f, 0.937f, 0.059f, 0.800f, 0.243f, 0.984f},
                { 0.506f, 0.259f, 0.690f, 0.443f, 0.553f, 0.306f, 0.737f, 0.490f},
                { 0.137f, 0.875f, 0.075f, 0.812f, 0.184f, 0.922f, 0.122f, 0.859f},
                { 0.627f, 0.384f, 0.569f, 0.322f, 0.675f, 0.427f, 0.612f, 0.369f},
                { 0.043f, 0.784f, 0.227f, 0.969f, 0.027f, 0.769f, 0.212f, 0.953f},
                { 0.537f, 0.290f, 0.722f, 0.475f, 0.522f, 0.275f, 0.706f, 0.459f},
                { 0.169f, 0.906f, 0.106f, 0.843f, 0.153f, 0.890f, 0.090f, 0.827f},
                { 0.659f, 0.412f, 0.600f, 0.353f, 0.643f, 0.400f, 0.584f, 0.337f},
                };

                sampler2D KW_WaterMaskScatterNormals_Blured;
                sampler2D KW_WaterDepth;

                uint KW_lightsCount;

                half KW_Transparent;
                half MaxDistance;
                half KW_RayMarchSteps;
                half KW_VolumeLightMaxDistance;			
                half KW_VolumeDepthFade;
                half4 KW_LightAnisotropy;

                float4 KW_VolumeTexSceenSize;
               
                float3 KW_WaterPosition;

                float4 KW_WaterMaskScatterNormals_Blured_TexelSize;
                float4 KW_WaterDepth_TexelSize;
                float4 KW_Frustum[4];
                float4 KW_UV_World[4];
                float4 _CurrentRTHandleSize;
                float4 _CameraDepthTexture_TexelSize;
                float4 Test4;

                struct appdata
                {
                    float4 vertex : POSITION;
                    float2 uv : TEXCOORD0;
                };

                struct v2f
                {
                    float4 vertex : SV_POSITION;
                    float2 uv : TEXCOORD0;
                    float2 ditherPos : TEXCOORD1;
                    float3 frustumWorldPos : TEXCOORD2;
                    float3 uvWorldPos : TEXCOORD3;
                };

                v2f vert(appdata v)
                {
                    v2f o;
                    o.vertex = float4(v.vertex.xy - 0.5, 0, 0.5);
                    o.uv = float2(v.uv.x, 1 - v.uv.y);
                    
                    o.ditherPos = o.uv * KW_VolumeTexSceenSize.xy;
                    o.frustumWorldPos = (KW_Frustum[o.uv.x + o.uv.y * 2]);
                    
                    o.uvWorldPos = (KW_UV_World[o.uv.x + o.uv.y * 2]);
                    return o;
                }

                inline half MieScattering(float cosAngle)
                {
                    return KW_LightAnisotropy.w * (KW_LightAnisotropy.x / (pow(KW_LightAnisotropy.y - KW_LightAnisotropy.z * cosAngle, 1.5)));
                }

                inline float4 RayMarch(float2 uv, float2 ditherScreenPos, float3 topPos, float3 rayStart, float3 rayDir, float rayLength, half isUnderwater)
                {
                    ditherScreenPos = ditherScreenPos % 8;
                    float offset = ditherPattern[ditherScreenPos.y][ditherScreenPos.x];

                    float stepSize = rayLength / KW_RayMarchSteps;
                    float3 step = rayDir * stepSize;
                    float3 currentPos = rayStart + step * offset;

                    float4 result = float4(0,0,0,1);
                    float cosAngle = 0;
                    float shadowDistance = saturate(distance(rayStart, _WorldSpaceCameraPos) - KW_Transparent);
                    float depthFade = 1 - exp(-((_WorldSpaceCameraPos.y - KW_WaterPosition.y) + KW_Transparent));

                    LightLoopContext context;
                    context.shadowContext = InitShadowContext();
                    PositionInputs posInput;
                    float exposure = GetCurrentExposureMultiplier();

                    if (_DirectionalShadowIndex >= 0)
                    {
                        DirectionalLightData dirLight = _DirectionalLightDatas[_DirectionalShadowIndex];
                        float3 L = -dirLight.forward;

                        [loop]
                        for (int j = 0; j < KW_RayMarchSteps; ++j)
                        {
                           
                            int  cascadeCount;

                            
                            posInput.positionWS = currentPos;
                            if ((dirLight.volumetricLightDimmer > 0) && (dirLight.volumetricShadowDimmer > 0))
                                context.shadowValue = GetDirectionalShadowAttenuation(context.shadowContext, uv, currentPos, 0, dirLight.shadowIndex, L);
                            else context.shadowValue = 1;

                            float4 lightColor = EvaluateLight_Directional(context, posInput, dirLight);
                            lightColor.a *= dirLight.volumetricLightDimmer;
                            lightColor.rgb *= lightColor.a; // Composite
                           // atten = lerp(1, atten, dirLight.volumetricShadowDimmer);
                            float3 scattering = stepSize;
//#if defined (USE_CAUSTIC)
//                            float underwaterStrength = lerp(saturate((KW_Transparent - 1) / 5) * 0.5, 1, isUnderwater);
//                            scattering += scattering * ComputeCaustic(rayStart, currentPos) * underwaterStrength;
//
//#endif
                            float3 light = context.shadowValue * scattering * lightColor * exposure;
                            result.rgb += light;
                            currentPos += step;
                        }
                        cosAngle = dot(dirLight.forward.xyz, -rayDir);
                        result.rgb *= MieScattering(cosAngle) * 0.5;
                       
                        result.a = lerp(1, GetDirectionalShadowAttenuation(context.shadowContext, uv, topPos, 0, dirLight.shadowIndex, L), dirLight.volumetricShadowDimmer);
                   }
                 
//
                    if (LIGHTFEATUREFLAGS_PUNCTUAL) 
                    {
                        uint lightCount, lightStart;

#ifndef LIGHTLOOP_DISABLE_TILE_AND_CLUSTER
                        uint2 pixelCoord = uint2(uv * KW_VolumeTexSceenSize.xy);
                        int2 tileCoord = (float2)pixelCoord / GetTileSize();
                        PositionInputs posInput = GetPositionInput(pixelCoord, KW_VolumeTexSceenSize.zw, tileCoord);
                        GetCountAndStart(posInput, LIGHTCATEGORY_PUNCTUAL, lightStart, lightCount);
#else   // LIGHTLOOP_DISABLE_TILE_AND_CLUSTER
                        lightCount = _PunctualLightCount;
                        lightStart = 0;
#endif

                        uint startFirstLane = 0;
                        bool fastPath;

                        fastPath = IsFastPath(lightStart, startFirstLane);
                        if (fastPath)
                        {
                            lightStart = startFirstLane;
                        }

                        uint v_lightIdx = lightStart;
                        uint v_lightListOffset = 0;
                        while (v_lightListOffset < lightCount)
                        {
                            v_lightIdx = FetchIndex(lightStart, v_lightListOffset);
                            uint s_lightIdx = ScalarizeElementIndex(v_lightIdx, fastPath);
                            if (s_lightIdx == -1)
                                break;

                           LightData addLight = FetchLight(s_lightIdx);
                           if (s_lightIdx >= v_lightIdx) 
                           {
                               v_lightListOffset++;
                               currentPos = rayStart + step * offset;

                               [loop]
                               for (int i = 0; i < KW_RayMarchSteps; ++i)
                               {

                                   float3 L;
                                   float4 distances; // {d, d^2, 1/d, d_proj}
                                   GetPunctualLightVectors(currentPos, addLight, L, distances);

                                   float4 lightColor = float4(addLight.color, 1.0);
                                   lightColor.a = PunctualLightAttenuation(distances, addLight.rangeAttenuationScale, addLight.rangeAttenuationBias, addLight.angleScale, addLight.angleOffset);
                                   lightColor.a *= addLight.volumetricLightDimmer;
                                   lightColor.rgb *= lightColor.a;

                                   float shadow = GetPunctualShadowAttenuation(context.shadowContext, uv, currentPos, 0, addLight.shadowIndex, L, distances.x, addLight.lightType == GPULIGHTTYPE_POINT, addLight.lightType != GPULIGHTTYPE_PROJECTOR_BOX);

                                   lightColor.rgb *= ComputeShadowColor(shadow, addLight.shadowTint, addLight.penumbraTint);
                                   float3 scattering = stepSize * lightColor.rgb * exposure;
                                   float3 light = scattering;

                                   cosAngle = dot(-rayDir, normalize(currentPos - addLight.positionRWS));
                                   light *= MieScattering(cosAngle) * 5;

                                   result.rgb += light;
                                   currentPos += step;

                               }
                           }
                        }
                    }

                    result.rgb /= KW_Transparent;
                    result.rgb *= KW_VolumeDepthFade;
                    //result *= 4;

                    return max(0, result);
               }


                float4 frag(v2f i) : SV_Target
                {
                    //return float4(frac(i.frustumWorldPos.yyy * 0.001), 1);
                    half mask = tex2D(KW_WaterMaskScatterNormals_Blured, i.uv - float2(0, 6 * KW_WaterMaskScatterNormals_Blured_TexelSize.y)).x;
                    if (mask < 0.45) discard;

                   
                    float depthTop = tex2D(KW_WaterDepth, i.uv);
                    float depthBot = SampleCameraDepth(i.uv);

                    bool isUnderwater = mask < 0.75;
                    if (depthBot > depthTop && isUnderwater) discard;

                    float3 topPos = ComputeWorldSpacePosition(i.uv, depthTop, UNITY_MATRIX_I_VP);
                    float3 botPos = ComputeWorldSpacePosition(i.uv, depthBot, UNITY_MATRIX_I_VP);
                    //topPos = GetAbsolutePositionWS(topPos);
                   // botPos = GetAbsolutePositionWS(botPos);

                    float3 rayDir = botPos - topPos;
                    rayDir = normalize(rayDir);
                    float rayLength = KW_VolumeLightMaxDistance;

                    float3 rayStart;

                    if (isUnderwater) {
                        rayLength = min(length(topPos - botPos), rayLength);
                        rayStart = topPos;
                    }
                    else
                    {
                        rayDir = normalize(i.frustumWorldPos - i.uvWorldPos);
                        i.uvWorldPos = GetCameraRelativePositionWS(i.uvWorldPos);
                        rayLength = min(length(i.uvWorldPos - botPos), rayLength);
                        rayLength = min(length(i.uvWorldPos - topPos), rayLength);
                        rayStart = i.uvWorldPos;
                    }
                    
                    half4 finalColor;
                   
                    finalColor = RayMarch(i.uv, i.ditherPos, topPos, rayStart, rayDir, rayLength, isUnderwater);
                    
                    return finalColor;
           }
           ENDHLSL
       }
    }
}