Shader "Custom/Toon"
{
    
    Properties
    {
        _MainTex("Texture",2D) = "white"{}
        _BaseColor("Base Color",Color) = (1,1,1,1)
        _AmbientColor("Ambient Color",Color) = (0.2,0.2,0.2,1)//环境光（防止背面死黑）

        _ShadowColor("Shadow Color",Color) = (0.3,0.3,0.5,1)
        _ShadowThreshold("Shadow Threshold",Range(0,1)) = 0.3//阴影的边界位置
        _ShadowSmoothness("Shadow Smoothness",Range(0.001,0.1)) = 0.01
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
                half4 _ShadowColor;
                float _ShadowThreshold;
                float _ShadowSmoothness;
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

                half toonRamp = smoothstep(_ShadowThreshold - _ShadowSmoothness,_ShadowThreshold + _ShadowSmoothness,NdotL);

                half3 lightColor = mainLight.color * toonRamp;

                half3 baseRGB =texColor.rgb * _BaseColor.rgb;

                half3 shadowRGB = baseRGB * _ShadowColor.rgb;

                half3 finalRGB = lerp(shadowRGB,baseRGB  * lightColor,toonRamp);

                finalRGB += baseRGB *  _AmbientColor.rgb * 0.2;;

                return half4(finalRGB,texColor.a);
            }
            ENDHLSL
        }
    }
}
