Shader "Unity Shaders Book/Chapter 11/WaterAni"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Speed ("Speed",Float) = 0.5
		_Magnitude ("Distortion Magnitude", Float) = 1
 		_Frequency ("Distortion Frequency", Float) = 1
 		_InvWaveLength ("Distortion Inverse Wave Length", Float) = 10
	}
	SubShader
	{
		Tags {"Queue"="Transparent" "RenderType"="Transparent" "IgnoreProjector"="True" "DisableBatching"="True"}
		LOD 100

		Pass
		{
			ZWrite off
			Cull off
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
			float _Speed;
			float _Magnitude;
			float _Frequency;
			float _InvWaveLength;
			
			v2f vert (appdata v)
			{
				v2f o;
				float4 offsetPos = float4(0,0,0,0);

				offsetPos.x = sin(_Frequency * _Time.y + v.vertex.z * _InvWaveLength) * _Magnitude;

				o.vertex = UnityObjectToClipPos(v.vertex + offsetPos);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex) + float2(0.0,_Time.y*_Speed);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv);

				return col;
			}
			ENDCG
		}
	}
}
