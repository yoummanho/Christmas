Shader "Hidden/KriptoFX/Water/KW_BlitToDepthTexture_HDRP"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite On ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;
            sampler2D KW_WaterDepth;
            sampler2D KW_WaterMaskScatterNormals_Blured;
            UNITY_DECLARE_TEX2DARRAY(_CameraDepthTexture);
            float4 _CurrentRTHandleSize;
            float4 _CameraDepthTexture_TexelSize;

            float frag (v2f i, out float depth : SV_Depth) : SV_Target
            {
                half mask = tex2Dlod(KW_WaterMaskScatterNormals_Blured, float4(i.uv.x, i.uv.y , 0, 0)).x;
                if (mask > 0.7)
                {
                    depth = 1;
                    return 0.001;
                }

                float2 depthUV = clamp(i.uv * _CurrentRTHandleSize.xy * _CameraDepthTexture_TexelSize.xy, 0.001, 0.999);
                float sceneDepth = UNITY_SAMPLE_TEX2DARRAY(_CameraDepthTexture, float3(depthUV, 0));
                float waterDepth = tex2D(KW_WaterDepth, i.uv);
                depth = max(sceneDepth, waterDepth);
                return 0;
            }
            ENDCG
        }
    }
}
