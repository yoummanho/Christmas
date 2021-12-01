Shader "Hidden/KriptoFX/Water/KW_OffscreenRendering_HDRP"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Blend SrcAlpha OneMinusSrcAlpha
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/RenderPass/CustomPass/CustomPassCommon.hlsl"

            struct appdata
            {
                uint vertexID : SV_VertexID;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            v2f vert(appdata v)
            {
                v2f o;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                o.positionCS = GetFullScreenTriangleVertexPosition(v.vertexID, UNITY_RAW_FAR_CLIP_VALUE);
                o.uv = GetFullScreenTriangleTexCoord(v.vertexID);
                return o;
            }

            sampler2D _MainTex;
            sampler2D KW_ScreenSpaceWater;
            sampler2D _CameraColorTexture;

            half4 frag(v2f i) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                float2 uv = i.positionCS.xy * _ScreenSize.zw;

                half4 sceneColor = 1;
                sceneColor.rgb = LoadCameraColor(uv * _ScreenSize.xy);
                half4 waterColor = tex2D(KW_ScreenSpaceWater, uv);
                sceneColor.rgb = lerp(sceneColor.rgb, waterColor.rgb, waterColor.a);
                sceneColor.a = 1;
                return sceneColor;
            }
            ENDHLSL
        }
    }
}
