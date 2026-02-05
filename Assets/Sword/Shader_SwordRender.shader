Shader "Wanjian/Render"
{
    Properties
    {
        // 我们的“行动指令表”
        _PosTexture ("Position Texture (CRT)", 2D) = "white" {}
    }
    SubShader
    {
        // 关闭深度写入和开启混合，可以得到一些漂亮的叠加效果，但现在先保持简单
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 100
        Cull Off // 关闭背面剔除，确保我们能看到每个粒子
        ZWrite Off // 关闭深度写入
        Blend One One // 使用叠加混合

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 4.5 // tex2Dlod 需要较高的编译目标

            #include "UnityCG.cginc"

            sampler2D _PosTexture;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0; // 接收来自“士兵名册”Mesh的UV，也就是ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;

                // 核心操作：
                // 1. 使用当前顶点的 UV (ID) 去读取位置纹理 (CRT)
                // 2. 使用 tex2Dlod 而不是 tex2D，因为它可以在顶点着色器中工作
                //    lod 的 '0' 表示读取最高精度的 mipmap
                float4 posData = tex2Dlod(_PosTexture, float4(v.uv, 0, 0));

                // 3. 将模型空间的顶点位置移动到从纹理中读取到的位置
                //    因为我们的蓝图网格顶点位置都是(0,0,0)，所以相当于直接设置位置
                //    注意：posData 是在 SwordSystem 的局部坐标系下的位置
                float3 worldPos = posData.xyz;

                // 4. 将局部坐标转换为最终的裁剪空间坐标，这样摄像机才能正确渲染它
                o.vertex = UnityObjectToClipPos(worldPos);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 先给它一个简单的白色
                return fixed4(1.0, 1.0, 1.0, 0.5);
            }
            ENDCG
        }
    }
}