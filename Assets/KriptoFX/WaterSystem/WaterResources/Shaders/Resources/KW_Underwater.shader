Shader "KriptoFX/Water30/Underwater"
{ 
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
	}
	HLSLINCLUDE



	//#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
	//#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
	//#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonLighting.hlsl"
	//#include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
	#include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/RenderPass/CustomPass/CustomPassCommon.hlsl"
	#include "HDRP/KW_WaterHelpers_HDRP.cginc"
	#include "KW_WaterVariables.cginc"
	#include "KW_WaterHelpers.cginc"


	sampler2D KW_UnderwaterRT;
	float KW_TargetResolutionMultiplier;

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

	inline float3 ScreenToWorld(float2 UV, float depth)
	{
		float2 uvClip = UV * 2.0 - 1.0;
		float4 clipPos = float4(uvClip, depth, 1.0);
		float4 viewPos = mul(KW_ProjToView, clipPos);
		viewPos /= viewPos.w;
		float3 worldPos = mul(KW_ViewToWorld, viewPos).xyz;
		return worldPos;
	}

	v2f vert(appdata v)
	{
		v2f o;

		UNITY_SETUP_INSTANCE_ID(input);
		UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
		o.positionCS = GetFullScreenTriangleVertexPosition(v.vertexID, UNITY_RAW_FAR_CLIP_VALUE);
		o.uv = GetFullScreenTriangleTexCoord(v.vertexID);
		return o;
	}

	float4 frag1(v2f i) : SV_Target
	{
		UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
		float2 uv = i.uv;
		
		//return float4(frac(uv * 2), 0, 1);
		half mask = tex2Dlod(KW_WaterMaskScatterNormals_Blured, float4(uv, 0, 0)).x;
		
		if (mask < 0.7) return 0;
		
		//return float4(frac(i.uv * 2), 0, 1);
		float waterDepth = tex2Dlod(KW_WaterDepth, float4(uv - KW_WaterDepth_TexelSize.y * 3, 0, 0)).r;
		float linearZ = LinearEyeDepth(SampleCameraDepth(uv));
		
		float depthSurface = LinearEyeDepth(waterDepth);
		half waterSurfaceMask = saturate((depthSurface - linearZ));
		
		float fade = min(depthSurface, linearZ);
		float fadeExp = saturate(1 - exp(-1 * fade / KW_Transparent));
		//return float4(frac(fade), 0, 0, 1);
#if USE_VOLUMETRIC_LIGHT
		half halfMask = 1 - saturate(mask * 2 - 1);
		float3 volumeScattering = tex2D(KW_VolumetricLight, uv - float2(0, halfMask * 0.1 + KW_VolumetricLight_TexelSize.y * 1)).rgb;
#else
		half4 volumeScattering = half4(GetAmbientColor() * GetCurrentExposureMultiplier(), 1.0);
#endif
	
		//float halfWaterLineMask = saturate(0.45 - Pow5(maskRaw));
		half2 normals = tex2Dlod(KW_WaterMaskScatterNormals, float4(uv, 0, 0)).zw * 2 - 1;
		float2 colorUV = i.uv * _ScreenSize.xy;
		half3 waterColorUnder = LoadCameraColor(lerp(colorUV, colorUV * 1.75, 0));
		half3 waterColorBellow = LoadCameraColor(colorUV + normals * _ScreenSize.xy);
		half3 refraction = lerp(waterColorBellow, waterColorUnder, waterSurfaceMask);
	
		half3 underwaterColor = ComputeUnderwaterColor(refraction.xyz, volumeScattering.rgb, fade, KW_Transparent, KW_WaterColor.xyz, KW_Turbidity, KW_TurbidityColor.xyz);
		
		return float4(underwaterColor, 1);
	}

	float4 frag2(v2f i) : SV_Target
	{
		UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
		float2 uv = i.positionCS.xy * _ScreenSize.zw;
		half maskRaw = tex2Dlod(KW_WaterMaskScatterNormals_Blured, float4(uv, 0, 0)).x;
		if (maskRaw < 0.72) return 0;
		
		half3 color = tex2D(KW_UnderwaterRT, uv).xyz;
		return float4(color, 1);
	}

		ENDHLSL

	SubShader
	{
		//Stencil{
		//		Ref 230
		//		Comp Greater
		//		Pass keep
		//}

		Pass
		{
			ZWrite Off
			ZTest Always
			Blend SrcAlpha OneMinusSrcAlpha
			Cull Off

			HLSLPROGRAM
				#pragma multi_compile _ USE_VOLUMETRIC_LIGHT
				#pragma vertex vert
				#pragma fragment frag1
			ENDHLSL
		}

		Pass
		{
			ZWrite Off
			ZTest Always
			Blend SrcAlpha OneMinusSrcAlpha
			Cull Off

			HLSLPROGRAM
				#pragma vertex vert
				#pragma fragment frag2
			ENDHLSL
		}

	}
}
