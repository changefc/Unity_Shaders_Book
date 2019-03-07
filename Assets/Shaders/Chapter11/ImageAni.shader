Shader "Unity Shaders Book/Chapter 11/ImageAni"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Hor ("Hor", Float) = 8
		_Ver ("Ver", Float) = 8
		_Speed ("Speed", Float) = 30
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _Hor;
			float _Ver;
			float _Speed;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				float time = floor(_Time.y * _Speed);
				float row = floor(time/_Hor);
				float column = time - row*_Hor;	
				
				half2 uv = i.uv + half2(column,-row);
				uv.x /= _Hor;
				uv.y /= _Ver;
				
				fixed4 col = tex2D(_MainTex, uv);
				return col;
			}
			ENDCG
		}
	}
}
