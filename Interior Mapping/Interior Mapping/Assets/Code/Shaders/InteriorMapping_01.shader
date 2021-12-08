Shader "Interior Mapping/Base"
{
    Properties
    {
        _RoomAtlas ("Room Atlas", 2D) = "white" {}
        _RoomAtlas ("Interior Atlas", 2D) = "white" {}
        _FacadeTex ("Facade", 2D) = "white" {}
        _RoomSize ("Room Size", Vector) = (8,8,0,0)
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


            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 tangentViewDirection : TEXCOORD1;
                float2 tangentPosition : TEXCOORD2;

            };

            sampler2D _MainTex;
            sampler2D _FacadeTex;
            float4 _MainTex_ST;
            float4 _FacadeTex_ST;
            float3 _RoomSize;

            v2f vert (appdata v) {
                v2f o;
                
                // First, let's determine a tangent basis matrix.
                // We will want to perform the interior raycast in tangent-space,
                // so it correctly follows building curvature, and we won't have to
                // worry about aligning rooms with edges.
                half tanSign = v.tangent.w * unity_WorldTransformParams.w;
                half3x3 objectToTangent = half3x3(
                    v.tangent.xyz,
                    cross(v.normal, v.tangent) * tanSign,
                    v.normal);

                // Next, determine the tangent-space eye vector. This will be
                // cast into an implied room volume to calculate a hit position.
                float3 viewDir = v.vertex - mul(unity_WorldToObject, _WorldSpaceCameraPos);
                o.tangentViewDirection = mul(objectToTangent, viewDir);

                // The vertex position in tangent-space is just the unscaled
                // texture coordinate.
                o.tangentPosition = v.uv;

                // Lastly, output the normal vertex data.
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _FacadeTex);

                return o;
            }

            float2 rand(float co)
            {
                return frac(sin(co * float2(12.9898, 78.233)) * 43758.5453);
            }

            fixed4 frag (v2f i) : SV_Target {
                // First, construct a ray from the camera, onto our UV plane.
                // Notice the ray is being pre-scaled by the room dimensions.
                // By distorting the ray in this way, the volume can be treated
                // as a unit cube in the intersection code.
                float3 rayOrigin = frac(float3(i.tangentPosition,0) / _RoomSize);
                float3 rayDirection = normalize(i.tangentViewDirection) / _RoomSize;

                // Now, define the volume of our room. With the pre-scale, this
                // is just a unit-sized box.
                float3 bMin = floor(float3(i.tangentPosition,-1));
                float3 bMax = bMin + 1;
                float3 bMid = bMin + 0.5;

                // Since the bounding box is axis-aligned, we can just find
                // the ray-plane intersections for each plane. we only 
                // actually need to solve for the 3 "back" planes, since the 
                // near walls of the virtual cube are "open".
                // just find the corner opposite the camera using the sign of
                // the ray's direction.
                float3 planes = lerp(bMin, bMax, step(0, rayDirection));
                float3 tPlane = (planes - rayOrigin) / rayDirection;

                // Now, we know the distance to the intersection is simply
                // equal to the closest ray-plane intersection point.
                float tDist = min(min(tPlane.x, tPlane.y), tPlane.z);

                // Lastly, given the point of intersection, we can calculate
                // a sample vector just like a cubemap.
                float3 roomVec = (rayOrigin + rayDirection * tDist) - bMid;
                float2 interiorUV = roomVec.xy * lerp(0.5, 1, roomVec.z + 0.5) + 0.5;

                // If the room texture is an atlas of multiple variants, transform
                // the texture coordinates using a random index based on the room index.
                float2 roomIdx = floor(i.tangentPosition / _RoomSize);
                float2 texPos = floor(rand(roomIdx) * _InteriorTexCount) / _InteriorTexCount;

                interiorUV /= _InteriorTexCount;
                interiorUV += texPos;

                // lastly, sample the interior texture, and blend it with an exterior!
                fixed4 interior = tex2D(_InteriorTex, interiorUV);
                fixed4 exterior = tex2D(_ExteriorTex, i.uv);

                return lerp(interior, exterior, exterior.a);
            }
            ENDCG
        }
    }
}
