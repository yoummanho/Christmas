using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.HighDefinition;
using static KW_Extensions;

public class KW_OffscreenRendering_CustomPass : CustomPass
{
    public RenderTextureTemp waterRT;
    private Material sceneCombineMaterial;

    private const string WaterDepthShaderName = "Hidden/KriptoFX/Water/KW_OffscreenRendering_HDRP";

    protected override void Setup(ScriptableRenderContext renderContext, CommandBuffer cmd)
    {
        name = "Water.OffscreenRenderingCustomPass";
    }

    void InitializeTextures(Camera cam, CommandBuffer cmd)
    {
        var water = KW_WaterDynamicScripts.GetCurrentWater();
        var resolutionScale = water.OffscreenRenderingResolution;
        var width = (int)(cam.scaledPixelWidth * resolutionScale);
        var height = (int)(cam.scaledPixelHeight * resolutionScale);

        waterRT = ReinitializeRenderTextureTemp(waterRT, cmd, "KW_OffscreenRenderingRenderPass._WaterOffscreenRT", width, height, 16, RenderTextureFormat.ARGBHalf, true, 
            FilterMode.Bilinear, false, false, TextureDimension.Tex2D, (int)water.OffscreenRenderingAA);
       
        if (sceneCombineMaterial == null) sceneCombineMaterial = KW_Extensions.CreateMaterial(WaterDepthShaderName);
    }

    protected override void Execute(CustomPassContext ctx)
    {
        var cam = ctx.hdCamera.camera;
        var water = KW_WaterDynamicScripts.GetCurrentWater();
        if (!IsCanExecuteCameraBuffers(cam, water)) return;
        var cmd = ctx.cmd;

        InitializeTextures(cam, cmd);

        CoreUtils.SetRenderTarget(cmd, waterRT.identifier, ClearFlag.All);

        cmd.DrawMesh(water.currentWaterMesh, water.waterMeshGO.transform.localToWorldMatrix, water.waterMaterial);

        cmd.SetGlobalTexture("KW_ScreenSpaceWater", waterRT.identifier);
        CoreUtils.SetRenderTarget(cmd, ctx.cameraColorBuffer, ClearFlag.None);
        CoreUtils.DrawFullScreen(cmd, sceneCombineMaterial, shaderPassId:0);
    }

    protected override void Cleanup()
    {
        waterRT.Release();
        KW_Extensions.SafeDestroy(sceneCombineMaterial);
    }


    public void Release()
    {
        Cleanup();
    }
}
