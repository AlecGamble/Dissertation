// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "InteriorMapping/SDF Features"
{
    Properties
    {
        [NoScaleOffset]_FacadeTex("Facade", 2D) = "white" {}
        _RoomTex("Central Rooms", 2D) = "white" {}
        _CornersFrontTex ("Corner Rooms (Front)", 2D) = "white" {}
        _CornersSideTex ("Corner Rooms (Side)", 2D) = "white" {}
        _SDFLUT ("SDF LUT", 2D) = "white" {}
        _Rooms ("Rooms", Vector) = (1,1,1,1)
        _GlassTint("Glass Tint", Color) = (1,1,1,0)

        _SpecularPower("Specular", float) = 10
        _SpecularPower("Gloss", float) = 1



    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "DisableBatching"="true" }
        LOD 200

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "sdf.cginc"

            struct vertexInput
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct vertexOutput
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float normal : NORMAL;

                float3 viewDirection : TEXCOORD1; // potentially use this for ramarching SDFs
                half3 worldNormal : TEXCOORD2;
                float3 worldPosition : TEXCOORD3;
                float4 cameraPosition : TEXCOORD4;

                float3 position : TEXCOORD5;
            };

            #define STEPS 64
            #define MIN_DISTANCE 0.005

            sampler2D _FacadeTex;
            sampler2D _RoomTex;
            sampler2D _CornersFrontTex;
            sampler2D _CornersSideTex;
            sampler2D _SDFLUT;

            float4 _RoomTex_ST;
            float4 _CornersFrontTex_ST;
            float4 _CornersSideTex_ST;
            float4 _SDFLUT_ST;
            float4 _Rooms;
            float4 _GlassTint;

            float _SpecularPower;
            float _Gloss;
            
            

            vertexOutput vert (vertexInput v)
            {
                vertexOutput o;

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv * _Rooms.xy;
                o.normal = v.normal;

                // tangent space camera set up
                o.cameraPosition = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1.0));
                

                float3 viewDirection = v.vertex.xyz - o.cameraPosition.xyz;

                float tangentSign = v.tangent.w * unity_WorldTransformParams.w;
                float3 bitangent = cross(v.normal.xyz, v.tangent.xyz) * tangentSign;
                o.viewDirection = float3(
                    dot(viewDirection, v.tangent.xyz),
                    dot(viewDirection, bitangent),
                    dot(viewDirection, v.normal)
                );
                o.viewDirection *= _Rooms.xyx;
                o.worldPosition = mul(unity_ObjectToWorld, v.vertex).xyz;
                
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                

                return o;
            }

            float map (float3 p, float sdfID)
            {
                if(sdfID > 0.5 && sdfID < 1.5)

                    return sdf_table(p);
                if(sdfID > 1.5  && sdfID < 2.5)
                    return sdf_complex(p);
                return 10000;
            }

                        // estimate normals by sampling distances from adjacent pixels - only works for smooth surfaces
            float3 normal (float3 p, float sdfID)
            {
                const float eps = 0.01;
                return normalize
                (    float3
                (       map(p + float3(eps, 0, 0), sdfID) - map(p - float3(eps, 0, 0), sdfID),
                        map(p + float3(0, eps, 0), sdfID) - map(p - float3(0, eps, 0), sdfID),
                        map(p + float3(0, 0, eps), sdfID) - map(p - float3(0, 0, eps), sdfID)
                    )
                );
            }

            #include "Lighting.cginc"
            fixed4 shade (fixed3 normal, float3 color) {
                fixed3 lightDir = _WorldSpaceLightPos0.xyz;    // Light direction
                fixed3 lightCol = _LightColor0.rgb;        // Light color
                fixed NdotL = max(dot(normal, lightDir),0);
                fixed4 c;
                c.rgb = color * lightCol * NdotL;
                c.a = 1;
                return c;
            }

            fixed4 raymarch (float3 position, float3 direction, float sdfID)
            {
                float originalPosition = position;
                for (int i = 0; i < STEPS; i++)
                {
                    float distance = map(position, sdfID);
        
                    if (distance < MIN_DISTANCE)
                    {
                        fixed4 color = shade(normal(position, sdfID), float3(0.3,0.1,0.0));
                        return color;
                    }
                    position += distance * direction;
                }
                return 0;
            }

            

            float2 rand2(float co)
            {
                return frac(sin(co * float2(12.9898, 78.233)) * 43758.5453);
            }

            fixed4 frag (vertexOutput i) : SV_Target
            {
                // per room uvs
                float2 roomUV = frac(i.uv);
                // room ID
                float2 roomID = floor(i.uv);
                // for each _Rooms.x adjust the index by 1 to make sure the same room is rendered
                roomID.x += saturate((roomID.x) % _Rooms.x);
                // and wrap the final room back around to the first
                roomID.x = roomID.x % (_Rooms.x * 4);

                float2 roomOffset = floor(rand2(roomID.x * _Rooms.w + roomID.y * _Rooms.z) * _Rooms.xy);

                float2 roomLookupIndex = roomOffset;

                fixed farFrac = 0.5;
                float depthScale = 1.0 / (1.0 - farFrac) - 1.0;

                //adjust scale to match room
                float3 position = float3(roomUV * 2 - 1, -1);

                i.viewDirection.z *= -depthScale;

                float3 direction = 1.0 / i.viewDirection;
                
                float3 k = abs(direction) - position * direction;
                float kMin = min(min(k.x, k.y), k.z);
                position += kMin * i.viewDirection;
            
                
                float interp = position.z * 0.5 + 0.5;
                float realZ = saturate(interp) / depthScale + 1.0;
                interp = 1.0 - (1.0 / realZ);
                interp *= depthScale + 1.0;

                float2 interiorUV = position.xy * lerp(1.0, farFrac, interp);
                interiorUV = interiorUV * 0.5 + 0.5;
                

                fixed4 room = tex2D(_RoomTex, (roomLookupIndex + interiorUV.xy) / _RoomTex_ST.xy);

                float leftCorner = 1 - floor(i.uv.x % _Rooms.x);
                float rightCorner = 1 - floor((i.uv.x +1) % _Rooms.x);                
    
                float face = floor(i.uv.x / _Rooms.x);

                if(rightCorner > 0) room = tex2D(_CornersFrontTex, (roomLookupIndex + interiorUV.xy) / _CornersFrontTex_ST.xy);
                if(leftCorner > 0) room = tex2D(_CornersSideTex, (roomLookupIndex + interiorUV.xy) / _CornersSideTex_ST.xy);


                // calculate transparency for windows
                half3 worldViewDir = UnityWorldSpaceViewDir(i.worldPosition);
                worldViewDir.xz *= -1;

                half3 reflection = reflect(-worldViewDir, i.worldNormal);
                half4 skyData = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, reflection);
                half3 skyColor = DecodeHDR (skyData, unity_SpecCube0_HDR);
                skyColor *= _GlassTint;


                room.rgb = lerp(skyColor * _GlassTint, room.rgb, room.a);



                // sample facade
                fixed4 facade = tex2D(_FacadeTex, i.uv);
                float featuresID = tex2D(_SDFLUT, (roomLookupIndex + interiorUV.xy) / _RoomTex_ST.xy) * 2;

                float3 localPosition = position;

                float3 localViewDirection = normalize(localPosition - i.viewDirection );
                float4 features = raymarch(localPosition, localViewDirection, featuresID);
                // view direction is the issue

                fixed3 color = 0;
                color = room.rgb;
                color = lerp(room.rgb * _GlassTint, features.rgb, features.a);
                color = lerp(color, facade.rgb, facade.a);
                // return facade.a;

                return fixed4(color.rgb, 1.0);


            }
            ENDCG
        }
    }
}
