using System.Collections.Generic;
using System.IO;
using UnityEngine;

using UnityEngine.Rendering;

//[ExecuteInEditMode]
public class KW_CausticRendering : MonoBehaviour
{
    public Texture2D depth_tex;
    public RenderTexture causticLod0;
    public RenderTexture causticLod1;
    public RenderTexture causticLod2;
    public RenderTexture causticLod3;
    public RenderTexture causticRT;

    private Material causticComputeMaterial;
    private Material causticDecalMaterial;
    private Mesh causticMesh;
    private Mesh decalMesh;

    private CommandBuffer cb;

    private const string path_causticFolder = "CausticMaps";
    private const string path_causticDepthTexture = "KW_CausticDepthTexture";
    private const string path_causticDepthData = "KW_CausticDepthData";
    private const string CausticComputeShaderName = "Hidden/KriptoFX/Water/ComputeCaustic";
    private const string CausticDecalShaderName = "Hidden/KriptoFX/Water/CausticDecal";

    private int ID_KW_CausticDepth = Shader.PropertyToID("KW_CausticDepthTex");
    private int ID_KW_CausticDepthOrthoSize = Shader.PropertyToID("KW_CausticDepthOrthoSize");
    private int ID_KW_CausticDepthNearFarDistance = Shader.PropertyToID("KW_CausticDepth_Near_Far_Dist");
    private int ID_KW_CausticDepthPos = Shader.PropertyToID("KW_CausticDepthPos");

    private const int nearPlaneDepth = -2;
    private const int farPlaneDepth = 100;

    private int currentMeshResolution;
    private bool isDepthTextureInitialized;
    public static Vector4 LodSettings = new Vector4(10, 20, 40, 80);

    public void Release()
    {
        OnDisable();
    }

    void OnDisable()
    {
        KW_Extensions.SafeDestroy(depth_tex, causticComputeMaterial, causticDecalMaterial, causticMesh, decalMesh);
        KW_Extensions.ReleaseRenderTextures(causticLod0, causticLod1, causticLod2, causticLod3, causticRT);

        currentMeshResolution = 0;
        isDepthTextureInitialized = false;
        Shader.DisableKeyword("USE_DEPTH_SCALE");
    }

    private void InitializeCausticTexture(int size)
    {
        causticLod0 = KW_Extensions.ReinitializeRenderTexture(causticLod0, size, size, 0, RenderTextureFormat.R8, null, false, true);
        causticLod1 = KW_Extensions.ReinitializeRenderTexture(causticLod1, size, size, 0, RenderTextureFormat.R8, null, false, true);
        causticLod2 = KW_Extensions.ReinitializeRenderTexture(causticLod2, size, size, 0, RenderTextureFormat.R8, null, false, true);
        causticLod3 = KW_Extensions.ReinitializeRenderTexture(causticLod3, size, size, 0, RenderTextureFormat.R8, null, false, true);
    }

    private async void LoadDepthTexture(string GUID)

    {
        isDepthTextureInitialized = true;
        var pathToBakedDataFolder = KW_Extensions.GetPathToStreamingAssetsFolder();
        var pathToDepthTex = Path.Combine(pathToBakedDataFolder, path_causticFolder, GUID, path_causticDepthTexture);
        var pathToDepthData = Path.Combine(pathToBakedDataFolder, path_causticFolder, GUID, path_causticDepthData);
        var depthParams = await KW_Extensions.DeserializeFromFile<KW_WaterOrthoDepth.OrthoDepthParams>(pathToDepthData);
        if (depthParams != null)
        {
            if (depth_tex == null) depth_tex = await KW_Extensions.ReadTextureFromFileAsync(pathToDepthTex);
            Shader.SetGlobalTexture(ID_KW_CausticDepth, depth_tex);
            Shader.SetGlobalFloat(ID_KW_CausticDepthOrthoSize, depthParams.OtrhograpicSize);
            Shader.SetGlobalVector(ID_KW_CausticDepthNearFarDistance, new Vector3(nearPlaneDepth, farPlaneDepth, farPlaneDepth - nearPlaneDepth));
            Shader.SetGlobalVector(ID_KW_CausticDepthPos, new Vector3(depthParams.PositionX, depthParams.PositionY, depthParams.PositionZ));
          
            Shader.EnableKeyword("USE_DEPTH_SCALE");
        }
    }

