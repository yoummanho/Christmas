Shader "Hidden/KriptoFX/Water/VolumetricLighting"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
		SubShader
	{
		Cull Off
		ZWrite Off
		ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#pragma multi_compile _ SHADOWS_DEPTH
			#pragma multi_compile _ SHADOWS_SPLIT_SPHERES
			#pragma multi_compile _ SHADOWS_SINGLE_CASCADE
			#pragma multi_compile _ SHADOWS_CUBE_IN_DEPTH_TEX
			#pragma multi_compile _ DIRECTIONAL POINT SPOT
			#pragma multi_compile _ USE_MULTIPLE_SIMULATIONS
			#pragma multi_compile _ USE_CAUSTIC
			#pragma multi_compile _ USE_LOD1 USE_LOD2 USE_LOD3


			#if defined(SHADOWS_DEPTH) || defined(SHADOWS_CUBE)
				#define SHADOWS_NATIVE
			#endif

			#include "UnityCG.cginc"
			#include "UnityDeferredLibrary.cginc"

			UNITY_DECLARE_SHADOWMAP(_DirShadowMapTexture);
#if defined(SHADOWS_CUBE_IN_DEPTH_TEX)
			UNITY_DECLARE_TEXCUBE_SHADOWMAP(_PointShadowMapTexture);
#else
			UNITY_DECLARE_TEXCUBE(_PointShadowMapTexture);
#endif
			UNITY_DECLARE_SHADOWMAP(_SpotShadowMapTexture);

			float4 KW_LightDir;
			float4 KW_LightPos;
			float4 KW_LightColor;


			int KW_DirLightCount;
			float4 KW_DirLightPositions[3];
			float4 KW_DirLightColors[3];

			int KW_PointLightCount;
			float4 KW_PointLightPositions[100];
			float4 KW_PointLightColors[100];

			int KW_SpotLightCount;
			float4 KW_SpotLightPositions[100];
			float4 KW_SpotLightColors[100];
			float4x4 KW_SpotLightWorldToShadows[100];
			int KW_SpotLightShadowIndex;

			sampler2D KW_PointLightAttenuation;
			sampler2D _LightVolume;

			sampler2D _MainTex;
			sampler2D KW_DitherTexture;
			sampler2D KW_SpotLightTex;
sampler2D					KW_DispTex;
sampler2D					KW_DispTex_LOD1;
sampler2D					KW_DispTex_LOD2;
sampler2D KW_NormTex;
sampler2D KW_NormTex_LOD1;
sampler2D KW_NormTex_LOD2;

			sampler2D KW_WaterDepth;
			sampler2D KW_WaterDepthWithFoam;
			float4 KW_WaterDepth_TexelSize;
			sampler2D KW_WaterMaskScatterNormals;
			sampler2D KW_WaterMaskScatterNormals_Blured;
			float4 KW_WaterMaskScatterNormals_Blured_TexelSize;
			//sampler2D _CameraDepthTextureAfterWaterZWrite;
			//sampler2D _CameraDepthTextureBeforeWaterZWrite;;
			sampler2D KW_WaterScreenPosTex;

			float4 KW_Frustum[4];
			float4 KW_UV_World[4];

			float2 KW_DitherSceenScale;
			float4x4 KW_ProjToView;
			float4x4 KW_ViewToWorld;
			float4x4 KW_SpotWorldToShadow;
			float4x4 KW_InverseProjectionMatrix;

			half KW_Transparent;
			half MaxDistance;
			half KW_RayMarchSteps;
			half _FogDensity;
			half _Extinction;
			half4 KW_LightAnisotropy;
			half _MieScattering;
			half _RayleighScattering;

half						KW_FFTDomainSize;
half						KW_FFTDomainSize_LOD1;
half						KW_FFTDomainSize_LOD2;
			float3 KW_WaterPosition;
			float KW_WindSpeed;
			half KW_Choppines;

			sampler2D KW_CausticLod0;
			sampler2D KW_CausticLod1;
			sampler2D KW_CausticLod2;
			sampler2D KW_CausticLod3;

			float4 KW_CausticLodSettings;
			float3 KW_CausticLodOffset;

			sampler2D KW_CausticTex;
			half KW_CausticDomainSize;
			float2 KW_CausticTex_TexelSize;
			float4	 KW_DispTex_TexelSize;
			float KW_ShadowDistance;
			float KW_VolumeLightMaxDistance;
			float _MyTest;
			float KW_VolumeLightBlurRadius;

			sampler2D _CameraColorTexture;
			float4 KW_TurbidityColor;
			float KW_VolumeDepthFade;

			inline half getRayleighPhase(half cosTheta) {
				return 0.05968310365f * (1 + (cosTheta * cosTheta));
			}

			inline half MieScattering(float cosAngle)
			{
				return KW_LightAnisotropy.w * (KW_LightAnisotropy.x / (pow(KW_LightAnisotropy.y - KW_LightAnisotropy.z * cosAngle, 1.5)));
			}


			/*
			inline half getSchlickScattering(float costheta) {
				float sqr = 1 + KW_LightAnisotropy * costheta;
				sqr *= sqr;
				return 0.4959 / 12.5663706144 * sqr;
			}*/

			inline float3 ScreenToWorld(float2 UV, float depth)
			{
				float2 uvClip = UV * 2.0 - 1.0;
				float4 clipPos = float4(uvClip, depth, 1.0);
				float4 viewPos = mul(KW_ProjToView, clipPos);
				viewPos /= viewPos.w;
				float3 worldPos = mul(KW_ViewToWorld, viewPos).xyz;
				return worldPos;
			}

			//-------------------------------shadow helpers----------------------------------------------

#if defined (SHADOWS_SPLIT_SPHERES)
#define GET_CASCADE_WEIGHTS(wpos, z)    GetCascadeWeights_SplitSpheres(wpos)
#else
#define GET_CASCADE_WEIGHTS(wpos, z)    getCascadeWeights( wpos, z )
#endif

#if defined (SHADOWS_SINGLE_CASCADE)
#define GET_SHADOW_COORDINATES(wpos,cascadeWeights) getShadowCoord_SingleCascade(wpos)
#else
#define GET_SHADOW_COORDINATES(wpos,cascadeWeights) getShadowCoord(wpos,cascadeWeights)
#endif


			inline fixed4 GetCascadeWeights_SplitSpheres(float3 wpos)
			{
				float3 fromCenter0 = wpos.xyz - unity_ShadowSplitSpheres[0].xyz;
				float3 fromCenter1 = wpos.xyz - unity_ShadowSplitSpheres[1].xyz;
				float3 fromCenter2 = wpos.xyz - unity_ShadowSplitSpheres[2].xyz;
				float3 fromCenter3 = wpos.xyz - unity_ShadowSplitSpheres[3].xyz;
				float4 distances2 = float4(dot(fromCenter0, fromCenter0), dot(fromCenter1, fromCenter1), dot(fromCenter2, fromCenter2), dot(fromCenter3, fromCenter3));

				fixed4 weights = float4(distances2 < unity_ShadowSplitSqRadii);
				weights.yzw = saturate(weights.yzw - weights.xyz);
				return weights;
			}

			inline fixed4 getCascadeWeights(float3 wpos, float z)
			{
				fixed4 zNear = float4(z >= _LightSplitsNear);
				fixed4 zFar = float4(z < _LightSplitsFar);
				fixed4 weights = zNear * zFar;
				return weights;
			}

			inline float4 getShadowCoord_SingleCascade(float4 wpos)
			{
				return float4(mul(unity_WorldToShadow[0], wpos).xyz, 0);
			}


			inline float4 getShadowCoord(float4 wpos, fixed4 cascadeWeights) {

				float3 sc0 = mul(unity_WorldToShadow[0], wpos).xyz;
				float3 sc1 = mul(unity_WorldToShadow[1], wpos).xyz;
				float3 sc2 = mul(unity_WorldToShadow[2], wpos).xyz;
				float3 sc3 = mul(unity_WorldToShadow[3], wpos).xyz;
				float4 shadowMapCoordinate = float4(sc0 * cascadeWeights[0] + sc1 * cascadeWeights[1] + sc2 * cascadeWeights[2] + sc3 * cascadeWeights[3], 1);
#if defined(UNITY_REVERSED_Z)
				float  noCascadeWeights = 1 - dot(cascadeWeights, float4(1, 1, 1, 1));
				shadowMapCoordinate.z += noCascadeWeights;
#endif
				return shadowMapCoordinate;
			}

			inline half UnitySamplePointShadowmap(float3 vec, float range)
			{
#if defined(SHADOWS_CUBE_IN_DEPTH_TEX)
				float3 absVec = abs(vec);
				float dominantAxis = max(max(absVec.x, absVec.y), absVec.z); // TODO use max3() instead
				dominantAxis = max(0.00001, dominantAxis - _LightProjectionParams.z); // shadow bias from point light is apllied here.
				dominantAxis *= _LightProjectionParams.w; // bias
				float mydist = -_LightProjectionParams.x + _LightProjectionParams.y / dominantAxis; // project to shadow map clip space [0; 1]

#if defined(UNITY_REVERSED_Z)
				mydist = 1.0 - mydist; // depth buffers are reversed! Additionally we can move this to CPP code!
#endif
#else
				float mydist = length(vec) * range;
#endif

#if defined (SHADOWS_CUBE_IN_DEPTH_TEX)
				half shadow = UNITY_SAMPLE_TEXCUBE_SHADOW(_PointShadowMapTexture, float4(vec, mydist));
				return lerp(_LightShadowData.r, 1.0, shadow);
#else
				half shadowVal = UnityDecodeCubeShadowDepth(UNITY_SAMPLE_TEXCUBE(_PointShadowMapTexture, vec));

				half shadow = shadowVal < mydist ? _LightShadowData.r : 1.0;
				return shadow;
#endif
			}


			float GetLightAttenuation(float3 wpos, float viewPosZ)
			{
				float atten = 0;

#if defined (DIRECTIONAL)
				atten = 1;
	#if defined (SHADOWS_DEPTH)
#if defined (SHADOWS_SPLIT_SPHERES)
				
#endif
					float4 weights = GET_CASCADE_WEIGHTS(wpos , viewPosZ);
					//float4 cascadeWeights = GetCascadeWeights_SplitSpheres(wpos);
					float4 samplePos = GET_SHADOW_COORDINATES(float4(wpos, 1), weights);

					half inside = dot(weights, float4(1, 1, 1, 1));
					atten = inside > 0 ? UNITY_SAMPLE_SHADOW(_DirShadowMapTexture, samplePos.xyz) : 1.0f;
					atten = _LightShadowData.r + atten * (1 - _LightShadowData.r);
	#endif
#endif
#if defined (SPOT)
					float4 lightPos = mul(KW_SpotWorldToShadow, float4(wpos, 1));
					float3 tolight = KW_LightPos.xyz - wpos;
					half3 lightDir = normalize(tolight);

					atten = tex2Dbias(KW_SpotLightTex, float4(lightPos.xy / lightPos.w * 0.5 + 0.25, 0, -8)).r;
					atten *= lightPos.w > 1;
					atten *= 1 - length(tolight) / KW_LightPos.w;

	#if defined(SHADOWS_DEPTH)
					atten *= UNITY_SAMPLE_SHADOW(_SpotShadowMapTexture, lightPos.xyz / lightPos.w);
	#endif
#endif

#if defined (POINT)
				float3 tolight = wpos - KW_LightPos.xyz;

				half3 lightDir = -normalize(tolight);

				float lightRange = 1.0f / KW_LightPos.w;
				float lightRangeDouble = 1.0f / (KW_LightPos.w * KW_LightPos.w);
				float att = dot(tolight, tolight) * lightRangeDouble;
				atten = tex2Dlod(_LightTextureB0, float4(att.rr, 0, 0));
	#if defined(SHADOWS_DEPTH)
				atten *= UnitySamplePointShadowmap(tolight, lightRange);
	#endif
#endif
				return atten;
			}
			float4 Test4;
			float3 KW_CausticLodPosition;
			float KW_DecalScale;

			half3 GetCausticLod(float3 currentPos, float offsetLength, float lodDist, sampler2D tex, half lastLodCausticColor, float lodScale)
			{
				float2 uv = ((currentPos.xz - KW_CausticLodPosition.xz) - offsetLength * KW_LightDir.xz) / lodDist + 0.5 - KW_CausticLodOffset.xz;
				half caustic = tex2Dlod(tex, float4(uv, 0, KW_VolumeLightBlurRadius * 0.5 + 1)).r;
				uv = 1 - min(1, abs(uv * 2 - 1));
				float lerpLod = uv.x * uv.y;
				lerpLod = min(1, lerpLod * 3);
				return lerp(lastLodCausticColor, caustic, lerpLod);
			}

			half ComputeCaustic(float3 rayStart, float3 currentPos)
			{
				//half deepFade = 1 - saturate((KW_WaterYPos - currentPos.y) / KW_Transparent * 0.5);
				//half topFade = saturate(KW_WaterYPos - currentPos.y);
				half angle = dot(float3(0, -0.999, 0), KW_LightDir);
				half offsetLength = (rayStart.y - currentPos.y) / angle;

				float3 caustic = 0.1;
#if defined(USE_LOD3)
				caustic = GetCausticLod(currentPos, offsetLength, KW_CausticLodSettings.w, KW_CausticLod3, caustic, 2);
#endif
#if defined(USE_LOD2) || defined(USE_LOD3)
				caustic = GetCausticLod(currentPos, offsetLength, KW_CausticLodSettings.z, KW_CausticLod2, caustic, 2);
#endif
#if defined(USE_LOD1) || defined(USE_LOD2) || defined(USE_LOD3)
				caustic = GetCausticLod(currentPos, offsetLength, KW_CausticLodSettings.y, KW_CausticLod1, caustic, 2);
#endif
				caustic = GetCausticLod(currentPos, offsetLength, KW_CausticLodSettings.x, KW_CausticLod0, caustic, 2);

				float distToCamera = length(currentPos - _WorldSpaceCameraPos);
				float distFade = saturate(distToCamera / KW_DecalScale * 2);
				caustic = lerp(caustic, 0, distFade);
				return caustic * 5 - 0.5;
			}

		/*	static const float ditherPattern[4][4] = { { 0.1f, 0.5f, 0.125f, 0.625f},
			{ 0.75f, 0.22f, 0.875f, 0.375f},
			{ 0.1875f, 0.6875f, 0.0625f, 0.5625},
			{ 0.9375f, 0.4375f, 0.8125f, 0.3125} };*/

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

			inline float4 RayMarch(float2 ditherScreenPos, float3 rayStart, float3 rayDir, float rayLength, half isUnderwater, float viewPosZ)
			{
				//float offset = tex2D(KW_DitherTexture, ditherScreenPos/8).w;

				ditherScreenPos = ditherScreenPos % 8;
				float offset = ditherPattern[ditherScreenPos.y][ditherScreenPos.x];
			

				float stepSize = rayLength / KW_RayMarchSteps;
				float3 step = rayDir * stepSize;
				float3 currentPos = rayStart + step * offset;

				float4 result = 0;
				float cosAngle = 0;
				float scattering = 0;
				float shadowDistance = saturate(distance(rayStart, _WorldSpaceCameraPos) - KW_Transparent);


				float extinction = 0;
				float depthFade = 1-exp(-((_WorldSpaceCameraPos.y - KW_WaterPosition.y) + KW_Transparent));
				
				[loop]
				for (int i = 0; i < KW_RayMarchSteps; ++i)
				{
					float atten = GetLightAttenuation(currentPos, viewPosZ);
					
					float3 scattering = stepSize * KW_LightColor;

#if defined (DIRECTIONAL) && defined (USE_CAUSTIC)
					float underwaterStrength = lerp(saturate((KW_Transparent - 1) / 5) * 0.5, 1, isUnderwater);
					scattering += scattering * ComputeCaustic(rayStart, currentPos) * underwaterStrength;

#endif
					float3 light = atten * scattering;
					
#if defined (DIRECTIONAL)
					cosAngle = dot(KW_LightDir.xyz, -rayDir);
#endif
#if defined (POINT) || defined (SPOT)

					cosAngle = dot(-rayDir, normalize(currentPos - KW_LightPos.xyz));
					light *= MieScattering(cosAngle);

#endif

					result.rgb += light;
					currentPos += step;
	
				}
#if defined (DIRECTIONAL)
				result *= MieScattering(cosAngle);
#endif 
				result /= KW_Transparent;
				result *= KW_VolumeDepthFade;
				result *= 4;

				return max(0, result);
			}


			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float2 ditherPos : TEXCOORD1;
				float3 frustumWorldPos : TEXCOORD2;
				float3 uvWorldPos : TEXCOORD3;
				float3 ray : TEXCOORD4;
			};


			v2f vert (appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				o.ditherPos = v.uv * KW_DitherSceenScale.xy;
				o.frustumWorldPos = KW_Frustum[v.uv.x + v.uv.y * 2];
				o.uvWorldPos = KW_UV_World[v.uv.x + v.uv.y * 2];

				float4 clipPos = float4(v.uv * 2.0 - 1.0, 1.0, 1.0);
				float4 cameraRay = mul(KW_InverseProjectionMatrix, clipPos);
				o.ray = cameraRay / cameraRay.w;

				return o;
			}

		
			half4 frag (v2f i) : SV_Target
			{
				half mask = tex2D(KW_WaterMaskScatterNormals_Blured, i.uv).x;
				if (mask < 0.45) discard;

				float4 prevVolumeColor = tex2D(_MainTex, i.uv);
				float depthTop = tex2D(KW_WaterDepth, i.uv);
				float depthBot = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);

				bool isUnderwater = mask < 0.75;

				if (depthBot > depthTop && isUnderwater) return 0;

				float3 topPos = ScreenToWorld(i.uv, depthTop);
				float3 botPos = ScreenToWorld(i.uv, depthBot);

				float3 rayDir = botPos - topPos;
				rayDir = normalize(rayDir);
				float rayLength = KW_VolumeLightMaxDistance;

				half4 finalColor = 0;
				float3 rayStart;

				if (isUnderwater) {
					rayLength = min(length(topPos - botPos), rayLength);
					rayStart = topPos;
				}
				else
				{
					rayDir = normalize(i.frustumWorldPos - _WorldSpaceCameraPos);
					rayLength = min(length(i.uvWorldPos - botPos), rayLength);
					rayLength = min(length(i.uvWorldPos - topPos), rayLength);
					rayStart = i.uvWorldPos;
				}
				//return float4(frac(rayDir),  1);
#if defined (SHADOWS_SPLIT_SPHERES)
				float viewPosZ = 0;
#else 
				float viewPosZ = -float4(i.ray.xyz * Linear01Depth(depthBot), 1).z;
#endif
				finalColor = RayMarch(i.ditherPos, rayStart, rayDir, rayLength, isUnderwater, viewPosZ);

#if defined (DIRECTIONAL)
				finalColor.a = GetLightAttenuation(topPos, viewPosZ);
#else
				finalColor.a = 0;
#endif
				finalColor.a = max(finalColor.a, prevVolumeColor.a);
				//finalColor.a = (finalColor.a * 0.5 + 0.5) * bilateralBlurMask;

				finalColor.rgb += prevVolumeColor.rgb;

				return finalColor;
			}
			ENDCG
		}
	}
}
