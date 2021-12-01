Shader "Hidden/KriptoFX/Water/KW_FoamParticles"
{
    Properties
    {   _Color("Color", Color) = (0.95, 0.95, 0.95, 0.12)
        _MainTex("Texture", 2D) = "white" {}
        KW_VAT_Position("Position texture", 2D) = "white" {}
        KW_VAT_Alpha("Alpha texture", 2D) = "white" {}
        KW_VAT_Offset("Height Offset", 2D) = "black" {}
        KW_VAT_RangeLookup("Range Lookup texture", 2D) = "white" {}


        _FPS("FPS", Float) = 6.66666
         //_FPS("FPS", Float) = 6.7

        _Size("Size", Float) = 0.09
        //_Scale("AABB Scale", Vector) = (26.3, 4.5, 31.16)
        _Scale("AABB Scale", Vector) = (26.3, 4.8, 30.5)
        _NoiseOffset("Noise Offset", Vector) = (0, 0, 0)
        // _Offset("Offset", Vector) = (-9.5, -1.85, -15.3, 0)
        _Offset("Offset", Vector) = (-9.35, -2.025, -15.6, 0)

        _Test("Test", Float) = 0.1
    }
        SubShader
        { 
            Tags{ "RenderPipeline" = "HDRenderPipeline" "RenderType" = "HDLitShader" "Queue" = "Transparent+1" }
           // Tags { "RenderType" = "Transparent" "Queue" = "Transparent+1"}
            Pass
            {   
                  //Name "Forward"
                  //  Tags { "LightMode" = "Forward" } // This will be only for transparent object based on the RenderQueue index

                
                 Blend SrcAlpha OneMinusSrcAlpha
                 ZWrite Off
                 Cull Off

                HLSLPROGRAM
              
                #pragma target 4.6
                #pragma multi_compile _ KW_INTERACTIVE_WAVES
                #pragma shader_feature  KW_FLOW_MAP_EDIT_MODE
                #pragma multi_compile _ KW_FLOW_MAP
                #pragma shader_feature  KW_SHORELINE_EDIT_MODE
                #pragma multi_compile _ KW_SHORELINE
                #pragma multi_compile _ KW_FOAM
                #pragma multi_compile _ USE_MULTIPLE_SIMULATIONS

                #pragma multi_compile _ LIGHTLOOP_DISABLE_TILE_AND_CLUSTER
                #pragma multi_compile _ ENABLE_REPROJECTION
                #pragma multi_compile _ ENABLE_ANISOTROPY
                #pragma multi_compile _ VL_PRESET_OPTIMAL
                #pragma multi_compile _ SUPPORT_LOCAL_LIGHTS
           
                #define SHADERPASS SHADERPASS_FORWARD
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


                #include "KW_WaterVariables.cginc"
                #include "KW_WaterHelpers.cginc"
                #include "WaterVertFrag.cginc"

                #pragma vertex vert_foam
                #pragma fragment frag_foam

                struct appdata_foam
                {
                    float4 vertex : POSITION;
                    float2 uv : TEXCOORD0;
                    float4 uv2 : TEXCOORD1;
                };

                struct v2f_foam
                {
                    float4 pos : SV_POSITION;
                    float2 uv : TEXCOORD1;
                    float4 color : TEXCOORD2;
                    float4 screenPos : TEXCOORD3;
                    float3 worldPos : TEXCOORD4;
                };

                sampler2D KW_VAT_Position;
                float4 KW_VAT_Position_TexelSize;
                sampler2D KW_VAT_Alpha;
                sampler2D KW_VAT_RangeLookup;
                float4 KW_VAT_RangeLookup_TexelSize;
                sampler2D KW_VAT_Offset;

                sampler2D KW_BluredFoamShadow;
                float4 _MainTex_ST;
                float _Size;
                float4 _Offset;
                float3 _NoiseOffset;
                float _FPS;

                float4 _Color;

                float3 _Scale;
                half _Test;
                float3 KW_LightDir;
                float3 KW_LightDirColor;


                float KW_SizeAdditiveScale;

                UNITY_INSTANCING_BUFFER_START(Props)
                    UNITY_DEFINE_INSTANCED_PROP(float, KW_WaveTimeOffset)
                UNITY_INSTANCING_BUFFER_END(Props)

                float4 computeVertexData(float idx)
                {
                    float timeOffset = UNITY_ACCESS_INSTANCED_PROP(Props, KW_WaveTimeOffset);
                    float timeLimit = (14.0 * 15.0) / 20.0; //(frameX * frameY) / fps

                    //KW_Time = Test4.x * 0.01;
                    float time = frac((KW_GlobalTimeSpeedMultiplier * KW_Time) / timeLimit) * timeLimit;
                    time += timeOffset * KW_GlobalTimeOffsetMultiplier;
                    time = frac(time * KW_VAT_RangeLookup_TexelSize.x) * KW_VAT_RangeLookup_TexelSize.z;

                    float height = frac(idx / KW_VAT_Position_TexelSize.w);
                    float offset = (floor(idx / KW_VAT_Position_TexelSize.z)) * KW_VAT_Position_TexelSize.x; //todo check w instead of z

                    float4 lookup = tex2Dlod(KW_VAT_RangeLookup, float4((time * _FPS) * KW_VAT_RangeLookup_TexelSize.x, 0, 0, 0));

                    float offsetMin = min(lookup.y, offset);
                    float4 uv1 = float4((float2(offsetMin + lookup.x - KW_VAT_Position_TexelSize.x * 0.75, height)), 0, 0);
                    float4 texturePos1 = tex2Dlod(KW_VAT_Position, uv1);
                   // texturePos1.xyz = GammaToLinearSpace(texturePos1.xyz);
                    //texturePos1.a = tex2Dlod(KW_VAT_Alpha, uv1);


                    float offsetMin2 = min(lookup.w , offset);
                    float4 uv2 = float4((float2(offsetMin2 + lookup.z - KW_VAT_Position_TexelSize.x * 0.75, height)), 0, 0);
                    float4 texturePos2 = tex2Dlod(KW_VAT_Position, uv2);
                  //  texturePos2.xyz = GammaToLinearSpace(texturePos2.xyz);
                    //texturePos2.a = tex2Dlod(KW_VAT_Alpha, uv2);

                   // float interpolationMask = abs(texturePos1.z - texturePos2.z) > 0.15 ? 0 : 1;
                    //if (length(texturePos1.rgb) > 0.0001 && length(texturePos2.rgb) > 0.0001)
                    {
                        texturePos1 = lerp(texturePos1, texturePos2, frac(time * _FPS));
                    }


                    texturePos1.z = 1 - texturePos1.z;
                    return texturePos1;
                }

                v2f_foam vert_foam(appdata_foam v)
                {
                    v2f_foam o;

                    float3 cameraF = float3(v.uv.x - 0.5, v.uv.y - 0.5, 0);
                    _Size += KW_SizeAdditiveScale;
                    _Size /= length(UNITY_MATRIX_M._m01_m11_m21);
                    cameraF *= float3(_Size, _Size, 1);
                    cameraF = mul(cameraF, mul(UNITY_MATRIX_V, UNITY_MATRIX_M));

                  
                    //_Time.y = TEST;


                    float4 texturePos1 = computeVertexData(v.uv2.x);

                    float heightOffset = tex2Dlod(KW_VAT_Offset, float4(texturePos1.xz, 0, 0));

                    texturePos1.xyz *= _Scale;
                    texturePos1.xyz += v.uv2.yzw * _NoiseOffset + _Offset;

                    float3 localPos = texturePos1.xyz;

                    float3 waterOffset = 0;
                    float3 waterWorldPos = 0;
                    float4 shorelineUVAnim1;
                    float4 shorelineUVAnim2;
                    float4 shorelineWaveData1;
                    float4 shorelineWaveData2;

                    float3 worldPos = GetAbsolutePositionWS(mul(UNITY_MATRIX_M, float4(localPos, 1)));

                    waterOffset += ComputeWaterOffset(worldPos);
                    ShorelineData shorelineData;
                  //  waterOffset += ComputeBeachWaveOffset(worldPos, shorelineData);
                    float3 scale = float3(length(UNITY_MATRIX_M._m00_m10_m20), length(UNITY_MATRIX_M._m01_m11_m21), length(UNITY_MATRIX_M._m02_m12_m22));
                    waterOffset /= scale;
                    localPos += waterOffset;



                   // float2 depthUV = (worldPos.xz - KW_DepthPos.xz) / KW_DepthOrthographicSize + 0.5;
                   // float terrainDepth = tex2Dlod(KW_OrthoDepth, float4(depthUV, 0, 0)).r * KW_DepthNearFarDistance.z - KW_DepthNearFarDistance.y + KW_DepthPos.y;
					float terrainDepth = ComputeWaterOrthoDepth(worldPos);


                    worldPos.y -= heightOffset;
                    worldPos.y = max(worldPos.y, (terrainDepth + 0.05));
                    localPos.y = mul(UNITY_MATRIX_I_M, float4(GetCameraRelativePositionWS(worldPos), 1)).y;

                    v.vertex.xyz = cameraF;
                    v.vertex.xyz += localPos.xyz;

                    o.color.a = texturePos1.a;
                   
                    float exposure = GetCurrentExposureMultiplier();
                    KW_LightDirColor *= 1;
                    KW_AmbientColor *= exposure;

                    half3 lightColor = KW_LightDirColor;
                    o.color.rgb = clamp(lightColor + KW_AmbientColor.xyz*0, 0, 0.95);
                    o.color.rgb = KW_LightDirColor;
                 

                    o.uv = v.uv * float2(3, 4) - float2(2, 1);
                    o.worldPos = GetAbsolutePositionWS(mul(UNITY_MATRIX_M, v.vertex));
                    o.pos = UnityObjectToClipPos(v.vertex);
                    o.screenPos = ComputeScreenPos(o.pos);

                    return o;
                }

                half4 frag_foam(v2f_foam i) : SV_Target
                {
                    half exposure = GetCurrentExposureMultiplier();
                    float4 lightColor = 0; 
                   
                    float atten = 1;
                    if (_DirectionalShadowIndex >= 0)
                    {
                        LightLoopContext context;
                        context.shadowContext = InitShadowContext();
                        PositionInputs posInput;
                        DirectionalLightData dirLight = _DirectionalLightDatas[_DirectionalShadowIndex];
                        float3 L = -dirLight.forward;
                        int  cascadeCount;
                        posInput.positionWS = i.worldPos;
              /*          if ((dirLight.volumetricLightDimmer > 0) && (dirLight.volumetricShadowDimmer > 0))
                            context.shadowValue = GetDirectionalShadowAttenuation(context.shadowContext, i.screenPos.xy / i.screenPos.w, i.worldPos, 0, dirLight.shadowIndex, L);
                        else context.shadowValue = 1;*/

                        lightColor = EvaluateLight_Directional(context, posInput, dirLight);
                        lightColor.a *= dirLight.volumetricLightDimmer;
                        lightColor.rgb *= lightColor.a; // Composite
                        lightColor.rgb *= exposure;
                        //lightColor.rgb = context.shadowValue;
                    }
                    lightColor.rgb += exposure * half3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w);
                    lightColor = clamp(lightColor, 0, 1.35);

                    half alphaMask = max(0, 1 - length(i.uv));

                    half4 result = _Color;

                    result.rgb *= lightColor.rgb;

                    result.a *= 1 + KW_SizeAdditiveScale*5;

                    result.a *= i.color.a;
                    result.a *= alphaMask;

                    return result;
                }
                ENDHLSL
            }
            
            Pass
            {

            Name "ShadowCaster"
            Tags{ "LightMode" = "ShadowCaster" }

                ZWrite On
                Cull Off

                HLSLPROGRAM

                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
                #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"

                #include "KW_WaterVariables.cginc"
                #include "KW_WaterHelpers.cginc"
                #include "WaterVertFrag.cginc"

                #define SHADERPASS SHADERPASS_SHADOWS
                #pragma vertex vert_foam
                #pragma fragment frag_foam

                struct appdata_foam
                {
                    float4 vertex : POSITION;
                    float2 uv : TEXCOORD0;
                    float4 uv2 : TEXCOORD1;
                };

                struct v2f_foam
                {
                    float4 pos : SV_POSITION;
                    float2 uv : TEXCOORD0;
                    float alpha : TEXCOORD1;
                };

                sampler2D KW_VAT_Position;
                float4 KW_VAT_Position_TexelSize;
                sampler2D KW_VAT_Alpha;
                sampler2D KW_VAT_RangeLookup;
                float4 KW_VAT_RangeLookup_TexelSize;
                sampler2D KW_VAT_Offset;

                sampler2D KW_BluredFoamShadow;
                float4 _MainTex_ST;
                float _Size;
                float4 _Offset;
                float3 _NoiseOffset;
                float _FPS;

                float4 _Color;

                float3 _Scale;
                half _Test;
                float3 KW_LightDir;
                float3 KW_LightDirColor;


                float KW_SizeAdditiveScale;

                UNITY_INSTANCING_BUFFER_START(Props)
                    UNITY_DEFINE_INSTANCED_PROP(float, KW_WaveTimeOffset)
                UNITY_INSTANCING_BUFFER_END(Props)

                float4 computeVertexData(float idx)
                {
                    float timeOffset = UNITY_ACCESS_INSTANCED_PROP(Props, KW_WaveTimeOffset);
                    float timeLimit = (14.0 * 15.0) / 20.0; //(frameX * frameY) / fps

                    //KW_Time = Test4.x * 0.01;
                    float time = frac((KW_GlobalTimeSpeedMultiplier * KW_Time) / timeLimit) * timeLimit;
                    time += timeOffset * KW_GlobalTimeOffsetMultiplier;
                    time = frac(time * KW_VAT_RangeLookup_TexelSize.x) * KW_VAT_RangeLookup_TexelSize.z;

                    float height = frac(idx / KW_VAT_Position_TexelSize.w);
                    float offset = (floor(idx / KW_VAT_Position_TexelSize.z)) * KW_VAT_Position_TexelSize.x; //todo check w instead of z

                    float4 lookup = tex2Dlod(KW_VAT_RangeLookup, float4((time * _FPS) * KW_VAT_RangeLookup_TexelSize.x, 0, 0, 0));

                    float offsetMin = min(lookup.y, offset);
                    float4 uv1 = float4((float2(offsetMin + lookup.x - KW_VAT_Position_TexelSize.x * 0.75, height)), 0, 0);
                    float4 texturePos1 = tex2Dlod(KW_VAT_Position, uv1);
                    // texturePos1.xyz = GammaToLinearSpace(texturePos1.xyz);
                     //texturePos1.a = tex2Dlod(KW_VAT_Alpha, uv1);


                     float offsetMin2 = min(lookup.w , offset);
                     float4 uv2 = float4((float2(offsetMin2 + lookup.z - KW_VAT_Position_TexelSize.x * 0.75, height)), 0, 0);
                     float4 texturePos2 = tex2Dlod(KW_VAT_Position, uv2);
                     //  texturePos2.xyz = GammaToLinearSpace(texturePos2.xyz);
                       //texturePos2.a = tex2Dlod(KW_VAT_Alpha, uv2);

                      // float interpolationMask = abs(texturePos1.z - texturePos2.z) > 0.15 ? 0 : 1;
                       //if (length(texturePos1.rgb) > 0.0001 && length(texturePos2.rgb) > 0.0001)
                       {
                           texturePos1 = lerp(texturePos1, texturePos2, frac(time * _FPS));
                       }


                       texturePos1.z = 1 - texturePos1.z;
                       return texturePos1;
                   }

                   v2f_foam vert_foam(appdata_foam v)
                   {
                       v2f_foam o;

                       float3 cameraF = float3(v.uv.x - 0.5, v.uv.y - 0.5, 0);
                       _Size += KW_SizeAdditiveScale;
                       _Size /= length(UNITY_MATRIX_M._m01_m11_m21);
                       cameraF *= float3(_Size, _Size, 1);
                       cameraF = mul(cameraF, mul(UNITY_MATRIX_V, UNITY_MATRIX_M));


                       //_Time.y = TEST;


                       float4 texturePos1 = computeVertexData(v.uv2.x);

                       float heightOffset = tex2Dlod(KW_VAT_Offset, float4(texturePos1.xz, 0, 0));

                       texturePos1.xyz *= _Scale;
                       texturePos1.xyz += v.uv2.yzw * _NoiseOffset + _Offset;

                       float3 localPos = texturePos1.xyz;

                       float3 waterOffset = 0;
                       float3 waterWorldPos = 0;
                       float4 shorelineUVAnim1;
                       float4 shorelineUVAnim2;
                       float4 shorelineWaveData1;
                       float4 shorelineWaveData2;

                       float3 worldPos = GetAbsolutePositionWS(mul(UNITY_MATRIX_M, float4(localPos, 1)));

                       waterOffset += ComputeWaterOffset(worldPos);
                       ShorelineData shorelineData;
                       //  waterOffset += ComputeBeachWaveOffset(worldPos, shorelineData);
                         float3 scale = float3(length(UNITY_MATRIX_M._m00_m10_m20), length(UNITY_MATRIX_M._m01_m11_m21), length(UNITY_MATRIX_M._m02_m12_m22));
                         waterOffset /= scale;
                         localPos += waterOffset;



                         // float2 depthUV = (worldPos.xz - KW_DepthPos.xz) / KW_DepthOrthographicSize + 0.5;
                         // float terrainDepth = tex2Dlod(KW_OrthoDepth, float4(depthUV, 0, 0)).r * KW_DepthNearFarDistance.z - KW_DepthNearFarDistance.y + KW_DepthPos.y;
                          float terrainDepth = ComputeWaterOrthoDepth(worldPos);


                          worldPos.y -= heightOffset;
                          worldPos.y = max(worldPos.y, (terrainDepth + 0.05));
                          localPos.y = mul(UNITY_MATRIX_I_M, float4(GetCameraRelativePositionWS(worldPos), 1)).y;

                          v.vertex.xyz = cameraF;
                          v.vertex.xyz += localPos.xyz;

                          o.uv = v.uv * float2(3, 4) - float2(2, 1);
                          o.pos = UnityObjectToClipPos(v.vertex);
                          o.alpha = texturePos1.a;

                          return o;
                      }

                   float4 frag_foam(v2f_foam i) : SV_TARGET
                   { 
                        half alphaUVMask = max(0, 1 - length(i.uv));
                        half alpha = _Color.a;
                        alpha *= alphaUVMask;
                        alpha *= 1 + KW_SizeAdditiveScale;
                        alpha *= i.alpha;

                        if (alpha < 0.05) discard;
                       return 0;
                   }
                      ENDHLSL
            }
        }

}
