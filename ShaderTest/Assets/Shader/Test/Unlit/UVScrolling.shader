Shader "Custom/UVScrolling"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BaseColor ("Base Color", Color) = (1,1,1,1)
        _Speed ("Pulse Speed", Float) = 2.0
        _MinBrightness ("Min Brightness", Range(0, 1)) = 0.2
        _ScrollSpeed ("Scroll Speed", Float) = 1.0
    }

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            // --- 数据盒子 ---
            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0; // 规整回0号通道
            };

            // --- 同步面板数据 ---
            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            half4 _BaseColor;
            float _Speed;
            half _MinBrightness;
            float _ScrollSpeed;
            CBUFFER_END

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            // --- 顶点着色器 ---
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                
                // 【UV滚动核心代码】
                // 取模型原始 UV，给 Y 轴加上 (时间 * 滚动速度)
                float2 scrolledUV = IN.uv + float2(0, _Time.y * _ScrollSpeed);
                OUT.uv = TRANSFORM_TEX(scrolledUV, _MainTex);
                
                return OUT;
            }

            // --- 片元着色器 ---
            half4 frag(Varyings IN) : SV_Target
            {
                // 1. 呼吸灯逻辑
                float wave = sin(_Time.y * _Speed);
                float pulse = (wave + 1.0) * 0.5;
                float finalBrightness = lerp(_MinBrightness, 1.0, pulse);

                // 2. 贴图采样与颜色混合
                half4 texColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
                half4 finalColor = texColor * _BaseColor * finalBrightness;
                
                return finalColor; 
            }
            ENDHLSL
        }
    }
}