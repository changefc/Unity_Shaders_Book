//非半透明头发+scheuermann算法

Shader "topameng/Hair/Scheuermann"
{
	Properties
	{
		_Color ("Main Color", Color) = (1,1,1,1)
		_MainTex ("Texture", 2D) = "white" {}		
		_SpecularTex ("Spec Shift (G) Spec Mask (B)", 2D) = "gray" {}
		_SpecularMultiplier ("Specular Multiplier", float) = 128
		_SpecularColor ("Specular Color", Color) = (1,1,1,1)
		_SpecularMultiplier2 ("Secondary Specular Multiplier", float) = 128
		_SpecularColor2 ("Secondary Specular Color", Color) = (1,1,1,1)		
		_PrimaryShift ( "Specular Primary Shift", float) = 0
		_SecondaryShift ( "Specular Secondary Shift", float) = 0.1
	}

	SubShader
	{
		Tags { "RenderType"="Opaque"   "Queue"= "Geometry+75"}
		LOD 200
		Cull off

		CGINCLUDE
		#include "UnityCG.cginc"
		#include "Lighting.cginc"
		#include "AutoLight.cginc"
		#include "Common.cginc"

		struct appdata
		{
			float4 vertex : POSITION;
			float4 tangent : TANGENT;
		    float3 normal : NORMAL;
			float2 uv : TEXCOORD0;			    
		};

		sampler2D _MainTex;
		float4 _MainTex_ST;
		sampler2D _SpecularTex;
		float _SpecularMultiplier;
		float _SpecularMultiplier2;
		float  _PrimaryShift;
		float _SecondaryShift;
		half4 _SpecularColor;
		half4 _Color;
		half4 _SpecularColor2;

		half3 ShiftTangent ( half3 T, half3 N, float shift)
		{
			half3 shiftedT = T+ shift * N;
			return normalize( shiftedT);
		}
		
		float StrandSpecular ( half3 T, half3 V, half3 L, float exponent)
		{
			half3 H = normalize ( L + V );
			float dotTH = dot ( T, H );
			float sinTH = sqrt ( 1 - dotTH * dotTH);
			float dirAtten = smoothstep( -1, 0, dotTH );
			return dirAtten * pow(sinTH, exponent);
		}
		ENDCG

		Pass
		{
			Name "FORWARD" 
			Tags { "LightMode" = "ForwardBase" }				
			ZWrite on

			CGPROGRAM		
			//#pragma target 2.0	
			#pragma vertex vert
			#pragma fragment frag			
			//#pragma multi_compile_fog	
			#pragma multi_compile_fwdbase	

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0; 				// _MainTex
				half3 worldNormal : TEXCOORD1;
				float3 worldPos : TEXCOORD2;
				half4 worldTangent : TEXCOORD3; 	// tangent_input			
				half3 vlight : TEXCOORD4; 			// ambient/SH/vertexlights			
			    UNITY_SHADOW_COORDS(5)			    			
				//UNITY_FOG_COORDS(6)					
			};		
			
			v2f vert (appdata v)
			{				
				v2f o = (v2f)0;
				float4 worldPos = mul(unity_ObjectToWorld, v.vertex);				
				o.pos = mul(UNITY_MATRIX_VP, worldPos);				
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.worldTangent.xyz = UnityObjectToWorldDir(v.tangent.xyz);
				o.worldTangent.w = v.tangent.w * unity_WorldTransformParams.w;								
				o.worldPos = worldPos;
				o.worldNormal = UnityObjectToWorldNormal(v.normal);

				//SH/ambient and vertex lights	
			#if UNITY_SHOULD_SAMPLE_SH
				o.vlight = ShadeSH9 (float4(o.worldNormal, 1.0));				
			#else
				o.vlight = 0.0;
			#endif			
			
	        #ifdef VERTEXLIGHT_ON			            
	            o.vlight += Shade4PointLights (unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
	                unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
	                unity_4LightAtten0, o.worldPos, o.worldNormal);
	        #endif		

				TRANSFER_SHADOW(o); 
				//UNITY_TRANSFER_FOG(o, o.pos);
				return o;
			}
			
			half4 frag (v2f i) : SV_Target
			{																												
				half3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;				
				half3 specTex = tex2D(_SpecularTex, i.uv).rgb;
				half specShift = specTex.g;
				half specMask = specTex.b;	
				half3 worldNormal = i.worldNormal;				
				float3 worldPos = i.worldPos;
			#ifndef USING_DIRECTIONAL_LIGHT
				half3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
			#else
				half3 lightDir = _WorldSpaceLightPos0.xyz;
			#endif
				half3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));	

				//compute lighting & shadowing factor
				UNITY_LIGHT_ATTENUATION(atten, i, worldPos)				
				half4 c = 1;				
				c.rgb = albedo * i.vlight;				
				half NdotL = saturate(dot(worldNormal, lightDir));
		
				half shiftTex = specShift - 0.5;
				half3 T = -normalize(cross( worldNormal, i.worldTangent)) * i.worldTangent.w;				
				
				half3 t1 = ShiftTangent ( T, worldNormal, _PrimaryShift + shiftTex );
				half3 t2 = ShiftTangent ( T, worldNormal, _SecondaryShift + shiftTex );
				
				half3 diff = lerp (0.25, 1, NdotL);																
				
				half3 spec =  _SpecularColor * StrandSpecular(t1, worldViewDir, lightDir, _SpecularMultiplier);				
				spec = spec +  _SpecularColor2 * specMask * StrandSpecular ( t2, worldViewDir, lightDir, _SpecularMultiplier2) ;
								
				c.rgb += (diff * albedo + spec) * _LightColor0.rgb * NdotL * atten;								
				//UNITY_APPLY_FOG(i.fogCoord, c); 
				return c;
			}
			ENDCG
		}

		Pass 
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardAdd" }

			Blend One One
			ZWrite Off 

			CGPROGRAM			
			//#pragma target 2.0
			#pragma vertex vert
			#pragma fragment frag		
			#pragma multi_compile_fwdadd	
			//#pragma multi_compile_fog	

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0; 				// _MainTex
				half3 worldNormal : TEXCOORD1;
				float3 worldPos : TEXCOORD2;
				half4 worldTangent : TEXCOORD3; 	// tangent_input
				UNITY_LIGHTING_COORDS(4, 5)		    			
				//UNITY_FOG_COORDS(6)					
			};			

			v2f vert (appdata v)
			{				
				v2f o = (v2f)0;
				float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.pos = mul(UNITY_MATRIX_VP, worldPos);				
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.worldTangent.xyz = UnityObjectToWorldDir(v.tangent.xyz);
				o.worldTangent.w = v.tangent.w * unity_WorldTransformParams.w;								
				o.worldPos = worldPos;
				o.worldNormal = UnityObjectToWorldNormal(v.normal);

				TRANSFER_VERTEX_TO_FRAGMENT(o);
				//TRANSFER_SHADOW(o);
				//UNITY_TRANSFER_FOG(o, o.pos);
				return o;
			}

			half4 frag (v2f i) : SV_Target
			{																												
				half3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;
				//albedo = lerp(albedo.rgb, albedo.rgb * _Color.rgb, 0.5);
				half3 specTex = tex2D(_SpecularTex, i.uv).rgb;
				half specShift = specTex.g;
				half specMask = specTex.b;	
				half3 worldNormal = i.worldNormal;				
				float3 worldPos = i.worldPos;
			#ifndef USING_DIRECTIONAL_LIGHT
				half3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
			#else
				half3 lightDir = _WorldSpaceLightPos0.xyz;
			#endif
				half3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));	

				// compute lighting & shadowing factor
				UNITY_LIGHT_ATTENUATION(atten, i, worldPos)							
				half NdotL = saturate(dot(worldNormal, lightDir));
		
				half shiftTex = specShift - 0.5;
				half3 T = -normalize(cross( worldNormal, i.worldTangent)) * i.worldTangent.w;				
				
				half3 t1 = ShiftTangent ( T, worldNormal, _PrimaryShift + shiftTex );
				half3 t2 = ShiftTangent ( T, worldNormal, _SecondaryShift + shiftTex );
				
				half3 diff = lerp (0.25, 1, NdotL);													
				
				half3 spec =  _SpecularColor * StrandSpecular(t1, worldViewDir, lightDir, _SpecularMultiplier);				
				spec = spec +  _SpecularColor2 * specMask * StrandSpecular ( t2, worldViewDir, lightDir, _SpecularMultiplier2) ;
						
				half4 c = 1;		
				c.rgb = (diff * albedo + spec) * _LightColor0.rgb * NdotL * atten;							
				//UNITY_APPLY_FOG(i.fogCoord, c); 				
				return c;
			}
			ENDCG
		}

		UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
	}	
}
