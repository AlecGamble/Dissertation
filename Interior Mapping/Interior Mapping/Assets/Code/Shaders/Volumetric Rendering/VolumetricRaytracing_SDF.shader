Shader "Volumetric/Raymarch/SDF"
{
    Properties
    {
        _Radius("Radius", Vector) = (0.5,0.5,0.5,0.0)
        _Centre("Position", Vector) = (0,0,0,0)
        _Color("Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _SpecularPower("Specular", float) = 1.0
        _Gloss("Gloss", float) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "sdf.cginc"
            #include "shading.cginc"

            struct vertexInput
            {
                float4 vertex : POSITION;
            };

            struct vertexOutput
            {
                float4 vertex : SV_POSITION;
                float3 worldPosition : TEXCOORD1;
            };

            #define STEPS 64
            #define MIN_DISTANCE 0.005

            float3 _Centre;
            float3 _Radius;
            float3 _Color;
            float _SpecularPower;
            float _Gloss;

            vertexOutput vert (vertexInput v)
            {
                vertexOutput o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPosition = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            // estimate normals by sampling distances from adjacent pixels - only works for smooth surfaces
            float3 normal (float3 p)
            {
                const float eps = 0.01;
                return normalize
                (    float3
                (       sdf_box(p + float3(eps, 0, 0), _Centre, _Radius       ) - sdf_box(p - float3(eps, 0, 0), _Centre, _Radius),
                        sdf_box(p + float3(0, eps, 0), _Centre, _Radius    ) - sdf_box(p - float3(0, eps, 0), _Centre, _Radius),
                        sdf_box(p + float3(0, 0, eps), _Centre, _Radius    ) - sdf_box(p - float3(0, 0, eps), _Centre, _Radius)
                    )
                );
            }

            fixed4 renderSurface(float3 p, float3 viewDirection)
            {
                float3 n = normal(p);
                return specular(n, viewDirection, _SpecularPower, _Gloss);
            }

            
            fixed4 raymarch (float3 position, float3 direction)
            {
                for (int i = 0; i < STEPS; i++)
                {
                    float distance = sdf_box(position, _Centre, _Radius);
                    if (distance < MIN_DISTANCE)
                    {
                        fixed4 color = renderSurface(position, direction);
                        return color;
                    }
                    position += distance * direction;
                }
                return 0;
            }

            fixed4 frag (vertexOutput i) : SV_Target
            {
                float3 worldPosition = i.worldPosition;
                float3 viewDirection = normalize(i.worldPosition - _WorldSpaceCameraPos);

                return raymarch(worldPosition, viewDirection);
            }
            ENDCG
        }
    }
}
