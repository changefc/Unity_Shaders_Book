// Upgrade NOTE: replaced 'UNITY_INSTANCE_ID' with 'UNITY_VERTEX_INPUT_INSTANCE_ID'

//放一些便利函数,常量,以及unity函数补丁等等
//author: topameng

#ifndef __COMMON__
#define __COMMON__
#include "UnityGlobalIllumination.cginc"    

#define HALF_MAX    65504.0

#if UNITY_VERSION < 560    
    #define UNITY_SHADOW_COORDS(idx1) SHADOW_COORDS(idx1)
    #define UNITY_VERTEX_INPUT_INSTANCE_ID UNITY_VERTEX_INPUT_INSTANCE_ID
    #define UNITY_TRANSFER_SHADOW(o, uv) TRANSFER_SHADOW(o)       
#endif

#if DYNAMICLIGHTMAP_ON 
    #define DYNAMIC_LIGHTMAP_COORDS float4 texcoord2 : TEXCOORD2;
#else
    #define DYNAMIC_LIGHTMAP_COORDS
#endif

#if (SHADER_TARGET >= 30)
    #define TBN_WORLD_COORDS(idx1, idx2, idx3) float4 tangentToWorld[3] : TEXCOORD##idx1;    
    #define TBN_LIGHT_COORDS(idx1, idx2, idx3) half4 tangentToWorld[3] : TEXCOORD##idx1;
    #define TBN_VIEWDIR_COORDS(idx1, idx2, idx3) half4 tangentToWorld[3] : TEXCOORD##idx1;

    #define TRANSFER_TBN_ROTATION(o, worldTangent, worldBinormal, worldNormal) \
                o.tangentToWorld[0].xyz = worldTangent;     \
                o.tangentToWorld[1].xyz = worldBinormal;    \
                o.tangentToWorld[2].xyz = worldNormal;

    #define TRANSFER_WORLD_POS(o, worldPos)\
                o.tangentToWorld[0].w = worldPos.x;\
                o.tangentToWorld[1].w = worldPos.y;\
                o.tangentToWorld[2].w = worldPos.z;

    #define TRANSFER_LIGHT_DIR(o, lightDir)\
                o.tangentToWorld[0].w = lightDir.x;\
                o.tangentToWorld[1].w = lightDir.y;\
                o.tangentToWorld[2].w = lightDir.z;

    #define TRANSFER_VIEW_DIR(o, viewDir)\
                o.tangentToWorld[0].w = viewDir.x;\
                o.tangentToWorld[1].w = viewDir.y;\
                o.tangentToWorld[2].w = viewDir.z;                


    #define UNPACK_WORLD_NORMAL(_BumpMap, uv, i) PerPixelWorldNormal(_BumpMap, uv, i.tangentToWorld[0], i.tangentToWorld[1], i.tangentToWorld[2]); 
    #define UNITY_WORLD_POS(i) UnPackWorldPos(i.tangentToWorld[0], i.tangentToWorld[1], i.tangentToWorld[2]);         
    #define UNITY_WORLD_TANGENT(i) i.tangentToWorld[0].xyz;
    #define UNITY_WORLD_BINORMAL(i) i.tangentToWorld[1].xyz;
    #define UNITY_WORLD_NORMAL(i) i.tangentToWorld[2].xyz;
    #define UNITY_WORLD_LIGHT(i) UnPackNormalizeDir(i.tangentToWorld[0], i.tangentToWorld[1], i.tangentToWorld[2]);
    #define UNITY_WORLD_VIEWDIR(i) UnPackNormalizeDir(i.tangentToWorld[0], i.tangentToWorld[1], i.tangentToWorld[2]);
