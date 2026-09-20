Shader "Custom/VHS_2000s_Realistic"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}

        [Header(VHS Noise)]
        _NoiseTex ("Noise Texture", 2D) = "white" {}
        _NoiseAmount ("Noise Amount", Range(0, 0.1)) = 0.012
        _NoiseSpeed ("Noise Speed", Range(0, 3)) = 0.5

        [Header(Scanlines)]
        _ScanlineCount ("Scanline Count", Range(50, 600)) = 240
        _ScanlineStrength ("Scanline Strength", Range(0, 0.3)) = 0.06
        _ScanlineSpeed ("Scanline Speed", Range(-5, 5)) = 0.15

        [Header(Chromatic Aberration)]
        _ChromaticAmount ("Chromatic Amount", Range(0, 0.01)) = 0.0015

        [Header(Color Bleeding)]
        _ColorBleed ("Color Bleed", Range(0, 0.02)) = 0.003

        [Header(Soft Blur)]
        _BlurAmount ("Blur Amount", Range(0, 1)) = 0.08
        _BlurRadius ("Blur Radius", Range(0, 3)) = 1.0

        [Header(Tracking)]
        _TrackingStrength ("Tracking Strength", Range(0, 0.2)) = 0.035
        _TrackingHeight ("Tracking Height", Range(0.01, 0.3)) = 0.05
        _TrackingSpeed ("Tracking Speed", Range(-2, 2)) = 0.2

        [Header(Tape Jitter)]
        _JitterStrength ("Jitter Strength", Range(0, 0.01)) = 0.0015
        _JitterSpeed ("Jitter Speed", Range(1, 30)) = 12.0
        _WobbleStrength ("Wobble Strength", Range(0, 0.01)) = 0.0015

        [Header(Ghosting)]
        _GhostAmount ("Ghost Amount", Range(0, 0.2)) = 0.035
        _GhostOffset ("Ghost Offset", Range(0.0001, 0.02)) = 0.0025

        [Header(Dropout)]
        _DropoutStrength ("Dropout Strength", Range(0, 1)) = 0.12
        _DropoutAmount ("Dropout Amount", Range(0, 0.1)) = 0.015

        [Header(Interlace)]
        _InterlaceAmount ("Interlace Amount", Range(0, 0.1)) = 0.025

        [Header(Head Switching)]
        _HeadSwitchStrength ("Head Switch Strength", Range(0, 1)) = 0.18
        _HeadSwitchHeight ("Head Switch Height", Range(0.001, 0.1)) = 0.025

        [Header(Vignette)]
        _VignetteStrength ("Vignette Strength", Range(0, 1)) = 0.18

        [Header(Color)]
        _Exposure ("Exposure", Range(0.5, 1.5)) = 1.02
        _Contrast ("Contrast", Range(0.5, 1.5)) = 1.05
        _Saturation ("Saturation", Range(0, 2)) = 0.92
        _WarmTint ("Warm Tint", Color) = (1.02, 1.0, 0.94, 1)
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

            float _NoiseAmount;
            float _NoiseSpeed;

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

            float4 _WarmTint;


            // ==========================================================
            // HASH
            // ==========================================================

            float hash(float2 p)
            {
                return frac(
                    sin(
                        dot(
                            p,
                            float2(127.1, 311.7)
                        )
                    ) * 43758.5453123
                );
            }


            // ==========================================================
            // 1D HASH
            // ==========================================================

            float hash1(float p)
            {
                return frac(
                    sin(p * 127.1) *
                    43758.5453123
                );
            }


            // ==========================================================
            // SIMPLE BLUR
            // ==========================================================

            float3 SampleBlur(float2 uv)
            {
                float2 offset =
                    _MainTex_TexelSize.xy *
                    _BlurRadius;

                float3 sum = 0;

                sum += tex2D(
                    _MainTex,
                    uv + float2(-offset.x, 0)
                ).rgb;

                sum += tex2D(
                    _MainTex,
                    uv
                ).rgb;

                sum += tex2D(
                    _MainTex,
                    uv + float2(offset.x, 0)
                ).rgb;

                sum += tex2D(
                    _MainTex,
                    uv + float2(0, offset.y)
                ).rgb;

                sum += tex2D(
                    _MainTex,
                    uv + float2(0, -offset.y)
                ).rgb;

                return sum / 5.0;
            }


            // ==========================================================
            // FRAGMENT
            // ==========================================================

            fixed4 frag(v2f_img i) : SV_Target
            {
                float2 uv = i.uv;
                float time = _Time.y;


                // ======================================================
                // TAPE WOBBLE
                // ======================================================

                float wobble =
                    sin(
                        uv.y * 17.0 +
                        time * 2.1
                    ) * _WobbleStrength;

                wobble +=
                    sin(
                        uv.y * 43.0 -
                        time * 1.7
                    ) * _WobbleStrength * 0.35;

                uv.x += wobble;


                // ======================================================
                // HORIZONTAL JITTER
                // ======================================================

                float jitterLine =
                    floor(
                        uv.y *
                        900.0
                    );

                float jitterNoise =
                    hash(
                        float2(
                            jitterLine,
                            floor(time * _JitterSpeed)
                        )
                    );

                float jitter =
                    (jitterNoise - 0.5) *
                    _JitterStrength;

                uv.x += jitter;


                // ======================================================
                // TRACKING DISTORTION
                // ======================================================

                float trackingCenter =
                    frac(
                        time *
                        _TrackingSpeed
                    );

                float trackingDistance =
                    abs(
                        uv.y -
                        trackingCenter
                    );

                float trackingMask =
                    1.0 -
                    smoothstep(
                        0.0,
                        max(
                            _TrackingHeight,
                            0.0001
                        ),
                        trackingDistance
                    );

                float trackingNoise =
                    hash(
                        float2(
                            floor(uv.y * 300.0),
                            floor(time * 20.0)
                        )
                    );

                float trackingOffset =
                    (
                        trackingNoise -
                        0.5
                    ) *
                    _TrackingStrength *
                    trackingMask;

                uv.x += trackingOffset;


                // ======================================================
                // CLAMP
                // ======================================================

                uv = saturate(uv);


                // ======================================================
                // INTERLACE
                // ======================================================

                float field =
                    fmod(
                        floor(
                            uv.y *
                            720.0
                        ),
                        2.0
                    );

                float interlaceShift =
                    (field * 2.0 - 1.0) *
                    _InterlaceAmount *
                    _MainTex_TexelSize.y;

                float2 interlaceUV =
                    uv + float2(
                        0.0,
                        interlaceShift
                    );

                interlaceUV = saturate(interlaceUV);


                // ======================================================
                // CHROMATIC ABERRATION
                // ======================================================

                float2 center =
                    uv -
                    0.5;

                float distanceFromCenter =
                    length(center);

                float2 direction =
                    distanceFromCenter > 0.0001
                    ? center / distanceFromCenter
                    : float2(1, 0);

                float2 chromaOffset =
                    direction *
                    _ChromaticAmount *
                    distanceFromCenter;


                // ======================================================
                // COLOR BLEED
                // ======================================================

                float2 bleedOffset =
                    float2(
                        _ColorBleed,
                        0
                    );

                float3 sampleLeft =
                    tex2D(
                        _MainTex,
                        saturate(
                            interlaceUV -
                            bleedOffset
                        )
                    ).rgb;

                float3 sampleRight =
                    tex2D(
                        _MainTex,
                        saturate(
                            interlaceUV +
                            bleedOffset
                        )
                    ).rgb;


                // ======================================================
                // RGB SEPARATION
                // ======================================================

                float red =
                    tex2D(
                        _MainTex,
                        saturate(
                            interlaceUV +
                            chromaOffset
                        )
                    ).r;

                float green =
                    tex2D(
                        _MainTex,
                        interlaceUV
                    ).g;

                float blue =
                    tex2D(
                        _MainTex,
                        saturate(
                            interlaceUV -
                            chromaOffset
                        )
                    ).b;


                float3 col =
                    float3(
                        red,
                        green,
                        blue
                    );


                // ======================================================
                // VHS COLOR BLEED MIX
                // ======================================================

                float3 bleedColor =
                    float3(
                        sampleRight.r,
                        sampleLeft.g,
                        sampleLeft.b
                    );

                col =
                    lerp(
                        col,
                        bleedColor,
                        0.35
                    );


                // ======================================================
                // SOFT BLUR
                // ======================================================

                if (_BlurAmount > 0.001)
                {
                    float3 blurred =
                        SampleBlur(
                            interlaceUV
                        );

                    col =
                        lerp(
                            col,
                            blurred,
                            _BlurAmount
                        );
                }


                // ======================================================
                // GHOSTING
                // ======================================================

                float2 ghostUV =
                    interlaceUV +
                    float2(
                        _GhostOffset,
                        0
                    );

                float3 ghost =
                    tex2D(
                        _MainTex,
                        saturate(ghostUV)
                    ).rgb;

                col =
                    lerp(
                        col,
                        ghost,
                        _GhostAmount
                    );


                // ======================================================
                // VHS GRAIN
                // ======================================================

                float2 noiseUV =
                    uv * 2.0 +
                    float2(
                        time * _NoiseSpeed,
                        time * _NoiseSpeed * 0.73
                    );

                float noise =
                    tex2D(
                        _NoiseTex,
                        noiseUV
                    ).r;

                col +=
                    (noise - 0.5) *
                    _NoiseAmount;


                // ======================================================
                // LUMA NOISE
                // ======================================================

                float lumaNoise =
                    hash(
                        float2(
                            floor(uv.x * 500.0),
                            floor(
                                uv.y * 500.0 +
                                time * 15.0
                            )
                        )
                    );

                col +=
                    (lumaNoise - 0.5) *
                    0.006;


                // ======================================================
                // SCANLINES
                // ======================================================

                float scan =
                    uv.y *
                    _ScanlineCount +
                    time *
                    _ScanlineSpeed;

                float scanWave =
                    sin(
                        scan *
                        6.2831853
                    );

                float scanMask =
                    scanWave *
                    0.5 +
                    0.5;

                col *=
                    1.0 -
                    scanMask *
                    _ScanlineStrength;


                // ======================================================
                // TAPE HORIZONTAL BAND
                // ======================================================

                float bandNoise =
                    hash(
                        float2(
                            floor(
                                uv.y *
                                120.0
                            ),
                            floor(
                                time *
                                7.0
                            )
                        )
                    );

                float band =
                    smoothstep(
                        0.72,
                        0.98,
                        bandNoise
                    );

                band *=
                    sin(
                        uv.y *
                        120.0 +
                        time *
                        5.0
                    ) *
                    0.5 +
                    0.5;

                col +=
                    band *
                    0.008;


                // ======================================================
                // DROPOUT / TAPE DAMAGE
                // ======================================================

                float dropoutLine =
                    floor(
                        uv.y *
                        260.0
                    );

                float dropoutNoise =
                    hash(
                        float2(
                            dropoutLine,
                            floor(
                                time *
                                5.0
                            )
                        )
                    );

                float dropout =
                    step(
                        1.0 -
                        _DropoutAmount,
                        dropoutNoise
                    );

                float dropoutMask =
                    smoothstep(
                        0.15,
                        0.85,
                        hash1(
                            floor(
                                time *
                                4.0
                            )
                        )
                    );

                dropout *=
                    dropoutMask;

                col =
                    lerp(
                        col,
                        float3(
                            0.8,
                            0.8,
                            0.8
                        ),
                        dropout *
                        _DropoutStrength
                    );


                // ======================================================
                // HEAD SWITCHING NOISE
                // ======================================================

                float distanceFromBottom =
                    1.0 -
                    uv.y;

                float headSwitchMask =
                    1.0 -
                    smoothstep(
                        0.0,
                        _HeadSwitchHeight,
                        distanceFromBottom
                    );

                float headNoise =
                    hash(
                        float2(
                            floor(
                                uv.x *
                                300.0
                            ),
                            floor(
                                time *
                                18.0
                            )
                        )
                    );

                float3 headSwitchColor =
                    float3(
                        headNoise,
                        headNoise,
                        headNoise
                    );

                col =
                    lerp(
                        col,
                        headSwitchColor,
                        headSwitchMask *
                        _HeadSwitchStrength
                    );


                // ======================================================
                // VERY LIGHT ANALOG FLICKER
                // ======================================================

                float flicker =
                    hash(
                        float2(
                            floor(
                                time *
                                12.0
                            ),
                            17.0
                        )
                    );

                float flickerAmount =
                    lerp(
                        0.985,
                        1.015,
                        flicker
                    );

                col *=
                    flickerAmount;


                // ======================================================
                // COLOR
                // ======================================================

                col *=
                    _Exposure;

                col =
                    (col - 0.5) *
                    _Contrast +
                    0.5;

                col *=
                    _WarmTint.rgb;


                float luminance =
                    dot(
                        col,
                        float3(
                            0.299,
                            0.587,
                            0.114
                        )
                    );

                col =
                    lerp(
                        luminance.xxx,
                        col,
                        _Saturation
                    );


                // ======================================================
                // VIGNETTE
                // ======================================================

                float vignette =
                    smoothstep(
                        0.85,
                        0.35,
                        distanceFromCenter
                    );

                col *=
                    lerp(
                        1.0 -
                        _VignetteStrength,
                        1.0,
                        vignette
                    );


                // ======================================================
                // FINAL
                // ======================================================

                col =
                    saturate(
                        col
                    );

                return float4(
                    col,
                    1.0
                );
            }

            ENDCG
        }
    }
}