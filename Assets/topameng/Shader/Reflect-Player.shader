
Shader "topameng/Reflective/Player" 
{
    Properties 
    {                
        _Color ("Main Color", Color) = (1,1,1,1)       
        _ReflectColor ("Reflection Color", Color) = (1,1,1,0.5)         
        _MainTex ("Base (RGB) RefStrength (A)", 2D) = "white" {}			     
		_MixTex ("_MixTex(RGB)", 2D) = "white" {}			
		_Cube ("Reflection Cubemap", Cube) = "_Skybox" {  }                        
        _RimColor  ("Rim Color", Color) = (0.741176,0.807831,0.874509,1)
        _RimPower  ("Rim Power", Range(0,2)) = 0.28
        _RimParam ("Rim Param", Range(0,2)) = 1.1
        _FakeDir("Fake Light Dir", Vector) = (-1.43, 2.22, 1.32, 0)
        _LightFactor("Light Factor", range(0, 0.3)) = 0.3
	}

    SubShader 
    {
        Tags{"RenderType"="Opaque"}
        //Fog { Mode Off }
				
        Pass 
        {
            Name "FORWARD"
            Tags { "LightMode" = "ForwardBase" }
            //Fog { Mode Off }
            Cull back
			Blend SrcAlpha OneMinusSrcAlpha
			
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma exclude_renderers ps3 xbox360 flash xboxone ps4 psp2
            #pragma multi_compile_fwdbase
            #pragma multi_compile __ _RIMOFF
            #pragma multi_compile __ _REFLECTOFF
            #pragma skip_variants DYNAMICLIGHTMAP_ON DIRLIGHTMAP_COMBINED LIGHTMAP_ON LIGHTMAP_SHADOW_MIXING SHADOWS_SHADOWMASK SHADOWS_SCREEN
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            #include "Common.cginc"


            sampler2D _MainTex;
			sampler2D _MixTex;
            float4 _MainTex_ST;
            samplerCUBE _Cube;        
            fixed4 _Color;
            fixed4 _ReflectColor;

            half4 _RimColor;
            fixed3 _FakeDir;
            half  _RimPower;
            half _RimParam;
			
			fixed _LightFactor;


            struct appdata
            {
                float4 vertex : POSITION;               
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0; 
                //float4 texcoord1 : TEXCOORD1;                                      
            }; 

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 pack0 : TEXCOORD0;                        
                float3 worldNormal : TEXCOORD1;
            #if UNITY_SHOULD_SAMPLE_SH
                half3 sh : TEXCOORD2;           
            #endif
                float3 worldPos : TEXCOORD3;                                
                UNITY_SHADOW_COORDS(4)
            };

            v2f vert(appdata v) 
            {
                v2f o = (v2f)0;
                float4 worldPos = mul(unity_ObjectToWorld, v.vertex); 
                o.pos = mul (UNITY_MATRIX_VP, worldPos);
                o.pack0.xy = TRANSFORM_TEX(v.texcoord, _MainTex);                                               

                float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldNormal = worldNormal;                                  
                o.worldPos = worldPos;

            #if UNITY_SHOULD_SAMPLE_SH                                              
                #ifdef VERTEXLIGHT_ON
                    o.sh = Shade4PointLights (unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
                        unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
                        unity_4LightAtten0, worldPos, worldNormal);
                #endif
                    o.sh = ShadeSHPerVertex (worldNormal, o.sh);
            #endif        
  
                //UNITY_TRANSFER_SHADOW(o,v.texcoord1.xy);            
                return o;
            }
						
            fixed4 frag (v2f i) : SV_Target 
            {  
                fixed4 albedo = tex2D(_MainTex, i.pack0.xy) * _Color;  
				fixed3 mixTex = tex2D(_MixTex,i.pack0.xy).rgb;
                half3 worldNormal  = i.worldNormal;      
                float3 worldPos = i.worldPos;    
            #ifndef USING_DIRECTIONAL_LIGHT
                half3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
            #else
                half3 lightDir = _WorldSpaceLightPos0.xyz;
            #endif
            
            #if !defined(_RIMOFF) || !defined(_REFLECTOFF)
                half3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
            #endif

            #ifndef _REFLECTOFF
                half3 worldRefl = reflect (-worldViewDir, worldNormal);
                fixed4 reflcol = texCUBE (_Cube, worldRefl);
                reflcol *= albedo.a;            
            #endif

                //UNITY_LIGHT_ATTENUATION(atten, i, worldPos)             

                // Setup lighting environment
                UnityGI gi;
                UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
                gi.light.color = _LightColor0.rgb;
                gi.light.dir = lightDir;

                UnityGIInput giInput;
                UNITY_INITIALIZE_OUTPUT(UnityGIInput, giInput);
                giInput.light = gi.light;
                giInput.worldPos = worldPos;                
                giInput.atten = 1; //atten

            #if UNITY_SHOULD_SAMPLE_SH
                giInput.ambient = i.sh;
            #endif

                gi = UnityGlobalIlluminationEx(giInput, 1.0, worldNormal);      

                fixed4 c = 1;
                fixed diff = saturate(dot (worldNormal, lightDir));
                diff = 0.5 * diff + 0.5;
                c.rgb = albedo.rgb * diff * gi.light.color * 0.5 + _LightFactor * albedo.rgb;       

            #ifndef _REFLECTOFF                             
                c.rgb += reflcol.rgb * _ReflectColor.rgb;   
            #endif

            #ifdef UNITY_LIGHT_FUNCTION_APPLY_INDIRECT
                c.rgb += albedo * gi.indirect.diffuse;
            #endif                                          

            #ifndef _RIMOFF
                half rim2 = saturate(dot(worldNormal, _FakeDir.xyz));      
				float power = dot(worldNormal , worldViewDir);				
				power = max(0.00001,power);				
                half rim = saturate(1.0 - pow(power, _RimPower));  
                c.rgb += rim * rim2 * _RimParam * _RimColor.rgb;
            #endif
				c.a = mixTex.r;
                return c;
            }
            ENDCG
        }
		
        UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }

    //FallBack "Diffuse"    
    CustomEditor "ActorRimShaderGUI"
}