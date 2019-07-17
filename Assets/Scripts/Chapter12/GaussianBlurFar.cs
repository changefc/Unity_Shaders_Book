using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GaussianBlurFar : PostEffectsBase {

    public Shader gaussianBluarShader;
    private Material gaussianBlurMaterial = null;

    public Material material
    {
        get
        {
            gaussianBlurMaterial = CheckShaderAndCreateMaterial(gaussianBluarShader, gaussianBlurMaterial);
            return gaussianBlurMaterial;
        }
    }

    [Range(0.2f,3.0f)]
    public int iterations = 3;

    [Range(0.2f,3.0f)]
    public float blurSpead = 0.6f;

    [Range(1, 8)]
    public int downSimple = 3;

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if(material != null){
            int tempW = source.width / downSimple;
            int tempH = source.height / downSimple;

            RenderTexture buffer0 = RenderTexture.GetTemporary(tempW, tempH, 0);
            Graphics.Blit(source, buffer0);

            for(int i=0;i< iterations; i++)
            {
                material.SetFloat("_BlurSize", 1.0f + i * blurSpead);
                RenderTexture buffer1 = RenderTexture.GetTemporary(tempW, tempH, 0);
                Graphics.Blit(buffer0, buffer1, material, 0);
                RenderTexture.ReleaseTemporary(buffer0);
                buffer0 = buffer1;
                buffer1 = RenderTexture.GetTemporary(tempW, tempH, 0);
                Graphics.Blit(buffer0, buffer1, material, 1);
                RenderTexture.ReleaseTemporary(buffer0);
                buffer0 = buffer1;
            }

            Graphics.Blit(buffer0, destination);
            RenderTexture.ReleaseTemporary(buffer0);
        }
        else
        {
            Graphics.Blit(source, destination);
        }
        
    }
}
