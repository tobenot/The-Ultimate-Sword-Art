Shader "Wanjian/Render_SwordModel"
{
	Properties
	{
		_PosTexture ("Position Texture", 2D) = "white" {}
		_VelTexture ("Velocity Texture", 2D) = "white" {}
		_MainTex ("Sword Texture", 2D) = "white" {}
		_Color ("Color Tint", Color) = (1,1,1,1)
		_Scale ("Sword Scale", Float) = 1.0
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 4.5

			#include "UnityCG.cginc"

			sampler2D _PosTexture;
			sampler2D _VelTexture;
			sampler2D _MainTex;
			float4 _Color;
			float _Scale;

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
				float2 uv1 : TEXCOORD1;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : TEXCOORD1;
			};

			float3x3 LookRotation(float3 forward)
			{
				float3 up = float3(0, 1, 0);
				if (abs(forward.y) > 0.999) up = float3(1, 0, 0);
				float3 right = normalize(cross(up, forward));
				up = cross(forward, right);
				return float3x3(right, up, forward);
			}

			v2f vert (appdata v)
			{
				v2f o;

				float3 posData = tex2Dlod(_PosTexture, float4(v.uv, 0, 0)).rgb;
				float3 velData = tex2Dlod(_VelTexture, float4(v.uv, 0, 0)).rgb;

				float3 forward = normalize(velData + 0.0001);
				float3x3 rot = LookRotation(forward);

				float3 localPos = v.vertex.xyz * _Scale;
				float3 rotatedPos = mul(rot, localPos);
				float3 worldPos = rotatedPos + posData;

				o.pos = UnityObjectToClipPos(float4(worldPos, 1.0));
				o.uv = v.uv1;
				o.normal = mul(rot, v.normal);
				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv) * _Color;
				float ndotl = max(0, dot(normalize(i.normal), normalize(float3(1,1,1))));
				return col * (ndotl * 0.5 + 0.5);
			}
			ENDCG
		}
	}
}
