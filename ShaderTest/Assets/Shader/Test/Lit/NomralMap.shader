Shader "Custom/NomralMap"
{
    Properties
    {
        _MainTex("Texture",2D) = "white"{}
        _BaseColor("Base Color",Color) = (1,1,1,1)
        _AmbientColor("Ambient Color",Color) = (0.2,0.2,0.2,1)//环境光（防止背面死黑）

        _NormalMap("Normal Map",2D) = "bump" {}
        _NormalScale("Normal Scale",Range(0,2)) = 1.0
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
                float4 tangentOS : TANGENT;//要切线，法线贴图离不开
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float4 tangentWS : TEXCOORD2;
            };

            // --- 同步面板数据 ---
            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                half4 _BaseColor;
                half4 _AmbientColor;
                float4 _NormalMap_ST;
                half _NormalScale;
            CBUFFER_END

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_NormalMap);
            SAMPLER(sampler_NormalMap);

            // --- 顶点着色器 ---
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv,_MainTex);

                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);

                OUT.tangentWS = float4(TransformObjectToWorldDir(IN.tangentOS.xyz),IN.tangentOS.w);
                return OUT;
            }

            // --- 片元着色器 ---
            half4 frag(Varyings IN) : SV_Target
            {
                half4 texColor = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,IN.uv);

                half3 normalSample = UnpackNormalScale(SAMPLE_TEXTURE2D(_NormalMap,sampler_NormalMap,IN.uv),_NormalScale);

                half3 N = normalize(IN.normalWS);
                half3 T = normalize(IN.tangentWS.xyz);
                half3 B = cross(N,T) * IN.tangentWS.w;
                half3x3 TBN = half3x3(T,B,N);

                half3 worldNormal = normalize(mul(normalSample,TBN));

                Light mainLight = GetMainLight();
                half3 normal = normalize(worldNormal);

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
