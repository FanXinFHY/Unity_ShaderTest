Shader "Custom/BreathingLight1"
{
    Properties
    {
        _BaseColor ("Base Color",Color) = (1,1,1,1)
        _Speed ("Pulse Speed",Float) = 2.0
        _MinBrightness("Min Brightness",Range(0,1)) = 0.2
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
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
            };

            // --- 同步面板数据 ---
            CBUFFER_START(UnityPerMaterial)
            half4 _BaseColor;
            float _Speed;
            half _MinBrightness;
            CBUFFER_END

            // --- 顶点着色器 ---
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                return OUT;
            }

            // --- 片元着色器 ---
            half4 frag(Varyings IN) : SV_Target
            {
                float wave = sin(_Time.y * _Speed);
                float pulse = (wave + 1) * 0.5;
                float finalBrightness = lerp(_MinBrightness,1.0,pulse);

                half4 finalColor = _BaseColor * finalBrightness;

                return finalColor; 
            }
            ENDHLSL
        }
    }
}