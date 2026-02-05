Shader "WanJian/PosLogic"
{
	Properties
	{
		_VelTexture ("Current Velocity", 2D) = "white" {}
	}

	SubShader
	{
		Lighting Off
		Blend One Zero
		
		Pass
		{
			CGPROGRAM
			#include "UnityCustomRenderTexture.cginc"
			#pragma vertex CustomRenderTextureVertexShader
			#pragma fragment frag
			#pragma target 3.0

			sampler2D _VelTexture;

			float4 frag(v2f_customrendertexture IN) : SV_Target
			{
				float3 oldPos = tex2D(_SelfTexture2D, IN.localTexcoord.xy).rgb;
				float3 currentVel = tex2D(_VelTexture, IN.localTexcoord.xy).rgb;
				float deltaTime = unity_DeltaTime.x;
				float3 newPos = oldPos + currentVel * deltaTime;
				if(distance(newPos, float3(0,0,0)) > 80.0)
				{
					float randomX = (IN.globalTexcoord.x - 0.5) * 20.0;
					float randomZ = (IN.globalTexcoord.y - 0.5) * 20.0;
					newPos = float3(randomX, 0, randomZ);
				}
				float oldAlpha = tex2D(_SelfTexture2D, IN.localTexcoord.xy).a;
				if(oldAlpha < 0.5)
				{
					float initialX = (IN.globalTexcoord.x - 0.5) * 20.0;
					float initialZ = (IN.globalTexcoord.y - 0.5) * 20.0;
					newPos = float3(initialX, 0, initialZ);
				}
				return float4(newPos, 1.0);
			}
			ENDCG
		}
	}
}