#else
    #define TBN_WORLD_COORDS(idx1, idx2, idx3)\
                float4 tangentToWorld0 : TEXCOORD##idx1;\
                float4 tangentToWorld1 : TEXCOORD##idx2;\
                float4 tangentToWorld2 : TEXCOORD##idx3; 

    #define TBN_LIGHT_COORDS(idx1, idx2, idx3)\
                half4 tangentToWorld0 : TEXCOORD##idx1;\
                half4 tangentToWorld1 : TEXCOORD##idx2;\
                half4 tangentToWorld2 : TEXCOORD##idx3; 

    #define TBN_VIEWDIR_COORDS(idx1, idx2, idx3)\
                half4 tangentToWorld0 : TEXCOORD##idx1;\
                half4 tangentToWorld1 : TEXCOORD##idx2;\
                half4 tangentToWorld2 : TEXCOORD##idx3;                             

    #define TRANSFER_TBN_ROTATION(o, worldTangent, worldBinormal, worldNormal)\
                o.tangentToWorld0.xyz = worldTangent;\
                o.tangentToWorld1.xyz = worldBinormal;\
                o.tangentToWorld2.xyz = worldNormal;

   #define TRANSFER_WORLD_POS(o, worldPos)\
                o.tangentToWorld0.w = worldPos.x;\
                o.tangentToWorld1.w = worldPos.y;\
                o.tangentToWorld2.w = worldPos.z;    

   #define TRANSFER_LIGHT_DIR(o, lightDir)\
                o.tangentToWorld0.w = lightDir.x;\
                o.tangentToWorld1.w = lightDir.y;\
                o.tangentToWorld2.w = lightDir.z;       

   #define TRANSFER_VIEW_DIR(o, viewDir)\
                o.tangentToWorld0.w = viewDir.x;\
                o.tangentToWorld1.w = viewDir.y;\
                o.tangentToWorld2.w = viewDir.z;                               

    #define UNPACK_WORLD_NORMAL(_BumpMap, uv, i) PerPixelWorldNormal(_BumpMap, uv, i.tangentToWorld0, i.tangentToWorld1, i.tangentToWorld2);
    #define UNITY_WORLD_POS(i) UnPackWorldPos(i.tangentToWorld0, i.tangentToWorld1, i.tangentToWorld2);                                    
    #define UNITY_WORLD_TANGENT(i) i.tangentToWorld0.xyz;
    #define UNITY_WORLD_BINORMAL(i) i.tangentToWorld1.xyz;
    #define UNITY_WORLD_NORMAL(i) i.tangentToWorld2.xyz;
    #define UNITY_WORLD_LIGHT(i) UnPackNormalizeDir(i.tangentToWorld0, i.tangentToWorld1, i.tangentToWorld2);                                    
    #define UNITY_WORLD_VIEWDIR(i) UnPackNormalizeDir(i.tangentToWorld0, i.tangentToWorld1, i.tangentToWorld2);
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

//从TBN顶点数据提出worldPos
inline float3 UnPackWorldPos(float4 T, float4 B, float4 N)
{
    return float3(T.w, B.w, N.w);   
}

//从TBN顶点数据提出Dir数据
inline half3 UnPackNormalizeDir(half4 T, half4 B, half4 N)
{
    return normalize(half3(T.w, B.w, N.w));   
}

//mobile不支持half4[] 到 float4[] 转换
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

//修正mobile linear下，lightmap值过低问题
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

//修正烘培后GI环境光丢失问题
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

#if UNITY_SHOULD_SAMPLE_SH    
    o_gi.indirect.diffuse = ShadeSHPerPixel(normalWorld, data.ambient, data.worldPos);    
#endif

#if defined(LIGHTMAP_ON)        
    half4 bakedColorTex = UNITY_SAMPLE_TEX2D(unity_Lightmap, data.lightmapUV.xy);
    half3 bakedColor = DecodeLightmapEx(bakedColorTex, unity_Lightmap_HDR);

    #ifdef DIRLIGHTMAP_COMBINED
        fixed4 bakedDirTex = UNITY_SAMPLE_TEX2D_SAMPLER (unity_LightmapInd, unity_Lightmap, data.lightmapUV.xy);
        o_gi.indirect.diffuse += DecodeDirectionalLightmap (bakedColor, bakedDirTex, normalWorld);

        #if defined(LIGHTMAP_SHADOW_MIXING) && !defined(SHADOWS_SHADOWMASK) && defined(SHADOWS_SCREEN)
            ResetUnityLight(o_gi.light);
            o_gi.indirect.diffuse = SubtractMainLightWithRealtimeAttenuationFromLightmap (o_gi.indirect.diffuse, data.atten, bakedColorTex, normalWorld);
        #endif

    #else
        o_gi.indirect.diffuse += bakedColor;

        #if defined(LIGHTMAP_SHADOW_MIXING) && !defined(SHADOWS_SHADOWMASK) && defined(SHADOWS_SCREEN)
            ResetUnityLight(o_gi.light);
            o_gi.indirect.diffuse = SubtractMainLightWithRealtimeAttenuationFromLightmap(o_gi.indirect.diffuse, data.atten, bakedColorTex, normalWorld);
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

