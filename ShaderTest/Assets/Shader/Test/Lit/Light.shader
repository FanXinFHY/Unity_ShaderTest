Shader "Custom/Light"
{
    Properties
    {
        _MainTex("Texture",2D) = "white"{}
        _BaseColor("Base Color",Color) = (1,1,1,1)
        _AmbientColor("Ambient Color",Color) = (0.2,0.2,0.2,1)//环境光（防止背面死黑）
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
             #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

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
                
            };

            // --- 同步面板数据 ---
            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                half4 _BaseColor;
                half4 _AmbientColor;
            CBUFFER_END

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            // --- 顶点着色器 ---
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv,_MainTex);

                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                return OUT;
            }

            // --- 片元着色器 ---
            half4 frag(Varyings IN) : SV_Target
            {
                half4 texColor = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,IN.uv);
                Light mainLight = GetMainLight();
                half3 normal = normalize(IN.normalWS);

                half NdotL = saturate(dot(normal,mainLight.direction));

                half3 lightColor = mainLight.color * NdotL;

                half3 baseRGB =texColor.rgb * _BaseColor.rgb;

                half3 finalRGB = baseRGB * (lightColor + _AmbientColor.rgb);
                return half4(finalRGB,texColor.a);
            }
            ENDHLSL
        }
    }
}