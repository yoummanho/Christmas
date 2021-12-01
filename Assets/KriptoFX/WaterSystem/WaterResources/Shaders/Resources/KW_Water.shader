Shader "KriptoFX/Water/Water" {
	Properties{

	}

	SubShader{

	Tags{ "Queue" = "Transparent-1" "IgnoreProjector" = "True" "RenderType" = "Transparent" }

		Blend SrcAlpha OneMinusSrcAlpha

		Stencil {
			Ref 230
			Comp Greater
			Pass keep
		}

	Pass
		{
			ZWrite On
			//ZTest LEqual

			Cull Back
			HLSLPROGRAM

			#define WATER_HDRP
			#define USE_FOG
		//#define ENVIRO_FOG

		#if defined(ENVIRO_FOG)
			#include "Assets/Enviro - Sky and Weather/Core/Resources/Shaders/Core/EnviroFogCore.cginc"
		#endif

		#if defined(WATER_HDRP)
			#include "Packages/com.unity.render-pipelines.high-definition-config/Runtime/ShaderConfig.cs.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/TextureXR.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/AtmosphericScattering/AtmosphericScattering.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonLighting.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
			#include "HDRP/KW_WaterHelpers_HDRP.cginc"
		#endif




		//#include "UnityCG.cginc"
		#include "KW_WaterVariables.cginc"
		#include "KW_WaterHelpers.cginc"
		#include "WaterVertFrag.cginc"
		#include "KW_Tessellation.cginc"

		#pragma shader_feature  KW_FLOW_MAP_EDIT_MODE
		#pragma multi_compile _ KW_FLOW_MAP KW_FLOW_MAP_FLUIDS
		#pragma multi_compile _ KW_DYNAMIC_WAVES
		#pragma multi_compile _ USE_MULTIPLE_SIMULATIONS
		#pragma multi_compile _ PLANAR_REFLECTION SSPR_REFLECTION
		#pragma multi_compile _ USE_SHORELINE
		#pragma multi_compile _ REFLECT_SUN
		#pragma multi_compile _ USE_VOLUMETRIC_LIGHT
		#pragma multi_compile _ FIX_UNDERWATER_SKY_REFLECTION
		#pragma multi_compile _ USE_FILTERING


		#pragma target 4.6

		#pragma vertex vert
		#pragma fragment frag

	ENDHLSL

}
	}
}
