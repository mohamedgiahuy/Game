Shader "Custom/FlatWater"
{
    Properties
    {
        [Header(Color)]
        _ShallowColor ("Shallow Color", Color) = (0.2, 0.6, 0.8, 0.6)
        _DeepColor ("Deep Color", Color) = (0.05, 0.2, 0.4, 0.9)
        _DepthDistance ("Depth Distance", Range(0.1, 10)) = 3.0

        [Header(Normal Map)]
        _NormalMap ("Normal Map", 2D) = "bump" {}
        _NormalStrength ("Normal Strength", Range(0, 2)) = 0.5
        _NormalSpeed1 ("Normal Speed Layer 1", Vector) = (0.03, 0.02, 0, 0)
        _NormalSpeed2 ("Normal Speed Layer 2", Vector) = (-0.02, 0.03, 0, 0)
        _NormalScale2 ("Normal Scale Layer 2", Range(0.1, 5)) = 1.8

        [Header(Foam)]
        _FoamColor ("Foam Color", Color) = (1, 1, 1, 1)
        _FoamDistance ("Foam Distance", Range(0.01, 2)) = 0.4
        _FoamNoise ("Foam Noise", Range(0, 1)) = 0.3

        [Header(Specular)]
        _Specular ("Specular Intensity", Range(0, 1)) = 0.6
        _Smoothness ("Smoothness", Range(0, 1)) = 0.85

        [Header(Fresnel)]
        _FresnelPower ("Fresnel Power", Range(0.1, 5)) = 2.0

        [Header(Ripple)]
        _RippleSpeed ("Ripple Speed", Range(0, 2)) = 0.5
        _RippleScale ("Ripple Scale", Range(0.1, 5)) = 1.0
        _RippleStrength ("Ripple Strength", Range(0, 1)) = 0.15
    }

    SubShader
    {
        Tags
        {
            "Queue" = "Transparent"
            "RenderType" = "Transparent"
        }

        GrabPass { "_GrabTex" }

        Pass
        {
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            // Color
            fixed4 _ShallowColor;
            fixed4 _DeepColor;
            float  _DepthDistance;

            // Normal
            sampler2D _NormalMap;
            float4    _NormalMap_ST;
            float     _NormalStrength;
            float4    _NormalSpeed1;
            float4    _NormalSpeed2;
            float     _NormalScale2;

            // Foam
            fixed4 _FoamColor;
            float  _FoamDistance;
            float  _FoamNoise;

            // Specular / Fresnel
            float _Specular;
            float _Smoothness;
            float _FresnelPower;

            // Ripple
            float _RippleSpeed;
            float _RippleScale;
            float _RippleStrength;

            // Depth & Grab
            sampler2D _CameraDepthTexture;
            sampler2D _GrabTex;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv     : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos        : SV_POSITION;
                float2 uv         : TEXCOORD0;
                float4 grabPos    : TEXCOORD1;
                float4 screenPos  : TEXCOORD2;
                float3 worldPos   : TEXCOORD3;
                float3 worldNorm  : TEXCOORD4;
                float3 viewDir    : TEXCOORD5;
            };

            // Hash noise nhẹ cho foam
            float hash(float2 p)
            {
                return frac(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
            }

            v2f vert(appdata v)
            {
                v2f o;
                o.pos       = UnityObjectToClipPos(v.vertex);
                o.uv        = TRANSFORM_TEX(v.uv, _NormalMap);
                o.grabPos   = ComputeGrabScreenPos(o.pos);
                o.screenPos = ComputeScreenPos(o.pos);
                o.worldPos  = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldNorm = UnityObjectToWorldNormal(v.normal);
                o.viewDir   = normalize(UnityWorldSpaceViewDir(o.worldPos));
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float t = _Time.y;

                // ─── Normal Map 2 lớp cuộn ngược chiều ──────────────
                float2 uv1 = i.uv + _NormalSpeed1.xy * t;
                float2 uv2 = i.uv * _NormalScale2 + _NormalSpeed2.xy * t;

                float3 n1 = UnpackNormal(tex2D(_NormalMap, uv1));
                float3 n2 = UnpackNormal(tex2D(_NormalMap, uv2));
                float3 normal = normalize(float3(
                    (n1.xy + n2.xy) * _NormalStrength,
                    1.0));

                // ─── Ripple (gợn tròn lan rộng) ─────────────────────
                float2 centered = i.uv - 0.5;
                float dist = length(centered) * _RippleScale;
                float ripple = sin(dist * 10.0 - t * _RippleSpeed * 6.28) * _RippleStrength;
                ripple *= (1.0 - smoothstep(0.3, 0.5, dist)); // fade ở mép
                normal.xy += ripple;
                normal = normalize(normal);

                // ─── Depth (nông/sâu) ────────────────────────────────
                float4 screenPos = i.screenPos;
                screenPos.xy   /= screenPos.w;
                float sceneDepth = LinearEyeDepth(
                    tex2D(_CameraDepthTexture, screenPos.xy).r);
                float surfDepth  = i.screenPos.w;
                float depthDiff  = sceneDepth - surfDepth;
                float depthFade  = saturate(depthDiff / _DepthDistance);

                // ─── Màu nước: pha shallow/deep theo độ sâu ──────────
                fixed4 waterColor = lerp(_ShallowColor, _DeepColor, depthFade);

                // ─── Refraction (khúc xạ qua GrabPass) ──────────────
                float2 grabOffset = normal.xy * 0.03;
                float2 grabUV = (i.grabPos.xy + grabOffset) / i.grabPos.w;
                fixed4 refraction = tex2D(_GrabTex, grabUV);

                // ─── Fresnel ─────────────────────────────────────────
                float3 worldNorm = normalize(i.worldNorm + float3(normal.xy, 0));
                float fresnel = pow(1.0 - saturate(dot(i.viewDir, worldNorm)),
                                    _FresnelPower);

                // ─── Specular Blinn-Phong ────────────────────────────
                float3 lightDir  = normalize(_WorldSpaceLightPos0.xyz);
                float3 halfDir   = normalize(lightDir + i.viewDir);
                float  spec      = pow(saturate(dot(worldNorm, halfDir)),
                                       _Smoothness * 128.0) * _Specular;
                fixed3 specColor = _LightColor0.rgb * spec;

                // ─── Foam (bọt ở vùng nước nông) ────────────────────
                float foamNoise = hash(i.uv * 8.0 + t * 0.3);
                float foamMask  = 1.0 - smoothstep(0.0,
                                    _FoamDistance + foamNoise * _FoamNoise,
                                    depthDiff);
                fixed4 foamCol  = _FoamColor * foamMask;

                // ─── Combine ─────────────────────────────────────────
                fixed4 col = lerp(refraction, waterColor, waterColor.a);
                col.rgb   += specColor;
                col.rgb    = lerp(col.rgb, foamCol.rgb, foamMask * _FoamColor.a);
                col.rgb   += fresnel * 0.15;
                col.a      = waterColor.a + fresnel * 0.2;

                return col;
            }
            ENDCG
        }
    }
    FallBack "Transparent/Diffuse"
}