Shader "Custom/BlinnPhong"
{
   Properties
    {
        _MainTex("Texture",2D) = "white"{}
        _BaseColor("Base Color",Color) = (1,1,1,1)
        _AmbientColor("Ambient Color",Color) = (0.2,0.2,0.2,1)//环境光（防止背面死黑）

        _ShadowColor("Shadow Color",Color) = (0.3,0.3,0.5,1)
        _ShadowThreshold("Shadow Threshold",Range(0,1)) = 0.3//阴影的边界位置
        _ShadowSmoothness("Shadow Smoothness",Range(0.001,0.1)) = 0.01

        _OutLineColor("Outline Color",Color) = (0,0,0,1)//描边颜色
        _OutLineWidth("Outline Width",Range(0,0.1)) = 0.01//描边粗细

        _SpecColor("Spec Color",Color) = (1,1,1,1)
        _SpecSize("Spec Size",Range(0,1)) = 0.5
        _SpecSmoothness("Spec Smoothness",Range(0.001,0.1)) = 0.01
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
                float3 viewDirWS : TEXCOORD2;
            };

            // --- 同步面板数据 ---
            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                half4 _BaseColor;
                half4 _AmbientColor;
                half4 _ShadowColor;
                float _ShadowThreshold;
                float _ShadowSmoothness;
                half4 _OutLineColor;
                float _OutLineWidth;
                half4 _SpecColor;
                float _SpecSize;
                float _SpecSmoothness;

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

                float3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.viewDirWS = GetWorldSpaceViewDir(positionWS);
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

                half3 viewDir = normalize(IN.viewDirWS);
                half3 halfDir = normalize(mainLight.direction + viewDir);
                half NdotH = saturate(dot(normal,halfDir));

                half specRamp = smoothstep(_SpecSize - _SpecSmoothness,_SpecSize + _SpecSmoothness, NdotH);

                specRamp *= toonRamp;
                half3 specRGB = _SpecColor.rgb * specRamp;

                half3 baseRGB =texColor.rgb * _BaseColor.rgb;
                half3 shadowRGB = baseRGB * _ShadowColor.rgb;
                half3 finalRGB = lerp(shadowRGB,baseRGB * mainLight.color,toonRamp);
                finalRGB += specRGB;
                finalRGB += baseRGB *  _AmbientColor.rgb * 0.2;

                return half4(finalRGB,texColor.a);
            }
            ENDHLSL
        }

        //法线外扩
        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
            //只渲染背面
            Cull Front

            //把描边往远处推一点，防止和原本的模型发生“Z轴冲突”
            ZWrite On
            Offset 1,1

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                half4 _BaseColor;
                half4 _AmbientColor;
                half4 _ShadowColor;
                float _ShadowThreshold;
                float _ShadowSmoothness;
                half4 _OutLineColor;  
                float _OutLineWidth;
                half4 _SpecColor;
                float _SpecSize;
                float _SpecSmoothness;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                float3 positionOS = IN.positionOS.xyz;
                positionOS += normalize(IN.normalOS) * _OutLineWidth;
                OUT.positionCS = TransformObjectToHClip(positionOS);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                return _OutLineColor;
            }
            ENDHLSL
        }
    }
}
