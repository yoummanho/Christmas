using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using UnityEngine.Rendering.HighDefinition;
using static KW_Extensions;

class KW_Underwater_CustomPass : CustomPass
{
    float resolutionScale;

    const string UnderwaterShaderName = "KriptoFX/Water30/Underwater";

    private Material underwaterMaterial;
    KW_PyramidBlur pyramidBlur;
    private RenderTextureTemp underwaterRT;
    private RenderTextureTemp underwaterRT_Blured;

    protected override void Setup(ScriptableRenderContext renderContext, CommandBuffer cmd)
    {
        name = "Water.UnderwaterCustomPass";
    }

   
    void InitializeTextures(Camera cam, CommandBuffer cmd)
    {
        var width = (int)(cam.scaledPixelWidth * resolutionScale);
        var height = (int)(cam.scaledPixelHeight * resolutionScale);

        underwaterRT = ReinitializeRenderTextureTemp(underwaterRT, cmd, "KW_UnderwaterRenderPass._UnderwaterRT", width, height, 0, RenderTextureFormat.ARGBHalf);
        underwaterRT_Blured = ReinitializeRenderTextureTemp(underwaterRT_Blured, cmd, "KW_UnderwaterRenderPass._UnderwaterRT_Blured", width, height, 0, RenderTextureFormat.ARGBHalf);
    }

    public void UpdateParams()
    {
        var water = KW_WaterDynamicScripts.GetCurrentWater();
        resolutionScale = water.UnderwaterResolutionScale;
       
        if (underwaterMaterial == null) underwaterMaterial = KW_Extensions.CreateMaterial(UnderwaterShaderName);
        if (!water.waterSharedMaterials.Contains(underwaterMaterial)) water.waterSharedMaterials.Add(underwaterMaterial);
        if (pyramidBlur == null) pyramidBlur = new KW_PyramidBlur();
    }

    protected override void Execute(CustomPassContext ctx)
    {
        var cam = ctx.hdCamera.camera;
        var water = KW_WaterDynamicScripts.GetCurrentWater();

        if (!IsCanExecuteCameraBuffers(cam, water)) return;

        UpdateParams();
        InitializeTextures(cam, ctx.cmd);
       
        var cmd = ctx.cmd;

        underwaterMaterial.SetFloat("KW_TargetResolutionMultiplier", 1f/resolutionScale);
        CoreUtils.SetRenderTarget(cmd, underwaterRT.identifier, ClearFlag.Color, Color.black);
        //cmd.Blit(null, underwaterRT.identifier, underwaterMaterial, 0);
        CoreUtils.DrawFullScreen(cmd, underwaterMaterial, shaderPassId : 0);
        if (water.UseUnderwaterBlur)
        {
            pyramidBlur.ComputeBlurPyramid(water.UnderwaterBlurRadius, underwaterRT, underwaterRT_Blured, cmd);
            CoreUtils.SetRenderTarget(cmd, ctx.cameraColorBuffer, ClearFlag.None);
            cmd.SetGlobalTexture("KW_UnderwaterRT", underwaterRT_Blured.identifier);
            //cmd.Blit(underwaterRT_Blured.identifier, ctx.cameraColorBuffer, underwaterMaterial, 1);
            CoreUtils.DrawFullScreen(cmd, underwaterMaterial, shaderPassId: 1);
        }
        else
        {
            CoreUtils.SetRenderTarget(cmd, ctx.cameraColorBuffer, ClearFlag.None);
            //cmd.Blit(underwaterRT.identifier, ctx.cameraColorBuffer, underwaterMaterial, 1);
            cmd.SetGlobalTexture("KW_UnderwaterRT", underwaterRT.identifier);
            CoreUtils.DrawFullScreen(cmd, underwaterMaterial, shaderPassId: 1);
        }
    }

   
    protected override void Cleanup()
    {
        underwaterRT.Release();
        underwaterRT_Blured.Release();
        SafeDestroy(underwaterMaterial);
        if (pyramidBlur != null) pyramidBlur.Release();
    }

    public void Release()
    {
        Cleanup();
    }
}
