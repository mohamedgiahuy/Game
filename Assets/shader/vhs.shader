Shader "Custom/VHS_2000s_Realistic"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}

        [Header(Fisheye Lens)]
        _FisheyeBlend ("Fisheye Blend", Range(0, 1)) = 0.5
        _FisheyeStrength ("Fisheye Strength", Range(0, 0.5)) = 0.12
        _LensDistortion ("Lens Distortion", Range(-0.3, 0.3)) = 0.04

        [Header(CRT Curved Screen)]
        _CRTCurvature ("CRT Curvature", Range(0, 0.3)) = 0.08
        _CRTCornerRadius ("CRT Corner Radius", Range(0.01, 0.5)) = 0.12
        _CRTBorderWidth ("CRT Border Width", Range(0, 0.1)) = 0.025
        _CRTBorderDarkness ("CRT Border Darkness", Range(0, 1)) = 0.8
        _CRTCornerDarkness ("CRT Corner Darkness", Range(0, 1)) = 0.85
        _CRTMaskSoftness ("CRT Edge Softness", Range(0.001, 0.1)) = 0.015

        [Header(VHS Noise)]
        _NoiseTex ("Noise Texture", 2D) = "gray" {}
        _NoiseAmount ("Noise Amount", Range(0, 0.1)) = 0.012
        _NoiseSpeed ("Noise Speed", Range(0, 3)) = 0.5
        _AnalogNoiseAmount ("Analog Grain", Range(0, 0.15)) = 0.025

        [Header(Scanlines)]
        _ScanlineCount ("Scanline Count", Range(50, 600)) = 240
        _ScanlineStrength ("Scanline Strength", Range(0, 0.3)) = 0.06
        _ScanlineSpeed ("Scanline Speed", Range(-5, 5)) = 0.15

        [Header(Chromatic Aberration)]
        _ChromaticAmount ("Chromatic Amount", Range(0, 0.01)) = 0.0008

        [Header(Color Bleeding)]
        _ColorBleed ("Color Bleed", Range(0, 0.02)) = 0.002

        [Header(Soft Blur)]
        _BlurAmount ("Blur Amount", Range(0, 1)) = 0.03
        _BlurRadius ("Blur Radius", Range(0, 3)) = 1.0

        [Header(Tracking)]
        _TrackingStrength ("Tracking Strength", Range(0, 0.2)) = 0.01
        _TrackingHeight ("Tracking Height", Range(0.01, 0.3)) = 0.05
        _TrackingSpeed ("Tracking Speed", Range(-2, 2)) = 0.2

        [Header(Tape Jitter)]
        _JitterStrength ("Jitter Strength", Range(0, 0.01)) = 0.0003
        _JitterSpeed ("Jitter Speed", Range(1, 30)) = 12.0
        _WobbleStrength ("Wobble Strength", Range(0, 0.01)) = 0.0005

        [Header(Analog Glitch)]
        _GlitchStrength ("Glitch Strength", Range(0, 0.05)) = 0.006
        _GlitchFrequency ("Glitch Frequency", Range(0, 10)) = 1.5
        _GlitchBandHeight ("Glitch Band Height", Range(0.001, 0.2)) = 0.025

        [Header(Ghosting)]
        _GhostAmount ("Ghost Amount", Range(0, 0.2)) = 0.015
        _GhostOffset ("Ghost Offset", Range(0.0001, 0.02)) = 0.002

        [Header(Dropout)]
        _DropoutStrength ("Dropout Strength", Range(0, 1)) = 0.1
        _DropoutAmount ("Dropout Amount", Range(0, 0.1)) = 0.01

        [Header(Interlace)]
        _InterlaceAmount ("Interlace Amount", Range(0, 0.1)) = 0.01

        [Header(Head Switching)]
        _HeadSwitchStrength ("Head Switch Strength", Range(0, 1)) = 0.15
        _HeadSwitchHeight ("Head Switch Height", Range(0.001, 0.1)) = 0.02

        [Header(Vignette)]
        _VignetteStrength ("Vignette Strength", Range(0, 1)) = 0.25

        [Header(Analog Color)]
        _Exposure ("Exposure", Range(0.5, 1.5)) = 1.0
        _Contrast ("Contrast", Range(0.5, 1.5)) = 1.02
        _Saturation ("Saturation", Range(0, 2)) = 0.85
        _ColorFade ("Color Fade", Range(0, 1)) = 0.12
        _WarmTint ("Warm Tint", Color) = (1.0, 1.0, 0.98, 1)
    }

    SubShader
    {
        Cull Off
        ZWrite Off
        ZTest Always

        Pass
        {
            CGPROGRAM

            #pragma vertex vert_img
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            sampler2D _NoiseTex;
            float4 _MainTex_TexelSize;

            float _FisheyeBlend;
            float _FisheyeStrength;
            float _LensDistortion;

            float _CRTCurvature;
            float _CRTCornerRadius;
            float _CRTBorderWidth;
            float _CRTBorderDarkness;
            float _CRTCornerDarkness;
            float _CRTMaskSoftness;

            float _NoiseAmount;
            float _NoiseSpeed;
            float _AnalogNoiseAmount;

            float _ScanlineCount;
            float _ScanlineStrength;
            float _ScanlineSpeed;

            float _ChromaticAmount;
            float _ColorBleed;

            float _BlurAmount;
            float _BlurRadius;

            float _TrackingStrength;
            float _TrackingHeight;
            float _TrackingSpeed;

            float _JitterStrength;
            float _JitterSpeed;
            float _WobbleStrength;

            float _GlitchStrength;
            float _GlitchFrequency;
            float _GlitchBandHeight;

            float _GhostAmount;
            float _GhostOffset;

            float _DropoutStrength;
            float _DropoutAmount;

            float _InterlaceAmount;

            float _HeadSwitchStrength;
            float _HeadSwitchHeight;

            float _VignetteStrength;

            float _Exposure;
            float _Contrast;
            float _Saturation;
            float _ColorFade;

            float4 _WarmTint;

            float hash(float2 p)
            {
                return frac(
                    sin(dot(p, float2(127.1, 311.7)))
                    * 43758.5453123
                );
            }

            float hash1(float p)
            {
                return frac(sin(p * 127.1) * 43758.5453123);
            }

            float3 SampleBlur(float2 uv)
            {
                float2 offset = _MainTex_TexelSize.xy * _BlurRadius;

                float3 sum = 0;
                sum += tex2D(_MainTex, saturate(uv + float2(-offset.x, 0))).rgb;
                sum += tex2D(_MainTex, saturate(uv)).rgb;
                sum += tex2D(_MainTex, saturate(uv + float2(offset.x, 0))).rgb;
                sum += tex2D(_MainTex, saturate(uv + float2(0, offset.y))).rgb;
                sum += tex2D(_MainTex, saturate(uv + float2(0, -offset.y))).rgb;

                return sum / 5.0;
            }

            // Rounded rectangle distance field.
            float RoundedBoxDistance(float2 p, float2 halfSize, float radius)
            {
                float2 q = abs(p) - halfSize + radius;
                return length(max(q, 0.0))
                    + min(max(q.x, q.y), 0.0)
                    - radius;
            }

            // Barrel distortion dùng chung cho CRT / Fisheye / Lens.
            // Có bù tỉ lệ khung hình để méo tròn đều, không bị méo ngang.
            float2 Barrel(float2 uv, float k, float aspect)
            {
                float2 p = (uv - 0.5) * 2.0;
                p.x *= aspect;
                p *= 1.0 + k * dot(p, p);
                p.x /= aspect;
                return p * 0.5 + 0.5;
            }

            fixed4 frag(v2f_img i) : SV_Target
            {
                float2 screenUV = i.uv;
                float time = _Time.y;

                float aspect =
                    _MainTex_TexelSize.z /
                    max(_MainTex_TexelSize.w, 1.0);

                // --- CRT CURVATURE -> FISHEYE (CHỒNG LÊN) -> LENS ---
                // 1. Độ cong màn hình CRT (luôn áp dụng).
                float2 uv = Barrel(screenUV, _CRTCurvature, aspect);

                // 2. Fisheye chồng lên CRT; Blend = 0 thì tắt hẳn, 1 thì full.
                float2 fishUV = Barrel(uv, _FisheyeStrength, aspect);
                uv = lerp(uv, fishUV, _FisheyeBlend);

                // 3. Méo thấu kính bổ sung.
                uv = Barrel(uv, _LensDistortion, 1.0);

                // --- TAPE WOBBLE ---
                uv.x += sin(uv.y * 17.0 + time * 2.1) * _WobbleStrength;

                // --- HORIZONTAL JITTER ---
                float jitterLine = floor(uv.y * 900.0);
                float jitterNoise = hash(
                    float2(jitterLine, floor(time * _JitterSpeed))
                );
                uv.x += (jitterNoise - 0.5) * _JitterStrength;

                // --- TRACKING ---
                float trackingCenter = frac(time * _TrackingSpeed);
                float trackingDistance = abs(uv.y - trackingCenter);

                float trackingMask = 1.0 - smoothstep(
                    0.0,
                    max(_TrackingHeight, 0.0001),
                    trackingDistance
                );

                float trackingNoise = hash(
                    float2(floor(uv.y * 300.0), floor(time * 20.0))
                );

                uv.x += (trackingNoise - 0.5)
                    * _TrackingStrength * trackingMask;

                // --- ANALOG GLITCH BANDS ---
                float glitchFrame = floor(time * max(_GlitchFrequency, 0.01));
                float glitchSeed = hash1(glitchFrame);
                float glitchCenter = hash1(glitchFrame + 17.0);

                float glitchBand = 1.0 - smoothstep(
                    _GlitchBandHeight,
                    _GlitchBandHeight + 0.015,
                    abs(uv.y - glitchCenter)
                );

                float glitchActive = step(
                    1.0 - saturate(_GlitchFrequency * 0.08),
                    glitchSeed
                );

                float glitchOffset =
                    (hash1(glitchFrame + floor(uv.y * 30.0)) - 0.5)
                    * _GlitchStrength * glitchBand * glitchActive;

                uv.x += glitchOffset;

                // --- HEAD SWITCHING ---
                float headMask = 1.0 - smoothstep(
                    0.0,
                    _HeadSwitchHeight,
                    uv.y
                );

                uv.x += (
                    hash(float2(floor(time * 12.0), 4.0)) - 0.5
                ) * _HeadSwitchStrength * 0.02 * headMask;

                // --- CRT SCREEN MASK ---
                float2 maskPos = (screenUV - 0.5) * 2.0;
                maskPos.x *= aspect;

                float roundedDistance = RoundedBoxDistance(
                    maskPos,
                    float2(aspect, 1.0) - _CRTBorderWidth,
                    _CRTCornerRadius
                );

                float screenMask = 1.0 - smoothstep(
                    -_CRTMaskSoftness,
                    _CRTMaskSoftness,
                    roundedDistance
                );

                // Edge darkness grows toward the screen border.
                float edgeDistance = min(
                    min(screenUV.x, 1.0 - screenUV.x),
                    min(screenUV.y, 1.0 - screenUV.y)
                );

                float borderMask = 1.0 - smoothstep(
                    _CRTBorderWidth,
                    _CRTBorderWidth + _CRTMaskSoftness,
                    edgeDistance
                );

                // --- VÙNG NGOÀI ẢNH SAU KHI BẺ UV: tô đen, không kéo dài pixel mép ---
                float2 edgeDist = min(uv, 1.0 - uv);
                float insideMask = smoothstep(0.0, 0.003, min(edgeDist.x, edgeDist.y));

                uv = saturate(uv);

                // --- INTERLACE ---
                float field = fmod(floor(uv.y * 720.0), 2.0);

                float interlaceShift =
                    (field * 2.0 - 1.0)
                    * _InterlaceAmount * _MainTex_TexelSize.y;

                float2 interlaceUV = saturate(
                    uv + float2(0.0, interlaceShift)
                );

                // --- CHROMATIC ABERRATION ---
                float2 center = uv - 0.5;
                float distanceFromCenter = length(center);

                float2 direction = distanceFromCenter > 0.0001
                    ? center / distanceFromCenter
                    : float2(1, 0);

                float2 chromaOffset =
                    direction * _ChromaticAmount * distanceFromCenter;

                float red = tex2D(
                    _MainTex,
                    saturate(interlaceUV + chromaOffset)
                ).r;

                float green = tex2D(_MainTex, interlaceUV).g;

                float blue = tex2D(
                    _MainTex,
                    saturate(interlaceUV - chromaOffset)
                ).b;

                float3 col = float3(red, green, blue);

                // --- COLOR BLEED ---
                float3 bleed = tex2D(
                    _MainTex,
                    saturate(interlaceUV + float2(_ColorBleed, 0))
                ).rgb;

                col = lerp(col, bleed, 0.15);

                // --- SOFT BLUR ---
                if (_BlurAmount > 0.001)
                {
                    float3 blurred = SampleBlur(interlaceUV);
                    col = lerp(col, blurred, _BlurAmount);
                }

                // --- GHOSTING ---
                float3 ghost = tex2D(
                    _MainTex,
                    saturate(interlaceUV + float2(_GhostOffset, 0))
                ).rgb;

                col = lerp(col, ghost, _GhostAmount);

                // --- VHS GRAIN ---
                float2 noiseUV = uv * 2.0 + float2(
                    time * _NoiseSpeed,
                    time * _NoiseSpeed * 0.73
                );

                float noiseTexture = tex2D(_NoiseTex, noiseUV).r;

                float grain = hash(
                    floor(i.uv * _ScreenParams.xy)
                    + floor(time * 24.0)
                );

                col += (noiseTexture - 0.5) * _NoiseAmount;
                col += (grain - 0.5) * _AnalogNoiseAmount;

                // --- RANDOM DROPOUT ---
                float dropoutLine = floor(uv.y * 500.0);

                float dropoutNoise = hash(
                    float2(dropoutLine, floor(time * 8.0))
                );

                float dropoutMask = step(
                    1.0 - _DropoutAmount,
                    dropoutNoise
                );

                col = lerp(
                    col,
                    col * 0.25,
                    dropoutMask * _DropoutStrength
                );

                // --- SCANLINES ---
                float scan = uv.y * _ScanlineCount
                    + time * _ScanlineSpeed;

                float scanMask = sin(scan * 6.2831853) * 0.5 + 0.5;

                col *= 1.0 - scanMask * _ScanlineStrength;

                // --- ANALOG COLOR GRADING ---
                col *= _Exposure;
                col = saturate(col);

                col = (col - 0.5) * _Contrast + 0.5;
                col *= _WarmTint.rgb;

                float luminance = dot(col, float3(0.299, 0.587, 0.114));
                col = lerp(luminance.xxx, col, _Saturation);

                col = lerp(
                    col,
                    float3(0.45, 0.43, 0.40),
                    _ColorFade * 0.18
                );

                // --- VIGNETTE ---
                float vignette = smoothstep(
                    0.85,
                    0.35,
                    distanceFromCenter
                );

                col *= lerp(
                    1.0 - _VignetteStrength,
                    1.0,
                    vignette
                );

                // --- CRT BORDER DARKNESS ---
                col *= 1.0 - borderMask * _CRTBorderDarkness;

                // --- ROUNDED CORNERS ---
                col *= lerp(
                    1.0 - _CRTCornerDarkness,
                    1.0,
                    screenMask
                );

                // Outside the CRT screen is black.
                col *= screenMask;

                // Vùng UV bị bẻ ra ngoài ảnh -> đen.
                col *= insideMask;

                col = saturate(col);

                return float4(col, 1.0);
            }

            ENDCG
        }
    }

    FallBack Off
}