    public void AddMaterialsToWaterRendering(List<Material> waterShaderMaterials)
    {
        if (causticComputeMaterial == null) causticComputeMaterial = KW_Extensions.CreateMaterial(CausticComputeShaderName);
        if (!waterShaderMaterials.Contains(causticComputeMaterial)) waterShaderMaterials.Add(causticComputeMaterial);

        if (causticDecalMaterial == null) causticDecalMaterial = KW_Extensions.CreateMaterial(CausticDecalShaderName);
        if (!waterShaderMaterials.Contains(causticDecalMaterial)) waterShaderMaterials.Add(causticDecalMaterial);
    }

    void RenderLod(Vector3 camPos, Vector3 camDir, float lodDistance, RenderTexture target, float causticStr, float causticDepthScale, bool useFiltering = false)
    {
        var bakeCamPos = camPos + camDir * lodDistance * 0.5f;

        if (useFiltering) causticComputeMaterial.EnableKeyword("USE_CAUSTIC_FILTERING");
        else causticComputeMaterial.DisableKeyword("USE_CAUSTIC_FILTERING");

        causticComputeMaterial.SetFloat("KW_MeshScale", lodDistance);
        causticComputeMaterial.SetVector("KW_CausticCameraOffset", bakeCamPos);
        causticComputeMaterial.SetFloat("KW_CaustisStrength", causticStr);
        causticComputeMaterial.SetFloat("KW_CausticDepthScale", causticDepthScale);

        Graphics.SetRenderTarget(target);
        GL.Clear(false, true, Color.black);
        causticComputeMaterial.SetPass(0);
        Graphics.DrawMeshNow(causticMesh, Matrix4x4.identity);
      
    }

    public void ComputeCausticTextures(Camera currentCamera, float causticStr, float causticDepthScale, int causticTextureSize, int activeLodCounts, int meshResolution, bool useFiltering,
        bool useDisperstion, bool useDepthScale, float dispersionStrength, List<Material> waterSharedMaterials, string GUID)
    {

        if (causticLod0 == null || causticTextureSize != causticLod0.width) InitializeCausticTexture(causticTextureSize);
        if (currentMeshResolution != meshResolution) GeneratePlane(meshResolution, 1.2f);
        if (decalMesh == null) GenerateDecalMesh();
        if (useDepthScale && !isDepthTextureInitialized) LoadDepthTexture(GUID);
       
        var camPos = currentCamera.transform.position;
        var camDir = currentCamera.transform.forward;
        var decalScale = LodSettings[activeLodCounts - 1] * 2;

        RenderLod(camPos, camDir, LodSettings.x, causticLod0, causticStr, causticDepthScale, useFiltering);
        if (activeLodCounts > 1) RenderLod(camPos, camDir, LodSettings.y, causticLod1, causticStr, causticDepthScale, useFiltering);
        if (activeLodCounts > 2) RenderLod(camPos, camDir, LodSettings.z, causticLod2, causticStr, causticDepthScale);
        if (activeLodCounts > 3) RenderLod(camPos, camDir, LodSettings.w, causticLod3, causticStr, causticDepthScale);
        Graphics.SetRenderTarget(null);
        var decalPos = currentCamera.transform.position;
        decalPos.y = transform.position.y - 15;

        var lodDir = camDir * 0.5f;
        UpdateMaterialParams(causticDecalMaterial, lodDir, camPos, decalScale);

        foreach (var waterSharedMaterial in waterSharedMaterials)
        {
            UpdateMaterialParams(waterSharedMaterial, lodDir, camPos, decalScale);
        }

        causticDecalMaterial.SetFloat("KW_CaustisStrength", causticStr);
        if (useDisperstion && dispersionStrength > 0.1f)
        {
            causticDecalMaterial.EnableKeyword("USE_DISPERSION");
            dispersionStrength = Mathf.Lerp(dispersionStrength * 0.25f, dispersionStrength, causticTextureSize / 1024f);
            causticDecalMaterial.SetFloat("KW_CausticDispersionStrength", dispersionStrength);
        }
        else causticDecalMaterial.DisableKeyword("USE_DISPERSION");

        if (!useDepthScale)
        {
            isDepthTextureInitialized = false;
            Shader.DisableKeyword("USE_DEPTH_SCALE");
        }

        Shader.DisableKeyword("USE_LOD1");
        Shader.DisableKeyword("USE_LOD2");
        Shader.DisableKeyword("USE_LOD3");
        switch (activeLodCounts)
        {
            case 2:
                Shader.EnableKeyword("USE_LOD1");
                break;
            case 3:
                Shader.EnableKeyword("USE_LOD2");
                break;
            case 4:
                Shader.EnableKeyword("USE_LOD3");
                break;
        }
    }