half3 Unity_GlossyEnvironment (UNITY_ARGS_TEXCUBE(tex), half4 hdr, half roughness, half3 reflUVW)
{               
    half perceptualRoughness = roughness * (1.7 - 0.7 * roughness);         
    half mip = perceptualRoughness * UNITY_SPECCUBE_LOD_STEPS;              
    half4 rgbm = UNITY_SAMPLE_TEXCUBE_LOD(tex, reflUVW, mip);
    return DecodeHDR(rgbm, hdr);
}

inline half3 LightingBlinnPhong(half3 albedo, half3 specColor, half3 normal, half3 viewDir, half shininess, UnityLight light)
{
    half3 h = Unity_SafeNormalize(light.dir + viewDir);
    half diff = saturate(dot(normal, light.dir));

    half nh = saturate(dot (normal, h));
    half spec = pow(nh, shininess * 128.0);
                
    half3 color = (albedo * diff +  specColor * spec) * light.color;    
    return color;
}

// [ Lazarov 2013, "Getting More Physical in Call of Duty: Black Ops II" ]
// Adaptation to fit our G term.
half3 EnvBRDFApprox(half3 specColor, half roughness, half nv)
{    
    const half4 c0 = { -1, -0.0275, -0.572, 0.022 };
    const half4 c1 = { 1, 0.0425, 1.04, -0.04 };
    half4 r = roughness * c0 + c1;
    half a004 = min( r.x * r.x, exp2( -9.28 * nv ) ) * r.x + r.y;
    half2 AB = half2( -1.04, 1.04 ) * a004 + r.zw;

    return specColor * AB.x + AB.y;
}

// Same as EnvBRDFApprox( 0.04, Roughness, NoV )    
half EnvBRDFApproxNonmetal(half roughness, half nv) 
{               
    const half2 c0 = { -1, -0.0275 }; 
    const half2 c1 = { 1, 0.0425 }; 
    half2 r = roughness * c0 + c1; 
    return min( r.x * r.x, exp2( -9.28 * nv ) ) * r.x + r.y; 
}

half3 Unity_BRDF_PBS(half3 diffColor, half3 specColor, half oneMinusReflectivity, half roughness, half3 normal, half3 viewDir, UnityLight light, UnityIndirect gi)
{            
    half3 halfDir = Unity_SafeNormalize (light.dir + viewDir);

    half nv = saturate(dot(normal, viewDir));    
    half nl = saturate(dot(normal, light.dir));
    half nh = saturate(dot(normal, halfDir));               
    half lh = saturate(dot(light.dir, halfDir));

    //D
    half a = roughness * roughness;          
    half a2 = a * a;
    half d = nh * nh * (a2 - 1.h) + 1.00001h;       

    //D * V * F
#ifdef UNITY_COLORSPACE_GAMMA
    half specular = a / (max(0.32h, lh) * (1.5h + a) * d);                  
#else
    half specular = a2 / (max(0.1h, lh*lh) * (a + 0.5h) * (d * d) * 4);
#endif                                               

#if defined (SHADER_API_MOBILE)
    specular = specular - 1e-4h;
    specular = clamp(specular, 0.0, 100.0);     // Prevent FP16 overflow on mobiles
#endif

#if 1
    #ifdef UNITY_COLORSPACE_GAMMA               
        half surfaceReduction = 0.28;   
    #else               
        half surfaceReduction = (0.6 - 0.08 * roughness);
    #endif
      
    // surfaceReduction = Int D(NdotH) * NdotH * Id(NdotL>0) dH = 1/(realRoughness^2+1)
    // Gamma: 1-0.28*x^3 as approximation for (1/(x^4+1))^(1/2.2) on the domain [0;1] 
    // Linear: 1-x^3*(0.6-0.08*x)   approximation for 1/(x^4+1)             
    surfaceReduction = 1.0 - a * roughness * surfaceReduction;
    half grazingTerm = saturate(1 - roughness + (1 - oneMinusReflectivity)); //F90    

    half3 color = (diffColor + specular * specColor) * light.color * nl + gi.diffuse * diffColor        
        + surfaceReduction * gi.specular * FresnelLerpFast(specColor, grazingTerm, nv);     
#else
    half F = EnvBRDFApprox(specColor, a, nv);
    half3 color = (diffColor + specular * specColor) * light.color * nl + gi.diffuse * diffColor + F * gi.specular;  
#endif
    
    return color;
}

