// Upgrade NOTE: replaced 'UNITY_INSTANCE_ID' with 'UNITY_VERTEX_INPUT_INSTANCE_ID'

//放一些便利函数,常量,以及unity函数补丁等等
//author: topameng

#ifndef __COMMON__
#define __COMMON__
#include "UnityGlobalIllumination.cginc"    

#if UNITY_VERSION < 560    
    #define UNITY_SHADOW_COORDS(idx1) SHADOW_COORDS(idx1)
    #define UNITY_VERTEX_INPUT_INSTANCE_ID UNITY_VERTEX_INPUT_INSTANCE_ID
    #define UNITY_TRANSFER_SHADOW(o, uv) TRANSFER_SHADOW(o)       
#endif

#define HALF_MAX	65504.0

#if DYNAMICLIGHTMAP_ON 
    #define DYNAMIC_LIGHTMAP_COORDS float4 texcoord2 : TEXCOORD2;
#else
    #define DYNAMIC_LIGHTMAP_COORDS
#endif

#if (SHADER_TARGET >= 30)
    #define TBN_COORDS(idx1, idx2, idx3) float4 tangentToWorld[3] : TEXCOORD##idx1;    

    #define TRANSFER_TBN_ROTATION(o, worldTangent, worldBinormal, worldNormal) \
                o.tangentToWorld[0].xyz = worldTangent;     \
                o.tangentToWorld[1].xyz = worldBinormal;    \
                o.tangentToWorld[2].xyz = worldNormal

    #define TRANSFER_WORLD_POS(o, worldPos)\
                o.tangentToWorld[0].w = worldPos.x;\
                o.tangentToWorld[1].w = worldPos.y;\
                o.tangentToWorld[2].w = worldPos.z

    #define UNPACK_WORLD_NORMAL(_BumpMap, uv, i) PerPixelWorldNormal(_BumpMap, uv, i.tangentToWorld); 
    #define UNITY_WORLD_POS(i) GetWorldPos(i.tangentToWorld[0], i.tangentToWorld[1], i.tangentToWorld[2]);     
#else
    #define TBN_COORDS(idx1, idx2, idx3)\
                float4 tangentToWorld0 : TEXCOORD##idx1;\
                float4 tangentToWorld1 : TEXCOORD##idx2;\
                float4 tangentToWorld2 : TEXCOORD##idx3; 

    #define TRANSFER_TBN_ROTATION(o, worldTangent, worldBinormal, worldNormal)\
                o.tangentToWorld0.xyz = worldTangent;\
                o.tangentToWorld1.xyz = worldBinormal;\
                o.tangentToWorld2.xyz = worldNormal;

   #define TRANSFER_WORLD_POS(o, worldPos)\
                o.tangentToWorld0.w = worldPos.x;\
                o.tangentToWorld1.w = worldPos.y;\
                o.tangentToWorld2.w = worldPos.z;    

    #define UNPACK_WORLD_NORMAL(_BumpMap, uv, i) PerPixelWorldNormal(_BumpMap, uv, i.tangentToWorld0, i.tangentToWorld1, i.tangentToWorld2);
    #define UNITY_WORLD_POS(i) GetWorldPos(i.tangentToWorld0, i.tangentToWorld1, i.tangentToWorld2);
#endif

inline half Min3(half3 x) 
{ 
	return min(x.x, min(x.y, x.z)); 
}

inline half Min3(half x, half y, half z) 
{ 
	return min(x, min(y, z)); 
}

inline half Max3(half3 x) 
{
	return max(x.x, max(x.y, x.z)); 
}

inline half Max3(half x, half y, half z) 
{
	return max(x, max(y, z)); 
}

inline half  Pow2(half  x) 
{
	return x * x; 
}

inline half2 Pow2(half2 x) 
{
	return x * x; 
}

inline half3 Pow2(half3 x) 
{
	return x * x; 
}

inline half4 Pow2(half4 x)
{
	return x * x; 
}

float3 GetWorldPos(float4 T, float4 B, float4 N)
{
    return float3(T.w, B.w, N.w);   
}

half3 PerPixelWorldNormal(sampler2D bumpMap, float2 uv, float4 tangentToWorld[3])
{
    half3 tangent = tangentToWorld[0].xyz;
    half3 binormal = tangentToWorld[1].xyz;
    half3 normal = tangentToWorld[2].xyz;

    half3 normalTangent = UnpackScaleNormal(tex2D(bumpMap, uv), 1.0);    
    return normalize(tangent * normalTangent.x + binormal * normalTangent.y + normal * normalTangent.z);    
}