    public void RenderDecal(Vector3 cameraPos, int activeLodCounts, Dictionary<CommandBuffer, CameraEvent> waterSharedBuffers)
    {
        if (cb == null) cb = new CommandBuffer() { name = "CausticDecal" };
        else cb.Clear();

        cameraPos.y = transform.position.y - 15;
        var decalScale = LodSettings[activeLodCounts - 1] * 2;
        var decalTRS = Matrix4x4.TRS(cameraPos, Quaternion.identity, new Vector3(decalScale, 40, decalScale));
        cb.DrawMesh(decalMesh, decalTRS, causticDecalMaterial);

        if (!waterSharedBuffers.ContainsKey(cb)) waterSharedBuffers.Add(cb, CameraEvent.BeforeForwardAlpha);
    }

    public void SaveOrthoDepth(string GUID, Vector3 position, int areaSize, int texSize)
    {
        var pathToBakedDataFolder = KW_Extensions.GetPathToStreamingAssetsFolder();
        var pathToDepthTex = Path.Combine(pathToBakedDataFolder, path_causticFolder, GUID, path_causticDepthTexture);
        var pathToDepthData = Path.Combine(pathToBakedDataFolder, path_causticFolder, GUID, path_causticDepthData);
        KW_WaterOrthoDepth.RenderAndSaveDepth(transform, position, areaSize, texSize, nearPlaneDepth, farPlaneDepth, pathToDepthTex, pathToDepthData);
        Release();
    }

    void UpdateMaterialParams(Material mat, Vector3 lodDir, Vector3 lodPos, float decalScale)
    {
        if (mat == null) return;
        mat.SetTexture("KW_CausticLod0", causticLod0);
        mat.SetTexture("KW_CausticLod1", causticLod1);
        mat.SetTexture("KW_CausticLod2", causticLod2);
        mat.SetTexture("KW_CausticLod3", causticLod3);
        mat.SetVector("KW_CausticLodSettings", LodSettings);
        mat.SetVector("KW_CausticLodOffset", lodDir);
        mat.SetVector("KW_CausticLodPosition", lodPos);
        mat.SetFloat("KW_DecalScale", decalScale);
    }

    private void GeneratePlane(int meshResolution, float scale)
    {
        currentMeshResolution = meshResolution;
        if (causticMesh == null)
        {
            causticMesh = new Mesh();
            causticMesh.indexFormat = IndexFormat.UInt32;
        }

        var vertices = new Vector3[(meshResolution + 1) * (meshResolution + 1)];
        var uv = new Vector2[vertices.Length];
        var triangles = new int[meshResolution * meshResolution * 6];

        for (int i = 0, y = 0; y <= meshResolution; y++)
        for (var x = 0; x <= meshResolution; x++, i++)
        {
            vertices[i] = new Vector3(x * scale / meshResolution - 0.5f * scale, y * scale / meshResolution - 0.5f * scale, 0);
            uv[i] = new Vector2(x * scale / meshResolution, y * scale / meshResolution);
        }

        for (int ti = 0, vi = 0, y = 0; y < meshResolution; y++, vi++)
        for (var x = 0; x < meshResolution; x++, ti += 6, vi++)
        {
            triangles[ti] = vi;
            triangles[ti + 3] = triangles[ti + 2] = vi + 1;
            triangles[ti + 4] = triangles[ti + 1] = vi + meshResolution + 1;
            triangles[ti + 5] = vi + meshResolution + 2;
        }

        causticMesh.Clear();
        causticMesh.vertices = vertices;
        causticMesh.uv = uv;
        causticMesh.triangles = triangles;
    }
    void GenerateDecalMesh()
    {
        Vector3[] vertices = {
            new Vector3 (-0.5f, -0.5f, -0.5f),
            new Vector3 (0.5f, -0.5f, -0.5f),
            new Vector3 (0.5f, 0.5f, -0.5f),
            new Vector3 (-0.5f, 0.5f, -0.5f),
            new Vector3 (-0.5f, 0.5f, 0.5f),
            new Vector3 (0.5f, 0.5f, 0.5f),
            new Vector3 (0.5f, -0.5f, 0.5f),
            new Vector3 (-0.5f, -0.5f, 0.5f),
        };

        int[] triangles = {
            0, 2, 1, //face front
            0, 3, 2,
            2, 3, 4, //face top
            2, 4, 5,
            1, 2, 5, //face right
            1, 5, 6,
            0, 7, 4, //face left
            0, 4, 3,
            5, 4, 7, //face back
            5, 7, 6,
            0, 6, 7, //face bottom
            0, 1, 6
        };

        if (decalMesh == null)
        {
            decalMesh = new Mesh();
        }
        decalMesh.Clear();
        decalMesh.vertices = vertices;
        decalMesh.triangles = triangles;
        decalMesh.RecalculateNormals();
    }
}
