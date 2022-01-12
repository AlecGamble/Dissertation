Shader "InteriorMapping/Consistent Corners"
{
    Properties
    {
        [NoScaleOffset]_FacadeTex("Facade", 2D) = "white" {}
        _RoomTex("Central Rooms", 2D) = "white" {}
        _CornersFrontTex ("Corner Rooms (Front)", 2D) = "white" {}
        _CornersSideTex ("Corner Rooms (Side)", 2D) = "white" {}
        _Rooms ("Rooms", Vector) = (1,1,1,1)

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

            struct vertexInput
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float4 color : COLOR;
            };

            struct vertexOutput
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float normal : NORMAL;
                float3 viewDirection : TEXCOORD1;
                float4 color : COLOR;
            };

            sampler2D _FacadeTex;
            sampler2D _RoomTex;
            sampler2D _CornersFrontTex;
            sampler2D _CornersSideTex;
            float4 _RoomTex_ST;
            float4 _CornersFrontTex_ST;
            float4 _CornersSideTex_ST;
            float4 _Rooms;
            
            

            vertexOutput vert (vertexInput v)
            {
                vertexOutput o;

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv * _Rooms.xy;
                o.normal = v.normal;

                // tangent space camera set up
                float4 camera = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1.0));
                float3 viewDirection = v.vertex.xyz - camera.xyz;

                float tangentSign = v.tangent.w * unity_WorldTransformParams.w;
                float3 bitangent = cross(v.normal.xyz, v.tangent.xyz) * tangentSign;
                o.viewDirection = float3(
                    dot(viewDirection, v.tangent.xyz),
                    dot(viewDirection, bitangent),
                    dot(viewDirection, v.normal)
                );
                o.viewDirection *= _Rooms.xyx;
                return o;
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

                float leftCorner = 1 - floor(i.uv.x % _Rooms.x);//1-saturate((roomID.x) % _Rooms.x);
                float rightCorner = 1 - floor((i.uv.x +1) % _Rooms.x);
    
                float face = floor(i.uv.x / _Rooms.x);

                if(rightCorner > 0) room = tex2D(_CornersFrontTex, (roomLookupIndex + interiorUV.xy) / _CornersFrontTex_ST.xy);
                if(leftCorner > 0) room = tex2D(_CornersSideTex, (roomLookupIndex + interiorUV.xy) / _CornersSideTex_ST.xy);

                // sample facade
                fixed4 facade = tex2D(_FacadeTex, i.uv);

                return fixed4(lerp(room.rgb, facade.rgb, facade.a), 1.0);


            }
            

            ENDCG
        }
    }
}