half3 PerPixelWorldNormal(sampler2D bumpMap, float2 uv, half3 tangent, half3 binormal, half3 normal)
{
    half3 normalTangent = UnpackScaleNormal(tex2D(bumpMap, uv), 1.0);    
    return normalize(tangent * normalTangent.x + binormal * normalTangent.y + normal * normalTangent.z);    
}

inline half3 UnpackNormalMap(half4 packednormal)
{
#if defined(UNITY_NO_DXT5nm)
    return normalize(packednormal.xyz * 2 - 1);
#else
    return UnpackNormalDXT5nm(packednormal);
#endif
}

inline half3 DecodeLightmapEx(half4 color, half4 decodeInstructions)
{
#if defined(UNITY_NO_RGBM)
    #ifdef UNITY_COLORSPACE_GAMMA    
        return 2.0 * color.rgb;
    #else
        return 4.5947938 * color.rgb;
    #endif
#else
    return DecodeLightmapRGBM(color, decodeInstructions);
#endif
}

UnityGI UnityGlobalIlluminationEx(UnityGIInput data, half occlusion, half3 normalWorld)
{
    UnityGI o_gi;
    ResetUnityGI(o_gi);

    // Base pass with Lightmap support is responsible for handling ShadowMask / blending here for performance reason
    #if defined(HANDLE_SHADOWS_BLENDING_IN_GI)
        half bakedAtten = UnitySampleBakedOcclusion(data.lightmapUV.xy, data.worldPos);
        float zDist = dot(_WorldSpaceCameraPos - data.worldPos, UNITY_MATRIX_V[2].xyz);
        float fadeDist = UnityComputeShadowFadeDistance(data.worldPos, zDist);
        data.atten = UnityMixRealtimeAndBakedShadows(data.atten, bakedAtten, UnityComputeShadowFade(fadeDist));
    #endif

    o_gi.light = data.light;
    o_gi.light.color *= data.atten;    
    o_gi.indirect.diffuse = ShadeSHPerPixel(normalWorld, data.ambient, data.worldPos);    

    #if defined(LIGHTMAP_ON)        
        half4 bakedColorTex = UNITY_SAMPLE_TEX2D(unity_Lightmap, data.lightmapUV.xy);
        half3 bakedColor = DecodeLightmapEx(bakedColorTex, unity_Lightmap_HDR);

        #ifdef DIRLIGHTMAP_COMBINED
            fixed4 bakedDirTex = UNITY_SAMPLE_TEX2D_SAMPLER (unity_LightmapInd, unity_Lightmap, data.lightmapUV.xy);
            o_gi.indirect.diffuse += DecodeDirectionalLightmap (bakedColor, bakedDirTex, normalWorld);

            #if defined(LIGHTMAP_SHADOW_MIXING) && !defined(SHADOWS_SHADOWMASK) && defined(SHADOWS_SCREEN)
                ResetUnityLight(o_gi.light);
                o_gi.indirect.diffuse += SubtractMainLightWithRealtimeAttenuationFromLightmap (o_gi.indirect.diffuse, data.atten, bakedColorTex, normalWorld);
            #endif

        #else
            o_gi.indirect.diffuse += bakedColor;

            #if defined(LIGHTMAP_SHADOW_MIXING) && !defined(SHADOWS_SHADOWMASK) && defined(SHADOWS_SCREEN)
                ResetUnityLight(o_gi.light);
                o_gi.indirect.diffuse += SubtractMainLightWithRealtimeAttenuationFromLightmap(o_gi.indirect.diffuse, data.atten, bakedColorTex, normalWorld);
            #endif

        #endif
    #endif

    #ifdef DYNAMICLIGHTMAP_ON        
        fixed4 realtimeColorTex = UNITY_SAMPLE_TEX2D(unity_DynamicLightmap, data.lightmapUV.zw);
        half3 realtimeColor = DecodeRealtimeLightmap (realtimeColorTex);

        #ifdef DIRLIGHTMAP_COMBINED
            half4 realtimeDirTex = UNITY_SAMPLE_TEX2D_SAMPLER(unity_DynamicDirectionality, unity_DynamicLightmap, data.lightmapUV.zw);
            o_gi.indirect.diffuse += DecodeDirectionalLightmap (realtimeColor, realtimeDirTex, normalWorld);
        #else
            o_gi.indirect.diffuse += realtimeColor;
        #endif
    #endif

    o_gi.indirect.diffuse *= occlusion;
    return o_gi;
}

#endif