using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.HighDefinition;
using static KW_Extensions;


public class KW_ScreenSpaceReflection_CustomPass: CustomPass
{
    float resolutionScale;
    bool debugNonDx11Features = false;
   

    int currentWidth;
    int currentHeight;

    private const string hashProjectionShaderName = "Hidden/KriptoFX/Water/SSPR_Projection";
    private const string hashReflectionShaderName = "Hidden/KriptoFX/Water/SSPR_Reflection";

    private RenderTextureTemp reflectionRT;
    private RenderTextureTemp reflectionHash;
   // private RenderTextureTemp reflectionHashMobile;

    ComputeShader cs;


    const int SHADER_NUMTHREAD_X = 8; //must match compute shader's [numthread(x)]
    const int SHADER_NUMTHREAD_Y = 8; //must match compute shader's [numthread(y)]

    protected override void Setup(ScriptableRenderContext renderContext, CommandBuffer cmd)
    {
        name = "Water.ScreenSpaceReflectionCustomPass";
    }

    // called each frame before Execute, use it to set up things the pass will need
    public void InitializeTextures(Camera currentCamera, CommandBuffer cmd)
    {
        currentWidth = GetRTWidth(currentCamera.scaledPixelWidth, currentCamera.scaledPixelHeight);
        currentHeight = GetRTHeight(currentCamera.scaledPixelHeight);

        var canUseMipMap = Application.isPlaying;
        reflectionRT = ReinitializeRenderTextureTemp(reflectionRT, cmd, "KW_ScreenSpaceReflectionRenderPass._reflectionRT", currentWidth, currentHeight, 0, RenderTextureFormat.ARGBHalf, true, FilterMode.Bilinear, true, canUseMipMap, mipCount: 5); //bug, mipmaping is flickering in editor
        reflectionHash = ReinitializeRenderTextureTemp(reflectionHash, cmd, "KW_ScreenSpaceReflectionRenderPass._reflectionHash", currentWidth, currentHeight, 0, IsSupportDx11Features() ? RenderTextureFormat.RInt : RenderTextureFormat.RFloat, true, FilterMode.Point, true);

        if (cs == null) cs = (ComputeShader)Resources.Load(@"HDRP/SSPR_Projection_HDRP");
    }


    public void UpdateParams()
    {
        var water = KW_WaterDynamicScripts.GetCurrentWater();
        resolutionScale = water.ReflectionTextureScale;
    }

    bool IsSupportDx11Features()
    {
        if (debugNonDx11Features) return false;

        if (!SystemInfo.SupportsRenderTextureFormat(RenderTextureFormat.RInt))
            return false;

        if (SystemInfo.graphicsDeviceType == GraphicsDeviceType.Metal)
            return false;

        if (SystemInfo.graphicsDeviceType == GraphicsDeviceType.Direct3D11 || SystemInfo.graphicsDeviceType == GraphicsDeviceType.Direct3D12)
            return true;
#if UNITY_ANDROID
        return false;
#endif

        return false;
    }

    int GetRTHeight(int height)
    {
        return Mathf.CeilToInt((resolutionScale * height) / (float)SHADER_NUMTHREAD_Y) * SHADER_NUMTHREAD_Y;
    }
    int GetRTWidth(int width, int height)
    {
        float aspect = (float)width / height;
        return Mathf.CeilToInt(GetRTHeight(height) * aspect / (float)SHADER_NUMTHREAD_X) * SHADER_NUMTHREAD_X;
    }

