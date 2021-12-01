using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.HighDefinition;
using static KW_Extensions;

class KW_MaskDepthNormalCustomPass : CustomPass
{
    string profilerTag;
    private float resolutionScale;

    KW_PyramidBlur pyramidBlurMask;
    private Material maskDepthNormalMaterial;

    RenderTextureTemp waterMaskRT;
    RenderTextureTemp waterMaskRT_Blured;
    RenderTextureTemp waterDepthRT;

    private const string maskDepthNormal_ShaderName = "Hidden/KriptoFX/Water/KW_MaskDepthNormalPass";
    private const int DepthMaskTextureHeightLimit = 540; //fullHD * 0.5 enough even for 4k

    private int KW_WaterMaskScatterNormals_ID = Shader.PropertyToID("KW_WaterMaskScatterNormals");
    private int KW_WaterDepth_ID = Shader.PropertyToID("KW_WaterDepth");
    private int KW_WaterMaskScatterNormals_Blured_ID = Shader.PropertyToID("KW_WaterMaskScatterNormals_Blured");

    protected override void Setup(ScriptableRenderContext renderContext, CommandBuffer cmd)
    {
        name = "Water.MaskDepthNormalsCustomPass";
    }

    public void InitializeTextures(Camera currentCamera, CommandBuffer cmd)
    {
        var width = (int)(currentCamera.scaledPixelWidth * resolutionScale);
        var height = (int)(currentCamera.scaledPixelHeight * resolutionScale);
        
        waterMaskRT = ReinitializeRenderTextureTemp(waterMaskRT, cmd, "KW_MaskDepthNormalRenderPass._waterMaskRT", width, height, 0, RenderTextureFormat.ARGBHalf);
        waterMaskRT_Blured = ReinitializeRenderTextureTemp(waterMaskRT_Blured, cmd, "KW_MaskDepthNormalRenderPass._waterMaskRT_Blured", width, height, 0, RenderTextureFormat.ARGBHalf);
        waterDepthRT = ReinitializeRenderTextureTemp(waterDepthRT, cmd, "KW_MaskDepthNormalRenderPass._waterDepthRT", width, height, 24, RenderTextureFormat.Depth);
     
    }
   
    public void UpdateParams(Camera currentCamera)
    {
        var water = KW_WaterDynamicScripts.GetCurrentWater();
        resolutionScale = (water.UseUnderwaterEffect && water.UseHighQualityUnderwater) ? 0.5f : 0.25f;
        if (currentCamera.scaledPixelHeight  * resolutionScale > DepthMaskTextureHeightLimit)
        {
            var newRelativeScale = DepthMaskTextureHeightLimit / (currentCamera.scaledPixelHeight * resolutionScale);
            resolutionScale *= newRelativeScale;
        }

        if (pyramidBlurMask == null) pyramidBlurMask = new KW_PyramidBlur();
        if (maskDepthNormalMaterial == null) maskDepthNormalMaterial = KW_Extensions.CreateMaterial(maskDepthNormal_ShaderName);
        if (!water.waterSharedMaterials.Contains(maskDepthNormalMaterial)) water.waterSharedMaterials.Add(maskDepthNormalMaterial);
    }

    protected override void Execute(CustomPassContext ctx)
    {
        var cam = ctx.hdCamera.camera;
        var water = KW_WaterDynamicScripts.GetCurrentWater();

        if (!IsCanExecuteCameraBuffers(cam, water)) return;

        var cmd = ctx.cmd;

        UpdateParams(cam);
        InitializeTextures(cam, cmd);
     
        CoreUtils.SetRenderTarget(cmd, waterMaskRT.identifier, waterDepthRT.identifier, ClearFlag.All, Color.black);

        var shaderPass = water.UseTesselation && SystemInfo.graphicsShaderLevel >= 46 ? 0 : 1;
        cmd.DrawMesh(water.currentWaterMesh, water.waterMeshGO.transform.localToWorldMatrix, maskDepthNormalMaterial, 0, shaderPass);

        cmd.SetGlobalTexture(KW_WaterMaskScatterNormals_ID, waterMaskRT.identifier);
        cmd.SetGlobalTexture(KW_WaterDepth_ID, waterDepthRT.identifier);

        CoreUtils.SetRenderTarget(cmd, waterMaskRT_Blured.identifier, ClearFlag.None);
        pyramidBlurMask.ComputeBlurPyramid(3.0f, waterMaskRT, waterMaskRT_Blured, cmd);
        cmd.SetGlobalTexture(KW_WaterMaskScatterNormals_Blured_ID, waterMaskRT_Blured.identifier);

        
    }

    // called after Execute, use it to clean up anything allocated in Configure
    protected override void Cleanup()
    {
        waterMaskRT.Release();
        waterMaskRT_Blured.Release();
        waterDepthRT.Release();
        if (pyramidBlurMask != null) pyramidBlurMask.Release();
        KW_Extensions.SafeDestroy(maskDepthNormalMaterial);
    }

    public void Release()
    {
        Cleanup();
    }
}
