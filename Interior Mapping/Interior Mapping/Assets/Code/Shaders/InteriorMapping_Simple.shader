Shader "InteriorMapping/Simple"
{
    Properties
    {
        [NoScaleOffset]_FacadeTex("Facade", 2D) = "white" {}
        _RoomTex("Room Atlas", 2D) = "white" {}
        _Rooms ("Rooms", Vector) = (1,1,0,0)

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
            };

            struct vertexOutput
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float normal : NORMAL;
                float3 viewDirection : TEXCOORD1;
            };

            sampler2D _FacadeTex;
            sampler2D _RoomTex;
            float4 _RoomTex_ST;
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

            fixed4 frag (vertexOutput i) : SV_Target
            {
                // per room uvs
                float2 roomUV = frac(i.uv);
                // room ID
                float2 roomID = floor(i.uv);
                
                float depthScale = 1.0;

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


                float2 interiorUV = position.xy * lerp(1.0, 0.5, interp);
                interiorUV = interiorUV * 0.5 + 0.5;
                

                fixed4 room = tex2D(_RoomTex, (roomID + interiorUV.xy) / _RoomTex_ST.xy);

                // sample facade
                fixed4 facade = tex2D(_FacadeTex, i.uv);

                return fixed4(lerp(room.rgb, facade.rgb, facade.a), 1.0);


            }
            

            ENDCG
        }
    }
}
