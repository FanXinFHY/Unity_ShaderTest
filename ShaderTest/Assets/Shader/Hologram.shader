Shader "Custom/Hologram"
{
    Properties
    {
        _MainColor ("Hologram Color", Color) = (1, 0, 1, 1) // 【建议改成洋红/粉色】
        _RimColor ("Rim Color", Color) = (0, 1, 1, 1)       // 【建议改成青蓝色，形成对比】
        _RimPower ("Rim Power", Range(1.0, 10.0)) = 3.0
        _ScanSpeed ("Scan Speed", Float) = 2.0
        _ScanDensity ("Scan Density", Float) = 50.0
        _ScanStrength ("Scan Strength", Range(0, 1)) = 0.5
        
        // 【新增赛博朋克参数】
        _GlitchSpeed ("Glitch Speed", Float) = 10.0         // 故障发生的频率（每秒跳变几次）
        _GlitchStrength ("Glitch Strength", Range(0, 1)) = 0.5 // 故障错位的严重程度
    }

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Transparent" "Queue" = "Transparent" }
        ZWrite Off
        Blend SrcAlpha One
        Cull Off

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 normalWS   : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float3 viewDirWS  : TEXCOORD2;
            };

            CBUFFER_START(UnityPerMaterial)
                half4 _MainColor;
                half4 _RimColor;
                half _RimPower;
                float _ScanSpeed;
                float _ScanDensity;
                half _ScanStrength;
                float _GlitchSpeed;    // 新增
                half _GlitchStrength;  // 新增
            CBUFFER_END

            // 【新增函数】伪随机数生成器：根据输入给出一段固定的随机值
            // 赛博朋克的核心就是不可预测的随机感
            float random(float2 st) 
            {
                return frac(sin(dot(st.xy, float2(12.9898, 78.233))) * 43758.5453);
            }

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                VertexPositionInputs positionInputs = GetVertexPositionInputs(IN.positionOS.xyz);
                OUT.positionCS = positionInputs.positionCS;
                OUT.positionWS = positionInputs.positionWS;
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                OUT.viewDirWS = GetWorldSpaceViewDir(positionInputs.positionWS); 
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                // 1. 基础菲涅尔边缘光
                half NdotV = dot(normalize(IN.normalWS), normalize(IN.viewDirWS));
                half fresnel = pow(1.0 - saturate(NdotV), _RimPower);

                // ==========================================
                // 2. 【新增】赛博朋克故障逻辑
                // ==========================================
                // 把连续的时间切成一块一块的（离散化），乘以故障频率
                float glitchTime = floor(_Time.y * _GlitchSpeed); 
                
                // 用当前时间块生成一个 0~1 的随机数
                float glitchNoise = random(float2(glitchTime, 0.0));
                
                // 如果随机数大于 0.8（大概 20% 的概率），就触发故障（1），否则正常（0）
                float isGlitch = step(0.8, glitchNoise); 
                
                // 计算错位偏移量（-1 到 1 之间），乘以强度
                float glitchOffset = (glitchNoise - 0.5) * isGlitch * _GlitchStrength;

                // 3. 扫描线计算（受到故障偏移的影响）
                // 这里把 glitchOffset 乘了 5.0，让错位在视觉上更明显一点
                float scanLine = sin((IN.positionWS.y * _ScanDensity) - (_Time.y * _ScanSpeed) + (glitchOffset * 5.0));
                scanLine = smoothstep(0.8, 1.0, scanLine) * _ScanStrength;

                // 4. 颜色组合
                half3 finalColor = _MainColor.rgb + (_RimColor.rgb * fresnel) + (_MainColor.rgb * scanLine);
                
                // 【新增】颜色通道分离（红蓝错位）：发生故障时，红色和蓝色通道会发生偏移
                finalColor.r += isGlitch * glitchOffset * 0.5; // 红色异常增强
                finalColor.b -= isGlitch * glitchOffset * 0.5; // 蓝色异常减弱
                
                // 5. 透明度计算
                half alpha = _MainColor.a + fresnel + scanLine;
                
                // 【新增】闪断：如果发生故障，透明度瞬间变暗，产生“接触不良”的闪烁感
                alpha = lerp(alpha, alpha * 0.2, isGlitch);

                return half4(finalColor, saturate(alpha));
            }
            ENDHLSL
        }
    }
}