    protected override void Execute(CustomPassContext ctx)
    {
        var cam = ctx.hdCamera.camera;
        var water = KW_WaterDynamicScripts.GetCurrentWater();

        if (!IsCanExecuteCameraBuffers(cam, water)) return;

        var cmd = ctx.cmd;

        UpdateParams();
        InitializeTextures(cam, cmd);

        int dispatchThreadGroupXCount = currentWidth / SHADER_NUMTHREAD_X; //divide by shader's numthreads.x
        int dispatchThreadGroupYCount = currentHeight / SHADER_NUMTHREAD_Y; //divide by shader's numthreads.y
        int dispatchThreadGroupZCount = 1; //divide by shader's numthreads.z
      
        cmd.SetComputeVectorParam(cs, Shader.PropertyToID("_RTSize"), new Vector2(currentWidth, currentHeight));
        cmd.SetComputeFloatParam(cs, Shader.PropertyToID("_HorizontalPlaneHeightWS"), water.transform.position.y);
        cmd.SetComputeFloatParam(cs, Shader.PropertyToID("_DepthHolesFillDistance"), water.SSR_DepthHolesFillDistance);
      
        Matrix4x4 VP = GL.GetGPUProjectionMatrix(cam.projectionMatrix, true) * cam.worldToCameraMatrix;
        cmd.SetComputeMatrixParam(cs, "KW_CameraMatrix", VP);

        if (IsSupportDx11Features())
        {
            CoreUtils.SetRenderTarget(cmd, reflectionRT.identifier);
           
            int kernel_NonMobilePathClear = cs.FindKernel("NonMobilePathClear");
            cmd.SetComputeTextureParam(cs, kernel_NonMobilePathClear, "HashRT", reflectionHash.identifier);
            cmd.SetComputeTextureParam(cs, kernel_NonMobilePathClear, "ColorRT", reflectionRT.identifier);
            cmd.DispatchCompute(cs, kernel_NonMobilePathClear, dispatchThreadGroupXCount, dispatchThreadGroupYCount, dispatchThreadGroupZCount);

            int kernel_NonMobilePathRenderHashRT = cs.FindKernel("NonMobilePathRenderHashRT");
            cmd.SetComputeTextureParam(cs, kernel_NonMobilePathRenderHashRT, "HashRT", reflectionHash.identifier);
            cmd.SetComputeTextureParam(cs, kernel_NonMobilePathRenderHashRT, "ColorRT", reflectionRT.identifier);
            cmd.SetComputeTextureParam(cs, kernel_NonMobilePathRenderHashRT, "_CameraDepthTexture", ctx.cameraDepthBuffer);

            cmd.DispatchCompute(cs, kernel_NonMobilePathRenderHashRT, dispatchThreadGroupXCount, dispatchThreadGroupYCount, dispatchThreadGroupZCount);

            int kernel_NonMobilePathResolveColorRT = cs.FindKernel("NonMobilePathResolveColorRT");
            cmd.SetComputeTextureParam(cs, kernel_NonMobilePathResolveColorRT, "_CameraColorTexture", ctx.cameraColorBuffer);
            cmd.SetComputeTextureParam(cs, kernel_NonMobilePathResolveColorRT, "ColorRT", reflectionRT.identifier);
            cmd.SetComputeTextureParam(cs, kernel_NonMobilePathResolveColorRT, "HashRT", reflectionHash.identifier);
            cmd.DispatchCompute(cs, kernel_NonMobilePathResolveColorRT, dispatchThreadGroupXCount, dispatchThreadGroupYCount, dispatchThreadGroupZCount);
           
        }
        else
        {
            CoreUtils.SetRenderTarget(cmd, reflectionRT.identifier);
            int kernel_MobilePathSinglePassColorRTDirectResolve = cs.FindKernel("MobilePathSinglePassColorRTDirectResolve");
            cmd.SetComputeTextureParam(cs, kernel_MobilePathSinglePassColorRTDirectResolve, "ColorRT", reflectionRT.identifier);
            cmd.SetComputeTextureParam(cs, kernel_MobilePathSinglePassColorRTDirectResolve, "PosWSyRT", reflectionHash.identifier);
            cmd.SetComputeTextureParam(cs, kernel_MobilePathSinglePassColorRTDirectResolve, "_CameraColorTexture", ctx.cameraColorBuffer);
            cmd.SetComputeTextureParam(cs, kernel_MobilePathSinglePassColorRTDirectResolve, "_CameraDepthTexture", ctx.cameraDepthBuffer);
            cmd.DispatchCompute(cs, kernel_MobilePathSinglePassColorRTDirectResolve, dispatchThreadGroupXCount, dispatchThreadGroupYCount, dispatchThreadGroupZCount);

            int kernel_FillHoles = cs.FindKernel("FillHoles");
            cmd.SetComputeTextureParam(cs, kernel_FillHoles, "ColorRT", reflectionRT.identifier);
            cmd.SetComputeTextureParam(cs, kernel_FillHoles, "PackedDataRT", reflectionHash.identifier);
            cmd.DispatchCompute(cs, kernel_FillHoles, Mathf.CeilToInt(dispatchThreadGroupXCount / 2f), Mathf.CeilToInt(dispatchThreadGroupYCount / 2f), dispatchThreadGroupZCount);

        }
        cmd.SetGlobalTexture("KW_ScreenSpaceReflectionTex", reflectionRT.identifier);
        
        
    }

    protected override void Cleanup()
    {
        reflectionRT.Release();
        reflectionHash.Release();
    }

    public void Release()
    {
       
    }
}
