Shader "WanJian/VelLogic"
{
	Properties
	{
		_PosTexture("Current Position", 2D) = "white" {}
		_TargetPos("Target Position (Local)", Vector) = (0,0,0,0)
		_MaxSpeed("Max Speed", Float) = 6.0
		_TurnSpeed("Turn Speed", Float) = 12.0
		_ArriveRadius("Arrive Radius", Float) = 20.0
		_StopRadius("Stop Radius", Float) = 3.0
		_NoiseStrength("Noise Strength", Float) = 1.5
		_NoiseFreq("Noise Frequency", Float) = 1.0
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

			sampler2D _PosTexture;
			float4 _TargetPos;
			float _MaxSpeed;
			float _TurnSpeed;
			float _ArriveRadius;
			float _StopRadius;
			float _NoiseStrength;
			float _NoiseFreq;

			float hash(float2 p)
			{
				return frac(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
			}

			float4 frag(v2f_customrendertexture IN) : SV_Target
			{
				float3 currentVel = tex2D(_SelfTexture2D, IN.localTexcoord.xy).rgb;
				float3 currentPos = tex2D(_PosTexture, IN.localTexcoord.xy).rgb;
				float deltaTime = unity_DeltaTime.x;
				float3 toTarget = _TargetPos.xyz - currentPos;
				float dist = length(toTarget);
				float safeDen = max(_ArriveRadius - _StopRadius, 0.01);
				float speedScale = saturate((dist - _StopRadius) / safeDen);
				float targetSpeed = _MaxSpeed * speedScale;
				float3 desiredDir = dist > 0.01 ? toTarget / dist : float3(hash(IN.globalTexcoord.xy) - 0.5, 0.1, hash(IN.globalTexcoord.yx + 7.0) - 0.5);
				float3 tangent = cross(desiredDir, float3(0, 1, 0));
				if(length(tangent) < 0.001) tangent = cross(desiredDir, float3(1, 0, 0));
				tangent = normalize(tangent);
				float swirlSign = hash(IN.globalTexcoord.xy + 10.0) > 0.5 ? 1.0 : -1.0;
				tangent *= swirlSign;
				float3 desiredVel = desiredDir * targetSpeed;
				float2 seed = IN.globalTexcoord.xy * 100.0;
				float t = _Time.y * _NoiseFreq;
				float noiseX = sin(t + hash(seed) * 6.28) * _NoiseStrength;
				float noiseY = cos(t * 1.3 + hash(seed + 1.0) * 6.28) * _NoiseStrength * 0.5;
				float noiseZ = sin(t * 0.7 + hash(seed + 2.0) * 6.28) * _NoiseStrength;
				float3 perpNoise = float3(noiseX, noiseY, noiseZ);
				perpNoise -= desiredDir * dot(perpNoise, desiredDir);
				float noiseFade = smoothstep(_StopRadius, _ArriveRadius, dist);
				desiredVel += perpNoise * noiseFade;
				float swirl = 1.0 - speedScale;
				float swirlRand = lerp(0.05, 0.25, hash(seed + 11.0));
				float swirlWeight = swirl * 0.6;
				desiredVel += tangent * (_MaxSpeed * swirlRand * swirlWeight);
				float proxJitter = swirl;
				float3 jitterDir = normalize(float3(hash(seed + 20.0) - 0.5, 0, hash(seed + 21.0) - 0.5) + desiredDir * 0.1);
				desiredVel += jitterDir * (_MaxSpeed * 0.25 * proxJitter);
				float baseJitter = lerp(0.05, 0.12, hash(seed + 30.0));
				desiredVel += jitterDir * (_MaxSpeed * baseJitter * (1.0 - speedScale));
				float strikeBias = smoothstep(0.0, _ArriveRadius * 0.6, dist);
				float strikeChance = hash(seed + 40.0);
				if(strikeChance > 0.45)
				{
					float3 strikeDir = normalize(desiredDir + jitterDir * 0.2);
					float strikeMix = lerp(0.4, 0.85, strikeBias);
					desiredVel = lerp(desiredVel, strikeDir * _MaxSpeed, strikeMix);
				}
				float3 steering = desiredVel - currentVel;
				float3 newVel = currentVel + steering * _TurnSpeed * deltaTime;
				if(dist > 80.0)
				{
					float rndX = hash(seed) * 2.0 - 1.0;
					float rndY = hash(seed + 3.0) * 0.5;
					float rndZ = hash(seed + 5.0) * 2.0 - 1.0;
					newVel = normalize(float3(rndX, rndY, rndZ)) * _MaxSpeed * 0.5;
				}
				float speed = length(newVel);
				if(speed > _MaxSpeed)
				{
					newVel = newVel / speed * _MaxSpeed;
				}
				if(dist <= _StopRadius)
				{
					float3 awayDir = normalize(newVel + jitterDir * 0.2 + tangent * 0.2 + float3(0, 0.01, 0));
					float awayBoost = lerp(1.1, 1.6, hash(seed + 50.0));
					newVel = awayDir * (_MaxSpeed * awayBoost);
				}
				float newSpeed = length(newVel);
				float minGlide = _MaxSpeed * 0.25;
				float3 glideDir = normalize(newVel + jitterDir * 0.5 + desiredDir * 0.2 + tangent * 0.2);
				newVel = newSpeed > minGlide ? newVel : glideDir * minGlide;
				float oldAlpha = tex2D(_SelfTexture2D, IN.localTexcoord.xy).a;
				if(oldAlpha < 0.5)
				{
					float rndX = hash(seed) * 2.0 - 1.0;
					float rndY = hash(seed + 3.0) * 0.5;
					float rndZ = hash(seed + 5.0) * 2.0 - 1.0;
					newVel = normalize(float3(rndX, rndY, rndZ)) * _MaxSpeed * 0.5;
				}
				return float4(newVel, 1.0);
			}
			ENDCG
		}
	}
}