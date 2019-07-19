Shader "Freedom/MatCap_Spec_Player_Reflect" 
{
	Properties
	{
		_MainTex("Base (RGB) RefStrength (A)", 2D) = "white" {}
		_Color("Main Color", Color) = (1,1,1,1)
				
		_SpecularRamps("Specular Ramp (RGB)", 2D) = "white" {}
		_SpecularColor("Reflection Color", Color) = (1,1,1,0.5)
		_SpecSaturation("Specular Saturation",Range(0.0003,1)) = 0.5
	    _SpecIntensity("Specular Intensity",Range(0,1)) = 0.572

		_LightIntensity("Light Intensity", range(0, 1)) = 0.2
	}


	SubShader
	{
		Tags{"RenderType" = "Opaque"  "Queue"= "Geometry+100"}
		Fog { Mode Off }

		Pass
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }

			Cull back
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma exclude_renderers ps3 xbox360 flash xboxone ps4 psp2
			#pragma multi_compile_fwdbase
			#pragma multi_compile __ _REFLECTOFF
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma skip_variants DYNAMICLIGHTMAP_ON DIRLIGHTMAP_COMBINED LIGHTMAP_ON LIGHTMAP_SHADOW_MIXING SHADOWS_SHADOWMASK SHADOWS_SCREEN
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			#include "Common.cginc"


			sampler2D _MainTex;
			float4 _MainTex_ST;

			fixed4 _Color;

			sampler2D _SpecularRamps;						
			float4 _SpecularRamps_ST;
			fixed4 _SpecularColor;
			float _SpecSaturation;
			float _SpecIntensity;

			fixed _LightIntensity;

			struct appdata
			{
				float4 vertex		: POSITION;
				float3 normal		: NORMAL;
				float4 texcoord		: TEXCOORD0;                                     
			};

			struct v2f
			{
				float4 pos			: SV_POSITION;
				float4 pack0		: TEXCOORD0;
				float3 worldNormal	: TEXCOORD1;
				float3 worldPos		: TEXCOORD2;

			#if UNITY_SHOULD_SAMPLE_SH
				half3 sh			: TEXCOORD3;
			#endif
								
            #if !defined(_REFLECTOFF)
			    float3 worldViewDir	: TEXCOORD4;
            #endif
			};

			v2f vert(appdata v)
			{
				v2f o = (v2f)0;
				float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.pos = mul(UNITY_MATRIX_VP, worldPos);
				o.pack0.xy = TRANSFORM_TEX(v.texcoord, _MainTex);

				float3 worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldNormal = worldNormal;
				o.worldPos = worldPos;

            #ifndef _REFLECTOFF
				o.worldViewDir = normalize(UnityWorldSpaceViewDir(o.worldPos));
				o.pack0.z = max(0.0, dot(o.worldViewDir, worldNormal));
				o.pack0.w = max(0, saturate(1 - max(0.0, dot(worldNormal, o.worldViewDir))));
            #endif

			#if UNITY_SHOULD_SAMPLE_SH                                              
				#ifdef VERTEXLIGHT_ON
					o.sh = Shade4PointLights(unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
						unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
						unity_4LightAtten0, worldPos, worldNormal);
				#endif
					o.sh = ShadeSHPerVertex(worldNormal, o.sh);
			#endif        
           
					return o;
				}

				fixed4 frag(v2f i) : SV_Target
				{
					fixed4 albedo = tex2D(_MainTex, i.pack0.xy) * _Color;

					half3 worldNormal = i.worldNormal;
					float3 worldPos = i.worldPos;
				#ifndef USING_DIRECTIONAL_LIGHT
					half3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
				#else
					half3 lightDir = _WorldSpaceLightPos0.xyz;
				#endif

				#if !defined(_REFLECTOFF)
					half3 worldViewDir = i.worldViewDir;
				#endif         

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
					fixed diff = saturate(dot(worldNormal, lightDir));
					diff = 0.5 * diff + 0.5;
					c.rgb = (albedo.rgb * diff * gi.light.color * 0.5 + _LightIntensity * albedo.rgb);		

				#ifdef UNITY_LIGHT_FUNCTION_APPLY_INDIRECT
					c.rgb += albedo.rgb * gi.indirect.diffuse;
				#endif                                          

				#ifndef _REFLECTOFF
					float2 spec_uv = i.pack0.z * albedo.w * _SpecularRamps_ST.xy + _SpecularRamps_ST.zw;
					fixed3 satColor = dot(albedo.rgb, unity_ColorSpaceLuminance.rgb);
					fixed3 specProperty = lerp(satColor.rgb, albedo.rgb, _SpecSaturation) * _SpecIntensity * _SpecularColor;
					fixed3 spec = tex2D(_SpecularRamps, spec_uv).x * specProperty;
					c.rgb += spec;
				#endif

					return c;
					
				}
				ENDCG
			}
			
			UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
		}
}
