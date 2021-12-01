using UnityEngine;
using UnityEngine.Rendering.HighDefinition;

public class KW_WaterSystemVolumes_HDRP : MonoBehaviour
{
    CustomPassVolume volumeAfterOpaque;
    CustomPassVolume volumeBeforePreRefraction;
    CustomPassVolume volumeBeforeTransparent;
    CustomPassVolume volumeBeforePostProcess;

    KW_MaskDepthNormalCustomPass maskDepthNormalCustomPass;
    KW_VolumetricLighting_CustomPass volumetricLightingCustomPass;
    KW_CausticDecal_CustomPass causticDecalCustomPass;
    KW_ScreenSpaceReflection_CustomPass screenSpaceReflectionCustomPass;
    KW_OffscreenRendering_CustomPass offscreenRenderingCustomPass;
    KW_Underwater_CustomPass underwaterCustomPass;
    KW_DrawToDepth_CustomPass drawToDepthCustomPass;

    public void UpdateWaterPasses()   
    {
        if (volumeAfterOpaque == null)
        {
            var tempGO = new GameObject("HDRP_WaterVolume_AfterOpaque");
            tempGO.transform.parent = transform;
            volumeAfterOpaque = tempGO.AddComponent<CustomPassVolume>();
            volumeAfterOpaque.injectionPoint = CustomPassInjectionPoint.AfterOpaqueDepthAndNormal;
        }

        if (volumeBeforePreRefraction == null)
        {
            var tempGO = new GameObject("HDRP_WaterVolume_BeforePreRefraction");
            tempGO.transform.parent = transform;
            volumeBeforePreRefraction = tempGO.AddComponent<CustomPassVolume>();
            volumeBeforePreRefraction.injectionPoint = CustomPassInjectionPoint.BeforePreRefraction;
        }

        if (volumeBeforeTransparent == null)
        {
            var tempGO = new GameObject("HDRP_WaterVolume_BeforeTransparent");
            tempGO.transform.parent = transform;
            volumeBeforeTransparent = tempGO.AddComponent<CustomPassVolume>();
            volumeBeforeTransparent.injectionPoint = CustomPassInjectionPoint.BeforeTransparent;
        }

        if (volumeBeforePostProcess == null)
        {
            var tempGO = new GameObject("HDRP_WaterVolume_BeforePostProcess");
            tempGO.transform.parent = transform;
            volumeBeforePostProcess = tempGO.AddComponent<CustomPassVolume>();
            volumeBeforePostProcess.injectionPoint = CustomPassInjectionPoint.BeforePostProcess;
        }

        var water = KW_WaterDynamicScripts.GetCurrentWater();

        if (maskDepthNormalCustomPass == null) maskDepthNormalCustomPass = (KW_MaskDepthNormalCustomPass)volumeAfterOpaque.AddPassOfType<KW_MaskDepthNormalCustomPass>();

        if (water.UseVolumetricLight && volumetricLightingCustomPass == null) volumetricLightingCustomPass = (KW_VolumetricLighting_CustomPass)volumeBeforeTransparent.AddPassOfType<KW_VolumetricLighting_CustomPass>();
        if (volumetricLightingCustomPass != null) volumetricLightingCustomPass.enabled = water.UseVolumetricLight;

        if(water.UseCausticEffect && causticDecalCustomPass == null) causticDecalCustomPass = (KW_CausticDecal_CustomPass)volumeBeforePreRefraction.AddPassOfType<KW_CausticDecal_CustomPass>();
        if (causticDecalCustomPass != null) causticDecalCustomPass.enabled = water.UseCausticEffect;

        if (water.ReflectionMode == WaterSystem.ReflectionModeEnum.ScreenSpaceReflection && screenSpaceReflectionCustomPass == null) 
            screenSpaceReflectionCustomPass = (KW_ScreenSpaceReflection_CustomPass)volumeBeforeTransparent.AddPassOfType<KW_ScreenSpaceReflection_CustomPass>();
        if (screenSpaceReflectionCustomPass != null) screenSpaceReflectionCustomPass.enabled = (water.ReflectionMode == WaterSystem.ReflectionModeEnum.ScreenSpaceReflection);

        if (water.OffscreenRendering && offscreenRenderingCustomPass == null) offscreenRenderingCustomPass = (KW_OffscreenRendering_CustomPass)volumeBeforeTransparent.AddPassOfType<KW_OffscreenRendering_CustomPass>();
        if (offscreenRenderingCustomPass != null) offscreenRenderingCustomPass.enabled = water.OffscreenRendering;

        if (water.UseUnderwaterEffect && underwaterCustomPass == null) underwaterCustomPass = (KW_Underwater_CustomPass)volumeBeforePostProcess.AddPassOfType<KW_Underwater_CustomPass>();
        if(underwaterCustomPass != null) underwaterCustomPass.enabled = water.UseUnderwaterEffect;

        if(water.DrawToPosteffectsDepth && drawToDepthCustomPass == null) drawToDepthCustomPass = (KW_DrawToDepth_CustomPass)volumeBeforePostProcess.AddPassOfType<KW_DrawToDepth_CustomPass>();
        if (drawToDepthCustomPass != null) drawToDepthCustomPass.enabled = water.DrawToPosteffectsDepth;
    }

}
