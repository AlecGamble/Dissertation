Shader "Volumetric/Raymarch/Constant Step"
{
    Properties
    {
        _Radius("Radius", float) = 0.5
        _Centre("Position", Vector) = (0,0,0,0)
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
            #define STEP_SIZE 0.1

            float3 _Centre;
            float _Radius;

            vertexOutput vert (vertexInput v)
            {
                vertexOutput o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPosition = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            //check whether point is inside the sphere
            bool sphereHit(float3 p)
            {
                return distance(p, _Centre) < 0.5;
            }

            //raymarch with a constant step
            fixed4 raymarchHit (float3 position, float3 direction)
            {
                for(int i = 0; i < STEPS; i++)
                {
                    if( sphereHit(position) )
                        return i / float(STEPS);
                    position += direction * STEP_SIZE;
                }
                return 0;
            }

            fixed4 frag (vertexOutput i) : SV_Target
            {
                float3 worldPosition = i.worldPosition;
                float3 viewDirection = normalize(i.worldPosition - _WorldSpaceCameraPos);

                return raymarchHit(worldPosition, viewDirection);
            }
            ENDCG
        }
    }
}
