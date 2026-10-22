Shader "Custom/RimLight"
{
    Properties
    {
        _MainTex ("Texture",2D) = "white"{}
        _BaseColor ("Base Color",Color) = (1,1,1,1)
        _Speed ("Pulse Speed",Float) = 2.0
        _MinBrightness("Min Brightness",Range(0,1)) = 0.2
        _RimColor ("Rim Color",color) = (0,1,1,1)
        _RimPower ("Rim Power",Range(0.5,8.0)) = 3.0
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
                float3 normalOS : NORMAL;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float3 viewDirWS : TEXCOORD2;
            };

            // --- 同步面板数据 ---
            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            half4 _BaseColor;
            float _Speed;
            half _MinBrightness;
            half4 _RimColor;
            half _RimPower;
            CBUFFER_END

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            // --- 顶点着色器 ---
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv,_MainTex);

                float3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                OUT.viewDirWS = GetWorldSpaceViewDir(positionWS);
                return OUT;
            }

            // --- 片元着色器 ---
            half4 frag(Varyings IN) : SV_Target
            {
                float wave = sin(_Time.y * _Speed);
                float pulse = (wave + 1) * 0.5;
                float finalBrightness = lerp(_MinBrightness,1.0,pulse);

                half4 texColor = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,IN.uv);

                //计算边缘光
                half NdotV = dot(normalize(IN.normalWS),normalize(IN.viewDirWS));
                half rim = pow(1.0 - saturate(NdotV),_RimPower);//saturate限制在0-1
                half3 finalColor = texColor.rgb * _BaseColor.rgb * finalBrightness + (_RimColor.rgb * rim);
                return half4(finalColor,texColor.a); 
            }
            ENDHLSL
        }
    }
}