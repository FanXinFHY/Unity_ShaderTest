Shader "Custom/VertexWave"
{
    Properties
    {   
        _BaseColor ("Base Color",Color) = (1,1,1,1)
        _MainTex ("Texture",2D) = "white"{}
        _NoiseTex ("Noise Texture",2D) = "white"{}
        _DissolveAmount ("Dissolve Amount",Range(0,1)) = 0.0
        _EdgeColor ("Edge Color",Color) = (1,0.5,0,1)//燃烧边缘的颜色
        _EdgeWidth("Edge Width",Range(0,0.2)) = 0.05 //燃烧边缘的厚度
        _Speed("Breathing Speed",Range(0,5)) = 0//边缘呼吸速率

        _WaveSpeed("Wave Speed",Float) = 2.0 //波浪流动的速度
        _WaveFrequency("Wave Frequency",Float) = 5.0 //波浪的密集程度
        _WaveHigh("Wave High",Float) = 0.1 //波浪的幅度
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
                float2 uv : TEXCOORD0;
            };

            // --- 同步面板数据 ---
            CBUFFER_START(UnityPerMaterial)
            half4 _BaseColor;
            float4 _MainTex_ST;
            float4 _NoiseTex_ST;
            half _DissolveAmount;
            half4 _EdgeColor;
            half _EdgeWidth;
            half _Speed;
            half _WaveSpeed;
            half _WaveFrequency;
            half _WaveHigh;
            CBUFFER_END

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_NoiseTex);
            SAMPLER(sampler_NoiseTex);
            // --- 顶点着色器 ---
            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                float3 positionOS = IN.positionOS.xyz;
                float waveOffset = sin(positionOS.x * _WaveFrequency + _Time.y * _WaveSpeed) + cos(positionOS.z * _WaveFrequency + _Time.y * _WaveSpeed);
                positionOS.y += waveOffset * _WaveHigh;

                OUT.positionCS = TransformObjectToHClip(positionOS);
                OUT.uv = TRANSFORM_TEX(IN.uv,_MainTex);
                return OUT;
            }

            // --- 片元着色器 ---
            half4 frag(Varyings IN) : SV_Target
            {
                half noise = SAMPLE_TEXTURE2D(_NoiseTex,sampler_NoiseTex,IN.uv).r;//采样噪点图
                clip(noise - _DissolveAmount);
                half edge = 1.0 - smoothstep(0.0,_EdgeWidth,noise - _DissolveAmount);

                half wave = sin(_Time.y * _Speed);
                half pulse = (wave + 1) * 0.5;
                half finalBreathing = lerp(0.2,1,pulse);
                
                half4 texColor = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,IN.uv);
                half4 finalColor = texColor * _BaseColor;
                finalColor.rgb += _EdgeColor.rgb * edge * finalBreathing;
                return finalColor; 
            }
            ENDHLSL
        }
    }
}
