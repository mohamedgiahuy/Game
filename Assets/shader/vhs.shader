Shader "Custom/VHS_Mobile_BlackFisheye"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
        _NoiseTex ("Noise Texture", 2D) = "white" {}
        _BleedAmount ("Bleed Amount", Float) = 0.005
        _NoiseAmount ("Noise Amount", Float) = 0.05
        _FisheyeBend ("Fisheye Bend", Float) = 0.2
        _TimeSpeed ("Time Speed", Float) = 1.0

        [Header(VHS Scanlines)]
        _ScanlineCount ("Scanline Count", Range(100, 600)) = 240
        _ScanlineDark ("Scanline Darkness", Range(0, 1)) = 0.25
        _ScanlineSpeed ("Scanline Scroll Speed", Float) = 0.4
        _BandHeight ("Band Height", Range(0.01, 0.5)) = 0.08
        _BandSpeed ("Band Scroll Speed", Float) = 0.18
        _BandDark ("Band Darkness", Range(0, 1)) = 0.35

        [Header(Analog Chroma Glitch)]
        _GlitchDensity ("Glitch Density", Range(0, 0.1)) = 0.008
        _GlitchBrightness ("Glitch Brightness", Range(0, 2)) = 1.2
        _GlitchRowScale ("Row Scale", Range(10, 400)) = 300
        _GlitchLineLength ("Line Length", Range(0.01, 1.0)) = 0.08
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        Pass
        {
            ZTest Always Cull Off ZWrite Off

            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            sampler2D _NoiseTex;
            float _BleedAmount, _NoiseAmount, _FisheyeBend, _TimeSpeed;
            float _ScanlineCount, _ScanlineDark, _ScanlineSpeed;
            float _BandHeight, _BandSpeed, _BandDark;
            float _GlitchDensity, _GlitchBrightness, _GlitchRowScale, _GlitchLineLength;

            float hash(float2 p)
            {
                return frac(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
            }

            fixed4 frag(v2f_img i) : SV_Target
            {
                float2 uv = i.uv;

                // 1. Fisheye
                float2 centered = uv - 0.5;
                float len = length(centered);
                uv = 0.5 + centered * (1.0 + _FisheyeBend * len * len);

                if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0)
                    return fixed4(0, 0, 0, 1);

                // 2. Chromatic Bleed
                fixed r = tex2D(_MainTex, uv + float2(_BleedAmount, 0)).r;
                fixed g = tex2D(_MainTex, uv).g;
                fixed b = tex2D(_MainTex, uv - float2(_BleedAmount, 0)).b;
                fixed4 col = fixed4(r, g, b, 1.0);

                // 3. Noise
                float n = tex2D(_NoiseTex, uv * 0.25 + _Time.y * _TimeSpeed).r;
                col.rgb += (n - 0.5) * _NoiseAmount;

                // 4. Scanlines
                float scanY = uv.y * _ScanlineCount + _Time.y * _ScanlineSpeed;
                float scanline = pow(sin(scanY * 3.14159) * 0.5 + 0.5, 1.5);
                col.rgb *= lerp(1.0 - _ScanlineDark, 1.0, scanline);

                // 5. Tracking Band
                float bandY = frac(uv.y - _Time.y * _BandSpeed);
                float band = smoothstep(0.0, _BandHeight * 0.5, bandY)
                           * smoothstep(_BandHeight, _BandHeight * 0.5, bandY);
                col.rgb *= 1.0 - band * _BandDark;

                // 6. Chroma Glitch lines
                float row = floor(uv.y * _GlitchRowScale);
                float timeSeed = floor(_Time.y * 3.0);
                float rowSeed = hash(float2(row * 0.017, timeSeed));
                float rowRand = hash(float2(rowSeed, timeSeed + row));

                if (rowRand < _GlitchDensity)
                {
                    float startX = hash(float2(row + 0.1, timeSeed));
                    float endX = startX + _GlitchLineLength
                               * (0.3 + hash(float2(row + 0.9, timeSeed)) * 0.4);
                    endX = min(endX, 1.0);

                    if (uv.x >= startX && uv.x <= endX)
                    {
                        float cr = hash(float2(row + 0.5, timeSeed));
                        float cg = hash(float2(row + 1.5, timeSeed));
                        float cb = hash(float2(row + 2.5, timeSeed));

                        float fadeW = (endX - startX) * 0.08;
                        float fadeL = smoothstep(startX, startX + fadeW, uv.x);
                        float fadeR = smoothstep(endX, endX - fadeW, uv.x);
                        float fade = fadeL * fadeR;

                        col.rgb = lerp(col.rgb,
                                       fixed3(cr, cg, cb) * _GlitchBrightness,
                                       fade * 0.85);
                    }
                }

                return col;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}