half3 Unity_BRDF_PBS(half3 diffColor, half3 specColor, half roughness, half3 normal, half3 viewDir, half3 lightDir, half atten)
{        
    half3 halfDir = Unity_SafeNormalize (lightDir + viewDir);

    half nv = saturate(dot(normal, viewDir));    
    half nl = saturate(dot(normal, lightDir));
    half nh = saturate(dot(normal, halfDir));               
    half lh = saturate(dot(lightDir, halfDir));
          
    //D     
    half a = roughness * roughness;                                                 
    half a2 = a * a;
    half d = nh * nh * (a2 - 1.h) + 1.00001h;   

    //D * V * F
#ifdef UNITY_COLORSPACE_GAMMA
    half specular = a / (max(0.32h, lh) * (1.5h + a) * d);                  
#else
    half specular = a2 / (max(0.1h, lh * lh) * (a + 0.5h) * (d * d) * 4);
#endif      

#if defined (SHADER_API_MOBILE)
    specular = specular - 1e-4h;
    specular = clamp(specular, 0.0, 100.0);
#endif                             

    half3 color = (diffColor + specular * specColor) * _LightColor0.rgb * (atten * nl);   
    return color;
}

// [Schlick 1994, "An Inexpensive BRDF Model for Physically-Based Rendering"]
half3 F_Schlick(half3 F0, float lh)
{
    half t = Pow5(1.0h - lh);                 // 1 sub, 3 mul
    return F0 + (1 - F0) * t;     // 1 add, 3 mad    
}

float Vis_SmithJointApprox( float roughness, float nv, float nl )
{
    float a = roughness * roughness;
    float Vis_SmithV = nl * ( nv * ( 1 - a ) + a );
    float Vis_SmithL = nv * ( nl * ( 1 - a ) + a );
    // Note: will generate NaNs with roughness = 0.  MinRoughness is used to prevent this
    return 0.5 / ( Vis_SmithV + Vis_SmithL + 1e-5f);
}

// GGX / Trowbridge-Reitz
// [Walter et al. 2007, "Microfacet models for refraction through rough surfaces"]
half D_GGX( half roughness, half nh )
{
    float a = roughness * roughness;
    float a2 = a * a;
    float d = (nh * a2 - nh) * nh + 1.00001h; // 2 mad
    return a2 / (d * d * 4);                 // 4 mul, 1 rcp
}

// Anisotropic GGX
// [Burley 2012, "Physically-Based Shading at Disney"]
/*float D_GGXaniso( float RoughnessX, float RoughnessY, float NoH, float3 H, float3 X, float3 Y )
{
    float ax = RoughnessX * RoughnessX;
    float ay = RoughnessY * RoughnessY;
    float XoH = dot( X, H );
    float YoH = dot( Y, H );
    float d = XoH*XoH / (ax*ax) + YoH*YoH / (ay*ay) + NoH*NoH;
    return 1 / ( 4 * ax*ay * d*d );
}*/

float G1V(float dotNV, float k)
{
    return 1.0f/(dotNV*(1.0f-k)+k);
}

