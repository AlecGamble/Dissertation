Shader "Volumetric/Raymarch/Room"
{
    Properties
    {
        _Color("Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _SpecularPower("Specular", float) = 1.0
        _Gloss("Gloss", float) = 1.0
        [KeywordEnum(None, Box, Table, Chair, TableAndChairs)] _SDF("SDF", float) = 0
        _Rooms("Rooms", Vector) = (1,1,0,0)
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
            #pragma shader_feature _SDF_NONE _SDF_BOX _SDF_TABLE _SDF_CHAIR _SDF_TABLEANDCHAIRS

            #include "sdf.cginc"

            struct vertexInput
            {
                float4 vertex : POSITION;
            };

            struct vertexOutput
            {
                float4 vertex : SV_POSITION;
                float4 localCameraPosition: TEXCOORD2;
                float3 position : TEXCOORD3;
            };

            #define STEPS 64
            #define MIN_DISTANCE 0.005


            float3 _Color;
            float _SpecularPower;
            float _Gloss;


            vertexOutput vert (vertexInput v)
            {
                vertexOutput o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.localCameraPosition = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1.0));
                o.position = v.vertex;
                return o;
            }

            float map(float3 p)
            {
                float r = 0;
                #ifdef _SDF_BOX

                    r = sdf_box(p, 0, 0.5);

                #elif _SDF_TABLE

                    r = sdf_table(p);

                #elif _SDF_CHAIR

                    r = sdf_chair(p);

                #elif _SDF_TABLEANDCHAIRS

                    r = sdf_table(p);
                    r = min(r, sdf_chair(p + float3(0.1,0.0,-0.05)));
                    r = min(r, sdf_chair(p + float3(-0.1,0.0,-0.05)));

                #endif

                return r;
            }

            // estimate normals by sampling distances from adjacent pixels - only works for smooth surfaces
            float3 normal (float3 p)
            {
                const float eps = 0.01;
                return normalize
                (    float3
                (       map(p + float3(eps, 0, 0)) - map(p - float3(eps, 0, 0)),
                        map(p + float3(0, eps, 0)) - map(p - float3(0, eps, 0)),
                        map(p + float3(0, 0, eps)) - map(p - float3(0, 0, eps))
                    )
                );
            }

            #include "Lighting.cginc"
            fixed4 shade (fixed3 normal, float3 viewDirection, float3 objectColor) {
                fixed3 lightDir = _WorldSpaceLightPos0.xyz;    // Light direction
                fixed3 lightCol = _LightColor0.rgb;        // Light color
                fixed NdotL = max(dot(normal, lightDir),0);
                fixed4 c;
                fixed3 h = (lightDir - viewDirection) / 2.;
                fixed s = pow( dot(normal, h), _SpecularPower) * _Gloss;
                c.rgb = objectColor * lightCol * NdotL + s;
                c.a = 1;
                return c;
            }

            fixed4 renderSurface(float3 p, float3 viewDirection)
            {
                float3 n = normal(p);
                return shade(n, viewDirection, float3(0.3,0.1,0.0));
            }

            
            fixed4 raymarch (float3 position, float3 direction)
            {
                for (int i = 0; i < STEPS; i++)
                {
                    float distance = map(position);
        
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
                float3 localPosition = i.position;
                // localPosition *= 2;
                float3 localViewDirection = normalize(localPosition - i.localCameraPosition);


                return raymarch(localPosition, localViewDirection);
            }
            ENDCG
        }
    }
}
