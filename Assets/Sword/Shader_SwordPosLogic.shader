Shader "WanJian/PosLogic_V3_Robust"
{
    Properties
    {
        _SelfTexture2D ("Previous Frame", 2D) = "white" {}
        
        // 调快速度，调低高度，让你立马看到效果
        _Speed ("Fly Speed", Float) = 0.5 
        _MaxHeight ("Max Height", Float) = 20.0 
        _ResetY ("Reset Y Level", Float) = -10.0
        _Spread ("Spread Range", Float) = 30.0
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

            float _Speed;
            float _MaxHeight;
            float _ResetY;
            float _Spread;

            float random(float2 uv)
            {
                return frac(sin(dot(uv, float2(12.9898, 78.233))) * 43758.5453123);
            }

            float4 frag(v2f_customrendertexture IN) : SV_Target
            {
                // 1. 读取上一帧
                float4 oldData = tex2D(_SelfTexture2D, IN.localTexcoord.xy);
                float3 pos = oldData.rgb;
                float aliveStatus = oldData.a; // 读取 Alpha 通道

                // --- 修复核心：初始化逻辑 ---
                // 如果 Alpha 是 0 (或者非常小)，说明这是第一帧，必须初始化
                if (aliveStatus < 0.5) 
                {
                    // 强制铺开 X 和 Z
                    pos.x = (IN.globalTexcoord.x - 0.5) * _Spread * 2.0;
                    pos.z = (IN.globalTexcoord.y - 0.5) * _Spread * 2.0;
                    // 随机高度，避免瞬间全部一起重置
                    pos.y = _ResetY + random(IN.globalTexcoord.xy) * _MaxHeight;
                    
                    // 返回初始化后的数据，把 Alpha 设为 1 (标记为"已存活")
                    return float4(pos, 1.0);
                }

                // --- 正常飞行逻辑 ---
                pos.y += _Speed;

                // --- 循环重置逻辑 ---
                if(pos.y > _MaxHeight)
                {
                    pos.y = _ResetY;

                    float2 seed = IN.localTexcoord.xy + _Time.y;
                    float randX = random(seed) * 2.0 - 1.0;
                    float randZ = random(seed + 1.0) * 2.0 - 1.0;

                    pos.x = randX * _Spread;
                    pos.z = randZ * _Spread;
                }

                // 保持 Alpha 为 1
                return float4(pos, 1.0);
            }
            ENDCG
        }
    }
}