float LightingFuncGGX_REF(float3 N, float3 V, float3 L, float roughness, float F0)
{
    float alpha = roughness*roughness;

    float3 H = normalize(V+L);

    float dotNL = saturate(dot(N,L));
    float dotNV = saturate(dot(N,V));
    float dotNH = saturate(dot(N,H));
    float dotLH = saturate(dot(L,H));

    float F, D, vis;

    // D
    float alphaSqr = alpha*alpha;
    float pi = 3.14159f;
    float denom = dotNH * dotNH *(alphaSqr-1.0) + 1.0f;
    D = alphaSqr/(pi * denom * denom);

    // F
    float dotLH5 = pow(1.0f-dotLH,5);
    F = F0 + (1.0-F0)*(dotLH5);

    // V
    float k = alpha/2.0f;
    vis = G1V(dotNL,k)*G1V(dotNV,k);

    float specular = dotNL * D * F * vis;
    return specular;
}

float LightingFuncGGX_OPT1(float3 N, float3 V, float3 L, float roughness, float F0)
{
    float alpha = roughness*roughness;

    float3 H = normalize(V+L);

    float dotNL = saturate(dot(N,L));
    float dotLH = saturate(dot(L,H));
    float dotNH = saturate(dot(N,H));

    float F, D, vis;

    // D
    float alphaSqr = alpha*alpha;
    float pi = 3.14159f;
    float denom = dotNH * dotNH *(alphaSqr-1.0) + 1.0f;
    D = alphaSqr/(pi * denom * denom);

    // F
    float dotLH5 = pow(1.0f-dotLH,5);
    F = F0 + (1.0-F0)*(dotLH5);

    // V
    float k = alpha/2.0f;
    vis = G1V(dotLH,k)*G1V(dotLH,k);

    float specular = dotNL * D * F * vis;
    return specular;
}


float LightingFuncGGX_OPT2(float3 N, float3 V, float3 L, float roughness, float F0)
{
    float alpha = roughness*roughness;

    float3 H = normalize(V+L);

    float dotNL = saturate(dot(N,L));
    float dotLH = saturate(dot(L,H));
    float dotNH = saturate(dot(N,H));

    float F, D, vis;

    // D
    float alphaSqr = alpha*alpha;
    float pi = 3.14159f;
    float denom = dotNH * dotNH *(alphaSqr-1.0) + 1.0f;
    D = alphaSqr/(pi * denom * denom);

    // F
    float dotLH5 = pow(1.0f-dotLH,5);
    F = F0 + (1.0-F0)*(dotLH5);

    // V
    float k = alpha/2.0f;
    float k2 = k*k;
    float invK2 = 1.0f-k2;
    vis = 1 / (dotLH*dotLH*invK2 + k2);

    float specular = dotNL * D * F * vis;
    return specular;
}

float2 LightingFuncGGX_FV(float dotLH, float roughness)
{
    float alpha = roughness*roughness;

    // F
    float F_a, F_b;
    float dotLH5 = pow(1.0f-dotLH,5);
    F_a = 1.0f;
    F_b = dotLH5;

    // V
    float vis;
    float k = alpha/2.0f;
    float k2 = k*k;
    float invK2 = 1.0f-k2;
    vis = 1 / (dotLH*dotLH*invK2 + k2);

    return float2(F_a*vis,F_b*vis);
}

float LightingFuncGGX_D(float dotNH, float roughness)
{
    float alpha = roughness*roughness;
    float alphaSqr = alpha*alpha;
    float pi = 3.14159f;
    float denom = dotNH * dotNH *(alphaSqr-1.0) + 1.0f;

    float D = alphaSqr/(pi * denom * denom);
    return D;
}

float LightingFuncGGX_OPT3(float3 N, float3 V, float3 L, float roughness, float F0)
{
    float3 H = normalize(V+L);

    float dotNL = saturate(dot(N,L));
    float dotLH = saturate(dot(L,H));
    float dotNH = saturate(dot(N,H));

    float D = LightingFuncGGX_D(dotNH,roughness);
    float2 FV_helper = LightingFuncGGX_FV(dotLH,roughness);
    float FV = F0*FV_helper.x + (1.0f-F0)*FV_helper.y;
    float specular = dotNL * D * FV;

    return specular;
}

#endif