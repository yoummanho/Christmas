
//float _TesselationFactor;
float _TesselationMaxDistance;
float _TesselationMaxDisplace;
float4 unity_CameraWorldClipPlanes[6];

struct TessellationFactors
{
	float edge[3]    : SV_TessFactor;
	float inside : SV_InsideTessFactor;
};

struct Hull_Input
{
	float4 vertex  : POSITION;
	float4 color  : COLOR0;
};

struct Hull_ControlPointOutput
{
	float3 vertex    : POS;
	float4 color  : COLOR0;
};

Hull_Input vertHull(float4 vertex : POSITION, float color : COLOR0)
{
	Hull_Input o;
	o.vertex = vertex;
	o.color = color;
	return o;
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
float UnityCalcDistanceTessFactor(float4 vertex, float minDist, float maxDist, float tess)
{
	float3 wpos = mul(UNITY_MATRIX_M, vertex).xyz;
	float dist = distance(wpos, _WorldSpaceCameraPos);
	float f = clamp(1.0 - (dist - minDist) / (maxDist - minDist), 0.01, 1.0) * tess;
	return f;
}

float4 UnityCalcTriEdgeTessFactors(float3 triVertexFactors)
{
	float4 tess;
	tess.x = 0.5 * (triVertexFactors.y + triVertexFactors.z);
	tess.y = 0.5 * (triVertexFactors.x + triVertexFactors.z);
	tess.z = 0.5 * (triVertexFactors.x + triVertexFactors.y);
	tess.w = (triVertexFactors.x + triVertexFactors.y + triVertexFactors.z) / 3.0f;
	return tess;
}


float UnityDistanceFromPlane(float3 pos, float4 plane)
{
	float d = dot(float4(pos, 1.0f), plane);
	return d;
}


bool UnityWorldViewFrustumCull(float3 wpos0, float3 wpos1, float3 wpos2, float cullEps)
{
	float4 planeTest;

	// left
	planeTest.x = ((UnityDistanceFromPlane(wpos0, _FrustumPlanes[0]) > -cullEps) ? 1.0f : 0.0f) +
		((UnityDistanceFromPlane(wpos1, _FrustumPlanes[0]) > -cullEps) ? 1.0f : 0.0f) +
		((UnityDistanceFromPlane(wpos2, _FrustumPlanes[0]) > -cullEps) ? 1.0f : 0.0f);
	// right
	planeTest.y = ((UnityDistanceFromPlane(wpos0, _FrustumPlanes[1]) > -cullEps) ? 1.0f : 0.0f) +
		((UnityDistanceFromPlane(wpos1, _FrustumPlanes[1]) > -cullEps) ? 1.0f : 0.0f) +
		((UnityDistanceFromPlane(wpos2, _FrustumPlanes[1]) > -cullEps) ? 1.0f : 0.0f);
	// top
	planeTest.z = ((UnityDistanceFromPlane(wpos0, _FrustumPlanes[2]) > -cullEps) ? 1.0f : 0.0f) +
		((UnityDistanceFromPlane(wpos1, _FrustumPlanes[2]) > -cullEps) ? 1.0f : 0.0f) +
		((UnityDistanceFromPlane(wpos2, _FrustumPlanes[2]) > -cullEps) ? 1.0f : 0.0f);
	// bottom
	planeTest.w = ((UnityDistanceFromPlane(wpos0, _FrustumPlanes[3]) > -cullEps) ? 1.0f : 0.0f) +
		((UnityDistanceFromPlane(wpos1, _FrustumPlanes[3]) > -cullEps) ? 1.0f : 0.0f) +
		((UnityDistanceFromPlane(wpos2, _FrustumPlanes[3]) > -cullEps) ? 1.0f : 0.0f);

	// has to pass all 4 plane tests to be visible
	return !all(planeTest);
}

float4 DistanceBasedTess(float4 v0, float4 v1, float4 v2, float minDist, float maxDist, float tessFactor)
{
	float3 pos0 = mul(UNITY_MATRIX_M, v0).xyz;
	float3 pos1 = mul(UNITY_MATRIX_M, v1).xyz;
	float3 pos2 = mul(UNITY_MATRIX_M, v2).xyz;
	float4 tess;
	
	float3 f;
	f.x = UnityCalcDistanceTessFactor(v0, minDist, maxDist, tessFactor);
	f.y = UnityCalcDistanceTessFactor(v1, minDist, maxDist, tessFactor);
	f.z = UnityCalcDistanceTessFactor(v2, minDist, maxDist, tessFactor);
	tess = UnityCalcTriEdgeTessFactors(f);
	
	return tess;
}

float4 DistanceBasedTessCull(float4 v0, float4 v1, float4 v2, float minDist, float maxDist, float tessFactor, float maxDisplace)
{
	float3 pos0 = mul(UNITY_MATRIX_M, v0).xyz;
	float3 pos1 = mul(UNITY_MATRIX_M, v1).xyz;
	float3 pos2 = mul(UNITY_MATRIX_M, v2).xyz;
	float4 tess;

	if (UnityWorldViewFrustumCull(pos0, pos1, pos2, maxDisplace))
	{
		tess = 0.0f;
	}
	else
	{
		float3 f;
		f.x = UnityCalcDistanceTessFactor(v0, minDist, maxDist, tessFactor);
		f.y = UnityCalcDistanceTessFactor(v1, minDist, maxDist, tessFactor);
		f.z = UnityCalcDistanceTessFactor(v2, minDist, maxDist, tessFactor);
		tess = UnityCalcTriEdgeTessFactors(f);
	}
	return tess;
}

TessellationFactors HSConstant(InputPatch<Hull_Input, 3> patch)
{
	TessellationFactors f;
	//half4 factor = UnityEdgeLengthBasedTessCull(patch[0].vertex, patch[1].vertex, patch[2].vertex, _TesselationFactor, _TessMaxDistance);
#if IGNORE_TESS_CULL
	half4 factor = DistanceBasedTess(patch[0].vertex, patch[1].vertex, patch[2].vertex, 1, _TesselationMaxDistance, _TesselationFactor);
#else
	half4 factor = DistanceBasedTessCull(patch[0].vertex, patch[1].vertex, patch[2].vertex, 1, _TesselationMaxDistance, _TesselationFactor, _TesselationMaxDisplace);
#endif

	f.edge[0] = factor.x;
	f.edge[1] = factor.y;
	f.edge[2] = factor.z;
	f.inside = factor.w;
	return f;
}

[domain("tri")]
[partitioning("integer")]
[outputtopology("triangle_cw")]
[patchconstantfunc("HSConstant")]
[outputcontrolpoints(3)]
Hull_ControlPointOutput HS(InputPatch<Hull_Input, 3> Input, uint uCPID : SV_OutputControlPointID)
{
	Hull_ControlPointOutput o;
	o.vertex = Input[uCPID].vertex.xyz;
	o.color = Input[uCPID].color;
	return o;
}

[domain("tri")]
v2f DS(TessellationFactors HSConstantData, const OutputPatch<Hull_ControlPointOutput, 3> Input, float3 BarycentricCoords : SV_DomainLocation)
{
	float fU = BarycentricCoords.x;
	float fV = BarycentricCoords.y;
	float fW = BarycentricCoords.z;

	float3 vertex = Input[0].vertex * fU + Input[1].vertex * fV + Input[2].vertex * fW;

	return vert(float4(vertex, 1), Input[0].color);
}

[domain("tri")]
v2fDepth DS_Depth(TessellationFactors HSConstantData, const OutputPatch<Hull_ControlPointOutput, 3> Input, float3 BarycentricCoords : SV_DomainLocation)
{
	float fU = BarycentricCoords.x;
	float fV = BarycentricCoords.y;
	float fW = BarycentricCoords.z;

	float3 vertex = Input[0].vertex * fU + Input[1].vertex * fV + Input[2].vertex * fW;

	return vertDepth(float4(vertex, 1), Input[0].color);
}
