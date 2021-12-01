Shader "Hidden/KriptoFX/Water/KW_FFT_Height"
{
	HLSLINCLUDE

	#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
	#include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
	#include "KW_WaterVariables.cginc"
	#include "KW_WaterHelpers.cginc"
	#include "WaterVertFrag.cginc"


	struct appdata_fft
	{
		float4 vertex : POSITION;
		float2 uv : TEXCOORD0;
	};

	struct v2f_fft
	{
		float4 vertex : SV_POSITION;
		float height : TEXCOORD0;
	};


	float3 KW_FFT_CameraPosition;
	float KW_FFT_DomainScale;

	v2f_fft vert_fft(appdata_fft v)
	{
		v2f_fft o;
//		v.uv /= 2.0;
//		
//		v.uv.y = 1 - v.uv.y;
//		v.uv += float2(-0.25, 0.25);
//		//float3 offset = tex2Dlod(KW_DispTex, float4(v.uv, 0, 0)) * float3(1.25, 1.0, 1.25);
//		
//#if USE_MULTIPLE_SIMULATIONS
//		float currentScale = KW_FFTDomainSize_LOD2;
//#else 
//		float currentScale = KW_FFTDomainSize;
//#endif
//		float3 offset = ComputeWaterOffset(float3(v.uv.x, 0, v.uv.y) * currentScale);
//		v.vertex.xy += offset.xz / currentScale;
//		v.vertex.z += offset.y;
//		o.vertex = float4(v.vertex.xy, v.vertex.z, 1);
//		o.height = mul(unity_ObjectToWorld, v.vertex).z;
		float3 worldPos = 0;
		worldPos.xz = KW_FFT_CameraPosition.xz + float2(1, -1) * v.vertex.xz * KW_FFT_DomainScale;
		float3 offset = ComputeWaterOffset(worldPos);
		v.vertex.xz += offset.xz / KW_FFT_DomainScale;
		o.height = offset.y;
		o.vertex = float4(v.vertex.xz, 0, 0.5);
		
		return o;
	}

	float4 frag_fft(v2f_fft i) : SV_Target
	{
		return i.height;
		//return Test4.x;
		
	}

		ENDHLSL

	SubShader
	{
		Pass
		{
			ZWrite On
			Cull Off
			
			HLSLPROGRAM
			#pragma vertex vert_fft
			#pragma fragment frag_fft
			#pragma multi_compile _ USE_MULTIPLE_SIMULATIONS

			ENDHLSL
		}

	}
}
