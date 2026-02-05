Shader "WanJian/VelLogic_StormDisperse"
{
	Properties
	{
		_PosTexture("Current Position", 2D) = "white" {}
		_TargetPos("Target Position (Local)", Vector) = (0,0,0,0)
		
		[Header(Movement Specs)]
		_MaxSpeed("Max Speed (Orbit)", Float) = 12.0
		_AttackSpeedMult("Attack Speed Multiplier", Float) = 3.0
		_TurnSpeed("Turn Speed (Agility)", Float) = 4.0
		
		[Header(Force Field Zones)]
		_RepulsionRadius("Repulsion Radius (Inner Core)", Float) = 5.0
		_OrbitRadius("Optimal Orbit Radius", Float) = 15.0
		_WanderRadius("Wander Radius (Outer Edge)", Float) = 30.0
		_RepulsionForce("Repulsion Force Scale", Float) = 2.0
		_PostPierceBoost("Post-Attack Outward Boost", Float) = 1.2
		
		[Header(Storm Behavior)]
		_Turbulence("Chaos/Noise Strength", Float) = 4.0
		_RotationAxis("Rotation Axis", Vector) = (0, 1, 0, 0)
		
		[Header(Attack Logic)]
		_AttackFreq("Attack Frequency", Float) = 0.6
		_AttackChance("Attack Probability", Range(0,1)) = 0.25
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
			float _AttackSpeedMult;
			float _TurnSpeed;
			
			float _RepulsionRadius;
			float _OrbitRadius;
			float _WanderRadius;
			float _RepulsionForce;
			float _PostPierceBoost;

			float _Turbulence;
			float3 _RotationAxis;
			
			float _AttackFreq;
			float _AttackChance;

			float hash(float2 p)
			{
				return frac(sin(dot(p, float2(12.9898, 78.233))) * 43758.5453);
			}

			float3 noise3D(float3 p)
			{
				float3 i = floor(p);
				float3 f = frac(p);
				f = f * f * (3.0 - 2.0 * f);
				float n = dot(i, float3(1.0, 57.0, 113.0));
				return float3(
					frac(sin(n) * 43758.5),
					frac(sin(n + 1.0) * 43758.5),
					frac(sin(n + 2.0) * 43758.5)
				) * 2.0 - 1.0;
			}

			float4 frag(v2f_customrendertexture IN) : SV_Target
			{
				// 1. 基础数据
				float2 uv = IN.localTexcoord.xy;
				float3 currentVel = tex2D(_SelfTexture2D, uv).rgb;
				float3 currentPos = tex2D(_PosTexture, uv).rgb;
				float deltaTime = unity_DeltaTime.x;
				float seed = hash(uv * 1024.0); 

				float3 toTarget = _TargetPos.xyz - currentPos;
				float dist = length(toTarget);
				float3 dirToTarget = dist > 0.001 ? toTarget / dist : float3(1,0,0);

				// =================================================
				// 核心逻辑: 多层力场
				// =================================================

				// --- A. 环绕力 (Orbit Force) ---
				
				// 1. 切向力 (Tangent Force): 产生旋转
				float3 upAxis = normalize(_RotationAxis + noise3D(currentPos * 0.05) * 0.2);
				float3 tangentForce = normalize(cross(dirToTarget, upAxis));
				
				// 2. 径向力 (Radial Force): 维持距离
				//    - 在排斥区内，强力向外推
				//    - 在漫游区外，强力向内拉
				//    - 在环绕区附近，力度最弱，形成稳定轨道
				float repulsion = (1.0 - smoothstep(_RepulsionRadius * 0.7, _RepulsionRadius, dist)) * _RepulsionForce;
				float attraction = smoothstep(_OrbitRadius, _WanderRadius, dist);
				float3 radialForce = dirToTarget * (attraction - repulsion);
				
				// 3. 湍流力 (Turbulence): 增加混乱感
				float3 chaosForce = noise3D(currentPos * 0.1 + _Time.y) * _Turbulence;
				
				// 组合成最终的环绕期望速度
				float3 orbitDesiredVel = normalize(tangentForce + radialForce + chaosForce) * _MaxSpeed;

				// --- B. 穿刺力 (Pierce Force) ---
				
				// 攻击相位控制
				float cycle = sin(_Time.y * _AttackFreq + seed * 6.2831);
				float attackThreshold = 1.0 - (_AttackChance * 2.0);
				float attackWeight = smoothstep(attackThreshold, 1.0, cycle);

				// 攻击时的期望速度
				float pierceSpeed = _MaxSpeed * _AttackSpeedMult;
				float3 attackDesiredVel = dirToTarget * pierceSpeed;

				// --- C. 穿刺后爆发力 (Post-Pierce Boost) ---
				float3 postPierceVel = float3(0,0,0);
				// 条件：攻击权重正在下降（攻击结束） 且 正在远离目标（已经穿过去了）
				// 使用 ddx/ddy 可以检测相邻像素的 cycle 值，判断是上升还是下降，但为了简单，我们用一个旧值来判断
				float prev_cycle = sin((_Time.y - deltaTime) * _AttackFreq + seed * 6.2831);
				bool isAttackFading = cycle < prev_cycle;
				bool isMovingAway = dot(currentVel, dirToTarget) < 0; // 速度方向和指向目标方向相反

				if (isAttackFading && isMovingAway && attackWeight > 0.1)
				{
					// 给一个远离中心方向的额外推力
					postPierceVel = -dirToTarget * pierceSpeed * _PostPierceBoost * attackWeight;
				}

				// =================================================
				// 融合与物理更新
				// =================================================

				// 最终期望速度：在 环绕 和 穿刺 之间插值
				float3 desiredVel = lerp(orbitDesiredVel, attackDesiredVel, attackWeight);

				// 转向力
				float3 steering = desiredVel - currentVel;
				float3 newVel = currentVel + steering * _TurnSpeed * deltaTime;
				
				// 叠加上穿刺后的爆发速度
				newVel += postPierceVel * deltaTime;

				// 速度限制
				float currentMaxSpeed = lerp(_MaxSpeed, pierceSpeed, attackWeight);
				float speed = length(newVel);
				if (speed > currentMaxSpeed)
				{
					newVel = newVel / speed * currentMaxSpeed;
				}

				// 防止完全停止
				if (speed < 0.1)
				{
					newVel = normalize(float3(seed, hash(uv+0.1), hash(uv-0.1)) - 0.5) * _MaxSpeed * 0.5;
				}
				
				return float4(newVel, 1.0);
			}
			ENDCG
		}
	}
}