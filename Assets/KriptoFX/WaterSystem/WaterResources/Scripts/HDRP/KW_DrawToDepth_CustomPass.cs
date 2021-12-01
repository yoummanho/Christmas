using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.HighDefinition;
using static KW_Extensions;

class KW_DrawToDepth_CustomPass : CustomPass
{
    float resolutionScale;

    string profilerTag;


   //RenderTextureTemp depthRT;
    //RenderTextureTemp depthRT_blured;

    private Material blitToDepthMaterial;

    private const string BlitToDepthShaderName = "Hidden/KriptoFX/Water/KW_BlitToDepthTexture_HDRP";

    protected override void Setup(ScriptableRenderContext renderContext, CommandBuffer cmd)
    {
        name = "Water.DrawToDepthCustomPass";
    }


    public void UpdateParams(WaterSystem water)
    {
        if (blitToDepthMaterial == null) blitToDepthMaterial = KW_Extensions.CreateMaterial(BlitToDepthShaderName);
        if (!water.waterSharedMaterials.Contains(blitToDepthMaterial)) water.waterSharedMaterials.Add(blitToDepthMaterial);
    }

    protected override void Execute(CustomPassContext ctx)
    {
        var cam = ctx.hdCamera.camera;
        var water = KW_WaterDynamicScripts.GetCurrentWater();

        if (!IsCanExecuteCameraBuffers(cam, water)) return;

        var cmd = ctx.cmd;

        UpdateParams(water);

        CoreUtils.SetRenderTarget(cmd, ctx.cameraDepthBuffer);
        cmd.Blit(null, ctx.cameraDepthBuffer, blitToDepthMaterial);

        
    }
    protected override void Cleanup()
    {
        KW_Extensions.SafeDestroy(blitToDepthMaterial);
    }

    public void Release()
    {
        Cleanup();
    }

}
